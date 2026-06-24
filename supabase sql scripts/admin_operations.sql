-- ═══════════════════════════════════════════════════════════════════════════
-- SUPER ADMIN OPERATIONS — Delete user, delete SACCO, remove member
-- Run ONCE after super_admin_setup.sql and fix_supabase.sql
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1. admin_delete_user — removes user from ALL tables + auth.users ──────

CREATE OR REPLACE FUNCTION public.admin_delete_user(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can delete users';
  END IF;

  DELETE FROM public.sacco_membership_requests WHERE user_id = p_user_id;
  DELETE FROM public.sacco_loan_requests WHERE user_id = p_user_id;
  DELETE FROM public.sacco_transactions WHERE user_id = p_user_id;
  DELETE FROM public.sacco_admins WHERE user_id = p_user_id;
  DELETE FROM public.super_admins WHERE user_id = p_user_id;
  DELETE FROM public.tenant_transactions WHERE user_id = p_user_id;
  DELETE FROM public.tenant_loans WHERE user_id = p_user_id;
  DELETE FROM public.profiles WHERE id = p_user_id;
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;

-- ─── 2. admin_delete_sacco — removes SACCO + all related data ──────────────

CREATE OR REPLACE FUNCTION public.admin_delete_sacco(p_sacco_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can delete SACCOS';
  END IF;

  DELETE FROM public.sacco_membership_requests WHERE sacco_id = p_sacco_id;
  DELETE FROM public.sacco_loan_requests WHERE sacco_id = p_sacco_id;
  DELETE FROM public.sacco_transactions WHERE sacco_id = p_sacco_id;
  DELETE FROM public.sacco_admins WHERE sacco_id = p_sacco_id;
  DELETE FROM public.saccos WHERE sacco_id = p_sacco_id;
END;
$$;

-- ─── 3. admin_remove_member — hard-deletes a membership record ─────────────

CREATE OR REPLACE FUNCTION public.admin_remove_member(p_request_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can remove members';
  END IF;

  DELETE FROM public.sacco_membership_requests WHERE request_id = p_request_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_delete_user TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_sacco TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_remove_member TO anon, authenticated;
