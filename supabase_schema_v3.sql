-- VP Workflow V3 Database Schema - Multi-Level Pipelines
-- Run this in your Supabase SQL Editor AFTER running supabase_schema_v2.sql

-- ============================================
-- CLIENTS TABLE (Sales Pipeline Cards)
-- ============================================
create table if not exists public.clients (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  email text,
  phone text,
  company text,
  notes text,
  stage text check (stage in ('leads', 'appointments', 'presentations', 'sales')) not null default 'leads',
  stage_order integer default 0, -- For ordering within a stage
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  converted_at timestamp with time zone -- When converted to a job
);

-- ============================================
-- JOBS TABLE (Jobs Pipeline Cards)
-- ============================================
create table if not exists public.jobs (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.clients(id) on delete set null,
  project_id uuid references public.projects(id) on delete set null, -- Links to creative Kanban
  title text not null,
  description text,
  value numeric(12, 2), -- Job value/price
  notes text,
  stage text check (stage in (
    'aprovacao', 
    'contrato_enviado', 
    'contrato_assinado', 
    'cadastro', 
    'nota_emitida', 
    'em_producao', 
    'entrega_executada', 
    'pagamento_efetuado'
  )) not null default 'aprovacao',
  stage_order integer default 0, -- For ordering within a stage
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- ============================================
-- ENABLE RLS
-- ============================================
alter table public.clients enable row level security;
alter table public.jobs enable row level security;

-- ============================================
-- RLS POLICIES - CLIENTS
-- ============================================

-- Drop existing policies if re-running
drop policy if exists "Authenticated users can view clients" on public.clients;
drop policy if exists "Authenticated users can create clients" on public.clients;
drop policy if exists "Authenticated users can update clients" on public.clients;
drop policy if exists "Authenticated users can delete clients" on public.clients;

-- All authenticated users can view clients (or master admin)
create policy "Authenticated users can view clients" on public.clients for select
  using (auth.uid() is not null or public.is_master_admin());

-- All authenticated users can create clients
create policy "Authenticated users can create clients" on public.clients for insert
  with check (auth.uid() is not null);

-- All authenticated users can update clients
create policy "Authenticated users can update clients" on public.clients for update
  using (auth.uid() is not null or public.is_master_admin());

-- Only creator or master admin can delete clients
create policy "Authenticated users can delete clients" on public.clients for delete
  using (created_by = auth.uid() or public.is_master_admin());

-- ============================================
-- RLS POLICIES - JOBS
-- ============================================

-- Drop existing policies if re-running
drop policy if exists "Authenticated users can view jobs" on public.jobs;
drop policy if exists "Authenticated users can create jobs" on public.jobs;
drop policy if exists "Authenticated users can update jobs" on public.jobs;
drop policy if exists "Authenticated users can delete jobs" on public.jobs;

-- All authenticated users can view jobs
create policy "Authenticated users can view jobs" on public.jobs for select
  using (auth.uid() is not null or public.is_master_admin());

-- All authenticated users can create jobs
create policy "Authenticated users can create jobs" on public.jobs for insert
  with check (auth.uid() is not null);

-- All authenticated users can update jobs
create policy "Authenticated users can update jobs" on public.jobs for update
  using (auth.uid() is not null or public.is_master_admin());

-- Only creator or master admin can delete jobs
create policy "Authenticated users can delete jobs" on public.jobs for delete
  using (created_by = auth.uid() or public.is_master_admin());

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
create index if not exists idx_clients_stage on public.clients(stage);
create index if not exists idx_clients_created_by on public.clients(created_by);
create index if not exists idx_jobs_stage on public.jobs(stage);
create index if not exists idx_jobs_client_id on public.jobs(client_id);
create index if not exists idx_jobs_project_id on public.jobs(project_id);

-- ============================================
-- TRIGGER FOR updated_at
-- ============================================
create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists update_clients_updated_at on public.clients;
create trigger update_clients_updated_at
  before update on public.clients
  for each row execute procedure public.update_updated_at_column();

drop trigger if exists update_jobs_updated_at on public.jobs;
create trigger update_jobs_updated_at
  before update on public.jobs
  for each row execute procedure public.update_updated_at_column();
