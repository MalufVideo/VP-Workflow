-- ============================================
-- FIX: Infinite recursion in client_members RLS policy
-- ============================================
-- The original policy on client_members causes infinite recursion because
-- it tries to SELECT from client_members to determine if a row is visible.
-- Solution: Use a SECURITY DEFINER function to bypass RLS during the check.

-- Step 1: Create a helper function that bypasses RLS
CREATE OR REPLACE FUNCTION public.get_user_client_ids(user_uuid UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT client_id FROM public.client_members WHERE user_id = user_uuid;
$$;

-- Step 2: Drop the problematic policies
DROP POLICY IF EXISTS "Client members can view client members" ON public.client_members;
DROP POLICY IF EXISTS "Client creator or admin can add members" ON public.client_members;
DROP POLICY IF EXISTS "Client creator or admin can remove members" ON public.client_members;

-- Step 3: Create fixed policies using the helper function
-- Members can see who else is a member (using the security definer function to avoid recursion)
CREATE POLICY "Client members can view client members" ON public.client_members FOR SELECT
  USING (
    client_id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR public.is_master_admin()
  );

-- Only Client creator or Master Admin can add members
CREATE POLICY "Client creator or admin can add members" ON public.client_members FOR INSERT
  WITH CHECK (
    client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

-- Only Client creator or Master Admin can remove members
CREATE POLICY "Client creator or admin can remove members" ON public.client_members FOR DELETE
  USING (
    client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

-- ============================================
-- ALSO FIX: Clients and Jobs policies that reference client_members
-- ============================================

-- Drop and recreate clients policies
DROP POLICY IF EXISTS "Client members and admin can view clients" ON public.clients;
DROP POLICY IF EXISTS "Client members and admin can update clients" ON public.clients;

CREATE POLICY "Client members and admin can view clients" ON public.clients FOR SELECT
  USING (
    created_by = auth.uid()
    OR id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR public.is_master_admin()
  );

CREATE POLICY "Client members and admin can update clients" ON public.clients FOR UPDATE
  USING (
    created_by = auth.uid()
    OR id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR public.is_master_admin()
  );

-- Drop and recreate jobs policies
DROP POLICY IF EXISTS "Client members and admin can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Client members and admin can update jobs" ON public.jobs;
DROP POLICY IF EXISTS "Client members and admin can delete jobs" ON public.jobs;
DROP POLICY IF EXISTS "User can create jobs for their clients" ON public.jobs;

CREATE POLICY "Client members and admin can view jobs" ON public.jobs FOR SELECT
  USING (
    client_id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Client members and admin can update jobs" ON public.jobs FOR UPDATE
  USING (
    client_id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Client members and admin can delete jobs" ON public.jobs FOR DELETE
  USING (
    client_id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "User can create jobs for their clients" ON public.jobs FOR INSERT
  WITH CHECK (
    client_id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );
