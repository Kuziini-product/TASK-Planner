-- ============================================================================
-- Kuziini Task Manager - Initial Database Schema
-- Migration: 001_initial_schema.sql
-- Description: Creates all tables, enums, indexes, triggers, and functions
-- ============================================================================

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

CREATE TYPE user_role AS ENUM ('user', 'manager', 'admin');
CREATE TYPE user_status AS ENUM ('pending', 'active', 'suspended', 'deactivated');
CREATE TYPE team_member_role AS ENUM ('member', 'lead');
CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'expired', 'revoked');
CREATE TYPE task_status AS ENUM ('todo', 'in_progress', 'review', 'done', 'archived');
CREATE TYPE task_priority AS ENUM ('none', 'low', 'medium', 'high', 'urgent');
CREATE TYPE activity_action AS ENUM (
  'created', 'updated', 'status_changed', 'assigned', 'unassigned',
  'commented', 'attachment_added', 'attachment_removed',
  'label_added', 'label_removed', 'checklist_added', 'checklist_completed',
  'due_date_changed', 'priority_changed', 'archived', 'restored'
);
CREATE TYPE notification_type AS ENUM (
  'task_assigned', 'task_updated', 'comment_added', 'mention',
  'deadline_approaching', 'task_completed', 'file_uploaded', 'approval_required'
);
CREATE TYPE device_platform AS ENUM ('ios', 'android', 'web');


-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Automatically update updated_at timestamp on row modification
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Auto-create a profile row when a new user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- TABLE: profiles
-- Extends Supabase auth.users with application-specific fields
-- ============================================================================

CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  full_name   TEXT NOT NULL DEFAULT '',
  avatar_url  TEXT DEFAULT '',
  role        user_role NOT NULL DEFAULT 'user',
  status      user_status NOT NULL DEFAULT 'pending',
  phone       TEXT,
  timezone    TEXT DEFAULT 'UTC',
  notification_preferences JSONB DEFAULT '{"push": true, "email": true, "in_app": true}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_email ON profiles (email);
CREATE INDEX idx_profiles_role ON profiles (role);
CREATE INDEX idx_profiles_status ON profiles (status);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Trigger on auth.users to auto-create profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- ============================================================================
-- TABLE: teams
-- ============================================================================

CREATE TABLE teams (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  created_by  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_teams_created_by ON teams (created_by);

CREATE TRIGGER trg_teams_updated_at
  BEFORE UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- TABLE: team_members
-- ============================================================================

CREATE TABLE team_members (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id   UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role      team_member_role NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (team_id, user_id)
);

CREATE INDEX idx_team_members_team_id ON team_members (team_id);
CREATE INDEX idx_team_members_user_id ON team_members (user_id);


-- ============================================================================
-- TABLE: invitations
-- ============================================================================

CREATE TABLE invitations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT NOT NULL,
  invited_by  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role        user_role NOT NULL DEFAULT 'user',
  token       TEXT NOT NULL UNIQUE,
  status      invitation_status NOT NULL DEFAULT 'pending',
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invitations_email ON invitations (email);
CREATE INDEX idx_invitations_token ON invitations (token);
CREATE INDEX idx_invitations_status ON invitations (status);
CREATE INDEX idx_invitations_invited_by ON invitations (invited_by);


-- ============================================================================
-- TABLE: task_labels
-- Defined before tasks so task_label_assignments can reference both
-- ============================================================================

CREATE TABLE task_labels (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  color       TEXT NOT NULL DEFAULT '#6B7280',
  created_by  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_labels_created_by ON task_labels (created_by);


-- ============================================================================
-- TABLE: tasks
-- ============================================================================

CREATE TABLE tasks (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  description       TEXT DEFAULT '',
  status            task_status NOT NULL DEFAULT 'todo',
  priority          task_priority NOT NULL DEFAULT 'none',
  created_by        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  due_date          DATE,
  due_time          TIME,
  start_time        TIMESTAMPTZ,
  end_time          TIMESTAMPTZ,
  estimated_minutes INTEGER CHECK (estimated_minutes >= 0),
  is_all_day        BOOLEAN NOT NULL DEFAULT false,
  recurrence_rule   TEXT,                      -- iCal RRULE format
  parent_task_id    UUID REFERENCES tasks(id) ON DELETE CASCADE,
  position          INTEGER NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at      TIMESTAMPTZ,
  archived_at       TIMESTAMPTZ
);

-- Primary query indexes
CREATE INDEX idx_tasks_status ON tasks (status);
CREATE INDEX idx_tasks_priority ON tasks (priority);
CREATE INDEX idx_tasks_created_by ON tasks (created_by);
CREATE INDEX idx_tasks_due_date ON tasks (due_date);
CREATE INDEX idx_tasks_parent_task_id ON tasks (parent_task_id);

-- Composite indexes for common query patterns
CREATE INDEX idx_tasks_status_due_date ON tasks (status, due_date);
CREATE INDEX idx_tasks_created_by_status ON tasks (created_by, status);
CREATE INDEX idx_tasks_status_priority ON tasks (status, priority);

CREATE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- TABLE: task_assignees
-- ============================================================================

CREATE TABLE task_assignees (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (task_id, user_id)
);

CREATE INDEX idx_task_assignees_task_id ON task_assignees (task_id);
CREATE INDEX idx_task_assignees_user_id ON task_assignees (user_id);


-- ============================================================================
-- TABLE: task_comments
-- ============================================================================

CREATE TABLE task_comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  mentions    TEXT[] DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_comments_task_id ON task_comments (task_id);
CREATE INDEX idx_task_comments_user_id ON task_comments (user_id);

CREATE TRIGGER trg_task_comments_updated_at
  BEFORE UPDATE ON task_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- TABLE: task_attachments
-- ============================================================================

CREATE TABLE task_attachments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id         UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  uploaded_by     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_name       TEXT NOT NULL,
  file_path       TEXT NOT NULL,
  file_size       BIGINT NOT NULL CHECK (file_size >= 0),
  mime_type       TEXT NOT NULL,
  thumbnail_url   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_attachments_task_id ON task_attachments (task_id);
CREATE INDEX idx_task_attachments_uploaded_by ON task_attachments (uploaded_by);


-- ============================================================================
-- TABLE: task_label_assignments
-- ============================================================================

CREATE TABLE task_label_assignments (
  task_id   UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  label_id  UUID NOT NULL REFERENCES task_labels(id) ON DELETE CASCADE,

  PRIMARY KEY (task_id, label_id)
);

CREATE INDEX idx_task_label_assignments_label_id ON task_label_assignments (label_id);


-- ============================================================================
-- TABLE: task_checklists
-- ============================================================================

CREATE TABLE task_checklists (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id       UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  position      INTEGER NOT NULL DEFAULT 0,
  is_completed  BOOLEAN NOT NULL DEFAULT false,
  completed_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  completed_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_task_checklists_task_id ON task_checklists (task_id);


-- ============================================================================
-- TABLE: activity_logs
-- ============================================================================

CREATE TABLE activity_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action      activity_action NOT NULL,
  details     JSONB DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_logs_task_id ON activity_logs (task_id);
CREATE INDEX idx_activity_logs_user_id ON activity_logs (user_id);
CREATE INDEX idx_activity_logs_action ON activity_logs (action);
CREATE INDEX idx_activity_logs_created_at ON activity_logs (created_at DESC);


-- ============================================================================
-- TABLE: notifications
-- ============================================================================

CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        notification_type NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT DEFAULT '',
  data        JSONB DEFAULT '{}'::jsonb,
  is_read     BOOLEAN NOT NULL DEFAULT false,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications (user_id);
CREATE INDEX idx_notifications_is_read ON notifications (user_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications (user_id, created_at DESC);


-- ============================================================================
-- TABLE: device_tokens
-- ============================================================================

CREATE TABLE device_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    device_platform NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, token)
);

CREATE INDEX idx_device_tokens_user_id ON device_tokens (user_id);

CREATE TRIGGER trg_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- TABLE: admin_settings
-- ============================================================================

CREATE TABLE admin_settings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT NOT NULL UNIQUE,
  value       JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_admin_settings_updated_at
  BEFORE UPDATE ON admin_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
