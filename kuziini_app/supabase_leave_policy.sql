-- Run this in Supabase SQL Editor to allow all users to see leave tasks

-- 1. Add RLS policy: everyone can read tasks with "concediu" or "liber" in title
CREATE POLICY "Everyone can view leave tasks" ON tasks
  FOR SELECT
  USING (
    title ILIKE '%concediu%' OR title ILIKE '%liber%'
  );

-- 2. Create SECURITY DEFINER function to fetch leave tasks (bypasses RLS)
CREATE OR REPLACE FUNCTION fetch_leave_tasks(target_date DATE)
RETURNS SETOF tasks
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM tasks
  WHERE (title ILIKE '%concediu%' OR title ILIKE '%liber%')
    AND due_date <= target_date
    AND (end_date >= target_date OR due_date = target_date);
$$;
