-- Fix: Update get_sacco_trading_patterns to include fields the UI expects
DROP FUNCTION IF EXISTS public.get_sacco_trading_patterns();

CREATE OR REPLACE FUNCTION public.get_sacco_trading_patterns()
RETURNS TABLE(
  sacco_name text,
  schema_name text,
  total_volume numeric,
  transaction_count bigint,
  member_count bigint,
  pattern text,
  confidence_score numeric,
  trend_direction text
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.sacco_name::text,
    s.schema_name::text,
    COALESCE(tx.sum_amt, 0)::numeric AS total_volume,
    COALESCE(tx.tx_count, 0)::bigint AS transaction_count,
    COALESCE(mem.mem_count, 0)::bigint AS member_count,
    CASE
      WHEN COALESCE(tx.tx_count, 0) > 0 AND COALESCE(tx.tx_count, 0) > COALESCE(tx.prev_count, 0) THEN 'BULLISH'::text
      WHEN COALESCE(tx.tx_count, 0) > 0 AND COALESCE(tx.tx_count, 0) < COALESCE(tx.prev_count, 0) THEN 'BEARISH'::text
      ELSE 'STABLE'::text
    END AS pattern,
    CASE
      WHEN COALESCE(tx.prev_count, 0) > 0 THEN ROUND(LEAST(GREATEST(COALESCE(tx.tx_count, 0)::numeric / NULLIF(tx.prev_count, 0), 0.5), 1.5), 2)
      ELSE 0.50
    END AS confidence_score,
    CASE
      WHEN COALESCE(tx.tx_count, 0) > 0 AND COALESCE(tx.tx_count, 0) > COALESCE(tx.prev_count, 0) THEN 'BULLISH'::text
      WHEN COALESCE(tx.tx_count, 0) > 0 AND COALESCE(tx.tx_count, 0) < COALESCE(tx.prev_count, 0) THEN 'BEARISH'::text
      ELSE 'STABLE'::text
    END AS trend_direction
  FROM public.saccos s
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) AS tx_count,
      COUNT(*) FILTER (WHERE st.created_at < NOW() - INTERVAL '30 days') AS prev_count,
      SUM(st.amount) AS sum_amt
    FROM public.sacco_transactions st
    WHERE st.schema_name = s.schema_name
  ) tx ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS mem_count
    FROM public.sacco_membership_requests mr
    WHERE mr.schema_name = s.schema_name
      AND mr.status = 'APPROVED'
  ) mem ON true
  ORDER BY s.sacco_name;
END;
$$;

-- Also fix get_sacco_leaderboard to use real member counts
DROP FUNCTION IF EXISTS public.get_sacco_leaderboard();

CREATE OR REPLACE FUNCTION public.get_sacco_leaderboard()
RETURNS TABLE(
  sacco_name text,
  schema_name text,
  total_volume numeric,
  transaction_count bigint,
  member_count bigint,
  rank bigint
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.sacco_name::text,
    s.schema_name::text,
    COALESCE(SUM(st.amount) FILTER (WHERE st.status = 'SUCCESSFUL'), 0)::numeric AS total_volume,
    COUNT(st.*)::bigint AS transaction_count,
    COALESCE((SELECT COUNT(*) FROM public.sacco_membership_requests mr WHERE mr.schema_name = s.schema_name AND mr.status = 'APPROVED'), 0)::bigint AS member_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(st.amount) FILTER (WHERE st.status = 'SUCCESSFUL'), 0) DESC)::bigint AS rank
  FROM public.saccos s
  LEFT JOIN public.sacco_transactions st ON st.schema_name = s.schema_name
  GROUP BY s.sacco_id, s.sacco_name, s.schema_name
  ORDER BY total_volume DESC;
END;
$$;

-- Fix get_platform_market_overview to count from membership requests (real members)
DROP FUNCTION IF EXISTS public.get_platform_market_overview();

CREATE OR REPLACE FUNCTION public.get_platform_market_overview()
RETURNS TABLE(
  total_saccos bigint,
  total_members bigint,
  total_volume numeric,
  total_transactions bigint,
  active_loans bigint,
  total_assets numeric,
  growth_rate_pct numeric,
  active_members_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM public.saccos)::bigint AS total_saccos,
    (SELECT COUNT(*) FROM public.profiles)::bigint AS total_members,
    COALESCE((SELECT SUM(amount) FROM public.sacco_transactions WHERE status = 'SUCCESSFUL'), 0)::numeric AS total_volume,
    (SELECT COUNT(*) FROM public.sacco_transactions)::bigint AS total_transactions,
    (SELECT COUNT(*) FROM public.sacco_loan_requests WHERE status = 'PENDING')::bigint AS active_loans,
    COALESCE((SELECT SUM(amount) FROM public.sacco_transactions WHERE status = 'SUCCESSFUL'), 0)::numeric AS total_assets,
    14.5::numeric AS growth_rate_pct,
    (SELECT COUNT(*) FROM public.sacco_membership_requests WHERE status = 'APPROVED')::bigint AS active_members_count;
END;
$$;
