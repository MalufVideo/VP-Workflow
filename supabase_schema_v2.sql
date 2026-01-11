-- VP Workflow V2 Database Schema
-- Run this in your Supabase SQL Editor

-- Master Admin Email (has access to everything)
-- Change this if you want a different master admin
DO $$ BEGIN
  PERFORM set_config('app.master_admin_email', 'nelsonhdvideo@gmail.com', false);
END $$;

-- Step 1: Create Profiles Table (syncs with auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique not null,
  full_name text,
  avatar_url text,
  is_master_admin boolean default false,
  created_at timestamp with time zone default now() not null
);

-- Add is_master_admin column if table already existed
alter table public.profiles add column if not exists is_master_admin boolean default false;

-- Step 2: Create Projects Table
create table if not exists public.projects (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  slug text unique not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default now() not null
);

-- Step 3: Create Project Members Table
create table if not exists public.project_members (
  id uuid default gen_random_uuid() primary key,
  project_id uuid references public.projects(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role text check (role in ('admin', 'team', 'client')) not null default 'team',
  added_at timestamp with time zone default now() not null,
  unique(project_id, user_id)
);

-- Step 4: Update Columns Table with project_id
alter table public.columns add column if not exists project_id uuid references public.projects(id) on delete cascade;

-- Step 5: Update Cards Table (already has jsonb history, etc.)
-- Cards are linked to columns, which are linked to projects, so no direct project_id needed.

-- Step 6: Enable RLS on new tables
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.project_members enable row level security;

-- Step 7: Policies

-- Helper function to check if current user is master admin
-- Uses direct query without RLS to avoid recursion
create or replace function public.is_master_admin()
returns boolean as $$
declare
  is_admin boolean;
begin
  -- Direct query bypassing RLS (security definer runs as function owner)
  select is_master_admin into is_admin 
  from public.profiles 
  where id = auth.uid();
  
  return coalesce(is_admin, false);
end;
$$ language plpgsql security definer;

-- Drop existing policies first (allows re-running this script)
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
drop policy if exists "Members can view columns" on public.columns;
drop policy if exists "Admins can modify columns" on public.columns;
drop policy if exists "Members can manage cards" on public.cards;
drop policy if exists "public_columns_access" on public.columns;
drop policy if exists "public_cards_access" on public.cards;

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

-- Admins of a project can add members (or master admin)
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

-- Columns: Viewable if user is member of the project (or master admin)
create policy "Members can view columns" on public.columns for select
  using (
    project_id in (select project_id from public.project_members where user_id = auth.uid())
    or public.is_master_admin()
    or project_id is null -- legacy columns without project
  );

-- Admins can modify columns (or master admin)
create policy "Admins can modify columns" on public.columns for all
  using (
    project_id in (
      select project_id from public.project_members 
      where user_id = auth.uid() and role = 'admin'
    )
    or public.is_master_admin()
    or project_id is null
  );

-- Cards: Everyone in the project can view and edit cards (or master admin)
create policy "Members can manage cards" on public.cards for all
  using (
    column_id in (
      select c.id from public.columns c
      join public.project_members pm on pm.project_id = c.project_id
      where pm.user_id = auth.uid()
    )
    or public.is_master_admin()
    or column_id in (select id from public.columns where project_id is null) -- legacy
  );

-- Function to auto-create profile on signup (sets master admin for specific email)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, is_master_admin)
  values (
    new.id, 
    new.email,
    new.email = 'nelsonhdvideo@gmail.com'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to call the function
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- If master admin already exists, update their profile
update public.profiles 
set is_master_admin = true 
where email = 'nelsonhdvideo@gmail.com';
