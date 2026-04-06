-- Run this in Supabase SQL Editor to add last_seen column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;
