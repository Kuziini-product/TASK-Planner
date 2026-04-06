import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';

/// Show a detailed report bottom sheet for a specific user.
void showUserReport(BuildContext context, String userId, String userName) {
  final theme = Theme.of(context);
  final primaryColor = theme.colorScheme.primary;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserReport(userId),
        builder: (ctx, snapshot) {
          return Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.fill), color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Raport $userName', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                Expanded(child: Center(child: Text('Eroare: ${snapshot.error}')))
              else
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _buildReportContent(ctx, snapshot.data!, primaryColor),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

List<Widget> _buildReportContent(BuildContext context, Map<String, dynamic> data, Color primaryColor) {
  final theme = Theme.of(context);
  final total = data['total'] as int;
  final done = data['done'] as int;
  final inProgress = data['in_progress'] as int;
  final todo = data['todo'] as int;
  final overdue = data['overdue'] as int;
  final pct = total > 0 ? (done * 100 / total).round() : 0;
  final weeklyDone = data['weekly_done'] as int;
  final monthlyDone = data['monthly_done'] as int;
  final avgDays = data['avg_completion_days'] as double;
  final recentTasks = data['recent_tasks'] as List<Map<String, dynamic>>;

  return [
    // Overview cards
    Row(
      children: [
        _StatBox('Total', '$total', primaryColor),
        const SizedBox(width: 8),
        _StatBox('Done', '$done', AppColors.success),
        const SizedBox(width: 8),
        _StatBox('In Prog', '$inProgress', Colors.orange),
        const SizedBox(width: 8),
        _StatBox('To Do', '$todo', Colors.blue),
      ],
    ),
    const SizedBox(height: 12),

    // Completion percentage
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.trophy(PhosphorIconsStyle.fill), size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Rata de completare', style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor)),
              const Spacer(),
              Text('$pct%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              color: primaryColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),

    // Overdue + speed
    Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: overdue > 0 ? Colors.red.withValues(alpha: 0.06) : AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (overdue > 0 ? Colors.red : AppColors.success).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), size: 22, color: overdue > 0 ? Colors.red : AppColors.success),
                const SizedBox(height: 4),
                Text('$overdue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: overdue > 0 ? Colors.red : AppColors.success)),
                Text('Overdue', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(PhosphorIcons.lightning(PhosphorIconsStyle.fill), size: 22, color: primaryColor),
                const SizedBox(height: 4),
                Text(avgDays > 0 ? '${avgDays.toStringAsFixed(1)}d' : '-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryColor)),
                Text('Timp mediu', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),

    // Weekly / Monthly
    Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('$weeklyDone', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.indigo)),
                Text('Săptămâna asta', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('$monthlyDone', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.teal)),
                Text('Luna asta', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),

    // Recent tasks
    Text('Ultimele task-uri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
    const SizedBox(height: 8),
    if (recentTasks.isEmpty)
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Fără task-uri recente', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      )
    else
      ...recentTasks.map((t) {
        final status = t['status'] as String;
        final title = t['title'] as String;
        final dueDate = t['due_date'] as String?;
        final statusColor = status == 'done' ? AppColors.success
            : status == 'in_progress' ? Colors.orange
            : status == 'todo' ? Colors.blue
            : Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (dueDate != null)
                Text(dueDate.substring(5), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
        );
      }),

    const SizedBox(height: 30),
  ];
}

Future<Map<String, dynamic>> _fetchUserReport(String userId) async {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  final monthStartStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

  final tasks = await Supabase.instance.client
      .from('tasks')
      .select('status, due_date, title, created_at, completed_at')
      .eq('created_by', userId);

  final taskList = (tasks as List).where((t) {
    final title = (t['title'] as String? ?? '').toLowerCase();
    return !title.contains('concediu') && !title.contains('liber') && t['status'] != 'archived';
  }).toList();

  final total = taskList.length;
  final done = taskList.where((t) => t['status'] == 'done').length;
  final inProgress = taskList.where((t) => t['status'] == 'in_progress').length;
  final todo = taskList.where((t) => t['status'] == 'todo').length;
  final overdue = taskList.where((t) {
    if (t['status'] == 'done') return false;
    final dd = t['due_date'] as String?;
    return dd != null && dd.compareTo(today) < 0;
  }).length;

  // Weekly done
  final weeklyDone = taskList.where((t) {
    if (t['status'] != 'done') return false;
    final ca = t['completed_at'] as String?;
    return ca != null && ca.compareTo(weekStartStr) >= 0;
  }).length;

  // Monthly done
  final monthlyDone = taskList.where((t) {
    if (t['status'] != 'done') return false;
    final ca = t['completed_at'] as String?;
    return ca != null && ca.compareTo(monthStartStr) >= 0;
  }).length;

  // Average completion time
  double avgDays = 0;
  int completedCount = 0;
  for (final t in taskList) {
    if (t['status'] == 'done' && t['created_at'] != null && t['completed_at'] != null) {
      final created = DateTime.tryParse(t['created_at'] as String);
      final completed = DateTime.tryParse(t['completed_at'] as String);
      if (created != null && completed != null) {
        avgDays += completed.difference(created).inHours / 24.0;
        completedCount++;
      }
    }
  }
  if (completedCount > 0) avgDays = avgDays / completedCount;

  // Recent tasks (last 10)
  final sorted = List<Map<String, dynamic>>.from(taskList);
  sorted.sort((a, b) => (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''));
  final recent = sorted.take(10).map((t) => {
    'title': t['title'] as String? ?? '',
    'status': t['status'] as String? ?? 'todo',
    'due_date': t['due_date'] as String?,
  }).toList();

  return {
    'total': total,
    'done': done,
    'in_progress': inProgress,
    'todo': todo,
    'overdue': overdue,
    'weekly_done': weeklyDone,
    'monthly_done': monthlyDone,
    'avg_completion_days': avgDays,
    'recent_tasks': recent,
  };
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
