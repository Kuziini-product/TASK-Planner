abstract final class AppConstants {
  // ── App Info ──
  static const String appName = 'Kuziini';
  static const String appTagline = 'Task Management, Simplified';
  static const String appVersion = '1.0.0';

  // ── Supabase Tables ──
  static const String tableUsers = 'profiles';
  static const String tableTasks = 'tasks';
  static const String tableTaskComments = 'task_comments';
  static const String tableTaskAttachments = 'task_attachments';
  static const String tableChecklistItems = 'task_checklists';
  static const String tableNotifications = 'notifications';
  static const String tableInvitations = 'invitations';
  static const String tableActivityLogs = 'activity_logs';

  // ── Storage Buckets ──
  static const String bucketAvatars = 'avatars';
  static const String bucketAttachments = 'task-attachments';

  // ── SharedPreferences Keys ──
  static const String prefThemeMode = 'theme_mode';
  static const String prefAccentColor = 'accent_color';
  static const String prefFcmToken = 'fcm_token';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefLastSyncTime = 'last_sync_time';

  // ── Timeline ──
  static const int timelineStartHour = 6;
  static const int timelineEndHour = 23;
  static const double timelineSlotHeight = 72.0;

  // ── Pagination ──
  static const int defaultPageSize = 20;
  static const int searchDebounceMs = 400;

  // ── Animation Durations (ms) ──
  static const int animationFast = 150;
  static const int animationNormal = 300;
  static const int animationSlow = 500;

  // ── Roles ──
  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';
  static const String roleViewer = 'viewer';

  // ── Validation ──
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 2000;
  static const int maxCommentLength = 1000;
  static const int maxAttachmentSizeMB = 10;
}
