-- FIX RLS RECURSION ERROR
-- This script fixes the infinite recursion caused by circular RLS policies between `jobs` and `job_members`.

-- 1. Create a helper function to get job IDs for the current user safely
-- SECURITY DEFINER means this runs with the privileges of the creator (postgres), bypassing RLS
CREATE OR REPLACE FUNCTION public.get_user_job_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT job_id FROM public.job_members WHERE user_id = auth.uid()
$$;

-- 2. Update RLS Policy for `jobs`
DROP POLICY IF EXISTS "Job members and admin can view jobs" ON public.jobs;

CREATE POLICY "Job members and admin can view jobs" ON public.jobs FOR SELECT
  USING (
    id IN (SELECT public.get_user_job_ids()) -- Uses the safe function
    OR created_by = auth.uid()
    OR public.is_master_admin()
  );

-- 3. Update RLS Policy for `job_members`
DROP POLICY IF EXISTS "Job members can view job members" ON public.job_members;

CREATE POLICY "Job members can view job members" ON public.job_members FOR SELECT
  USING (
    job_id IN (SELECT public.get_user_job_ids()) -- Uses the safe function
    OR public.is_master_admin()
    OR user_id = auth.uid() -- Always allow seeing own membership
  );

-- 4. Re-ensure INSERT policies exist (fixing potential missing V3 policies)
DROP POLICY IF EXISTS "Authenticated users can create jobs" ON public.jobs;
CREATE POLICY "Authenticated users can create jobs" ON public.jobs FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 5. Ensure client_id column exists (fixing potential missing V3 column)
DO $$ BEGIN
  ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES public.clients(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
