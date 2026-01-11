-- VP Workflow - Diagnostic and Quick Fix Script
-- Run this in Supabase SQL Editor to diagnose and temporarily fix the issue

-- =====================================================
-- STEP 1: DIAGNOSTICS - Check what exists
-- =====================================================

-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'projects', 'project_members', 'columns', 'cards');

-- Check if your user has a profile
SELECT * FROM public.profiles WHERE email = 'nelsonhdvideo@gmail.com';

-- Check current RLS status
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'projects';

-- =====================================================
-- STEP 2: QUICK FIX - Temporarily disable RLS on projects
-- This allows project creation to work while we debug
-- =====================================================

-- Option A: Disable RLS temporarily (QUICK FIX - NOT FOR PRODUCTION)
-- Uncomment these lines if diagnostics show tables exist
-- ALTER TABLE public.projects DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.project_members DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 3: Ensure profile exists for your user
-- =====================================================

-- First, find your user ID from auth.users
-- SELECT id, email FROM auth.users WHERE email = 'nelsonhdvideo@gmail.com';

-- Then manually insert profile if missing (replace USER_ID with actual UUID)
-- INSERT INTO public.profiles (id, email, is_master_admin) 
-- VALUES ('YOUR-USER-UUID-HERE', 'nelsonhdvideo@gmail.com', true)
-- ON CONFLICT (id) DO UPDATE SET is_master_admin = true;

-- =====================================================
-- STEP 4: RECOMMENDED - Use simpler policies for now
-- =====================================================

-- Drop all project policies and use simple ones
DROP POLICY IF EXISTS "Members can view projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can create projects" ON public.projects;
DROP POLICY IF EXISTS "Admins can update projects" ON public.projects;
DROP POLICY IF EXISTS "Admins can delete projects" ON public.projects;

-- Simple policies - any authenticated user can do anything (for testing)
CREATE POLICY "Allow all authenticated for projects" ON public.projects 
  FOR ALL 
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Same for project_members
DROP POLICY IF EXISTS "Members can view project members" ON public.project_members;
DROP POLICY IF EXISTS "Admins can add project members" ON public.project_members;
DROP POLICY IF EXISTS "Admins can update project members" ON public.project_members;
DROP POLICY IF EXISTS "Admins can delete project members" ON public.project_members;

CREATE POLICY "Allow all authenticated for project_members" ON public.project_members
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Simple profile policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view team member profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON public.profiles;

CREATE POLICY "Allow all authenticated for profiles" ON public.profiles
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- STEP 5: Make sure profile trigger works
-- =====================================================

-- Re-create the profile creation trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, is_master_admin)
  VALUES (
    new.id, 
    new.email,
    new.email = 'nelsonhdvideo@gmail.com'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- STEP 6: Manually add your profile if it doesn't exist
-- =====================================================

-- This will try to add your profile from auth.users
INSERT INTO public.profiles (id, email, is_master_admin)
SELECT id, email, (email = 'nelsonhdvideo@gmail.com')
FROM auth.users 
WHERE email = 'nelsonhdvideo@gmail.com'
ON CONFLICT (id) DO UPDATE SET is_master_admin = true;
