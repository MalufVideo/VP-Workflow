-- VP Workflow - Fixed Policy for Project Creation
-- Run this in your Supabase SQL Editor to fix project creation

-- The issue: After creating a project, the user tries to add themselves
-- as a project_member with role='admin'. But the current INSERT policy
-- only allows admins to add members, creating a chicken-and-egg problem.

-- Solution: Allow authenticated users to add THEMSELVES to a project that THEY created

-- Drop and recreate the project_members insert policy
drop policy if exists "Admins can add project members" on public.project_members;

-- New policy: Allow users to add themselves to projects they created, 
-- or allow existing admins to add others
create policy "Admins can add project members" on public.project_members for insert
  with check (
    -- Allow if the user is the project creator and adding themselves
    (
      user_id = auth.uid() 
      AND project_id IN (SELECT id FROM public.projects WHERE created_by = auth.uid())
    )
    -- Or allow existing admins to add anyone
    OR project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'admin'
    )
    -- Or allow master admin
    OR public.is_master_admin()
  );

-- Also ensure that profiles row exists for the user
-- The trigger should have created this, but let's make sure profiles has an insert policy
drop policy if exists "Users can create own profile" on public.profiles;
create policy "Users can create own profile" on public.profiles for insert
  with check (auth.uid() = id);
