/// VoiceTaskParser v3 – semantic keyword context switching.
///
/// The user speaks naturally. Keywords change the active field context.
/// Keywords are stripped from final content.
///
/// ## Active field contexts:
///   title (default) → description → time → date → address → priority → assign
///
/// ## Keyword triggers (not saved in content):
///   Description: "description", "descriere", "subiect"
///   Time:        "time", "timp", "ora"
///   Date:        "date", "data", "dată"
///   Address:     "address", "adresă", "adresa", "locație", "locatie"
///   Priority:    "priority", "praioriti", "prioritate"
///   Assign:      "assign", "asign", "atribuie", "atribuie lui",
///                "trimite și la", "trimite la", "zi-i și lui",
///                "cc", "notifică", "notifica"
///
/// ## Example:
///   "Măsurătoare apartament Băneasa description discuție pentru mobilare
///    bucătărie time ora 14 date 4 aprilie adresă strada Solstițiului 11
///    București priority high trimite și la Radu"
///
/// Result:
///   title: "Măsurătoare apartament Băneasa"
///   description: "Discuție pentru mobilare bucătărie"
///   time: 14:00, date: 2026-04-04
///   address: "Strada Solstițiului 11 București"
///   priority: high
///   assignees: ["Radu"]
library;

// ── Field enum ──
enum VoiceField { title, description, time, date, address, priority, assign }

// ── Result ──
class VoiceTaskResult {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final int? hour;
  final int? minute;
  final String? priority; // high, medium, low, none
  final String? address;
  final List<String> assignees;
  /// Which field is currently being filled (for live UI).
  final VoiceField activeField;

  const VoiceTaskResult({
    this.title,
    this.description,
    this.dueDate,
    this.hour,
    this.minute,
    this.priority,
    this.address,
    this.assignees = const [],
    this.activeField = VoiceField.title,
  });

  bool get isEmpty =>
      title == null &&
      description == null &&
      dueDate == null &&
      hour == null &&
      priority == null &&
      address == null &&
      assignees.isEmpty;

  Map<String, dynamic> toMap() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (dueDate != null) 'date': '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
    if (hour != null) 'time': '${hour.toString().padLeft(2, '0')}:${(minute ?? 0).toString().padLeft(2, '0')}',
    if (address != null) 'address': address,
    if (priority != null) 'priority': priority,
    if (assignees.isNotEmpty) 'assignees': assignees,
  };
}

// ── Parser ──
class VoiceTaskParser {
  VoiceTaskParser._();

  // ── Months ──
  static const _months = <String, int>{
    'ianuarie': 1, 'februarie': 2, 'martie': 3, 'aprilie': 4,
    'mai': 5, 'iunie': 6, 'iulie': 7, 'august': 8,
    'septembrie': 9, 'octombrie': 10, 'noiembrie': 11, 'decembrie': 12,
  };

  // ── Priority values ──
  static const _priorityValues = <String, String>{
    'high': 'high', 'hai': 'high', 'urgent': 'high', 'urgentă': 'high',
    'ridicat': 'high', 'ridicată': 'high', 'mare': 'high',
    'medium': 'medium', 'mediu': 'medium', 'medie': 'medium',
    'normal': 'medium', 'normală': 'medium', 'moderat': 'medium',
    'low': 'low', 'lou': 'low', 'scăzut': 'low', 'scăzută': 'low',
    'mic': 'low', 'mică': 'low', 'redus': 'low',
    'none': 'none', 'fără': 'none', 'niciuna': 'none',
  };

  // ── Multi-word keyword triggers (longer first for greedy match) ──
  static const _contextTriggers = <String, VoiceField>{
    // Assign (multi-word first)
    'trimite și la': VoiceField.assign,
    'trimite si la': VoiceField.assign,
    'trimite la': VoiceField.assign,
    'zi-i și lui': VoiceField.assign,
    'zi-i si lui': VoiceField.assign,
    'atribuie lui': VoiceField.assign,
    'atribuie la': VoiceField.assign,
    'assign': VoiceField.assign,
    'asign': VoiceField.assign,
    'atribuie': VoiceField.assign,
    'notifică': VoiceField.assign,
    'notifica': VoiceField.assign,
    'cc': VoiceField.assign,
    // Description
    'description': VoiceField.description,
    'descriere': VoiceField.description,
    'subiect': VoiceField.description,
    // Time
    'time': VoiceField.time,
    'timp': VoiceField.time,
    'ora': VoiceField.time,
    // Date
    'date': VoiceField.date,
    'dată': VoiceField.date,
    'data': VoiceField.date,
    // Address
    'address': VoiceField.address,
    'adresă': VoiceField.address,
    'adresa': VoiceField.address,
    'locație': VoiceField.address,
    'locatie': VoiceField.address,
    'locația': VoiceField.address,
    // Priority
    'priority': VoiceField.priority,
    'praioriti': VoiceField.priority,
    'prioritate': VoiceField.priority,
  };

  /// Parse the full transcript. Returns structured result with active field.
  static VoiceTaskResult parse(String raw) {
    final text = _normalize(raw);
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty || (words.length == 1 && words[0].isEmpty)) {
      return const VoiceTaskResult();
    }

    var activeField = VoiceField.title;
    final buffers = <VoiceField, List<String>>{
      for (final f in VoiceField.values) f: [],
    };

    int i = 0;
    while (i < words.length) {
      // Try to match a context trigger (greedy: longest match first)
      final match = _matchContextTrigger(words, i);
      if (match != null) {
        activeField = match.field;
        i += match.wordCount;
        continue;
      }

      // Add word to active buffer
      buffers[activeField]!.add(words[i]);
      i++;
    }

    // ── Post-process each field ──
    final title = _joinAndCapitalize(buffers[VoiceField.title]!);
    final description = _joinAndCapitalize(buffers[VoiceField.description]!);
    final address = _joinAndCapitalize(buffers[VoiceField.address]!);

    // Time
    int? hour;
    int? minute;
    final timeWords = buffers[VoiceField.time]!;
    if (timeWords.isNotEmpty) {
      final parsed = _parseTime(timeWords);
      if (parsed != null) { hour = parsed.hour; minute = parsed.minute; }
    }

    // Date
    DateTime? dueDate;
    final dateWords = buffers[VoiceField.date]!;
    if (dateWords.isNotEmpty) {
      dueDate = _parseDate(dateWords);
    }

    // Priority
    String? priority;
    final prioWords = buffers[VoiceField.priority]!;
    if (prioWords.isNotEmpty) {
      for (final w in prioWords) {
        if (_priorityValues.containsKey(w)) {
          priority = _priorityValues[w];
          break;
        }
      }
    }

    // Assignees – split by "și", "si", ",", "and"
    final assignees = _parseAssignees(buffers[VoiceField.assign]!);

    return VoiceTaskResult(
      title: title,
      description: description,
      dueDate: dueDate,
      hour: hour,
      minute: minute ?? 0,
      priority: priority,
      address: address,
      assignees: assignees,
      activeField: activeField,
    );
  }

  // ── Helpers ──

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[.;!?]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _joinAndCapitalize(List<String> words) {
    if (words.isEmpty) return null;
    final s = words.join(' ').trim();
    if (s.isEmpty) return null;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Try to match a context trigger starting at position [start].
  /// Returns the matched field and word count, or null.
  static _TriggerMatch? _matchContextTrigger(List<String> words, int start) {
    // Sort triggers by word count descending (greedy match)
    final sorted = _contextTriggers.entries.toList()
      ..sort((a, b) => b.key.split(' ').length.compareTo(a.key.split(' ').length));

    for (final entry in sorted) {
      final triggerWords = entry.key.split(' ');
      if (start + triggerWords.length > words.length) continue;

      bool matched = true;
      for (int j = 0; j < triggerWords.length; j++) {
        if (words[start + j] != triggerWords[j]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return _TriggerMatch(entry.value, triggerWords.length);
      }
    }
    return null;
  }

  /// Parse time from buffer words. Handles: "14", "14 30", "10:30", "9 și jumătate"
  static _TimeResult? _parseTime(List<String> words) {
    int i = 0;
    // Skip filler
    while (i < words.length && ['la', 'de', 'pe', 'ora'].contains(words[i])) { i++; }
    if (i >= words.length) return null;

    int? h;
    int m = 0;

    if (words[i].contains(':')) {
      final parts = words[i].split(':');
      h = int.tryParse(parts[0]);
      if (parts.length > 1) m = int.tryParse(parts[1]) ?? 0;
      i++;
    } else {
      h = int.tryParse(words[i]);
      if (h != null) {
        i++;
        if (i < words.length) {
          if (words[i] == 'și' || words[i] == 'si') {
            i++;
            if (i < words.length) {
              if (['jumătate', 'jumatate', 'juma'].contains(words[i])) { m = 30; i++; }
              else if (words[i] == 'un' && i + 1 < words.length && words[i + 1] == 'sfert') { m = 15; i += 2; }
              else { final mins = int.tryParse(words[i]); if (mins != null && mins <= 59) { m = mins; i++; } }
            }
          } else {
            final mins = int.tryParse(words[i]);
            if (mins != null && mins >= 0 && mins <= 59) { m = mins; i++; }
          }
        }
      }
    }

    return (h != null && h >= 0 && h <= 23) ? _TimeResult(h, m) : null;
  }

  /// Parse date from buffer words. Handles: "4 aprilie", "20 iunie 2026"
  static DateTime? _parseDate(List<String> words) {
    int? day;
    int? month;
    int? year;

    for (int i = 0; i < words.length; i++) {
      // Skip filler
      if (['de', 'pe', 'la', 'în', 'in', 'din', 'lui'].contains(words[i])) continue;

      final num = int.tryParse(words[i]);
      if (num != null) {
        if (day == null && num >= 1 && num <= 31) {
          day = num;
        } else if (num >= 2024 && num <= 2030) {
          year = num;
        }
        continue;
      }

      if (_months.containsKey(words[i])) {
        month = _months[words[i]];
      }
    }

    if (day != null && month != null) {
      year ??= DateTime.now().year;
      final candidate = DateTime(year, month, day);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return candidate.isBefore(todayDate)
          ? DateTime(year + 1, month, day)
          : candidate;
    }

    return null;
  }

  /// Parse assignee names. Split by "și", "si", ",", "and".
  static List<String> _parseAssignees(List<String> words) {
    if (words.isEmpty) return [];

    // Join and split by separators
    final joined = words.join(' ');
    final parts = joined.split(RegExp(r'\s*(?:și|si|,|and)\s*'));

    final names = <String>[];
    for (final part in parts) {
      // Clean each name: remove "lui", "la" prefixes
      var name = part.trim();
      name = name.replaceAll(RegExp(r'^(lui|la|pe)\s+', caseSensitive: false), '');
      name = name.trim();
      if (name.isNotEmpty) {
        names.add(name[0].toUpperCase() + name.substring(1));
      }
    }
    return names;
  }
}

// ── Internal ──

class _TriggerMatch {
  final VoiceField field;
  final int wordCount;
  _TriggerMatch(this.field, this.wordCount);
}

class _TimeResult {
  final int hour;
  final int minute;
  _TimeResult(this.hour, this.minute);
}
