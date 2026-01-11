-- VP Workflow - Policy Migration for Delete Project & Team Management
-- Run this in your Supabase SQL Editor if you already have the base schema

-- Drop old policies
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can view team member profiles" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Members can view projects" on public.projects;
drop policy if exists "Authenticated users can create projects" on public.projects;
drop policy if exists "Master admin can manage all projects" on public.projects;
drop policy if exists "Master admin can delete all projects" on public.projects;
drop policy if exists "Admins can update projects" on public.projects;
drop policy if exists "Admins can delete projects" on public.projects;
drop policy if exists "Members can view project members" on public.project_members;
drop policy if exists "Admins can add project members" on public.project_members;
drop policy if exists "Admins can update project members" on public.project_members;
drop policy if exists "Admins can delete project members" on public.project_members;
drop policy if exists "Master admin can manage all members" on public.project_members;

-- Profiles: Users can view their own profile and profiles of people in shared projects
create policy "Users can view own profile" on public.profiles for select
  using (auth.uid() = id);

create policy "Users can view team member profiles" on public.profiles for select
  using (
    id in (
      select pm2.user_id from public.project_members pm1
      join public.project_members pm2 on pm1.project_id = pm2.project_id
      where pm1.user_id = auth.uid()
    )
  );

create policy "Users can update own profile" on public.profiles for update
  using (auth.uid() = id);

-- Projects: Members can view their projects OR master admin can see all
create policy "Members can view projects" on public.projects for select
  using (
    id in (select project_id from public.project_members where user_id = auth.uid())
    or public.is_master_admin()
  );

-- Any authenticated user can create projects
create policy "Authenticated users can create projects" on public.projects for insert
  with check (auth.uid() is not null);

-- Project admins can update their projects
create policy "Admins can update projects" on public.projects for update
  using (
    id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'admin'
    )
    or public.is_master_admin()
  );

-- Project admins can delete their projects
create policy "Admins can delete projects" on public.projects for delete
  using (
    id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'admin'
    )
    or public.is_master_admin()
  );

-- Project Members: Members can see who is in their projects
create policy "Members can view project members" on public.project_members for select
  using (
    project_id in (select project_id from public.project_members where user_id = auth.uid())
    or public.is_master_admin()
  );

-- Admins of a project can add members
create policy "Admins can add project members" on public.project_members for insert
  with check (
    project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'admin'
    )
    or public.is_master_admin()
  );

-- Admins can update member roles (but not their own)
create policy "Admins can update project members" on public.project_members for update
  using (
    (project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'admin'
    ) and user_id != auth.uid())
    or public.is_master_admin()
  );

-- Admins can remove members (but not themselves)
create policy "Admins can delete project members" on public.project_members for delete
  using (
    (project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'admin'
    ) and user_id != auth.uid())
    or public.is_master_admin()
  );
