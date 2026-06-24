-- Fix: Drop both overloaded versions and recreate a single one
DROP FUNCTION IF EXISTS public.resolve_sacco_loan_request(text, text, text);
DROP FUNCTION IF EXISTS public.resolve_sacco_loan_request(uuid, text, text);

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
