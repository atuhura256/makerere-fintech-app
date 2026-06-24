-- ═══════════════════════════════════════════════════════════════════════════
-- SUPER ADMIN SETUP — Table, function, RLS policies & bootstrap
-- Run AFTER fix_supabase.sql (run only once)
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. Create the super_admins table ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.super_admins (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  email text NOT NULL,
  role text DEFAULT 'SUPER_ADMIN',
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT super_admins_pkey PRIMARY KEY (id),
  CONSTRAINT super_admins_user_id_key UNIQUE (user_id)
);

-- ─── 2. Enable RLS ──────────────────────────────────────────────────────────

ALTER TABLE public.super_admins ENABLE ROW LEVEL SECURITY;

-- ─── 3. Create SECURITY DEFINER check function (bypasses RLS on super_admins) ─

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.super_admins
    WHERE user_id = auth.uid()
  );
END;
$$;

-- ─── 4. RLS policies for super_admins table itself ──────────────────────────

DROP POLICY IF EXISTS "super_admins_select" ON public.super_admins;
CREATE POLICY "super_admins_select" ON public.super_admins
  FOR SELECT USING (public.is_super_admin());

DROP POLICY IF EXISTS "super_admins_insert" ON public.super_admins;
CREATE POLICY "super_admins_insert" ON public.super_admins
  FOR INSERT WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS "super_admins_update" ON public.super_admins;
CREATE POLICY "super_admins_update" ON public.super_admins
  FOR UPDATE USING (public.is_super_admin());

DROP POLICY IF EXISTS "super_admins_delete" ON public.super_admins;
CREATE POLICY "super_admins_delete" ON public.super_admins
  FOR DELETE USING (public.is_super_admin());

-- ─── 5. Grant super admin full access to ALL existing tables ─────────────────
--     These work alongside existing anon/auth policies (PostgreSQL ORs them)

-- saccos
DROP POLICY IF EXISTS "super_admin_saccos" ON public.saccos;
CREATE POLICY "super_admin_saccos" ON public.saccos
  FOR ALL USING (public.is_super_admin());

-- profiles
DROP POLICY IF EXISTS "super_admin_profiles" ON public.profiles;
CREATE POLICY "super_admin_profiles" ON public.profiles
  FOR ALL USING (public.is_super_admin());

-- sacco_loan_requests
DROP POLICY IF EXISTS "super_admin_loan_requests" ON public.sacco_loan_requests;
CREATE POLICY "super_admin_loan_requests" ON public.sacco_loan_requests
  FOR ALL USING (public.is_super_admin());

-- sacco_membership_requests
DROP POLICY IF EXISTS "super_admin_membership_requests" ON public.sacco_membership_requests;
CREATE POLICY "super_admin_membership_requests" ON public.sacco_membership_requests
  FOR ALL USING (public.is_super_admin());

-- sacco_admins
DROP POLICY IF EXISTS "super_admin_sacco_admins" ON public.sacco_admins;
CREATE POLICY "super_admin_sacco_admins" ON public.sacco_admins
  FOR ALL USING (public.is_super_admin());

-- tenant_financial_products
DROP POLICY IF EXISTS "super_admin_financial_products" ON public.tenant_financial_products;
CREATE POLICY "super_admin_financial_products" ON public.tenant_financial_products
  FOR ALL USING (public.is_super_admin());

-- tenant_transactions
DROP POLICY IF EXISTS "super_admin_tenant_txns" ON public.tenant_transactions;
CREATE POLICY "super_admin_tenant_txns" ON public.tenant_transactions
  FOR ALL USING (public.is_super_admin());

-- tenant_loans
DROP POLICY IF EXISTS "super_admin_tenant_loans" ON public.tenant_loans;
CREATE POLICY "super_admin_tenant_loans" ON public.tenant_loans
  FOR ALL USING (public.is_super_admin());

-- blockchain_audit_footprints
DROP POLICY IF EXISTS "super_admin_audit" ON public.blockchain_audit_footprints;
CREATE POLICY "super_admin_audit" ON public.blockchain_audit_footprints
  FOR ALL USING (public.is_super_admin());

-- sacco_transactions
DROP POLICY IF EXISTS "super_admin_sacco_txns" ON public.sacco_transactions;
CREATE POLICY "super_admin_sacco_txns" ON public.sacco_transactions
  FOR ALL USING (public.is_super_admin());

-- ─── 6. Grant execute on is_super_admin to anon/authenticated ─────────────────

GRANT EXECUTE ON FUNCTION public.is_super_admin TO anon, authenticated;

-- ─── 7. Bootstrap ────────────────────────────────────────────────────────────
-- Run this AFTER inserting at least one super admin manually:
--
--   INSERT INTO public.super_admins (user_id, email, role, created_by)
--   VALUES (
--     (SELECT id FROM auth.users WHERE email = 'your-admin@email.com' LIMIT 1),
--     'your-admin@email.com',
--     'SUPER_ADMIN',
--     NULL
--   );
--
-- Replace 'your-admin@email.com' with the actual email of the first admin.
-- After that, admins can add more admins via the in-app admin panel.
