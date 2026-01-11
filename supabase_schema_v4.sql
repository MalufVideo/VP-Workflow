-- VP Workflow V4 Database Schema - Enhanced Pipelines
-- Run this in your Supabase SQL Editor AFTER running supabase_schema_v3.sql

-- ============================================
-- ENHANCED CLIENTS TABLE
-- ============================================

-- Add client_type column to clients
DO $$ BEGIN
  ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS client_type text 
    CHECK (client_type IN ('agencia', 'produtora', 'anunciante'));
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- Add custom_fields JSONB for dynamic fields
DO $$ BEGIN
  ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS custom_fields jsonb DEFAULT '{}';
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- ============================================
-- CLIENT COMMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.client_comments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id uuid REFERENCES public.clients(id) ON DELETE CASCADE NOT NULL,
  author_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  text text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- CLIENT ATTACHMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.client_attachments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id uuid REFERENCES public.clients(id) ON DELETE CASCADE NOT NULL,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_type text,
  uploaded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- ENHANCED JOBS TABLE
-- ============================================

-- Add agencia and produtora fields to jobs
DO $$ BEGIN
  ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS agencia text;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS produtora text;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- ============================================
-- JOB MEMBERS TABLE (Access Control)
-- ============================================
CREATE TABLE IF NOT EXISTS public.job_members (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  added_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  added_at timestamp with time zone DEFAULT now() NOT NULL,
  UNIQUE(job_id, user_id)
);

-- ============================================
-- JOB COMMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.job_comments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE NOT NULL,
  author_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  text text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- JOB ATTACHMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.job_attachments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE NOT NULL,
  file_name text NOT NULL,
  file_url text NOT NULL,
  file_type text,
  uploaded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- SERVICES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.services (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text,
  project_id uuid REFERENCES public.projects(id) ON DELETE SET NULL,
  status text CHECK (status IN ('pending', 'in_progress', 'completed')) DEFAULT 'pending',
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- ENABLE RLS ON NEW TABLES
-- ============================================
ALTER TABLE public.client_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES - CLIENT COMMENTS
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view client comments" ON public.client_comments;
DROP POLICY IF EXISTS "Authenticated users can create client comments" ON public.client_comments;
DROP POLICY IF EXISTS "Authors can delete own comments" ON public.client_comments;

CREATE POLICY "Authenticated users can view client comments" ON public.client_comments FOR SELECT
  USING (auth.uid() IS NOT NULL OR public.is_master_admin());

CREATE POLICY "Authenticated users can create client comments" ON public.client_comments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authors can delete own comments" ON public.client_comments FOR DELETE
  USING (author_id = auth.uid() OR public.is_master_admin());

-- ============================================
-- RLS POLICIES - CLIENT ATTACHMENTS
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view client attachments" ON public.client_attachments;
DROP POLICY IF EXISTS "Authenticated users can create client attachments" ON public.client_attachments;
DROP POLICY IF EXISTS "Uploaders can delete own attachments" ON public.client_attachments;

CREATE POLICY "Authenticated users can view client attachments" ON public.client_attachments FOR SELECT
  USING (auth.uid() IS NOT NULL OR public.is_master_admin());

CREATE POLICY "Authenticated users can create client attachments" ON public.client_attachments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Uploaders can delete own attachments" ON public.client_attachments FOR DELETE
  USING (uploaded_by = auth.uid() OR public.is_master_admin());

-- ============================================
-- RLS POLICIES - JOB MEMBERS
-- ============================================
DROP POLICY IF EXISTS "Job members can view job members" ON public.job_members;
DROP POLICY IF EXISTS "Job creator or admin can add members" ON public.job_members;
DROP POLICY IF EXISTS "Job creator or admin can remove members" ON public.job_members;

CREATE POLICY "Job members can view job members" ON public.job_members FOR SELECT
  USING (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Job creator or admin can add members" ON public.job_members FOR INSERT
  WITH CHECK (
    job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Job creator or admin can remove members" ON public.job_members FOR DELETE
  USING (
    job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

-- ============================================
-- RLS POLICIES - JOBS (Updated for member visibility)
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Job members and admin can view jobs" ON public.jobs;

CREATE POLICY "Job members and admin can view jobs" ON public.jobs FOR SELECT
  USING (
    id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR created_by = auth.uid()
    OR public.is_master_admin()
  );

-- ============================================
-- RLS POLICIES - JOB COMMENTS
-- ============================================
DROP POLICY IF EXISTS "Job members can view job comments" ON public.job_comments;
DROP POLICY IF EXISTS "Job members can create job comments" ON public.job_comments;
DROP POLICY IF EXISTS "Authors can delete own job comments" ON public.job_comments;

CREATE POLICY "Job members can view job comments" ON public.job_comments FOR SELECT
  USING (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Job members can create job comments" ON public.job_comments FOR INSERT
  WITH CHECK (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Authors can delete own job comments" ON public.job_comments FOR DELETE
  USING (author_id = auth.uid() OR public.is_master_admin());

-- ============================================
-- RLS POLICIES - JOB ATTACHMENTS
-- ============================================
DROP POLICY IF EXISTS "Job members can view job attachments" ON public.job_attachments;
DROP POLICY IF EXISTS "Job members can create job attachments" ON public.job_attachments;
DROP POLICY IF EXISTS "Uploaders can delete own job attachments" ON public.job_attachments;

CREATE POLICY "Job members can view job attachments" ON public.job_attachments FOR SELECT
  USING (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Job members can create job attachments" ON public.job_attachments FOR INSERT
  WITH CHECK (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Uploaders can delete own job attachments" ON public.job_attachments FOR DELETE
  USING (uploaded_by = auth.uid() OR public.is_master_admin());

-- ============================================
-- RLS POLICIES - SERVICES
-- ============================================
DROP POLICY IF EXISTS "Job members can view services" ON public.services;
DROP POLICY IF EXISTS "Job members can create services" ON public.services;
DROP POLICY IF EXISTS "Job members can update services" ON public.services;
DROP POLICY IF EXISTS "Service creator can delete services" ON public.services;

CREATE POLICY "Job members can view services" ON public.services FOR SELECT
  USING (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Job members can create services" ON public.services FOR INSERT
  WITH CHECK (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Job members can update services" ON public.services FOR UPDATE
  USING (
    job_id IN (SELECT job_id FROM public.job_members WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM public.jobs WHERE created_by = auth.uid())
    OR public.is_master_admin()
  );

CREATE POLICY "Service creator can delete services" ON public.services FOR DELETE
  USING (created_by = auth.uid() OR public.is_master_admin());

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_client_comments_client_id ON public.client_comments(client_id);
CREATE INDEX IF NOT EXISTS idx_client_attachments_client_id ON public.client_attachments(client_id);
CREATE INDEX IF NOT EXISTS idx_job_members_job_id ON public.job_members(job_id);
CREATE INDEX IF NOT EXISTS idx_job_members_user_id ON public.job_members(user_id);
CREATE INDEX IF NOT EXISTS idx_job_comments_job_id ON public.job_comments(job_id);
CREATE INDEX IF NOT EXISTS idx_job_attachments_job_id ON public.job_attachments(job_id);
CREATE INDEX IF NOT EXISTS idx_services_job_id ON public.services(job_id);
CREATE INDEX IF NOT EXISTS idx_services_project_id ON public.services(project_id);
CREATE INDEX IF NOT EXISTS idx_clients_client_type ON public.clients(client_type);

-- ============================================
-- TRIGGER FOR services.updated_at
-- ============================================
DROP TRIGGER IF EXISTS update_services_updated_at ON public.services;
CREATE TRIGGER update_services_updated_at
  BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

-- ============================================
-- AUTO-ADD JOB CREATOR AS MEMBER
-- ============================================
CREATE OR REPLACE FUNCTION public.auto_add_job_creator_as_member()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.job_members (job_id, user_id, added_by)
  VALUES (NEW.id, NEW.created_by, NEW.created_by)
  ON CONFLICT (job_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_job_created_add_member ON public.jobs;
CREATE TRIGGER on_job_created_add_member
  AFTER INSERT ON public.jobs
  FOR EACH ROW EXECUTE PROCEDURE public.auto_add_job_creator_as_member();
