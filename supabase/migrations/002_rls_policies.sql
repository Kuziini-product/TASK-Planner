-- ============================================================================
-- Kuziini Task Manager - Row Level Security Policies
-- Migration: 002_rls_policies.sql
-- Description: Enables RLS on all tables and defines access policies
-- ============================================================================

-- ============================================================================
-- HELPER FUNCTIONS FOR POLICY CHECKS
-- ============================================================================

-- Check if the current user has admin role
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;


-- Check if the current user can view a specific task
-- (they created it, are assigned to it, or are an admin)
CREATE OR REPLACE FUNCTION can_view_task(p_task_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM tasks WHERE id = p_task_id AND created_by = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM task_assignees WHERE task_id = p_task_id AND user_id = auth.uid()
  )
  OR is_admin();
$$ LANGUAGE sql SECURITY DEFINER STABLE;


-- Check if the current user is a member of a specific team
CREATE OR REPLACE FUNCTION is_team_member(p_team_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = p_team_id AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;


-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members          ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations           ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_assignees        ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_attachments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_labels           ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_label_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_checklists       ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications         ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens         ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_settings        ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- POLICIES: profiles
-- All authenticated users can read active profiles.
-- Users can only update their own profile.
-- ============================================================================

CREATE POLICY "profiles_select_active"
  ON profiles FOR SELECT
  TO authenticated
  USING (status = 'active' OR id = auth.uid());

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Allow the trigger function to insert profiles on signup
CREATE POLICY "profiles_insert_on_signup"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());


-- ============================================================================
-- POLICIES: teams
-- Team members can view their teams. Admins can see and manage all.
-- Team creators and admins can update/delete.
-- ============================================================================

CREATE POLICY "teams_select"
  ON teams FOR SELECT
  TO authenticated
  USING (
    is_team_member(id)
    OR created_by = auth.uid()
    OR is_admin()
  );

CREATE POLICY "teams_insert"
  ON teams FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "teams_update"
  ON teams FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid() OR is_admin())
  WITH CHECK (created_by = auth.uid() OR is_admin());

CREATE POLICY "teams_delete"
  ON teams FOR DELETE
  TO authenticated
  USING (created_by = auth.uid() OR is_admin());


-- ============================================================================
-- POLICIES: team_members
-- Members can view their own team's members. Admins and team creators manage.
-- ============================================================================

CREATE POLICY "team_members_select"
  ON team_members FOR SELECT
  TO authenticated
  USING (
    is_team_member(team_id)
    OR is_admin()
  );

CREATE POLICY "team_members_insert"
  ON team_members FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM teams WHERE id = team_id AND created_by = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM team_members
      WHERE team_id = team_members.team_id
        AND user_id = auth.uid()
        AND role = 'lead'
    )
    OR is_admin()
  );

CREATE POLICY "team_members_delete"
  ON team_members FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM teams WHERE id = team_id AND created_by = auth.uid()
    )
    OR is_admin()
  );


-- ============================================================================
-- POLICIES: invitations
-- Admins and managers can create/manage invitations.
-- Invited users can read their own invitation by email.
-- ============================================================================

CREATE POLICY "invitations_select_admin"
  ON invitations FOR SELECT
  TO authenticated
  USING (
    invited_by = auth.uid()
    OR is_admin()
    OR email = (SELECT email FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "invitations_insert"
  ON invitations FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role IN ('admin', 'manager')
    )
  );

CREATE POLICY "invitations_update"
  ON invitations FOR UPDATE
  TO authenticated
  USING (invited_by = auth.uid() OR is_admin())
  WITH CHECK (invited_by = auth.uid() OR is_admin());

CREATE POLICY "invitations_delete"
  ON invitations FOR DELETE
  TO authenticated
  USING (is_admin());


-- ============================================================================
-- POLICIES: tasks
-- Visible to creator and assignees. Admins see all.
-- ============================================================================

CREATE POLICY "tasks_select"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM task_assignees
      WHERE task_id = id AND user_id = auth.uid()
    )
    OR is_admin()
  );

CREATE POLICY "tasks_insert"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "tasks_update"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM task_assignees
      WHERE task_id = id AND user_id = auth.uid()
    )
    OR is_admin()
  )
  WITH CHECK (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM task_assignees
      WHERE task_id = id AND user_id = auth.uid()
    )
    OR is_admin()
  );

CREATE POLICY "tasks_delete"
  ON tasks FOR DELETE
  TO authenticated
  USING (created_by = auth.uid() OR is_admin());


-- ============================================================================
-- POLICIES: task_assignees
-- Visible if user can view the task.
-- ============================================================================

CREATE POLICY "task_assignees_select"
  ON task_assignees FOR SELECT
  TO authenticated
  USING (can_view_task(task_id));

CREATE POLICY "task_assignees_insert"
  ON task_assignees FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks WHERE id = task_id AND created_by = auth.uid()
    )
    OR is_admin()
  );

CREATE POLICY "task_assignees_delete"
  ON task_assignees FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks WHERE id = task_id AND created_by = auth.uid()
    )
    OR user_id = auth.uid()
    OR is_admin()
  );


-- ============================================================================
-- POLICIES: task_comments
-- Visible to those who can see the task.
-- Users can update/delete their own comments.
-- ============================================================================

CREATE POLICY "task_comments_select"
  ON task_comments FOR SELECT
  TO authenticated
  USING (can_view_task(task_id));

CREATE POLICY "task_comments_insert"
  ON task_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND can_view_task(task_id)
  );

CREATE POLICY "task_comments_update"
  ON task_comments FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "task_comments_delete"
  ON task_comments FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() OR is_admin());


-- ============================================================================
-- POLICIES: task_attachments
-- Visible to task creator, assignees, and admins.
-- ============================================================================

CREATE POLICY "task_attachments_select"
  ON task_attachments FOR SELECT
  TO authenticated
  USING (can_view_task(task_id));

CREATE POLICY "task_attachments_insert"
  ON task_attachments FOR INSERT
  TO authenticated
  WITH CHECK (
    uploaded_by = auth.uid()
    AND can_view_task(task_id)
  );

CREATE POLICY "task_attachments_delete"
  ON task_attachments FOR DELETE
  TO authenticated
  USING (uploaded_by = auth.uid() OR is_admin());


-- ============================================================================
-- POLICIES: task_labels
-- All authenticated users can read labels. Creator and admin can manage.
-- ============================================================================

CREATE POLICY "task_labels_select"
  ON task_labels FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "task_labels_insert"
  ON task_labels FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "task_labels_update"
  ON task_labels FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid() OR is_admin())
  WITH CHECK (created_by = auth.uid() OR is_admin());

CREATE POLICY "task_labels_delete"
  ON task_labels FOR DELETE
  TO authenticated
  USING (created_by = auth.uid() OR is_admin());


-- ============================================================================
-- POLICIES: task_label_assignments
-- Visible if user can view the task. Managed by task creator/admin.
-- ============================================================================

CREATE POLICY "task_label_assignments_select"
  ON task_label_assignments FOR SELECT
  TO authenticated
  USING (can_view_task(task_id));

CREATE POLICY "task_label_assignments_insert"
  ON task_label_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks WHERE id = task_id AND created_by = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM task_assignees WHERE task_id = task_label_assignments.task_id AND user_id = auth.uid()
    )
    OR is_admin()
  );

CREATE POLICY "task_label_assignments_delete"
  ON task_label_assignments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks WHERE id = task_id AND created_by = auth.uid()
    )
    OR is_admin()
  );


-- ============================================================================
-- POLICIES: task_checklists
-- Visible if user can view the task.
-- ============================================================================

CREATE POLICY "task_checklists_select"
  ON task_checklists FOR SELECT
  TO authenticated
  USING (can_view_task(task_id));

CREATE POLICY "task_checklists_insert"
  ON task_checklists FOR INSERT
  TO authenticated
  WITH CHECK (can_view_task(task_id));

CREATE POLICY "task_checklists_update"
  ON task_checklists FOR UPDATE
  TO authenticated
  USING (can_view_task(task_id))
  WITH CHECK (can_view_task(task_id));

CREATE POLICY "task_checklists_delete"
  ON task_checklists FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks WHERE id = task_id AND created_by = auth.uid()
    )
    OR is_admin()
  );


-- ============================================================================
-- POLICIES: activity_logs
-- Visible to those who can see the task. Insert only (no user edits).
-- ============================================================================

CREATE POLICY "activity_logs_select"
  ON activity_logs FOR SELECT
  TO authenticated
  USING (can_view_task(task_id));

CREATE POLICY "activity_logs_insert"
  ON activity_logs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());


-- ============================================================================
-- POLICIES: notifications
-- Users can only see and update their own notifications.
-- ============================================================================

CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_insert"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);  -- System/service role creates notifications

CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_delete_own"
  ON notifications FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());


-- ============================================================================
-- POLICIES: device_tokens
-- Users manage only their own device tokens.
-- ============================================================================

CREATE POLICY "device_tokens_select_own"
  ON device_tokens FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "device_tokens_insert_own"
  ON device_tokens FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_update_own"
  ON device_tokens FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_delete_own"
  ON device_tokens FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());


-- ============================================================================
-- POLICIES: admin_settings
-- Only admins can read and modify settings.
-- ============================================================================

CREATE POLICY "admin_settings_select"
  ON admin_settings FOR SELECT
  TO authenticated
  USING (is_admin());

CREATE POLICY "admin_settings_insert"
  ON admin_settings FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "admin_settings_update"
  ON admin_settings FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "admin_settings_delete"
  ON admin_settings FOR DELETE
  TO authenticated
  USING (is_admin());
