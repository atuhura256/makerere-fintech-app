-- ═══════════════════════════════════════════════════════════════════════════
-- FIX SCRIPT: Enable all app queries, RPCs, RLS policies & profile trigger
-- Run this ONCE in your Supabase SQL Editor (SQL Editor → New Query → Paste → Run)
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. Enable RLS on all tables & create policies ─────────────────────────

-- saccos
ALTER TABLE public.saccos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_saccos" ON public.saccos;
DROP POLICY IF EXISTS "auth_insert_saccos" ON public.saccos;
CREATE POLICY "anon_select_saccos" ON public.saccos
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_saccos" ON public.saccos
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- sacco_loan_requests
ALTER TABLE public.sacco_loan_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_loan_requests" ON public.sacco_loan_requests;
DROP POLICY IF EXISTS "auth_insert_loan_requests" ON public.sacco_loan_requests;
DROP POLICY IF EXISTS "auth_update_loan_requests" ON public.sacco_loan_requests;
CREATE POLICY "anon_select_loan_requests" ON public.sacco_loan_requests
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_loan_requests" ON public.sacco_loan_requests
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth_update_loan_requests" ON public.sacco_loan_requests
  FOR UPDATE USING (auth.role() = 'authenticated');

-- sacco_membership_requests
ALTER TABLE public.sacco_membership_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_membership_requests" ON public.sacco_membership_requests;
DROP POLICY IF EXISTS "auth_insert_membership_requests" ON public.sacco_membership_requests;
DROP POLICY IF EXISTS "auth_update_membership_requests" ON public.sacco_membership_requests;
CREATE POLICY "anon_select_membership_requests" ON public.sacco_membership_requests
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_membership_requests" ON public.sacco_membership_requests
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth_update_membership_requests" ON public.sacco_membership_requests
  FOR UPDATE USING (auth.role() = 'authenticated');

-- sacco_admins
ALTER TABLE public.sacco_admins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_admins" ON public.sacco_admins;
CREATE POLICY "anon_select_admins" ON public.sacco_admins
  FOR SELECT USING (true);

-- profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_profiles" ON public.profiles;
DROP POLICY IF EXISTS "auth_upsert_own_profile" ON public.profiles;
CREATE POLICY "anon_select_profiles" ON public.profiles
  FOR SELECT USING (true);
CREATE POLICY "auth_upsert_own_profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND id = auth.uid());
CREATE POLICY "auth_update_own_profile" ON public.profiles
  FOR UPDATE USING (auth.role() = 'authenticated' AND id = auth.uid());

-- tenant_financial_products
ALTER TABLE public.tenant_financial_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_financial_products" ON public.tenant_financial_products;
CREATE POLICY "anon_select_financial_products" ON public.tenant_financial_products
  FOR SELECT USING (true);

-- tenant_transactions
ALTER TABLE public.tenant_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_tenant_txns" ON public.tenant_transactions;
DROP POLICY IF EXISTS "auth_insert_tenant_txns" ON public.tenant_transactions;
CREATE POLICY "anon_select_tenant_txns" ON public.tenant_transactions
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_tenant_txns" ON public.tenant_transactions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- tenant_loans
ALTER TABLE public.tenant_loans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_tenant_loans" ON public.tenant_loans;
DROP POLICY IF EXISTS "auth_insert_tenant_loans" ON public.tenant_loans;
CREATE POLICY "anon_select_tenant_loans" ON public.tenant_loans
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_tenant_loans" ON public.tenant_loans
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- blockchain_audit_footprints
ALTER TABLE public.blockchain_audit_footprints ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_audit" ON public.blockchain_audit_footprints;
DROP POLICY IF EXISTS "auth_insert_audit" ON public.blockchain_audit_footprints;
CREATE POLICY "anon_select_audit" ON public.blockchain_audit_footprints
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_audit" ON public.blockchain_audit_footprints
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- sacco_transactions
ALTER TABLE public.sacco_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_sacco_txns" ON public.sacco_transactions;
DROP POLICY IF EXISTS "auth_insert_sacco_txns" ON public.sacco_transactions;
CREATE POLICY "anon_select_sacco_txns" ON public.sacco_transactions
  FOR SELECT USING (true);
CREATE POLICY "auth_insert_sacco_txns" ON public.sacco_transactions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ─── 2. Auto-create profile row on user signup ──────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    NEW.raw_user_meta_data ->> 'avatar_url',
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── 3. Add 'updated_at' column to profiles if missing ───────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone_number text,
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';

-- ─── 4. All RPC functions ────────────────────────────────────────────────────

-- Drop existing functions first to avoid return-type conflicts
DROP FUNCTION IF EXISTS public.get_sacco_trading_patterns();
DROP FUNCTION IF EXISTS public.get_platform_market_overview();
DROP FUNCTION IF EXISTS public.get_sacco_leaderboard();
DROP FUNCTION IF EXISTS public.get_sacco_daily_volume(text, int);
DROP FUNCTION IF EXISTS public.get_product_performance(text);
DROP FUNCTION IF EXISTS public.get_member_activity_patterns(text);
DROP FUNCTION IF EXISTS public.toggle_tenant_member_status(text, text, text);
DROP FUNCTION IF EXISTS public.toggle_member_ledger_freeze(text, text, text);
DROP FUNCTION IF EXISTS public.get_global_audit_overview();
DROP FUNCTION IF EXISTS public.check_sacco_admin_by_email(text, text);
DROP FUNCTION IF EXISTS public.check_is_sacco_member(text, text);
DROP FUNCTION IF EXISTS public.get_user_ledger_balance_sheet(text);
DROP FUNCTION IF EXISTS public.calculate_dynamic_loan_interest(numeric, int);
DROP FUNCTION IF EXISTS public.resolve_sacco_loan_request(text, text, text);

-- get_sacco_trading_patterns — returns trend data per SACCO
CREATE OR REPLACE FUNCTION public.get_sacco_trading_patterns()
RETURNS TABLE(
  sacco_name text,
  schema_name text,
  pattern text,
  confidence_score numeric
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.sacco_name::text,
    s.schema_name::text,
    CASE
      WHEN tx.vol > 0 AND tx.vol > tx.prev_vol THEN 'BULLISH'::text
      WHEN tx.vol > 0 AND tx.vol < tx.prev_vol THEN 'BEARISH'::text
      ELSE 'STABLE'::text
    END AS pattern,
    ROUND(LEAST(GREATEST(COALESCE(tx.vol, 0)::numeric / NULLIF(GREATEST(tx.prev_vol, 1), 0), 0.5), 1.5), 2) AS confidence_score
  FROM public.saccos s
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) AS vol,
      COUNT(*) FILTER (WHERE st.created_at < NOW() - INTERVAL '30 days') AS prev_vol
    FROM public.sacco_transactions st
    WHERE st.schema_name = s.schema_name
  ) tx ON true
  ORDER BY tx.vol DESC NULLS LAST;
END;
$$;

-- get_platform_market_overview — aggregate stats (matches home_dashboard field names)
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
    (SELECT COUNT(*) FROM public.profiles)::bigint AS active_members_count;
END;
$$;

-- get_sacco_leaderboard — rank SACCOS by volume
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
    0::bigint AS member_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(st.amount) FILTER (WHERE st.status = 'SUCCESSFUL'), 0) DESC)::bigint AS rank
  FROM public.saccos s
  LEFT JOIN public.sacco_transactions st ON st.schema_name = s.schema_name
  GROUP BY s.sacco_id, s.sacco_name, s.schema_name
  ORDER BY total_volume DESC;
END;
$$;

-- get_sacco_daily_volume — daily volume for a specific SACCO
CREATE OR REPLACE FUNCTION public.get_sacco_daily_volume(
  target_schema_name text,
  days_back int DEFAULT 30
)
RETURNS TABLE(
  date_label text,
  total_volume numeric,
  transaction_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    to_char(st.created_at::date, 'YYYY-MM-DD')::text AS date_label,
    COALESCE(SUM(st.amount), 0)::numeric AS total_volume,
    COUNT(*)::bigint AS transaction_count
  FROM public.sacco_transactions st
  WHERE st.schema_name = target_schema_name
    AND st.created_at >= NOW() - (days_back || ' days')::interval
  GROUP BY st.created_at::date
  ORDER BY st.created_at::date;
END;
$$;

-- get_product_performance — tenant financial products
CREATE OR REPLACE FUNCTION public.get_product_performance(
  target_schema_name text DEFAULT ''
)
RETURNS TABLE(
  product_id uuid,
  product_name text,
  interest_rate numeric,
  minimum_balance numeric,
  total_deposits numeric
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.product_id,
    p.product_name::text,
    p.interest_rate,
    p.minimum_balance,
    COALESCE(SUM(t.amount) FILTER (WHERE t.transaction_type = 'DEPOSIT'), 0)::numeric AS total_deposits
  FROM public.tenant_financial_products p
  LEFT JOIN public.tenant_transactions t ON t.product_id = p.product_id
  GROUP BY p.product_id
  ORDER BY p.product_name;
END;
$$;

-- get_member_activity_patterns — member activity by SACCO
CREATE OR REPLACE FUNCTION public.get_member_activity_patterns(
  target_schema_name text DEFAULT ''
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  transaction_count bigint,
  total_volume numeric,
  last_active timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    st.user_id,
    COALESCE(p.full_name::text, 'Unknown')::text AS full_name,
    COUNT(*)::bigint AS transaction_count,
    COALESCE(SUM(st.amount), 0)::numeric AS total_volume,
    MAX(st.created_at)::timestamp with time zone AS last_active
  FROM public.sacco_transactions st
  LEFT JOIN public.profiles p ON p.id = st.user_id
  WHERE ($1 = '' OR st.schema_name = $1)
  GROUP BY st.user_id, p.full_name
  ORDER BY total_volume DESC
  LIMIT 100;
END;
$$;

-- toggle_tenant_member_status — toggle member active/suspended
CREATE OR REPLACE FUNCTION public.toggle_tenant_member_status(
  target_schema_name text,
  target_user_id text,
  new_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.profiles
  SET status = new_status
  WHERE id = target_user_id::uuid;
END;
$$;

-- toggle_member_ledger_freeze — fallback toggle
CREATE OR REPLACE FUNCTION public.toggle_member_ledger_freeze(
  p_schema_name text,
  p_user_id text,
  p_current_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.profiles
  SET status = CASE WHEN p_current_status = 'ACTIVE' THEN 'SUSPENDED' ELSE 'ACTIVE' END
  WHERE id = p_user_id::uuid;
END;
$$;

-- get_global_audit_overview — blockchain audit summary
CREATE OR REPLACE FUNCTION public.get_global_audit_overview()
RETURNS TABLE(
  audit_id uuid,
  transaction_id uuid,
  merkle_root text,
  blockchain_network text,
  smart_contract_address text,
  blockchain_tx_hash text,
  anchored_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.blockchain_audit_footprints
  ORDER BY anchored_at DESC
  LIMIT 100;
END;
$$;

-- check_sacco_admin_by_email — verify admin
CREATE OR REPLACE FUNCTION public.check_sacco_admin_by_email(
  target_schema_name text,
  p_user_email text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.sacco_admins
  WHERE schema_name = target_schema_name
    AND admin_email = p_user_email;
  RETURN v_count > 0;
END;
$$;

-- check_is_sacco_member — check membership status
CREATE OR REPLACE FUNCTION public.check_is_sacco_member(
  target_schema_name text,
  target_user_id text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.sacco_membership_requests
  WHERE schema_name = target_schema_name
    AND user_id = target_user_id
    AND status = 'APPROVED';
  RETURN v_count > 0;
END;
$$;

-- get_user_ledger_balance_sheet — user's financial summary (profile screen)
CREATE OR REPLACE FUNCTION public.get_user_ledger_balance_sheet(
  p_user_id text DEFAULT ''
)
RETURNS TABLE(
  total_saved_ugx numeric,
  total_borrowed_ugx numeric,
  active_saccos_joined bigint
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE((SELECT SUM(amount) FROM public.sacco_transactions WHERE user_id = p_user_id::uuid AND transaction_type IN ('DEPOSIT','SAVINGS') AND status = 'SUCCESSFUL'), 0)::numeric AS total_saved_ugx,
    COALESCE((SELECT SUM(principal_amount) FROM public.sacco_loan_requests WHERE user_id = p_user_id::uuid AND status IN ('APPROVED','DISBURSED')), 0)::numeric AS total_borrowed_ugx,
    COALESCE((SELECT COUNT(DISTINCT schema_name) FROM public.sacco_transactions WHERE user_id = p_user_id::uuid), 0)::bigint AS active_saccos_joined;
END;
$$;

-- calculate_dynamic_loan_interest — loan interest calculator
CREATE OR REPLACE FUNCTION public.calculate_dynamic_loan_interest(
  p_principal numeric,
  p_months int
)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_rate numeric;
BEGIN
  v_rate := 5.0 + (p_months::numeric / 3.0) * 0.5;
  v_rate := LEAST(v_rate, 18.0);
  RETURN ROUND(v_rate, 2);
END;
$$;

-- resolve_sacco_loan_request — approve/reject/disburse loans
CREATE OR REPLACE FUNCTION public.resolve_sacco_loan_request(
  p_loan_id text,
  p_action text,
  p_blockchain_hash text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF p_action IN ('APPROVE', 'DISBURSE') THEN
    UPDATE public.sacco_loan_requests
    SET status = CASE
          WHEN p_action = 'APPROVE' THEN 'APPROVED'
          WHEN p_action = 'DISBURSE' THEN 'DISBURSED'
          ELSE status
        END,
        updated_at = NOW()
    WHERE request_id = p_loan_id::uuid;
  ELSIF p_action = 'REJECT' THEN
    UPDATE public.sacco_loan_requests
    SET status = 'REJECTED',
        updated_at = NOW()
    WHERE request_id = p_loan_id::uuid;
  END IF;
END;
$$;

-- ─── 5. Grant usage to anon & authenticated roles ────────────────────────────

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
