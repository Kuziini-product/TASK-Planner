-- ============================================================================
-- Kuziini Task Manager - Storage Buckets & Policies
-- Migration: 003_storage_policies.sql
-- Description: Creates storage buckets and access policies for file uploads
-- ============================================================================


-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Private bucket for task file attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-attachments',
  'task-attachments',
  false,
  52428800,  -- 50 MB max file size
  ARRAY[
    'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain', 'text/csv',
    'application/zip', 'application/x-rar-compressed',
    'video/mp4', 'video/quicktime',
    'audio/mpeg', 'audio/wav'
  ]
);

-- Public bucket for user avatar images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,  -- 5 MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
);


-- ============================================================================
-- STORAGE POLICIES: task-attachments (private)
-- ============================================================================

-- Upload: authenticated users can upload to their own folder within a task path
-- Path convention: {task_id}/{uploader_id}/{filename}
CREATE POLICY "task_attachments_upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'task-attachments'
    AND (storage.foldername(name))[2] = auth.uid()::text
    AND EXISTS (
      SELECT 1 FROM tasks
      WHERE id = (storage.foldername(name))[1]::uuid
        AND (
          created_by = auth.uid()
          OR EXISTS (
            SELECT 1 FROM task_assignees
            WHERE task_id = tasks.id AND user_id = auth.uid()
          )
          OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
          )
        )
    )
  );

-- Read: users who can view the task can download its attachments
CREATE POLICY "task_attachments_read"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'task-attachments'
    AND EXISTS (
      SELECT 1 FROM tasks
      WHERE id = (storage.foldername(name))[1]::uuid
        AND (
          created_by = auth.uid()
          OR EXISTS (
            SELECT 1 FROM task_assignees
            WHERE task_id = tasks.id AND user_id = auth.uid()
          )
          OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
          )
        )
    )
  );

-- Update: only the uploader can replace their own files
CREATE POLICY "task_attachments_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'task-attachments'
    AND (storage.foldername(name))[2] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'task-attachments'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- Delete: uploader or admin can remove files
CREATE POLICY "task_attachments_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'task-attachments'
    AND (
      (storage.foldername(name))[2] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );


-- ============================================================================
-- STORAGE POLICIES: avatars (public read, authenticated upload)
-- ============================================================================

-- Anyone can view avatars (public bucket)
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'avatars');

-- Users can upload their own avatar
-- Path convention: {user_id}/{filename}
CREATE POLICY "avatars_upload_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update (replace) their own avatar
CREATE POLICY "avatars_update_own"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own avatar
CREATE POLICY "avatars_delete_own"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
