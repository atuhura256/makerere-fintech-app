-- ═══════════════════════════════════════════════════════════════════════════
-- VERIFY CHAIN HASH — Simple, robust version
-- Run in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop old version first
DROP FUNCTION IF EXISTS public.verify_chain_hash(text);

CREATE OR REPLACE FUNCTION public.verify_chain_hash(p_hash text)
RETURNS TABLE(
  found          boolean,
  hash_type      text,
  block_index    bigint,
  transaction_id uuid,
  user_id        uuid,
  amount         numeric,
  transaction_type text,
  status         text,
  prev_hash      text,
  block_hash     text,
  merkle_root    text,
  chain_valid    boolean,
  created_at     timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_clean text;
  v_rec record;
  v_found boolean := false;
  v_match_type text := '';
  v_chain_valid boolean := true;
  v_prev text;
BEGIN
  -- Clean input: lowercase, remove everything except hex chars
  v_clean := lower(regexp_replace(p_hash, '[^a-f0-9]', '', 'g'));

  -- Too short to be a real hash
  IF length(v_clean) < 8 THEN
    found := false;
    hash_type := NULL;
    block_index := NULL;
    transaction_id := NULL;
    user_id := NULL;
    amount := NULL;
    transaction_type := NULL;
    status := NULL;
    prev_hash := NULL;
    block_hash := NULL;
    merkle_root := NULL;
    chain_valid := NULL;
    created_at := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  -- Search chain table for matching hash
  FOR v_rec IN
    SELECT
      c.block_index, c.transaction_id, c.user_id, c.amount,
      c.transaction_type, c.status, c.prev_hash, c.block_hash,
      c.merkle_root, c.created_at
    FROM public.user_transaction_chains c
    ORDER BY c.user_id, c.block_index ASC
  LOOP
    -- Check block_hash
    IF lower(replace(v_rec.block_hash, ' ', '')) = v_clean
       OR lower(replace(v_rec.block_hash, ' ', '')) LIKE v_clean || '%' THEN
      v_found := true;
      v_match_type := 'block_hash';

      found := true;
      hash_type := v_match_type;
      block_index := v_rec.block_index;
      transaction_id := v_rec.transaction_id;
      user_id := v_rec.user_id;
      amount := v_rec.amount;
      transaction_type := v_rec.transaction_type;
      status := v_rec.status;
      prev_hash := v_rec.prev_hash;
      block_hash := v_rec.block_hash;
      merkle_root := v_rec.merkle_root;
      created_at := v_rec.created_at;
      EXIT;
    END IF;

    -- Check prev_hash
    IF lower(replace(v_rec.prev_hash, ' ', '')) = v_clean
       OR lower(replace(v_rec.prev_hash, ' ', '')) LIKE v_clean || '%' THEN
      v_found := true;
      v_match_type := 'prev_hash';

      found := true;
      hash_type := v_match_type;
      block_index := v_rec.block_index;
      transaction_id := v_rec.transaction_id;
      user_id := v_rec.user_id;
      amount := v_rec.amount;
      transaction_type := v_rec.transaction_type;
      status := v_rec.status;
      prev_hash := v_rec.prev_hash;
      block_hash := v_rec.block_hash;
      merkle_root := v_rec.merkle_root;
      created_at := v_rec.created_at;
      EXIT;
    END IF;

    -- Check merkle_root
    IF v_rec.merkle_root IS NOT NULL
       AND (lower(replace(v_rec.merkle_root, ' ', '')) = v_clean
            OR lower(replace(v_rec.merkle_root, ' ', '')) LIKE v_clean || '%') THEN
      v_found := true;
      v_match_type := 'merkle_root';

      found := true;
      hash_type := v_match_type;
      block_index := v_rec.block_index;
      transaction_id := v_rec.transaction_id;
      user_id := v_rec.user_id;
      amount := v_rec.amount;
      transaction_type := v_rec.transaction_type;
      status := v_rec.status;
      prev_hash := v_rec.prev_hash;
      block_hash := v_rec.block_hash;
      merkle_root := v_rec.merkle_root;
      created_at := v_rec.created_at;
      EXIT;
    END IF;
  END LOOP;

  -- If found, check chain integrity for that user
  IF v_found AND user_id IS NOT NULL THEN
    v_prev := '0000000000000000000000000000000000000000000000000000000000000000';
    FOR v_rec IN
      SELECT c.prev_hash, c.block_hash
      FROM public.user_transaction_chains c
      WHERE c.user_id = verify_chain_hash.user_id
      ORDER BY c.block_index ASC
    LOOP
      IF v_rec.prev_hash != v_prev THEN
        v_chain_valid := false;
        EXIT;
      END IF;
      v_prev := v_rec.block_hash;
    END LOOP;
    chain_valid := v_chain_valid;
  END IF;

  -- If not found, return false
  IF NOT v_found THEN
    found := false;
    hash_type := NULL;
    block_index := NULL;
    transaction_id := NULL;
    user_id := NULL;
    amount := NULL;
    transaction_type := NULL;
    status := NULL;
    prev_hash := NULL;
    block_hash := NULL;
    merkle_root := NULL;
    chain_valid := NULL;
    created_at := NULL;
  END IF;

  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_chain_hash(text) TO anon, authenticated;
