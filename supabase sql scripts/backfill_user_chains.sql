-- ═══════════════════════════════════════════════════════════════════════════
-- BACKFILL: Populate user_transaction_chains from existing sacco_transactions
-- Run ONCE in Supabase SQL Editor AFTER user_transaction_chains.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- Ensure pgcrypto is available (needed for digest / SHA-256)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  rec RECORD;
  v_user_id       uuid;
  v_prev_hash     text := '0000000000000000000000000000000000000000000000000000000000000000';
  v_block_index   bigint := 0;
  v_nonce         bigint;
  v_payload       text;
  v_block_hash    text;
  v_merkle        text;
  v_inserted      bigint := 0;
  v_skipped       bigint := 0;
  v_current_user  uuid := NULL;
BEGIN
  -- Loop through every transaction ordered by user, then chronological
  FOR rec IN
    SELECT
      t.transaction_id,
      t.user_id,
      t.sacco_id,
      t.schema_name,
      t.transaction_type,
      t.amount,
      t.reference_id,
      t.status,
      t.created_at
    FROM public.sacco_transactions t
    WHERE t.user_id IS NOT NULL
    ORDER BY t.user_id, t.created_at ASC, t.transaction_id ASC
  LOOP
    -- Reset chain state when we hit a new user
    IF v_current_user IS DISTINCT FROM rec.user_id THEN
      v_current_user := rec.user_id;
      v_block_index  := 0;
      v_prev_hash    := '0000000000000000000000000000000000000000000000000000000000000000';
    END IF;

    -- Skip if this transaction already exists in the chain
    IF EXISTS (
      SELECT 1 FROM public.user_transaction_chains
      WHERE transaction_id = rec.transaction_id
    ) THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    -- Compute nonce (deterministic: amount + block index)
    v_nonce := (rec.amount::bigint) + v_block_index;

    -- Build hash payload (matches build_user_chain_block logic)
    v_payload := rec.user_id::text || rec.transaction_id::text || v_block_index::text ||
                 rec.amount::text || v_prev_hash || v_nonce::text || COALESCE(rec.reference_id, '');
    v_block_hash := encode(digest(v_payload, 'sha256'), 'hex');

    -- Merkle root (hash of block_hash + type + amount)
    v_merkle := encode(digest(v_block_hash || COALESCE(rec.transaction_type, 'TX') || rec.amount::text, 'sha256'), 'hex');

    -- Insert the chain block
    INSERT INTO public.user_transaction_chains (
      user_id, block_index, transaction_id, sacco_id, schema_name,
      transaction_type, amount, reference_id, status,
      nonce, prev_hash, block_hash, merkle_root, created_at
    ) VALUES (
      rec.user_id, v_block_index, rec.transaction_id,
      rec.sacco_id, COALESCE(rec.schema_name, ''),
      COALESCE(rec.transaction_type, 'UNKNOWN'), rec.amount,
      rec.reference_id, COALESCE(rec.status, 'SUCCESSFUL'),
      v_nonce, v_prev_hash, v_block_hash, v_merkle, rec.created_at
    );

    -- Advance chain: next block's prev_hash = this block's hash
    v_prev_hash   := v_block_hash;
    v_block_index := v_block_index + 1;
    v_inserted    := v_inserted + 1;
  END LOOP;

  RAISE NOTICE 'Backfill complete: % blocks inserted, % skipped (already existed)', v_inserted, v_skipped;
END $$;

-- ─── Verify the backfill ─────────────────────────────────────────────────
-- Run these after the backfill to confirm:

-- Count per user
-- SELECT user_id, COUNT(*) as blocks FROM user_transaction_chains GROUP BY user_id ORDER BY blocks DESC;

-- Check chain integrity for a specific user
-- SELECT verify_user_chain('USER_UUID_HERE');

-- Full chain for a user
-- SELECT * FROM get_user_chain('USER_UUID_HERE');
