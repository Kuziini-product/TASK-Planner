-- Add location fields to tasks table
ALTER TABLE tasks ADD COLUMN location_name TEXT;
ALTER TABLE tasks ADD COLUMN location_address TEXT;
ALTER TABLE tasks ADD COLUMN location_url TEXT;
ALTER TABLE tasks ADD COLUMN location_lat DOUBLE PRECISION;
ALTER TABLE tasks ADD COLUMN location_lng DOUBLE PRECISION;
