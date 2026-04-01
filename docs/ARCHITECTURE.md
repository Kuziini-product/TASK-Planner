# Kuziini Task Manager -- Product Architecture Document

> **Version:** 1.0  
> **Date:** April 2026  
> **Status:** Living Document  
> **Stack:** Flutter (mobile-first) + Supabase (backend)

---

## Table of Contents

- [A. Product Strategy](#a-product-strategy)
- [B. Information Architecture](#b-information-architecture)
- [C. UI/UX Design System](#c-uiux-design-system)
- [D. Technical Architecture](#d-technical-architecture)
- [E. Development Roadmap](#e-development-roadmap)

---

# A. Product Strategy

## A.1 Product Description

**Kuziini Task Manager** is a premium, mobile-first task management application designed for professionals and small teams who need clarity, structure, and elegance in how they manage work. The app is built around three core task dimensions:

- **Personal Tasks** -- tasks you create for yourself
- **Received Tasks** -- tasks assigned to you by others
- **Assigned Tasks** -- tasks you delegate to others

The name "Kuziini" evokes craftsmanship and precision. The product positions itself as a high-end, calm, and focused tool -- not a cluttered project management suite, but a refined daily companion for getting important work done.

**Core value proposition:** A beautifully designed daily task view that gives you immediate clarity on what needs your attention right now, combined with powerful team delegation features wrapped in a clean, premium interface.

## A.2 User Roles

| Role | Description | Capabilities |
|------|-------------|--------------|
| **User** | Standard team member | Create personal tasks, receive assigned tasks, view own calendar, manage own profile, attach files, comment on tasks |
| **Manager** | Team lead / supervisor | All User capabilities + assign tasks to users, view assigned task progress, see team workload overview |
| **Admin** | System administrator | All Manager capabilities + invite users, approve registrations, manage roles, manage organization settings, view admin analytics |

## A.3 User Journeys

### User Journey -- Standard User

```
Onboarding:
  Receives invite link via email
  --> Opens link, lands on registration screen
  --> Fills in name, email, password
  --> Sees "Pending Approval" screen
  --> Receives push notification when approved
  --> Lands on Daily Task View (Hero Screen)

Daily Flow:
  Opens app --> Daily Task View with today's tasks in timeline
  --> Sees time-blocked tasks, overdue items flagged red
  --> Taps task to view details, update status, add comment
  --> Swipes task to complete / snooze / reschedule
  --> Uses FAB to quick-add a new task
  --> Checks notifications for newly assigned tasks
  --> Reviews upcoming tasks in Calendar view

Task Management:
  Creates task --> Fills title, description, priority, deadline
  --> Optionally adds checklist, subtasks, tags, attachments
  --> Task appears in Daily View at scheduled time
  --> Updates status as work progresses
  --> Marks complete when done
```

### User Journey -- Manager

```
Task Delegation:
  Creates task --> Assigns to team member via assignee picker
  --> Sets priority, deadline, and description
  --> Task appears in "Assigned by Me" view
  --> Receives notification when assignee updates status
  --> Reviews progress via task comments and status changes
  --> Can reassign or adjust deadline as needed

Oversight:
  Opens "Assigned by Me" view --> Sees all delegated tasks
  --> Filters by status (in progress, overdue, completed)
  --> Taps into task to read comments and history
  --> Follows up on overdue items
```

### User Journey -- Admin

```
User Management:
  Opens Admin Zone --> Views pending registration requests
  --> Reviews applicant details
  --> Approves or rejects each request
  --> Assigns role (user / manager) to approved users
  --> Can later change roles or deactivate users

Invitation:
  Opens Admin Zone --> Taps "Invite User"
  --> Enters email address
  --> System sends invite link
  --> Tracks invitation status (sent, accepted, expired)

Organization:
  Manages organization-level settings
  --> Configures notification preferences
  --> Reviews system health and user activity
```

## A.4 Functional Scope

### MVP -- Phase 1

| Category | Features |
|----------|----------|
| **Authentication** | Email + password login, invite-only registration, admin approval workflow, secure session management, password reset |
| **Task CRUD** | Full task lifecycle with fields: title, description, priority (low/medium/high/urgent), status (todo/in_progress/done/cancelled), deadline, time interval (start/end time), assignee, creator, comments, file attachments, checklist items, subtasks, tags, edit history |
| **Daily Task View** | The HERO screen -- vertical timeline layout, tasks grouped by hour, swipe actions (complete, snooze, delete), drag-and-drop reordering, daily progress indicator, overdue task highlighting, empty state illustrations |
| **Task Views** | Today, Upcoming (next 7 days), Overdue, My Tasks (all personal), Assigned by Me, Received (assigned to me) |
| **Calendar View** | Monthly calendar with task density indicators, day detail view, ability to create tasks from calendar |
| **Notifications** | Push notifications (FCM), in-app notification center, notification for: task assigned, task updated, task overdue, comment added, approval status change |
| **File Attachments** | Camera capture, gallery picker, document picker, image preview, file download, storage in Supabase Storage |
| **Admin Zone** | Invitation management, approval queue, user list with role management, role assignment (user/manager/admin) |
| **Theming** | Dark mode and light mode with system preference detection, manual toggle |
| **Search & Filters** | Full-text search across task titles and descriptions, filter by priority, status, assignee, date range, tags |

### Phase 2 -- Future Enhancements

| Category | Features |
|----------|----------|
| **Analytics & Reports** | Personal productivity dashboard (tasks completed, streaks, time distribution), exportable reports |
| **Team Management** | Team creation, team-level task views, workload balancing visualization |
| **Task Dependencies** | "Blocked by" and "blocks" relationships, dependency chain visualization |
| **Recurring Tasks** | Daily, weekly, monthly, custom recurrence patterns, skip/complete instance handling |
| **Advanced Admin** | Organization analytics, user activity logs, audit trail, bulk operations |
| **Offline Mode** | Local SQLite cache, background sync, conflict resolution, offline task creation |
| **Widget Support** | iOS widgets (today summary, quick add), Android widgets (task list, progress ring) |

---

# B. Information Architecture

## B.1 Complete Sitemap

```
Kuziini Task Manager
|
+-- Auth
|   +-- Welcome / Landing
|   +-- Login
|   +-- Register (via invite link)
|   +-- Forgot Password
|   +-- Pending Approval
|
+-- Main App (authenticated)
|   |
|   +-- Today (Hero Screen) .................. [Bottom Nav 1]
|   |   +-- Daily Timeline View
|   |   +-- Task Detail Sheet
|   |   +-- Quick Add (FAB)
|   |
|   +-- Calendar ............................. [Bottom Nav 2]
|   |   +-- Month View
|   |   +-- Day Detail
|   |   +-- Create Task from Date
|   |
|   +-- Search ................................ [Bottom Nav 3]
|   |   +-- Search Results
|   |   +-- Filter Panel
|   |   +-- Task Views
|   |       +-- Upcoming
|   |       +-- Overdue
|   |       +-- My Tasks
|   |       +-- Assigned by Me
|   |       +-- Received
|   |
|   +-- Notifications ........................ [Bottom Nav 4]
|   |   +-- Notification List
|   |   +-- Notification Detail --> Task
|   |
|   +-- Profile ............................... [Bottom Nav 5]
|       +-- Account Settings
|       +-- Theme Toggle
|       +-- About
|       +-- Logout
|       +-- Admin Zone (admin only)
|           +-- Pending Approvals
|           +-- User Management
|           +-- Invitations
|           +-- Role Management
|
+-- Overlays & Sheets
    +-- Task Detail (bottom sheet / full screen)
    +-- Task Create / Edit (full screen)
    +-- Comment Thread
    +-- Attachment Viewer
    +-- Assignee Picker
    +-- Tag Picker
    +-- Filter Sheet
```

## B.2 Navigation Map

### Bottom Navigation Bar (5 tabs)

```
[  Today  ] [  Calendar  ] [  Search  ] [  Notifications  ] [  Profile  ]
    |             |             |               |                |
  Hero          Month         Search          Notif            Settings
  Screen        View          + Views         Center           + Admin
```

**Navigation rules:**
- Bottom nav is persistent across all main screens
- Task detail opens as a bottom sheet (half-screen) on tap, expandable to full screen on drag up
- Task create/edit opens as a full-screen modal with back/close
- Admin Zone is accessed from Profile tab (visible only to admin role)
- Deep links from notifications navigate directly to the relevant task

### Tab-specific navigation stacks

```
Today Tab:
  Daily Timeline --> [tap task] --> Task Detail Sheet
                 --> [FAB] --> Task Create
                 --> [swipe] --> Inline action (no navigation)

Calendar Tab:
  Month View --> [tap date] --> Day Detail --> [tap task] --> Task Detail
             --> [long press date] --> Task Create (with date pre-filled)

Search Tab:
  Search Bar + View Chips (Upcoming | Overdue | My Tasks | Assigned | Received)
  --> [search or select view] --> Task List --> Task Detail
  --> [filter icon] --> Filter Sheet (overlay)

Notifications Tab:
  Notification List --> [tap] --> Task Detail (navigates to Today or relevant view)

Profile Tab:
  Settings List --> Account Settings
                --> Theme Toggle (inline)
                --> Admin Zone --> Approvals / Users / Invitations
                --> Logout (confirmation dialog)
```

## B.3 User Flows

### Flow 1: Login

```
[App Launch]
    |
    v
[Check Auth State] --[valid session]--> [Main App / Today View]
    |
    [no session]
    |
    v
[Welcome Screen]
    |
    +-- [Login Button] --> [Login Screen]
    |                         |
    |                    [Enter email + password]
    |                         |
    |                    [Submit] --[success]--> [Main App / Today View]
    |                         |
    |                    [error] --> [Show error message, retry]
    |
    +-- [Forgot Password] --> [Enter email] --> [Send reset link] --> [Confirmation]
```

### Flow 2: Invite Acceptance & Registration

```
[Receive Invite Email]
    |
    v
[Tap Invite Link]
    |
    v
[App Opens / Deep Link to Register Screen]
    |
    v
[Registration Form]
    |-- Name
    |-- Email (pre-filled from invite)
    |-- Password
    |-- Confirm Password
    |
    v
[Submit Registration]
    |
    v
[Pending Approval Screen]
    |-- "Your account is under review"
    |-- Illustration + message
    |
    v
[Admin approves] --> [Push notification: "You're approved!"]
    |
    v
[User opens app] --> [Main App / Today View]
```

### Flow 3: Task Creation

```
[Any Screen with FAB visible]
    |
    v
[Tap FAB (+)]
    |
    v
[Task Create Screen]
    |
    +-- Title (required) ................ text input
    +-- Description ..................... rich text / plain text
    +-- Priority ....................... dropdown: Low | Medium | High | Urgent
    +-- Status ......................... default: To Do
    +-- Deadline ....................... date picker
    +-- Time Interval .................. start time + end time pickers
    +-- Assignee ....................... user search/picker (optional)
    +-- Tags ........................... tag picker / create new
    +-- Checklist ...................... add checklist items inline
    +-- Subtasks ....................... add subtask titles inline
    +-- Attachments .................... camera | gallery | document picker
    |
    v
[Save Task]
    |
    +--[personal task]--> Appears in "My Tasks" and "Today" (if deadline is today)
    +--[assigned task]--> Appears in "Assigned by Me" for creator
    |                     Appears in "Received" for assignee
    |                     Push notification sent to assignee
```

### Flow 4: Task Assignment

```
[Task Create or Task Edit]
    |
    v
[Tap Assignee Field]
    |
    v
[Assignee Picker]
    |-- Search bar
    |-- List of organization users (with avatars, names)
    |-- Currently assigned indicator
    |
    v
[Select User]
    |
    v
[Assignee populated in task form]
    |
    v
[Save Task]
    |
    v
[System Actions:]
    +-- Task.assignee_id = selected user
    +-- Task.creator_id = current user
    +-- Notification created for assignee
    +-- Push notification sent via FCM
    +-- Task visible in creator's "Assigned by Me"
    +-- Task visible in assignee's "Received"
    +-- History entry: "Assigned to [Name] by [Creator]"
```

### Flow 5: Admin Approval

```
[New user registers]
    |
    v
[Admin receives push notification: "New registration pending"]
    |
    v
[Admin opens app --> Profile --> Admin Zone --> Pending Approvals]
    |
    v
[Approval Queue]
    |-- User card: name, email, registration date
    |-- [Approve] button
    |-- [Reject] button
    |
    +--[Approve]
    |    |
    |    v
    |    [Select Role dialog: User | Manager]
    |    |
    |    v
    |    [Confirm]
    |    |
    |    v
    |    [User status --> approved, role assigned]
    |    [Push notification to user: "Welcome to Kuziini!"]
    |    [User can now log in and access the app]
    |
    +--[Reject]
         |
         v
         [Optional: rejection reason]
         [User status --> rejected]
         [Push notification to user: "Registration not approved"]
```

---

# C. UI/UX Design System

## C.1 Brand Identity

**Kuziini** represents:
- **Elegant** -- refined visual language, generous whitespace, considered typography
- **Mature** -- professional tone, no gimmicks, trusted by serious professionals
- **High-end** -- premium feel in every interaction, smooth animations, polished details
- **Professional** -- business-appropriate, focused on productivity
- **Calm** -- muted color palette, no visual noise, information density is controlled
- **Premium tech** -- cutting-edge but not flashy, smart defaults, delightful micro-interactions

**Design principles:**
1. **Clarity first** -- every element earns its place on screen
2. **Calm confidence** -- the interface should feel reassuring, never overwhelming
3. **Purposeful motion** -- animations guide attention, never distract
4. **Dense when needed, spacious by default** -- daily view is information-rich; creation flows are spacious
5. **Dark mode as a first-class citizen** -- not an afterthought

## C.2 Color System

### Light Mode Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#0D7377` | Deep teal -- primary actions, active nav, FAB |
| `primaryLight` | `#14919B` | Hover states, secondary emphasis |
| `primaryDark` | `#0A5C5F` | Pressed states, header backgrounds |
| `primarySurface` | `#E8F5F5` | Light teal tint for task cards, selected states |
| `secondary` | `#2D3142` | Dark navy -- text, headers, strong contrast |
| `secondaryLight` | `#4F5672` | Subheadings, secondary text |
| `accent` | `#E8AA42` | Warm gold -- highlights, badges, premium accents |
| `accentLight` | `#F5D89A` | Accent backgrounds, subtle highlights |
| `background` | `#FAFBFC` | Main background |
| `surface` | `#FFFFFF` | Cards, sheets, elevated surfaces |
| `surfaceVariant` | `#F0F2F5` | Grouped backgrounds, dividers |
| `onPrimary` | `#FFFFFF` | Text/icons on primary color |
| `onSecondary` | `#FFFFFF` | Text/icons on secondary color |
| `onBackground` | `#1A1C24` | Primary text on background |
| `onSurface` | `#2D3142` | Primary text on surface |
| `onSurfaceMuted` | `#8E93A6` | Placeholder text, disabled elements |

### Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `success` | `#2E7D5B` | Completed tasks, success toasts |
| `successSurface` | `#E6F4ED` | Success backgrounds |
| `warning` | `#D4880F` | Due soon, medium priority |
| `warningSurface` | `#FDF3E0` | Warning backgrounds |
| `error` | `#C0392B` | Overdue, urgent priority, errors |
| `errorSurface` | `#FDECEA` | Error backgrounds |
| `info` | `#2980B9` | Informational, low priority |
| `infoSurface` | `#E3F2FD` | Info backgrounds |

### Priority Colors

| Priority | Color | Badge BG |
|----------|-------|----------|
| Urgent | `#C0392B` (red) | `#FDECEA` |
| High | `#D4880F` (amber) | `#FDF3E0` |
| Medium | `#2980B9` (blue) | `#E3F2FD` |
| Low | `#8E93A6` (gray) | `#F0F2F5` |

### Dark Mode Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#14B8A6` | Brighter teal for dark backgrounds |
| `primaryLight` | `#2DD4BF` | Hover states |
| `primaryDark` | `#0D9488` | Pressed states |
| `primarySurface` | `#0D2E2E` | Tinted surface for selected states |
| `secondary` | `#E2E4EA` | Light text equivalent |
| `accent` | `#F5C542` | Brighter gold for dark backgrounds |
| `background` | `#0F1117` | Main background (near black, not pure black) |
| `surface` | `#1A1D27` | Cards, sheets |
| `surfaceVariant` | `#242836` | Grouped backgrounds |
| `surfaceElevated` | `#2A2E3D` | Modals, elevated sheets |
| `onBackground` | `#E8EAF0` | Primary text |
| `onSurface` | `#D1D5E0` | Text on surfaces |
| `onSurfaceMuted` | `#5A5F73` | Muted text, placeholders |

## C.3 Typography

**Font family:** `Inter` (primary), system font fallback

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `displayLarge` | 32px | 700 (Bold) | 40px | -0.5px | Hero numbers, empty state headings |
| `displayMedium` | 28px | 700 (Bold) | 36px | -0.3px | Screen titles |
| `headlineLarge` | 24px | 600 (SemiBold) | 32px | -0.2px | Section headers |
| `headlineMedium` | 20px | 600 (SemiBold) | 28px | 0 | Card titles, dialog headers |
| `titleLarge` | 18px | 600 (SemiBold) | 26px | 0 | Task titles in detail view |
| `titleMedium` | 16px | 500 (Medium) | 24px | 0.1px | Task titles in list, nav items |
| `bodyLarge` | 16px | 400 (Regular) | 24px | 0.2px | Task descriptions, body text |
| `bodyMedium` | 14px | 400 (Regular) | 20px | 0.2px | Comments, secondary content |
| `bodySmall` | 12px | 400 (Regular) | 16px | 0.3px | Timestamps, metadata |
| `labelLarge` | 14px | 500 (Medium) | 20px | 0.3px | Buttons, chips, tabs |
| `labelMedium` | 12px | 500 (Medium) | 16px | 0.5px | Badges, small labels |
| `labelSmall` | 10px | 500 (Medium) | 14px | 0.5px | Overline text, micro labels |

## C.4 Spacing System

**Base unit:** 4px

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2px | Hairline gaps, icon padding |
| `xs` | 4px | Tight internal spacing |
| `sm` | 8px | Small gaps, icon-to-text spacing |
| `md` | 12px | Card internal padding, list item gaps |
| `base` | 16px | Standard padding, section gaps |
| `lg` | 20px | Large internal spacing |
| `xl` | 24px | Section separators |
| `2xl` | 32px | Major section gaps |
| `3xl` | 40px | Screen top padding |
| `4xl` | 48px | Hero spacing |
| `5xl` | 64px | Empty state spacing |

**Border radius:**

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSm` | 6px | Small chips, badges |
| `radiusMd` | 10px | Cards, inputs |
| `radiusLg` | 14px | Bottom sheets, dialogs |
| `radiusXl` | 20px | FAB, large cards |
| `radiusFull` | 999px | Avatars, circular buttons |

## C.5 Component Library

### Core Components

| Component | Description | Key States |
|-----------|-------------|------------|
| **TaskCard** | Primary task display in lists and timeline. Shows title, priority badge, status chip, deadline, assignee avatar. Supports swipe gestures. | default, pressed, swiping-left, swiping-right, completed (strikethrough + muted), overdue (red accent border) |
| **TimeSlot** | Hourly container in Daily View timeline. Contains TaskCards for that hour. Shows hour label on left rail. | empty, has-tasks, current-hour (highlighted), past (muted) |
| **DayHeader** | Sticky header showing date, day name, task count, and daily progress ring. | today (accent), past (muted), future (default) |
| **QuickAddFAB** | Floating action button for rapid task creation. Bottom-right position. | default, pressed, expanded (shows mini-options) |
| **SwipeAction** | Swipe gesture handler wrapping TaskCard. Left swipe = complete. Right swipe = snooze/reschedule. | idle, swiping (reveals action background), threshold-reached (haptic feedback) |
| **PriorityBadge** | Small colored badge indicating task priority. | urgent (red), high (amber), medium (blue), low (gray) |
| **StatusChip** | Rounded chip showing task status. | todo (outline), in_progress (primary tint), done (success), cancelled (muted strikethrough) |
| **AvatarStack** | Overlapping circular avatars for showing multiple assignees/participants. | single, stacked (2-3), overflow (+N indicator) |
| **ProgressRing** | Circular progress indicator for daily completion rate. | 0% (empty, muted), partial (primary fill), 100% (success + checkmark animation) |
| **NotificationBell** | Nav bar icon with unread count badge. | no-unreads, has-unreads (red dot with count), animating (new notification pulse) |
| **EmptyState** | Illustration + message for empty lists. | varies per context (no tasks today, no notifications, etc.) |
| **FilterChip** | Selectable chip for filtering task lists. | unselected (outline), selected (filled primary) |
| **SearchBar** | Top search input with filter toggle. | collapsed (icon), expanded (full width input), active (with results) |
| **CommentBubble** | Chat-style comment display in task detail. | own-comment (right-aligned, primary tint), other-comment (left-aligned, surface) |
| **AttachmentTile** | File attachment thumbnail or icon with filename. | image (preview), document (icon + name), uploading (progress bar), error |
| **ChecklistItem** | Single checklist row with checkbox and text. | unchecked, checked (strikethrough), editing |
| **SubtaskRow** | Compact task row for subtask display. | incomplete, complete, overdue |
| **TagChip** | Colored tag label. | default (custom color), selected, removable (with X) |
| **DateTimePicker** | Custom date and time selector matching brand style. | date-only, time-only, date-and-time, range |
| **BottomSheet** | Draggable bottom sheet for task detail and pickers. | half-expanded, fully-expanded, dismissing |
| **ConfirmDialog** | Branded confirmation dialog for destructive actions. | default, loading (processing action) |

### Composite Screens

| Screen | Key Components Used |
|--------|-------------------|
| **Daily Task View** | DayHeader, TimeSlot (x24), TaskCard (multiple), ProgressRing, QuickAddFAB |
| **Task Detail** | BottomSheet, PriorityBadge, StatusChip, AvatarStack, ChecklistItem, SubtaskRow, CommentBubble, AttachmentTile, TagChip |
| **Task Create/Edit** | Full-screen modal, all input components, DateTimePicker, AssigneePicker, TagChip |
| **Calendar View** | MonthGrid, DayCell (with task dots), DayHeader, TaskCard (in day detail) |
| **Search / Views** | SearchBar, FilterChip, TaskCard (list), EmptyState |
| **Notification Center** | NotificationCard (list), EmptyState, pull-to-refresh |
| **Admin Zone** | UserCard, StatusBadge, RoleSelector, ApprovalActionButtons |

## C.6 State Handling Patterns

### Loading States
- **Skeleton screens** for initial loads (shimmer effect on placeholder TaskCards)
- **Pull-to-refresh** with branded loading indicator (teal spinner)
- **Inline loading** for actions (button shows spinner, disables interaction)
- **Optimistic updates** for status changes and completions (update UI immediately, rollback on error)

### Error States
- **Snackbar** for recoverable errors (network timeout, save failure) with retry action
- **Full-screen error** for critical failures (auth expired, server unreachable)
- **Inline validation** for form fields (red border, error text below input)
- **Toast** for non-critical confirmations (task saved, copied to clipboard)

### Empty States
- Each list view has a unique illustration and message
- Empty states include a primary CTA when applicable (e.g., "Create your first task")
- Illustrations match brand style (minimal line art, teal and gold accents)

### Transition States
- **Task completion:** checkbox fills with success color, text strikes through, card fades to 60% opacity after 1s delay
- **Task deletion:** card shrinks height to 0 with fade, list items reflow smoothly
- **View switching:** cross-fade between tab contents (200ms)
- **Sheet expansion:** spring-physics drag with velocity-based snapping

## C.7 Micro-interactions

| Interaction | Animation | Duration | Easing |
|-------------|-----------|----------|--------|
| Task complete (checkbox) | Scale bounce 1.0 -> 1.3 -> 1.0 + check draw | 400ms | spring (damping: 0.6) |
| Task complete (card) | Opacity 1.0 -> 0.6 + strikethrough sweep | 300ms | easeOut |
| Swipe action reveal | Background color slides in from edge | follows finger | linear |
| Swipe action trigger | Card snaps off-screen + haptic | 250ms | easeInOut |
| FAB press | Scale 1.0 -> 0.92 -> 1.0 | 150ms | easeOut |
| Priority badge appear | Scale 0 -> 1.1 -> 1.0 | 300ms | spring |
| Pull to refresh | Custom teal spinner rotation | continuous | linear |
| Progress ring fill | Arc sweep from 0 to value | 800ms | easeInOutCubic |
| Tab switch | Content cross-fade + subtle vertical shift (8px) | 200ms | easeOut |
| Notification badge | Scale pop 0 -> 1.2 -> 1.0 + subtle pulse | 400ms | spring |
| Bottom sheet drag | Spring physics with velocity | dynamic | spring (stiffness: 300) |
| Task card press | Slight scale down 1.0 -> 0.98 + shadow reduction | 100ms | easeOut |
| Drag-and-drop pickup | Scale 1.0 -> 1.05 + shadow elevation increase | 200ms | easeOut |
| Drag-and-drop drop | Scale 1.05 -> 1.0 + insertion animation | 300ms | spring |
| Toast/Snackbar enter | Slide up from bottom + fade in | 250ms | easeOutCubic |
| Toast/Snackbar exit | Slide down + fade out | 200ms | easeIn |
| Page transition (push) | Slide in from right + fade | 300ms | easeInOutCubic |
| Page transition (pop) | Slide out to right + fade | 250ms | easeInOutCubic |
| Skeleton shimmer | Gradient sweep left to right | 1500ms | linear (loop) |

---

# D. Technical Architecture

## D.1 Flutter Architecture

### State Management: Riverpod

Riverpod is used for all state management with the following provider hierarchy:

```
AsyncNotifierProvider  --> complex state with async operations (tasks, auth)
StateNotifierProvider  --> simple mutable state (filters, UI toggles)
FutureProvider         --> one-shot async reads (user profile, config)
StreamProvider         --> realtime data (notifications, task updates)
Provider               --> computed/derived values, dependency injection
```

### Routing: GoRouter

Declarative routing with:
- Route guards for auth state (redirect unauthenticated users to login)
- Route guards for role-based access (admin routes hidden from non-admins)
- Deep link support for notification navigation
- Shell route for bottom navigation persistence
- Nested navigation stacks per tab

### Clean Architecture Layers

```
lib/
|
+-- core/                          # Shared utilities and configuration
|   +-- constants/                 # App-wide constants, API keys references
|   +-- errors/                    # Custom exception classes, failure types
|   +-- extensions/                # Dart extensions (DateTime, String, etc.)
|   +-- theme/                     # ThemeData, colors, typography, spacing
|   |   +-- app_colors.dart
|   |   +-- app_typography.dart
|   |   +-- app_spacing.dart
|   |   +-- app_theme.dart
|   |   +-- dark_theme.dart
|   +-- utils/                     # Helpers (date formatting, validators)
|   +-- widgets/                   # Shared widgets (buttons, inputs, dialogs)
|
+-- features/                      # Feature-based modules
|   |
|   +-- auth/
|   |   +-- data/
|   |   |   +-- datasources/       # Supabase auth calls
|   |   |   +-- models/            # UserModel (JSON serialization)
|   |   |   +-- repositories/      # AuthRepositoryImpl
|   |   +-- domain/
|   |   |   +-- entities/          # User entity (pure Dart)
|   |   |   +-- repositories/      # AuthRepository (abstract)
|   |   |   +-- usecases/          # Login, Register, Logout, ResetPassword
|   |   +-- presentation/
|   |       +-- providers/         # Riverpod providers for auth state
|   |       +-- screens/           # LoginScreen, RegisterScreen, etc.
|   |       +-- widgets/           # Auth-specific widgets
|   |
|   +-- tasks/
|   |   +-- data/
|   |   |   +-- datasources/       # Supabase task CRUD, realtime subscriptions
|   |   |   +-- models/            # TaskModel, CommentModel, ChecklistItemModel
|   |   |   +-- repositories/      # TaskRepositoryImpl
|   |   +-- domain/
|   |   |   +-- entities/          # Task, Comment, ChecklistItem, Subtask
|   |   |   +-- repositories/      # TaskRepository (abstract)
|   |   |   +-- usecases/          # CreateTask, UpdateTask, DeleteTask,
|   |   |                          # GetTodayTasks, GetUpcoming, AssignTask, etc.
|   |   +-- presentation/
|   |       +-- providers/         # TaskListProvider, TaskDetailProvider,
|   |       |                      # TaskFilterProvider, DailyViewProvider
|   |       +-- screens/           # DailyTaskView, TaskDetailScreen,
|   |       |                      # TaskCreateScreen, TaskViewsScreen
|   |       +-- widgets/           # TaskCard, TimeSlot, SwipeAction,
|   |                              # PriorityBadge, StatusChip, etc.
|   |
|   +-- calendar/
|   |   +-- data/
|   |   +-- domain/
|   |   +-- presentation/
|   |       +-- providers/         # CalendarProvider, SelectedDateProvider
|   |       +-- screens/           # CalendarScreen
|   |       +-- widgets/           # MonthGrid, DayCell, DayDetail
|   |
|   +-- notifications/
|   |   +-- data/
|   |   |   +-- datasources/       # FCM setup, Supabase notifications table
|   |   |   +-- models/            # NotificationModel
|   |   |   +-- repositories/      # NotificationRepositoryImpl
|   |   +-- domain/
|   |   +-- presentation/
|   |       +-- providers/         # NotificationListProvider, UnreadCountProvider
|   |       +-- screens/           # NotificationCenterScreen
|   |       +-- widgets/           # NotificationCard
|   |
|   +-- search/
|   |   +-- presentation/
|   |       +-- providers/         # SearchProvider, FilterProvider
|   |       +-- screens/           # SearchScreen
|   |       +-- widgets/           # FilterSheet, FilterChip
|   |
|   +-- profile/
|   |   +-- data/
|   |   +-- domain/
|   |   +-- presentation/
|   |       +-- screens/           # ProfileScreen, AccountSettingsScreen
|   |
|   +-- admin/
|       +-- data/
|       |   +-- datasources/       # Supabase admin operations
|       |   +-- models/            # InvitationModel, ApprovalModel
|       |   +-- repositories/      # AdminRepositoryImpl
|       +-- domain/
|       |   +-- entities/          # Invitation, PendingUser
|       |   +-- repositories/      # AdminRepository (abstract)
|       |   +-- usecases/          # ApproveUser, RejectUser, InviteUser,
|       |                          # ChangeRole, ListUsers
|       +-- presentation/
|           +-- providers/         # AdminProvider, ApprovalQueueProvider
|           +-- screens/           # AdminZoneScreen, ApprovalScreen,
|           |                      # UserManagementScreen, InvitationsScreen
|           +-- widgets/           # UserCard, ApprovalActions, RoleSelector
|
+-- routing/
|   +-- app_router.dart            # GoRouter configuration
|   +-- route_names.dart           # Named route constants
|   +-- guards/                    # Auth guard, role guard
|
+-- services/
|   +-- supabase_service.dart      # Supabase client initialization
|   +-- notification_service.dart  # FCM initialization, token management
|   +-- storage_service.dart       # File upload/download helpers
|   +-- deep_link_service.dart     # Deep link handling
|
+-- app.dart                       # MaterialApp.router setup
+-- main.dart                      # Entry point, ProviderScope, initialization
```

## D.2 Supabase Backend Architecture

### Auth
- **Provider:** Email + password (Supabase Auth)
- **Custom flow:** Registration does not auto-confirm. A `profiles` table stores approval status. Users with `status = 'pending'` cannot access the app (enforced by RLS and client-side guard).
- **Session management:** Supabase handles JWT tokens, refresh tokens. Client stores session via `supabase_flutter` package.
- **Password reset:** Supabase built-in email flow.

### Database Schema

#### Table: `profiles`
Extends Supabase auth.users with app-specific fields.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, FK -> auth.users.id | User ID |
| `email` | text | not null | User email |
| `full_name` | text | not null | Display name |
| `avatar_url` | text | nullable | Profile picture URL |
| `role` | enum | default 'user' | 'user', 'manager', 'admin' |
| `status` | enum | default 'pending' | 'pending', 'approved', 'rejected', 'deactivated' |
| `fcm_token` | text | nullable | Push notification token |
| `created_at` | timestamptz | default now() | Registration timestamp |
| `updated_at` | timestamptz | default now() | Last profile update |

#### Table: `tasks`
Core task entity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK, default gen_random_uuid() | Task ID |
| `title` | text | not null | Task title |
| `description` | text | nullable | Detailed description |
| `priority` | enum | default 'medium' | 'low', 'medium', 'high', 'urgent' |
| `status` | enum | default 'todo' | 'todo', 'in_progress', 'done', 'cancelled' |
| `deadline` | date | nullable | Due date |
| `start_time` | time | nullable | Time interval start |
| `end_time` | time | nullable | Time interval end |
| `creator_id` | uuid | FK -> profiles.id, not null | Who created the task |
| `assignee_id` | uuid | FK -> profiles.id, nullable | Who the task is assigned to |
| `parent_task_id` | uuid | FK -> tasks.id, nullable | Parent task (for subtasks) |
| `sort_order` | integer | default 0 | Order within day/list (drag-and-drop) |
| `created_at` | timestamptz | default now() | Creation timestamp |
| `updated_at` | timestamptz | default now() | Last update timestamp |

#### Table: `task_comments`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Comment ID |
| `task_id` | uuid | FK -> tasks.id, not null | Parent task |
| `user_id` | uuid | FK -> profiles.id, not null | Comment author |
| `content` | text | not null | Comment text |
| `created_at` | timestamptz | default now() | Timestamp |

#### Table: `task_checklist_items`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Item ID |
| `task_id` | uuid | FK -> tasks.id, not null | Parent task |
| `title` | text | not null | Checklist item text |
| `is_completed` | boolean | default false | Completion status |
| `sort_order` | integer | default 0 | Display order |
| `created_at` | timestamptz | default now() | Timestamp |

#### Table: `task_attachments`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Attachment ID |
| `task_id` | uuid | FK -> tasks.id, not null | Parent task |
| `user_id` | uuid | FK -> profiles.id, not null | Uploader |
| `file_name` | text | not null | Original filename |
| `file_path` | text | not null | Storage path |
| `file_type` | text | not null | MIME type |
| `file_size` | bigint | not null | Size in bytes |
| `created_at` | timestamptz | default now() | Timestamp |

#### Table: `task_tags`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Tag ID |
| `name` | text | not null, unique | Tag name |
| `color` | text | not null | Hex color code |
| `created_by` | uuid | FK -> profiles.id | Creator |

#### Table: `task_tag_assignments`
Junction table for many-to-many task-tag relationship.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `task_id` | uuid | FK -> tasks.id, PK | Task |
| `tag_id` | uuid | FK -> task_tags.id, PK | Tag |

#### Table: `task_history`
Audit log for task changes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Entry ID |
| `task_id` | uuid | FK -> tasks.id, not null | Task |
| `user_id` | uuid | FK -> profiles.id, not null | Who made the change |
| `field_name` | text | not null | Changed field name |
| `old_value` | text | nullable | Previous value |
| `new_value` | text | nullable | New value |
| `created_at` | timestamptz | default now() | Timestamp |

#### Table: `notifications`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Notification ID |
| `user_id` | uuid | FK -> profiles.id, not null | Recipient |
| `type` | enum | not null | 'task_assigned', 'task_updated', 'comment_added', 'task_overdue', 'approval_status', 'invitation' |
| `title` | text | not null | Notification title |
| `body` | text | not null | Notification body |
| `data` | jsonb | nullable | Payload (task_id, etc.) |
| `is_read` | boolean | default false | Read status |
| `created_at` | timestamptz | default now() | Timestamp |

#### Table: `invitations`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | Invitation ID |
| `email` | text | not null | Invitee email |
| `invited_by` | uuid | FK -> profiles.id, not null | Admin who invited |
| `token` | text | not null, unique | Invite token for deep link |
| `status` | enum | default 'sent' | 'sent', 'accepted', 'expired' |
| `expires_at` | timestamptz | not null | Expiration timestamp |
| `created_at` | timestamptz | default now() | Timestamp |

### Entity Relationship Diagram

```
profiles (1) ----< (N) tasks (creator_id)
profiles (1) ----< (N) tasks (assignee_id)
tasks (1) ----< (N) tasks (parent_task_id)      [subtasks]
tasks (1) ----< (N) task_comments
tasks (1) ----< (N) task_checklist_items
tasks (1) ----< (N) task_attachments
tasks (1) ----< (N) task_history
tasks (N) >---< (N) task_tags                    [via task_tag_assignments]
profiles (1) ----< (N) notifications
profiles (1) ----< (N) invitations (invited_by)
profiles (1) ----< (N) task_comments (user_id)
profiles (1) ----< (N) task_history (user_id)
```

## D.3 Row Level Security (RLS)

All tables have RLS enabled. Policies follow these principles:

### `profiles`
- **SELECT:** Approved users can read all approved profiles (needed for assignee picker). Users can always read their own profile regardless of status.
- **UPDATE:** Users can update only their own profile (name, avatar, FCM token). Only admins can update `role` and `status` fields.
- **INSERT:** Handled by auth trigger (auto-creates profile on signup).
- **DELETE:** No direct deletion allowed.

### `tasks`
- **SELECT:** Users can read tasks where they are the `creator_id` OR the `assignee_id`. Subtasks inherit parent task visibility.
- **INSERT:** Any approved user can create tasks. `creator_id` must match `auth.uid()`.
- **UPDATE:** Creator can update all fields. Assignee can update `status` only. Admins can update any task.
- **DELETE:** Only the creator can delete a task. Admins can delete any task.

### `task_comments`
- **SELECT:** Users who can see the parent task can see its comments.
- **INSERT:** Users who can see the parent task can add comments. `user_id` must match `auth.uid()`.
- **UPDATE:** Users can edit only their own comments.
- **DELETE:** Users can delete only their own comments. Task creator can delete any comment on their task.

### `task_checklist_items` / `task_attachments`
- **SELECT / INSERT / UPDATE / DELETE:** Follow parent task visibility. Only task creator and assignee can modify.

### `task_history`
- **SELECT:** Same as parent task visibility.
- **INSERT:** System-level (via database triggers or edge functions). Not directly writable by clients.
- **UPDATE / DELETE:** Not allowed.

### `notifications`
- **SELECT:** Users can only read their own notifications.
- **UPDATE:** Users can mark their own notifications as read.
- **INSERT:** System-level only (via edge functions or triggers).
- **DELETE:** Users can delete their own notifications.

### `invitations`
- **SELECT:** Admins can see all invitations. Users can validate a specific invitation token during registration.
- **INSERT:** Only admins can create invitations.
- **UPDATE:** System-level (status changes on acceptance/expiration).
- **DELETE:** Only admins.

## D.4 Storage Structure

Supabase Storage buckets:

```
storage/
|
+-- avatars/                       # Profile pictures
|   +-- {user_id}/
|       +-- avatar.jpg             # Single avatar per user (overwritten)
|
+-- task-attachments/              # Task file attachments
    +-- {task_id}/
        +-- {uuid}_{filename}      # Unique prefix to avoid collisions
```

**Storage policies:**
- `avatars` bucket: Public read (profile pictures are visible to all authenticated users). Write restricted to own folder (`user_id` must match `auth.uid()`).
- `task-attachments` bucket: Private. Read/write restricted to users who have access to the parent task (creator or assignee). Validated via RLS-like storage policies that join against the `tasks` table.

**File size limits:**
- Avatars: 2MB max, images only (jpg, png, webp)
- Task attachments: 10MB max per file, common formats (images, PDF, DOC, XLS, TXT)

## D.5 Realtime Events

Supabase Realtime subscriptions used in the client:

| Channel | Table | Events | Purpose |
|---------|-------|--------|---------|
| `tasks:creator_id=eq.{uid}` | tasks | INSERT, UPDATE, DELETE | Live updates to "My Tasks" and "Assigned by Me" |
| `tasks:assignee_id=eq.{uid}` | tasks | INSERT, UPDATE, DELETE | Live updates to "Received" tasks |
| `task_comments:task_id=eq.{id}` | task_comments | INSERT | Live comment feed on task detail |
| `notifications:user_id=eq.{uid}` | notifications | INSERT | Real-time notification count and list |
| `profiles:status` | profiles | UPDATE | Admin: live approval queue updates |

**Realtime strategy:**
- Subscribe on screen mount, dispose on screen unmount
- Use Riverpod `StreamProvider` to bridge Supabase Realtime channels to UI
- Debounce rapid updates (e.g., drag-and-drop reordering) to avoid excessive traffic

## D.6 Notification Pipeline

```
[Event Trigger]
    |
    |  (e.g., task assigned, comment added, task overdue)
    |
    v
[Supabase Database Trigger / Edge Function]
    |
    +-- 1. Insert row into `notifications` table
    |       (for in-app notification center)
    |
    +-- 2. Call Supabase Edge Function: `send-push-notification`
            |
            v
        [Edge Function Logic]
            |
            +-- Fetch recipient's `fcm_token` from `profiles`
            +-- Skip if no token or user has disabled push
            +-- Build FCM payload:
            |     {
            |       "to": fcm_token,
            |       "notification": { "title": "...", "body": "..." },
            |       "data": { "type": "task_assigned", "task_id": "..." }
            |     }
            +-- Send POST to FCM API (Firebase Cloud Messaging)
            +-- Log result
```

**Notification triggers:**

| Event | Trigger Type | Recipient | Notification Content |
|-------|-------------|-----------|---------------------|
| Task assigned | DB trigger on `tasks` INSERT/UPDATE (when `assignee_id` changes) | Assignee | "[Creator] assigned you a task: [Title]" |
| Task status updated | DB trigger on `tasks` UPDATE (when `status` changes) | Creator (if assignee updated) | "[Assignee] marked [Title] as [Status]" |
| Comment added | DB trigger on `task_comments` INSERT | Task creator + assignee (excluding commenter) | "[Commenter] commented on [Title]" |
| Task overdue | Scheduled Edge Function (cron, runs daily at midnight) | Task creator + assignee | "Task overdue: [Title] was due [Date]" |
| Registration pending | DB trigger on `profiles` INSERT (when `status = 'pending'`) | All admins | "New registration: [Name] is waiting for approval" |
| Approval status change | DB trigger on `profiles` UPDATE (when `status` changes to `approved`/`rejected`) | The user | "Your account has been [approved/rejected]" |

**Edge Functions deployed:**
1. `send-push-notification` -- receives notification payload, sends to FCM
2. `check-overdue-tasks` -- cron job (daily), finds overdue tasks, creates notifications
3. `send-invitation-email` -- sends invite email with deep link token
4. `handle-invite-acceptance` -- validates invite token, marks as accepted

---

# E. Development Roadmap

## Overview

Six two-week sprints covering MVP (Phase 1) delivery. Total timeline: 12 weeks.

```
Sprint 1 [Week 1-2]   Project Setup, Auth, Database
Sprint 2 [Week 3-4]   Task CRUD, Daily Task View
Sprint 3 [Week 5-6]   Calendar, Task Views, Search
Sprint 4 [Week 7-8]   Files, Notifications
Sprint 5 [Week 9-10]  Admin Zone
Sprint 6 [Week 11-12] Polish, Testing, Launch
```

---

### Sprint 1: Foundation (Weeks 1-2)

**Goal:** Running app with auth flow and database ready.

| Task | Details | Priority |
|------|---------|----------|
| Flutter project initialization | Create project, configure folder structure, add dependencies (riverpod, go_router, supabase_flutter, etc.) | P0 |
| Supabase project setup | Create project, configure auth settings (disable email confirmation for invite flow), set up environment variables | P0 |
| Database schema creation | Create all tables, enums, indexes, foreign keys via Supabase migrations | P0 |
| RLS policies | Implement all Row Level Security policies for every table | P0 |
| Theme system | Implement AppColors, AppTypography, AppSpacing, light/dark ThemeData | P0 |
| Core widgets | Build shared Button, Input, Dialog, BottomSheet, Toast components | P1 |
| Auth screens | Welcome, Login, Register, Forgot Password, Pending Approval screens | P0 |
| Auth logic | Riverpod providers for auth state, Supabase auth integration, session persistence | P0 |
| Invite flow backend | Invitations table, Edge Function for sending invite emails, deep link configuration | P0 |
| GoRouter setup | Route definitions, auth guard, shell route for bottom nav | P0 |
| CI/CD basics | GitHub repo, branch protection, basic GitHub Actions for Flutter analyze + test | P2 |

**Sprint 1 deliverable:** User can receive an invite, register, wait for approval, log in, and see an empty home screen with bottom navigation. Dark/light mode toggle works.

---

### Sprint 2: Task Engine (Weeks 3-4)

**Goal:** Full task CRUD and the hero Daily Task View.

| Task | Details | Priority |
|------|---------|----------|
| Task data layer | TaskModel, TaskRepository, Supabase datasource for CRUD operations | P0 |
| Task domain layer | Task entity, use cases (CreateTask, UpdateTask, DeleteTask, GetTasks) | P0 |
| Task Create/Edit screen | Full form with all fields: title, description, priority, status, deadline, time interval, assignee picker, tags, checklist, subtasks | P0 |
| TaskCard widget | Implement with priority badge, status chip, deadline display, assignee avatar | P0 |
| Daily Task View (Hero Screen) | Timeline layout with hourly slots, DayHeader with progress ring, task cards positioned by time, current-hour indicator | P0 |
| Swipe actions | Left swipe to complete, right swipe to snooze/reschedule, with animated backgrounds and haptic feedback | P0 |
| Drag-and-drop reordering | Reorder tasks within and across time slots, persist sort_order | P1 |
| Quick Add FAB | Floating action button opening a minimal quick-add form (title + time only), with option to expand to full form | P0 |
| Comments system | Comment CRUD, CommentBubble widget, real-time comment updates | P1 |
| Checklist items | Add/remove/toggle checklist items within task detail | P1 |
| Subtasks | Create subtasks (child tasks), display in parent task detail | P1 |
| Task history | Database triggers to log field changes to `task_history`, display history timeline in task detail | P2 |
| Assignee picker | Searchable user list for assigning tasks, with avatar and name | P0 |

**Sprint 2 deliverable:** Users can create, view, edit, and delete tasks with all fields. The Daily Task View shows today's tasks in a timeline with swipe actions, drag-and-drop, and a progress ring. Tasks can be assigned to other users.

---

### Sprint 3: Views & Discovery (Weeks 5-6)

**Goal:** Calendar view, all task list views, and search functionality.

| Task | Details | Priority |
|------|---------|----------|
| Calendar screen | Month grid view with task density dots per day, swipe between months | P0 |
| Calendar day detail | Tap a day to see task list for that date, create task from date | P0 |
| Today view refinements | Edge cases: no tasks, all completed, overdue from previous days | P0 |
| Upcoming view | Tasks for the next 7 days, grouped by day | P0 |
| Overdue view | All tasks past deadline with status not done/cancelled, sorted by how overdue | P0 |
| My Tasks view | All tasks created by current user, filterable | P0 |
| Assigned by Me view | All tasks where creator is current user and assignee is someone else | P0 |
| Received view | All tasks assigned to current user by others | P0 |
| Search functionality | Full-text search across task titles and descriptions, debounced input | P0 |
| Filter system | Filter sheet with: priority, status, assignee, date range, tags. Applied via FilterChip row. | P0 |
| Tag management | Create, edit, delete tags. Tag picker in task create/edit. Tag filter chip. | P1 |
| Empty states | Design and implement unique empty state illustrations and messages for each view | P1 |
| Realtime subscriptions | Subscribe to task changes for live updates across all views | P0 |

**Sprint 3 deliverable:** All task views are functional. Calendar shows task distribution. Search and filters work across all views. Realtime updates keep everything in sync.

---

### Sprint 4: Attachments & Notifications (Weeks 7-8)

**Goal:** File handling and full notification pipeline.

| Task | Details | Priority |
|------|---------|----------|
| Storage setup | Configure Supabase Storage buckets (avatars, task-attachments) with policies | P0 |
| Camera capture | Capture photo from camera, compress, upload to storage | P0 |
| Gallery picker | Select image from gallery, compress, upload | P0 |
| Document picker | Select PDF/DOC/XLS files, upload to storage | P0 |
| AttachmentTile widget | Preview thumbnails for images, file icon for documents, upload progress | P0 |
| Attachment viewer | Full-screen image viewer with zoom, document download | P1 |
| Profile avatar upload | Camera/gallery picker for avatar, crop, upload to avatars bucket | P1 |
| FCM setup | Firebase project, FCM configuration for iOS and Android, token registration | P0 |
| Notification service | FCM initialization, foreground/background message handling, token refresh | P0 |
| Edge Function: send-push | Receives notification data, sends to FCM, handles errors | P0 |
| Database triggers | Create triggers for task assignment, status change, comment added | P0 |
| In-app notification center | Notification list screen, unread count badge on nav, mark as read, tap to navigate | P0 |
| Edge Function: overdue check | Cron function to detect overdue tasks and create notifications daily | P1 |
| Notification preferences | User settings: enable/disable push, enable/disable per notification type | P2 |

**Sprint 4 deliverable:** Users can attach files (photos, documents) to tasks. Push notifications arrive for key events. In-app notification center shows all notifications with unread count.

---

### Sprint 5: Admin Zone (Weeks 9-10)

**Goal:** Complete admin functionality for user and invitation management.

| Task | Details | Priority |
|------|---------|----------|
| Admin route guard | GoRouter guard: only `role = 'admin'` can access admin routes | P0 |
| Admin Zone screen | Dashboard entry point with cards: Pending Approvals, Users, Invitations | P0 |
| Approval queue | List pending registrations with user details, approve/reject buttons | P0 |
| Approve flow | Role selection dialog on approve, update profile status + role, send notification | P0 |
| Reject flow | Optional rejection reason, update profile status, send notification | P0 |
| User management | List all users with search, role badges, status indicators | P0 |
| Role management | Change user role (user/manager/admin) with confirmation dialog | P0 |
| User deactivation | Deactivate/reactivate users, deactivated users cannot log in | P1 |
| Invitation screen | List sent invitations with status (sent/accepted/expired) | P0 |
| Create invitation | Form to enter email, sends invite via Edge Function, generates deep link | P0 |
| Edge Function: invite email | Sends branded email with invite link, handles expiration | P0 |
| Deep link handling | App handles invite deep links, pre-fills email on register screen | P0 |
| Admin notifications | Push notifications to admins for new pending registrations | P1 |
| Pending approval screen | Polish the "waiting for approval" screen with illustration and messaging | P1 |

**Sprint 5 deliverable:** Admins can invite users via email, approve/reject registrations, manage roles, and view all users. The invite-to-onboarding pipeline is complete end-to-end.

---

### Sprint 6: Polish & Launch (Weeks 11-12)

**Goal:** Production-ready quality, performance, and launch.

| Task | Details | Priority |
|------|---------|----------|
| Animation polish | Refine all micro-interactions: task completion, swipe actions, page transitions, skeleton loaders | P0 |
| Performance optimization | Profile and optimize: list rendering (use `ListView.builder`), image caching, minimize rebuilds, lazy loading | P0 |
| Error handling | Comprehensive error states for all screens, network error recovery, retry logic | P0 |
| Loading states | Skeleton screens for all list views, inline loading indicators, optimistic UI updates | P0 |
| Accessibility | Semantic labels, sufficient contrast ratios, touch target sizes (min 48px), screen reader testing | P1 |
| Responsive polish | Test on various screen sizes (small phones to tablets), fix any layout issues | P1 |
| Edge case testing | Empty states, very long text, rapid tapping, back button behavior, deep link edge cases | P0 |
| Integration testing | Write integration tests for critical flows: auth, task CRUD, assignment, notification | P0 |
| Unit testing | Test business logic: use cases, providers, data transformations | P1 |
| Security audit | Review RLS policies, test unauthorized access attempts, validate input sanitization | P0 |
| App store assets | App icon (teal/emerald themed), splash screen, store screenshots, description | P1 |
| Splash screen | Branded splash with Kuziini logo and smooth transition to app | P1 |
| App icon | Design and implement adaptive icon for Android and iOS | P1 |
| Beta testing | Internal beta via TestFlight (iOS) and Firebase App Distribution (Android) | P0 |
| Bug fixes | Address all bugs found during beta testing | P0 |
| Production deployment | Supabase production project, environment separation, final database migration | P0 |
| App store submission | Submit to Google Play and Apple App Store | P0 |

**Sprint 6 deliverable:** Production-ready app submitted to both app stores. All critical flows tested, polished, and performant. Branded assets in place.

---

## Appendix: Key Dependencies

### Flutter Packages

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` / `riverpod_annotation` | State management |
| `go_router` | Declarative routing |
| `supabase_flutter` | Supabase client (auth, database, storage, realtime) |
| `firebase_messaging` | Push notifications (FCM) |
| `firebase_core` | Firebase initialization |
| `image_picker` | Camera and gallery access |
| `file_picker` | Document picker |
| `image_cropper` | Avatar cropping |
| `flutter_local_notifications` | Local notification display |
| `cached_network_image` | Image caching and loading |
| `intl` | Date/time formatting, localization |
| `freezed` / `json_serializable` | Immutable models, JSON serialization |
| `flutter_slidable` | Swipe action gestures |
| `flutter_animate` | Declarative animations |
| `table_calendar` | Calendar grid widget (customized) |
| `shimmer` | Skeleton loading effect |
| `uuid` | UUID generation |
| `url_launcher` | External link handling |
| `permission_handler` | Runtime permissions (camera, storage) |
| `flutter_svg` | SVG rendering for icons and illustrations |
| `path_provider` | File system paths |

### Supabase Edge Functions Runtime

- **Deno** (TypeScript)
- Dependencies: `supabase-js`, FCM HTTP v1 API, Resend or similar for invite emails

---

> **Document maintained by:** Kuziini Product & Engineering  
> **Last updated:** April 2026
