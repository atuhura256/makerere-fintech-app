-- ═══════════════════════════════════════════════════════════════════════════
-- USER TRANSACTION CHAINS — Per-user immutable blockchain audit ledger
-- Each user has a sequential chain starting from their first transaction.
-- Every new block references the previous block's hash, forming an
-- immutable linked chain that can never be retroactively altered.
-- Run ONCE in Supabase SQL Editor.
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. Create the chain table ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_transaction_chains (
  chain_id        uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL,
  block_index     bigint NOT NULL,
  transaction_id  uuid NOT NULL,
  sacco_id        uuid,
  schema_name     text,
  transaction_type text NOT NULL,
  amount          numeric NOT NULL,
  reference_id    text,
  status          text NOT NULL DEFAULT 'SUCCESSFUL',
  nonce           bigint NOT NULL DEFAULT 0,
  prev_hash       text NOT NULL DEFAULT '0000000000000000000000000000000000000000000000000000000000000000',
  block_hash      text NOT NULL,
  merkle_root     text,
  created_at      timestamp with time zone DEFAULT now(),
  CONSTRAINT user_transaction_chains_pkey PRIMARY KEY (chain_id),
  CONSTRAINT user_transaction_chains_user_block UNIQUE (user_id, block_index),
  CONSTRAINT user_transaction_chains_tx_unique UNIQUE (transaction_id),
  CONSTRAINT user_transaction_chains_user_fk FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT user_transaction_chains_tx_fk FOREIGN KEY (transaction_id) REFERENCES public.sacco_transactions(transaction_id)
);

-- ─── 2. Indexes for fast lookups ──────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_utx_chain_user ON public.user_transaction_chains(user_id);
CREATE INDEX IF NOT EXISTS idx_utx_chain_hash ON public.user_transaction_chains(block_hash);
CREATE INDEX IF NOT EXISTS idx_utx_chain_prev ON public.user_transaction_chains(prev_hash);

-- ─── 3. Enable RLS ────────────────────────────────────────────────────────

ALTER TABLE public.user_transaction_chains ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_user_chains" ON public.user_transaction_chains;
DROP POLICY IF EXISTS "auth_insert_user_chains" ON public.user_transaction_chains;

CREATE POLICY "anon_select_user_chains"
  ON public.user_transaction_chains FOR SELECT USING (true);
CREATE POLICY "auth_insert_user_chains"
  ON public.user_transaction_chains FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ─── 4. RPC: Get a user's full chain (ordered from genesis) ───────────────

CREATE OR REPLACE FUNCTION public.get_user_chain(p_user_id text)
RETURNS TABLE(
  chain_id        uuid,
  block_index     bigint,
  transaction_id  uuid,
  transaction_type text,
  amount          numeric,
  reference_id    text,
  status          text,
  prev_hash       text,
  block_hash      text,
  merkle_root     text,
  created_at      timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.chain_id,
    c.block_index,
    c.transaction_id,
    c.transaction_type,
    c.amount,
    c.reference_id,
    c.status,
    c.prev_hash,
    c.block_hash,
    c.merkle_root,
    c.created_at
  FROM public.user_transaction_chains c
  WHERE c.user_id = p_user_id::uuid
  ORDER BY c.block_index ASC;
END;
$$;

-- ─── 5. RPC: Verify chain integrity for a user ────────────────────────────
-- Returns true if every block's prev_hash matches the prior block's hash.

CREATE OR REPLACE FUNCTION public.verify_user_chain(p_user_id text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  rec RECORD;
  expected_prev text := '0000000000000000000000000000000000000000000000000000000000000000';
BEGIN
  FOR rec IN
    SELECT prev_hash, block_hash
    FROM public.user_transaction_chains
    WHERE user_id = p_user_id::uuid
    ORDER BY block_index ASC
  LOOP
    IF rec.prev_hash != expected_prev THEN
      RETURN false;
    END IF;
    expected_prev := rec.block_hash;
  END LOOP;
  RETURN true;
END;
$$;

-- ─── 6. RPC: Get chain summary stats for a user ───────────────────────────

CREATE OR REPLACE FUNCTION public.get_user_chain_summary(p_user_id text)
RETURNS TABLE(
  total_blocks     bigint,
  total_volume     numeric,
  chain_integrity  boolean,
  first_block_at   timestamp with time zone,
  latest_block_at  timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::bigint AS total_blocks,
    COALESCE(SUM(c.amount), 0)::numeric AS total_volume,
    public.verify_user_chain(p_user_id) AS chain_integrity,
    MIN(c.created_at)::timestamp with time zone AS first_block_at,
    MAX(c.created_at)::timestamp with time zone AS latest_block_at
  FROM public.user_transaction_chains c
  WHERE c.user_id = p_user_id::uuid;
END;
$$;

-- ─── 7. RPC: Build the next block for a user (called after each transaction)

CREATE OR REPLACE FUNCTION public.build_user_chain_block(
  p_user_id text,
  p_transaction_id text,
  p_sacco_id text DEFAULT NULL,
  p_schema_name text DEFAULT '',
  p_transaction_type text DEFAULT 'DEPOSIT',
  p_amount numeric DEFAULT 0,
  p_reference_id text DEFAULT ''
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_next_index   bigint;
  v_prev_hash    text;
  v_nonce        bigint;
  v_payload      text;
  v_block_hash   text;
  v_merkle       text;
  v_chain_id     uuid;
BEGIN
  -- Get next block index
  SELECT COALESCE(MAX(block_index), -1) + 1 INTO v_next_index
  FROM public.user_transaction_chains
  WHERE user_id = p_user_id::uuid;

  -- Get previous block hash
  IF v_next_index = 0 THEN
    v_prev_hash := '0000000000000000000000000000000000000000000000000000000000000000';
  ELSE
    SELECT block_hash INTO v_prev_hash
    FROM public.user_transaction_chains
    WHERE user_id = p_user_id::uuid AND block_index = v_next_index - 1;
  END IF;

  -- Simple deterministic nonce from amount + index
  v_nonce := (p_amount::bigint) + v_next_index;

  -- Build hash payload
  v_payload := p_user_id || p_transaction_id || v_next_index::text || p_amount::text || v_prev_hash || v_nonce::text || COALESCE(p_reference_id, '');
  v_block_hash := encode(digest(v_payload, 'sha256'), 'hex');

  -- Merkle root (simplified: hash of hash + type + amount)
  v_merkle := encode(digest(v_block_hash || p_transaction_type || p_amount::text, 'sha256'), 'hex');

  -- Insert block
  INSERT INTO public.user_transaction_chains (
    user_id, block_index, transaction_id, sacco_id, schema_name,
    transaction_type, amount, reference_id, status,
    nonce, prev_hash, block_hash, merkle_root
  ) VALUES (
    p_user_id::uuid, v_next_index, p_transaction_id::uuid,
    CASE WHEN p_sacco_id IS NOT NULL AND p_sacco_id != '' THEN p_sacco_id::uuid ELSE NULL END,
    COALESCE(p_schema_name, ''),
    p_transaction_type, p_amount, p_reference_id, 'SUCCESSFUL',
    v_nonce, v_prev_hash, v_block_hash, v_merkle
  )
  RETURNING chain_id INTO v_chain_id;

  RETURN v_chain_id;
END;
$$;

-- ─── 8. Grant permissions ─────────────────────────────────────────────────

GRANT SELECT, INSERT ON public.user_transaction_chains TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
