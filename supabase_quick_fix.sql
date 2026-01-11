-- QUICK FIX: Simple permissive policies for MVP
-- Run this to temporarily fix the 500 errors
-- We can add stricter policies later

-- Drop all existing policies first
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Members can view projects" on public.projects;
drop policy if exists "Authenticated users can create projects" on public.projects;
drop policy if exists "Master admin can manage all projects" on public.projects;
drop policy if exists "Master admin can delete all projects" on public.projects;
drop policy if exists "Members can view project members" on public.project_members;
drop policy if exists "Admins can add project members" on public.project_members;
drop policy if exists "Master admin can manage all members" on public.project_members;
drop policy if exists "Members can view columns" on public.columns;
drop policy if exists "Admins can modify columns" on public.columns;
drop policy if exists "Members can manage cards" on public.cards;
drop policy if exists "public_columns_access" on public.columns;
drop policy if exists "public_cards_access" on public.cards;

-- Simple permissive policies (authenticated users can do everything for now)
-- PROFILES
create policy "profiles_select" on public.profiles for select using (true);
create policy "profiles_insert" on public.profiles for insert with check (true);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);

-- PROJECTS (any authenticated user can CRUD)
create policy "projects_select" on public.projects for select using (true);
create policy "projects_insert" on public.projects for insert with check (auth.uid() is not null);
create policy "projects_update" on public.projects for update using (auth.uid() is not null);
create policy "projects_delete" on public.projects for delete using (auth.uid() is not null);

-- PROJECT MEMBERS
create policy "project_members_select" on public.project_members for select using (true);
create policy "project_members_insert" on public.project_members for insert with check (auth.uid() is not null);
create policy "project_members_update" on public.project_members for update using (auth.uid() is not null);
create policy "project_members_delete" on public.project_members for delete using (auth.uid() is not null);

-- COLUMNS
create policy "columns_select" on public.columns for select using (true);
create policy "columns_insert" on public.columns for insert with check (auth.uid() is not null);
create policy "columns_update" on public.columns for update using (auth.uid() is not null);
create policy "columns_delete" on public.columns for delete using (auth.uid() is not null);

-- CARDS
create policy "cards_select" on public.cards for select using (true);
create policy "cards_insert" on public.cards for insert with check (auth.uid() is not null);
create policy "cards_update" on public.cards for update using (auth.uid() is not null);
create policy "cards_delete" on public.cards for delete using (auth.uid() is not null);
