-- VP Workflow - Fix Columns and Cards RLS Policies
-- Run this in Supabase SQL Editor to enable card/column creation

-- =====================================================
-- FIX COLUMNS TABLE
-- =====================================================

-- Drop existing column policies
DROP POLICY IF EXISTS "Members can view columns" ON public.columns;
DROP POLICY IF EXISTS "Admins can modify columns" ON public.columns;
DROP POLICY IF EXISTS "public_columns_access" ON public.columns;

-- Simple policy - any authenticated user can do anything with columns
CREATE POLICY "Allow all authenticated for columns" ON public.columns 
  FOR ALL 
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- FIX CARDS TABLE
-- =====================================================

-- Drop existing card policies
DROP POLICY IF EXISTS "Members can manage cards" ON public.cards;
DROP POLICY IF EXISTS "public_cards_access" ON public.cards;

-- Simple policy - any authenticated user can do anything with cards
CREATE POLICY "Allow all authenticated for cards" ON public.cards
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- VERIFY RLS IS ENABLED (but with permissive policies)
-- =====================================================

ALTER TABLE public.columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- Show current policies to confirm
-- =====================================================

SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('columns', 'cards')
ORDER BY tablename;
