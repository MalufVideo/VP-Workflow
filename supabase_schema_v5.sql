-- VP Workflow V5 Database Schema - Sales Pipeline Access Control
-- Run this in your Supabase SQL Editor

-- ============================================
-- CLIENT MEMBERS TABLE (Access Control for Sales)
-- ============================================
CREATE TABLE IF NOT EXISTS public.client_members (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id uuid REFERENCES public.clients(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  added_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  added_at timestamp with time zone DEFAULT now() NOT NULL,
  UNIQUE(client_id, user_id)
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE public.client_members ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES - CLIENT MEMBERS
-- ============================================
DROP POLICY IF EXISTS "Client members can view client members" ON public.client_members;
DROP POLICY IF EXISTS "Client creator or admin can add members" ON public.client_members;
DROP POLICY IF EXISTS "Client creator or admin can remove members" ON public.client_members;

-- Members can see who else is a member
CREATE POLICY "Client members can view client members" ON public.client_members FOR SELECT
  USING (
    client_id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR public.is_master_admin()
  );

-- Only Master Admin (or maybe the creator?) can add members. 
-- Assuming creator should have rights too.
CREATE POLICY "Client creator or admin can add members" ON public.client_members FOR INSERT
  WITH CHECK (
    client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Client creator or admin can remove members" ON public.client_members FOR DELETE
  USING (
    client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

-- ============================================
-- UPDATE RLS POLICIES - CLIENTS
-- ============================================
-- Drop old open policies
DROP POLICY IF EXISTS "Authenticated users can view clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can create clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can update clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can delete clients" ON public.clients;

-- New strict policies
CREATE POLICY "Client members and admin can view clients" ON public.clients FOR SELECT
  USING (
    id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR created_by = auth.uid()
    OR public.is_master_admin()
  );

CREATE POLICY "Authenticated users can create clients" ON public.clients FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Client members and admin can update clients" ON public.clients FOR UPDATE
  USING (
    id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR created_by = auth.uid()
    OR public.is_master_admin()
  );

CREATE POLICY "Creator or admin can delete clients" ON public.clients FOR DELETE
  USING (created_by = auth.uid() OR public.is_master_admin());

-- ============================================
-- UPDATE RLS POLICIES - CLIENT COMMENTS
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view client comments" ON public.client_comments;
DROP POLICY IF EXISTS "Authenticated users can create client comments" ON public.client_comments;

CREATE POLICY "Client members can view client comments" ON public.client_comments FOR SELECT
  USING (
    client_id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Client members can create client comments" ON public.client_comments FOR INSERT
  WITH CHECK (
    client_id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

-- ============================================
-- UPDATE RLS POLICIES - CLIENT ATTACHMENTS
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view client attachments" ON public.client_attachments;
DROP POLICY IF EXISTS "Authenticated users can create client attachments" ON public.client_attachments;

CREATE POLICY "Client members can view client attachments" ON public.client_attachments FOR SELECT
  USING (
    client_id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Client members can create client attachments" ON public.client_attachments FOR INSERT
  WITH CHECK (
    client_id IN (SELECT client_id FROM public.client_members WHERE user_id = auth.uid())
    OR client_id IN (SELECT id FROM public.clients WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

-- ============================================
-- AUTO-ADD CREATOR TO MEMBERS
-- ============================================
CREATE OR REPLACE FUNCTION public.auto_add_client_creator_as_member()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.client_members (client_id, user_id, added_by)
  VALUES (NEW.id, NEW.created_by, NEW.created_by)
  ON CONFLICT (client_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_client_created_add_member ON public.clients;
CREATE TRIGGER on_client_created_add_member
  AFTER INSERT ON public.clients
  FOR EACH ROW EXECUTE PROCEDURE public.auto_add_client_creator_as_member();

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_client_members_client_id ON public.client_members(client_id);
CREATE INDEX IF NOT EXISTS idx_client_members_user_id ON public.client_members(user_id);
