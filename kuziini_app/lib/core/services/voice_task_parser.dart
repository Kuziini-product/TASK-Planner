/// VoiceTaskParser – parses Romanian voice commands into structured task data.
///
/// Keyword triggers (Romanian):
///   "adăugăm task nou" / "task nou"  → next segment = title
///   "descriere" / "descrierea"        → next segment = description
///   "data" / "dată"                   → parse date (e.g. "15 ianuarie")
///   "ora"                             → parse time (e.g. "ora 15")
///   "adresă" / "locație"             → parse location
///   "urgent" / "high" / "medium" / "low" → priority
///   "arond" / "cc" / "avertizează"   → next word(s) = assignee name
///
/// Usage:
///   final result = VoiceTaskParser.parse("adăugăm task nou livrare mobilă descriere ...");
library;

class VoiceTaskResult {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final int? hour;
  final int? minute;
  final String? priority; // urgent, high, medium, low
  final String? locationName;
  final String? locationAddress;
  final String? assigneeName;

  const VoiceTaskResult({
    this.title,
    this.description,
    this.dueDate,
    this.hour,
    this.minute,
    this.priority,
    this.locationName,
    this.locationAddress,
    this.assigneeName,
  });

  bool get isEmpty =>
      title == null &&
      description == null &&
      dueDate == null &&
      hour == null &&
      priority == null &&
      locationName == null &&
      assigneeName == null;

  @override
  String toString() =>
      'VoiceTaskResult(title: $title, desc: $description, date: $dueDate, '
      'hour: $hour:$minute, priority: $priority, loc: $locationName / $locationAddress, '
      'assignee: $assigneeName)';
}

class VoiceTaskParser {
  VoiceTaskParser._();

  // ── Month names (Romanian) ──
  static const _months = <String, int>{
    'ianuarie': 1, 'februarie': 2, 'martie': 3, 'aprilie': 4,
    'mai': 5, 'iunie': 6, 'iulie': 7, 'august': 8,
    'septembrie': 9, 'octombrie': 10, 'noiembrie': 11, 'decembrie': 12,
  };

  // ── Priority synonyms ──
  static const _priorityMap = <String, String>{
    'urgent': 'urgent', 'urgentă': 'urgent', 'urgență': 'urgent',
    'critic': 'urgent', 'critică': 'urgent', 'critical': 'urgent',
    'important': 'high', 'importantă': 'high', 'high': 'high', 'mare': 'high', 'ridicat': 'high', 'ridicată': 'high',
    'mediu': 'medium', 'medie': 'medium', 'medium': 'medium', 'normal': 'medium', 'normală': 'medium',
    'low': 'low', 'scăzut': 'low', 'scăzută': 'low', 'mic': 'low', 'mică': 'low', 'redus': 'low', 'redusă': 'low',
  };

  // ── Section trigger keywords ──
  static const _titleTriggers = ['adăugăm task nou', 'task nou', 'titlu'];
  static const _descTriggers = ['descrierea taskului', 'descriere task', 'descrierea', 'descriere'];
  static const _dateTriggers = ['dată', 'data'];
  static const _timeTriggers = ['ora'];
  static const _locationTriggers = ['adresă', 'adresa', 'locație', 'locația', 'locatie'];
  static const _assigneeTriggers = ['arond', 'cc', 'avertizează', 'avertizeaza', 'asignează', 'asigneaza', 'atribuie'];

  /// Main entry point – parse a full voice transcript.
  static VoiceTaskResult parse(String raw) {
    final text = _normalize(raw);
    final words = text.split(RegExp(r'\s+'));

    String? title;
    String? description;
    DateTime? dueDate;
    int? hour;
    int? minute;
    String? priority;
    String? locationName;
    String? locationAddress;
    String? assigneeName;

    int i = 0;

    while (i < words.length) {
      // ── Check multi-word triggers first (longest match) ──

      // Title triggers
      final titleMatch = _matchTrigger(words, i, _titleTriggers);
      if (titleMatch != null) {
        i += titleMatch;
        final seg = _collectUntilNextTrigger(words, i);
        title = seg.text;
        i = seg.endIndex;
        continue;
      }

      // Description triggers
      final descMatch = _matchTrigger(words, i, _descTriggers);
      if (descMatch != null) {
        i += descMatch;
        final seg = _collectUntilNextTrigger(words, i);
        description = seg.text;
        i = seg.endIndex;
        continue;
      }

      // Date triggers
      final dateMatch = _matchTrigger(words, i, _dateTriggers);
      if (dateMatch != null) {
        i += dateMatch;
        final parsed = _parseDate(words, i);
        if (parsed != null) {
          dueDate = parsed.date;
          i = parsed.endIndex;
        }
        continue;
      }

      // Time triggers
      final timeMatch = _matchTrigger(words, i, _timeTriggers);
      if (timeMatch != null) {
        i += timeMatch;
        final parsed = _parseTime(words, i);
        if (parsed != null) {
          hour = parsed.hour;
          minute = parsed.minute;
          i = parsed.endIndex;
        }
        continue;
      }

      // Location triggers
      final locMatch = _matchTrigger(words, i, _locationTriggers);
      if (locMatch != null) {
        i += locMatch;
        final seg = _collectUntilNextTrigger(words, i);
        final locText = seg.text ?? '';
        i = seg.endIndex;

        // Check for "kuziini" / "kuzini" in location text
        if (locText.toLowerCase().contains('kuziini') || locText.toLowerCase().contains('kuzini')) {
          locationName = 'Kuziini';
          locationAddress = 'Bulevardul Unirii Nr 63';
        } else {
          // Try to separate display name from address
          // Pattern: "DisplayName, Address" or "DisplayName Address Number"
          final parts = _splitLocationParts(locText);
          locationName = parts.name;
          locationAddress = parts.address;
        }
        continue;
      }

      // Assignee triggers
      final assignMatch = _matchTrigger(words, i, _assigneeTriggers);
      if (assignMatch != null) {
        i += assignMatch;
        // Collect 1-3 words for assignee name
        final nameParts = <String>[];
        int count = 0;
        while (i < words.length && count < 3) {
          if (_isAnyTriggerStart(words, i)) break;
          nameParts.add(words[i]);
          i++;
          count++;
        }
        if (nameParts.isNotEmpty) {
          assigneeName = nameParts.join(' ');
        }
        continue;
      }

      // Priority keywords (standalone)
      final lowerWord = words[i].toLowerCase();
      if (_priorityMap.containsKey(lowerWord)) {
        priority = _priorityMap[lowerWord];
        i++;
        continue;
      }

      // If no trigger matched and no title yet, treat first words as title
      if (title == null) {
        final seg = _collectUntilNextTrigger(words, i);
        title = seg.text;
        i = seg.endIndex;
        continue;
      }

      i++;
    }

    return VoiceTaskResult(
      title: title?.trim().isNotEmpty == true ? _capitalize(title!) : null,
      description: description?.trim().isNotEmpty == true ? _capitalize(description!) : null,
      dueDate: dueDate,
      hour: hour,
      minute: minute ?? 0,
      priority: priority,
      locationName: locationName,
      locationAddress: locationAddress,
      assigneeName: assigneeName,
    );
  }

  // ── Helpers ──

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[.,;!?]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Try to match a multi-word trigger starting at position [start].
  /// Returns the number of words consumed, or null if no match.
  static int? _matchTrigger(List<String> words, int start, List<String> triggers) {
    for (final trigger in triggers) {
      final triggerWords = trigger.split(' ');
      if (start + triggerWords.length > words.length) continue;

      bool matched = true;
      for (int j = 0; j < triggerWords.length; j++) {
        if (words[start + j] != triggerWords[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return triggerWords.length;
    }
    return null;
  }

  /// Check if position [start] is the beginning of any known trigger.
  static bool _isAnyTriggerStart(List<String> words, int start) {
    final all = [
      ..._titleTriggers, ..._descTriggers, ..._dateTriggers,
      ..._timeTriggers, ..._locationTriggers, ..._assigneeTriggers,
    ];
    for (final trigger in all) {
      final tw = trigger.split(' ');
      if (start + tw.length > words.length) continue;
      bool m = true;
      for (int j = 0; j < tw.length; j++) {
        if (words[start + j] != tw[j]) { m = false; break; }
      }
      if (m) return true;
    }
    // Also check priority words
    if (_priorityMap.containsKey(words[start])) return true;
    return false;
  }

  /// Collect words until the next trigger keyword.
  static _Segment _collectUntilNextTrigger(List<String> words, int start) {
    final parts = <String>[];
    int i = start;
    while (i < words.length) {
      if (_isAnyTriggerStart(words, i)) break;
      parts.add(words[i]);
      i++;
    }
    return _Segment(parts.isNotEmpty ? parts.join(' ') : null, i);
  }

  /// Parse date like "15 ianuarie", "20 decembrie 2025"
  static _DateResult? _parseDate(List<String> words, int start) {
    int i = start;
    int? day;
    int? month;
    int? year;

    // Try to find day number
    while (i < words.length) {
      final num = int.tryParse(words[i]);
      if (num != null && num >= 1 && num <= 31) {
        day = num;
        i++;
        break;
      }
      // Skip filler words like "de", "pe", "la"
      if (['de', 'pe', 'la', 'în', 'in', 'din', 'lui'].contains(words[i])) {
        i++;
        continue;
      }
      break;
    }

    // Try to find month name
    if (i < words.length) {
      final monthNum = _months[words[i]];
      if (monthNum != null) {
        month = monthNum;
        i++;
      }
    }

    // Optional year
    if (i < words.length) {
      final y = int.tryParse(words[i]);
      if (y != null && y >= 2024 && y <= 2030) {
        year = y;
        i++;
      }
    }

    if (day != null && month != null) {
      year ??= DateTime.now().year;
      // If the date is in the past this year, assume next year
      final candidate = DateTime(year, month, day);
      final now = DateTime.now();
      final date = candidate.isBefore(DateTime(now.year, now.month, now.day))
          ? DateTime(year + 1, month, day)
          : candidate;
      return _DateResult(date, i);
    }

    return null;
  }

  /// Parse time like "15", "15 30", "3 și jumătate"
  static _TimeResult? _parseTime(List<String> words, int start) {
    int i = start;
    int? hour;
    int minute = 0;

    // Skip filler
    while (i < words.length && ['la', 'de', 'pe'].contains(words[i])) {
      i++;
    }

    if (i < words.length) {
      // Try "15:30" format
      if (words[i].contains(':')) {
        final parts = words[i].split(':');
        hour = int.tryParse(parts[0]);
        if (parts.length > 1) minute = int.tryParse(parts[1]) ?? 0;
        i++;
      } else {
        hour = int.tryParse(words[i]);
        if (hour != null) {
          i++;
          // Check for minutes
          if (i < words.length) {
            if (words[i] == 'și' || words[i] == 'si') {
              i++;
              if (i < words.length) {
                if (words[i] == 'jumătate' || words[i] == 'jumatate' || words[i] == 'juma') {
                  minute = 30;
                  i++;
                } else if (words[i] == 'un' && i + 1 < words.length && words[i + 1] == 'sfert') {
                  minute = 15;
                  i += 2;
                } else {
                  final m = int.tryParse(words[i]);
                  if (m != null && m >= 0 && m <= 59) {
                    minute = m;
                    i++;
                  }
                }
              }
            } else {
              final m = int.tryParse(words[i]);
              if (m != null && m >= 0 && m <= 59) {
                minute = m;
                i++;
              }
            }
          }
        }
      }
    }

    if (hour != null && hour >= 0 && hour <= 23) {
      return _TimeResult(hour, minute, i);
    }
    return null;
  }

  /// Try to split location into name + address.
  /// e.g. "bucurești mall calea vitan numărul 55" →
  ///   name: "București Mall", address: "Calea Vitan Numărul 55"
  static _LocationParts _splitLocationParts(String text) {
    // If text contains a comma, split there
    if (text.contains(',')) {
      final idx = text.indexOf(',');
      return _LocationParts(
        _capitalize(text.substring(0, idx).trim()),
        _capitalize(text.substring(idx + 1).trim()),
      );
    }

    // Look for street indicators
    final streetIndicators = [
      'strada', 'str', 'bulevardul', 'bd', 'calea', 'aleea',
      'șoseaua', 'soseaua', 'piața', 'piata', 'numărul', 'numarul', 'nr',
    ];

    final words = text.split(' ');
    int splitIdx = -1;
    for (int i = 0; i < words.length; i++) {
      if (streetIndicators.contains(words[i].toLowerCase())) {
        splitIdx = i;
        break;
      }
    }

    if (splitIdx > 0) {
      return _LocationParts(
        _capitalize(words.sublist(0, splitIdx).join(' ')),
        _capitalize(words.sublist(splitIdx).join(' ')),
      );
    }

    // No clear split – use full text as address
    return _LocationParts(null, _capitalize(text));
  }
}

class _Segment {
  final String? text;
  final int endIndex;
  _Segment(this.text, this.endIndex);
}

class _DateResult {
  final DateTime date;
  final int endIndex;
  _DateResult(this.date, this.endIndex);
}

class _TimeResult {
  final int hour;
  final int minute;
  final int endIndex;
  _TimeResult(this.hour, this.minute, this.endIndex);
}

class _LocationParts {
  final String? name;
  final String? address;
  _LocationParts(this.name, this.address);
}
