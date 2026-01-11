-- FIX DELETE POLICIES
-- This script ensures that users can delete the jobs and services they created.

-- 1. Enable RLS (just in case)
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 2. Jobs Delete Policy
DROP POLICY IF EXISTS "Authenticated users can delete jobs" ON public.jobs;
DROP POLICY IF EXISTS "Job creator or admin can delete jobs" ON public.jobs;

CREATE POLICY "Job creator or admin can delete jobs" ON public.jobs FOR DELETE
  USING (created_by = auth.uid() OR public.is_master_admin());

-- 3. Services Delete Policy
DROP POLICY IF EXISTS "Service creator can delete services" ON public.services;
DROP POLICY IF EXISTS "Service creator or admin can delete services" ON public.services;

CREATE POLICY "Service creator or admin can delete services" ON public.services FOR DELETE
  USING (created_by = auth.uid() OR public.is_master_admin());

-- 4. Ensure master admin can do anything (Optional but helpful)
-- Note: This is usually covered by specific policies, but we ensure the profile flag works.
-- (This part doesn't change schema, just a comment)
