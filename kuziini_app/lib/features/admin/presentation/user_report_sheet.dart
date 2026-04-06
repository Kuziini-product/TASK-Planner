import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
              // Last seen
              if (snapshot.hasData && snapshot.data!['last_seen'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.clock(PhosphorIconsStyle.regular), size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Ultima accesare: ${_formatLastSeen(snapshot.data!['last_seen'] as String)}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
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

String _formatLastSeen(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);

  if (diff.inMinutes < 2) return 'Acum';
  if (diff.inMinutes < 60) return 'Acum ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Acum ${diff.inHours}h';
  if (diff.inDays == 1) return 'Ieri, ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
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

    const SizedBox(height: 16),

    // Auto-alerts button
    Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => _showAutoAlertsSetup(ctx),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.bellRinging(PhosphorIconsStyle.fill), size: 22, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alerte automate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
                    Text('Configurează mesaje automate', style: TextStyle(fontSize: 11, color: Colors.deepPurple.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 16, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    ),

    const SizedBox(height: 30),
  ];
}

Future<Map<String, dynamic>> _fetchUserReport(String userId) async {
  final now = DateTime.now();
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  final monthStartStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

  // Fetch last_seen from profile
  String? lastSeen;
  try {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('last_seen')
        .eq('id', userId)
        .maybeSingle();
    lastSeen = profile?['last_seen'] as String?;
  } catch (_) {}

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
    'last_seen': lastSeen,
  };
}

// ── Auto Alerts Setup ──

void _showAutoAlertsSetup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => const _AutoAlertsSheet(),
  );
}

class _AutoAlertsSheet extends StatefulWidget {
  const _AutoAlertsSheet();
  @override
  State<_AutoAlertsSheet> createState() => _AutoAlertsSheetState();
}

class _AutoAlertsSheetState extends State<_AutoAlertsSheet> {
  final List<_AlertRule> _rules = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = prefs.getStringList('auto_alert_rules') ?? [];
    setState(() {
      _rules.addAll(rulesJson.map((r) => _AlertRule.fromString(r)));
      if (_rules.isEmpty) {
        // Default rules
        _rules.addAll([
          _AlertRule(trigger: 'overdue_3', message: 'Ai 3+ task-uri restante. Te rog să le rezolvi urgent!', enabled: false, channel: 'app'),
          _AlertRule(trigger: 'completion_low', message: 'Rata de completare este sub 50%. Hai să îmbunătățim!', enabled: false, channel: 'app'),
          _AlertRule(trigger: 'inactive_3d', message: 'Nu ai accesat aplicația de 3 zile. Verifică task-urile!', enabled: false, channel: 'app'),
          _AlertRule(trigger: 'weekly_report', message: 'Raport săptămânal: verifică progresul task-urilor tale.', enabled: false, channel: 'app'),
        ]);
      }
      _loaded = true;
    });
  }

  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('auto_alert_rules', _rules.map((r) => r.toStorageString()).toList());
  }

  String _triggerLabel(String trigger) {
    return switch (trigger) {
      'overdue_3' => 'Overdue >= 3 task-uri',
      'overdue_5' => 'Overdue >= 5 task-uri',
      'completion_low' => 'Rata completare < 50%',
      'completion_vlow' => 'Rata completare < 30%',
      'inactive_3d' => 'Inactiv 3+ zile',
      'inactive_7d' => 'Inactiv 7+ zile',
      'weekly_report' => 'Raport săptămânal',
      'daily_reminder' => 'Reminder zilnic',
      _ => trigger,
    };
  }

  IconData _triggerIcon(String trigger) {
    if (trigger.startsWith('overdue')) return PhosphorIcons.warning(PhosphorIconsStyle.fill);
    if (trigger.startsWith('completion')) return PhosphorIcons.chartBar(PhosphorIconsStyle.fill);
    if (trigger.startsWith('inactive')) return PhosphorIcons.userMinus(PhosphorIconsStyle.fill);
    return PhosphorIcons.bellRinging(PhosphorIconsStyle.fill);
  }

  Color _triggerColor(String trigger) {
    if (trigger.startsWith('overdue')) return Colors.red;
    if (trigger.startsWith('completion')) return Colors.orange;
    if (trigger.startsWith('inactive')) return Colors.purple;
    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.bellRinging(PhosphorIconsStyle.fill), color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              Text('Alerte Automate', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Mesaje trimise automat în funcție de performanță',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),

          if (!_loaded)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ..._rules.asMap().entries.map((entry) {
                    final i = entry.key;
                    final rule = entry.value;
                    final color = _triggerColor(rule.trigger);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: rule.enabled ? color.withValues(alpha: 0.06) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: rule.enabled ? color.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_triggerIcon(rule.trigger), size: 18, color: color),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_triggerLabel(rule.trigger),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: rule.enabled ? color : theme.colorScheme.onSurfaceVariant))),
                              Switch(
                                value: rule.enabled,
                                activeColor: color,
                                onChanged: (v) {
                                  setState(() => _rules[i] = rule.copyWith(enabled: v));
                                  _saveRules();
                                },
                              ),
                            ],
                          ),
                          // Message preview
                          GestureDetector(
                            onTap: () => _editMessage(i),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(PhosphorIcons.chatText(PhosphorIconsStyle.regular), size: 14, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rule.message, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  Icon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular), size: 12, color: theme.colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                          // Channel selector
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Text('Trimite prin: ', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                                _ChannelChip(label: 'App', icon: PhosphorIcons.bell(PhosphorIconsStyle.regular), isSelected: rule.channel == 'app',
                                  onTap: () { setState(() => _rules[i] = rule.copyWith(channel: 'app')); _saveRules(); }),
                                const SizedBox(width: 4),
                                _ChannelChip(label: 'Email', icon: PhosphorIcons.envelope(PhosphorIconsStyle.regular), isSelected: rule.channel == 'email',
                                  onTap: () { setState(() => _rules[i] = rule.copyWith(channel: 'email')); _saveRules(); }),
                                const SizedBox(width: 4),
                                _ChannelChip(label: 'WhatsApp', icon: PhosphorIcons.whatsappLogo(PhosphorIconsStyle.regular), isSelected: rule.channel == 'whatsapp',
                                  onTap: () { setState(() => _rules[i] = rule.copyWith(channel: 'whatsapp')); _saveRules(); }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add custom rule
                  GestureDetector(
                    onTap: _addCustomRule,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3), style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Adaugă regulă', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _editMessage(int index) {
    final ctrl = TextEditingController(text: _rules[index].message);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editează mesajul', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Mesajul care va fi trimis...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          FilledButton(onPressed: () {
            setState(() => _rules[index] = _rules[index].copyWith(message: ctrl.text.trim()));
            _saveRules();
            Navigator.pop(ctx);
          }, child: const Text('Salvează')),
        ],
      ),
    );
  }

  void _addCustomRule() {
    final triggers = ['overdue_3', 'overdue_5', 'completion_low', 'completion_vlow', 'inactive_3d', 'inactive_7d', 'weekly_report', 'daily_reminder'];
    final existing = _rules.map((r) => r.trigger).toSet();
    final available = triggers.where((t) => !existing.contains(t)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toate regulile disponibile sunt deja adăugate')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Alege condiția', style: TextStyle(fontSize: 16)),
        children: available.map((t) => SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            setState(() {
              _rules.add(_AlertRule(trigger: t, message: 'Mesaj automat pentru: ${_triggerLabel(t)}', enabled: true, channel: 'app'));
            });
            _saveRules();
          },
          child: Row(
            children: [
              Icon(_triggerIcon(t), size: 18, color: _triggerColor(t)),
              const SizedBox(width: 10),
              Text(_triggerLabel(t)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _AlertRule {
  final String trigger;
  final String message;
  final bool enabled;
  final String channel; // app, email, whatsapp

  const _AlertRule({required this.trigger, required this.message, required this.enabled, required this.channel});

  _AlertRule copyWith({String? trigger, String? message, bool? enabled, String? channel}) {
    return _AlertRule(
      trigger: trigger ?? this.trigger,
      message: message ?? this.message,
      enabled: enabled ?? this.enabled,
      channel: channel ?? this.channel,
    );
  }

  String toStorageString() => '$trigger|||$message|||$enabled|||$channel';

  factory _AlertRule.fromString(String s) {
    final parts = s.split('|||');
    return _AlertRule(
      trigger: parts[0],
      message: parts.length > 1 ? parts[1] : '',
      enabled: parts.length > 2 ? parts[2] == 'true' : false,
      channel: parts.length > 3 ? parts[3] : 'app',
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.label, required this.icon, required this.isSelected, required this.onTap});
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? Colors.deepPurple : theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.deepPurple.withValues(alpha: 0.4) : theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: color)),
          ],
        ),
      ),
    );
  }
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
