-- ============================================
-- FIX: Complete RLS Policies for Clients Table (Updated)
-- ============================================
-- This script ensures ALL CRUD operations (Select, Insert, Update, Delete) 
-- are correctly permitted for Clients, using the safe `get_user_client_ids` function
-- to avoid recursion.

-- 1. Drop ALL existing/potential policies to ensure a clean slate
DROP POLICY IF EXISTS "Authenticated users can view clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can create clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can update clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can delete clients" ON public.clients;

DROP POLICY IF EXISTS "Client members and admin can view clients" ON public.clients;
DROP POLICY IF EXISTS "Client members and admin can update clients" ON public.clients;
DROP POLICY IF EXISTS "Client members and admin can delete clients" ON public.clients;
DROP POLICY IF EXISTS "Client members and admin can create clients" ON public.clients;
DROP POLICY IF EXISTS "Client creator and admin can delete clients" ON public.clients;

DROP POLICY IF EXISTS "Users can create clients" ON public.clients;

-- 2. Create optimized policies using the security definer function

-- VIEW: Users can see clients they created OR are members of
CREATE POLICY "Client members and admin can view clients" ON public.clients FOR SELECT
  USING (
    created_by = auth.uid()
    OR id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR public.is_master_admin()
  );

-- INSERT: Users can create clients
CREATE POLICY "Users can create clients" ON public.clients FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated'
  );

-- UPDATE: Creators and Members can update
CREATE POLICY "Client members and admin can update clients" ON public.clients FOR UPDATE
  USING (
    created_by = auth.uid()
    OR id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR public.is_master_admin()
  );

-- DELETE: Creators, Members, and Admins can delete
-- Relieved restriction so team members can manage/delete cards properly
CREATE POLICY "Client members and admin can delete clients" ON public.clients FOR DELETE
  USING (
    created_by = auth.uid()
    OR id IN (SELECT public.get_user_client_ids(auth.uid()))
    OR public.is_master_admin()
  );
