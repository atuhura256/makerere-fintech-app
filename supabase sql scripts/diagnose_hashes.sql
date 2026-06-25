-- ═══════════════════════════════════════════════════════════════════════════
-- DIAGNOSTIC: Check what exists in the database
-- Run this FIRST to understand the state of your data
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. How many transactions exist?
SELECT 'sacco_transactions count' as check_name, COUNT(*) as total FROM public.sacco_transactions;

-- 2. How many chain blocks exist?
SELECT 'user_transaction_chains count' as check_name, COUNT(*) as total FROM public.user_transaction_chains;

-- 3. Do any users have transactions but NO chain blocks?
SELECT
  t.user_id,
  COUNT(*) as tx_count,
  (SELECT COUNT(*) FROM public.user_transaction_chains c WHERE c.user_id = t.user_id) as chain_count
FROM public.sacco_transactions t
WHERE t.user_id IS NOT NULL
GROUP BY t.user_id
ORDER BY tx_count DESC
LIMIT 10;

-- 4. Show sample hashes from user_transaction_chains (if any exist)
SELECT
  block_index,
  left(block_hash, 16) || '...' as hash_preview,
  left(prev_hash, 16) || '...' as prev_preview,
  transaction_type,
  amount
FROM public.user_transaction_chains
ORDER BY block_index
LIMIT 5;
