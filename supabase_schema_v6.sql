-- VP Workflow V6 Database Schema - Dynamic Pipeline Stages
-- Run this in your Supabase SQL Editor AFTER running previous migrations

-- ============================================
-- SALES STAGES TABLE (Dynamic columns for Sales Pipeline)
-- ============================================
CREATE TABLE IF NOT EXISTS public.sales_stages (
  id text PRIMARY KEY,
  title text NOT NULL,
  "order" integer NOT NULL,
  color text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- JOB STAGES TABLE (Dynamic columns for Jobs Pipeline)
-- ============================================
CREATE TABLE IF NOT EXISTS public.job_stages (
  id text PRIMARY KEY,
  title text NOT NULL,
  "order" integer NOT NULL,
  color text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE public.sales_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_stages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES - SALES STAGES
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view sales stages" ON public.sales_stages;
DROP POLICY IF EXISTS "Admin can manage sales stages" ON public.sales_stages;
DROP POLICY IF EXISTS "Admin can insert sales stages" ON public.sales_stages;
DROP POLICY IF EXISTS "Admin can update sales stages" ON public.sales_stages;
DROP POLICY IF EXISTS "Admin can delete sales stages" ON public.sales_stages;

CREATE POLICY "Authenticated users can view sales stages" ON public.sales_stages FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin can insert sales stages" ON public.sales_stages FOR INSERT
  WITH CHECK (public.is_master_admin());

CREATE POLICY "Admin can update sales stages" ON public.sales_stages FOR UPDATE
  USING (public.is_master_admin());

CREATE POLICY "Admin can delete sales stages" ON public.sales_stages FOR DELETE
  USING (public.is_master_admin());

-- ============================================
-- RLS POLICIES - JOB STAGES
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can view job stages" ON public.job_stages;
DROP POLICY IF EXISTS "Admin can manage job stages" ON public.job_stages;
DROP POLICY IF EXISTS "Admin can insert job stages" ON public.job_stages;
DROP POLICY IF EXISTS "Admin can update job stages" ON public.job_stages;
DROP POLICY IF EXISTS "Admin can delete job stages" ON public.job_stages;

CREATE POLICY "Authenticated users can view job stages" ON public.job_stages FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin can insert job stages" ON public.job_stages FOR INSERT
  WITH CHECK (public.is_master_admin());

CREATE POLICY "Admin can update job stages" ON public.job_stages FOR UPDATE
  USING (public.is_master_admin());

CREATE POLICY "Admin can delete job stages" ON public.job_stages FOR DELETE
  USING (public.is_master_admin());

-- ============================================
-- SEED DEFAULT SALES STAGES
-- ============================================
INSERT INTO public.sales_stages (id, title, "order", color) VALUES
  ('leads', 'Leads', 0, 'from-blue-500 to-blue-600'),
  ('appointments', 'Agendamentos', 1, 'from-amber-500 to-orange-500'),
  ('presentations', 'Apresentações', 2, 'from-purple-500 to-pink-500'),
  ('sales', 'Vendas', 3, 'from-green-500 to-emerald-500')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SEED DEFAULT JOB STAGES
-- ============================================
INSERT INTO public.job_stages (id, title, "order", color) VALUES
  ('aprovacao', 'Aprovação', 0, 'from-blue-500 to-cyan-500'),
  ('contrato_enviado', 'Contrato Enviado', 1, 'from-cyan-500 to-teal-500'),
  ('contrato_assinado', 'Contrato Assinado', 2, 'from-teal-500 to-green-500'),
  ('cadastro', 'Cadastro', 3, 'from-green-500 to-emerald-500'),
  ('nota_emitida', 'Nota Emitida', 4, 'from-emerald-500 to-lime-500'),
  ('em_producao', 'Em Produção', 5, 'from-amber-500 to-orange-500'),
  ('entrega_executada', 'Entrega Executada', 6, 'from-orange-500 to-red-500'),
  ('pagamento_efetuado', 'Pagamento Efetuado', 7, 'from-purple-500 to-pink-500')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- REMOVE CHECK CONSTRAINTS TO ALLOW CUSTOM STAGES
-- ============================================
-- Note: We need to remove the CHECK constraints to allow custom stage values

-- For clients table
ALTER TABLE public.clients DROP CONSTRAINT IF EXISTS clients_stage_check;

-- For jobs table  
ALTER TABLE public.jobs DROP CONSTRAINT IF EXISTS jobs_stage_check;

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_sales_stages_order ON public.sales_stages("order");
CREATE INDEX IF NOT EXISTS idx_job_stages_order ON public.job_stages("order");
