/// VoiceTaskParser v2 – parses Romanian voice input into structured task data.
///
/// ## Parsing rules:
///
/// 1. **Slash separator** – "slash" splits the input into segments.
///    - First segment (before first slash) = **title**
///    - Middle segments (between slashes) = **description** (concatenated)
///    - Last segment may contain metadata (date, time, address, priority)
///
/// 2. **Date** – detected anywhere: "4 aprilie", "20 iunie 2026"
///    - If only date → no time. If only time → date = today.
///
/// 3. **Time** – "ora 14" → 14:00, "ora 9 și jumătate" → 9:30
///
/// 4. **Address** – triggered by "adresă" / "adresa" / "locație"
///    - Everything after keyword until next keyword = address text
///    - "Kuziini" → default Kuziini address
///
/// 5. **Priority** – "urgent" → high, "mediu" → medium, "low" → low
///
/// 6. **Assignee** – "arond" / "cc" / "avertizează" + name
///
/// 7. **Flexible order** – metadata can appear in any order, any segment.
///
/// ## Example:
/// ```
/// "măsurătoare Radu slash întâlnire Radu slash măsurătoare apartament
///  ora 14 4 aprilie adresă strada Solstițiului 11 urgent"
/// ```
/// Result:
/// ```json
/// { "title": "Măsurătoare Radu",
///   "description": "Întâlnire Radu. Măsurătoare apartament",
///   "date": "2026-04-04", "time": "14:00",
///   "address": "Strada Solstițiului 11",
///   "priority": "high" }
/// ```
library;

class VoiceTaskResult {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final int? hour;
  final int? minute;
  final String? priority; // high, medium, low
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
      locationAddress == null &&
      assigneeName == null;

  /// Convert to JSON-like map (for debugging / preview).
  Map<String, dynamic> toMap() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (dueDate != null) 'date': '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
    if (hour != null) 'time': '${hour.toString().padLeft(2, '0')}:${(minute ?? 0).toString().padLeft(2, '0')}',
    if (locationAddress != null) 'address': locationAddress,
    if (priority != null) 'priority': priority,
    if (assigneeName != null) 'assignee': assigneeName,
  };

  @override
  String toString() => 'VoiceTaskResult(${toMap()})';
}

class VoiceTaskParser {
  VoiceTaskParser._();

  // ── Month names (Romanian) ──
  static const _months = <String, int>{
    'ianuarie': 1, 'februarie': 2, 'martie': 3, 'aprilie': 4,
    'mai': 5, 'iunie': 6, 'iulie': 7, 'august': 8,
    'septembrie': 9, 'octombrie': 10, 'noiembrie': 11, 'decembrie': 12,
  };

  // ── Priority mapping ──
  // "urgent" → high (as per spec), "mediu" → medium, etc.
  static const _priorityMap = <String, String>{
    // → high
    'urgent': 'high', 'urgentă': 'high', 'urgență': 'high',
    'critic': 'high', 'critică': 'high', 'critical': 'high',
    'important': 'high', 'importantă': 'high', 'high': 'high',
    'mare': 'high', 'ridicat': 'high', 'ridicată': 'high',
    // → medium
    'mediu': 'medium', 'medie': 'medium', 'medium': 'medium',
    'normal': 'medium', 'normală': 'medium', 'moderat': 'medium',
    // → low
    'low': 'low', 'scăzut': 'low', 'scăzută': 'low',
    'mic': 'low', 'mică': 'low', 'redus': 'low', 'redusă': 'low',
    'opțional': 'low', 'optional': 'low',
  };

  // ── Keyword triggers ──
  static const _addressTriggers = ['adresă', 'adresa', 'locație', 'locația', 'locatie'];
  static const _timeTriggers = ['ora'];
  static const _assigneeTriggers = ['arond', 'cc', 'avertizează', 'avertizeaza', 'asignează', 'asigneaza', 'atribuie'];

  /// Main entry point.
  static VoiceTaskResult parse(String raw) {
    // ── Step 1: Split by "slash" ──
    final normalized = _preNormalize(raw);
    final segments = normalized.split(RegExp(r'\bslash\b'));

    String? title;
    final descParts = <String>[];
    DateTime? dueDate;
    int? hour;
    int? minute;
    String? priority;
    String? locationName;
    String? locationAddress;
    String? assigneeName;

    for (int segIdx = 0; segIdx < segments.length; segIdx++) {
      final segment = segments[segIdx].trim();
      if (segment.isEmpty) continue;

      // Extract metadata (date, time, address, priority, assignee) from this segment
      final extracted = _extractMetadata(segment);

      // Merge extracted metadata
      if (extracted.dueDate != null) dueDate = extracted.dueDate;
      if (extracted.hour != null) { hour = extracted.hour; minute = extracted.minute; }
      if (extracted.priority != null) priority = extracted.priority;
      if (extracted.locationAddress != null) locationAddress = extracted.locationAddress;
      if (extracted.locationName != null) locationName = extracted.locationName;
      if (extracted.assigneeName != null) assigneeName = extracted.assigneeName;

      // The remaining text (after metadata removal)
      final cleanText = extracted.remainingText.trim();
      if (cleanText.isEmpty) continue;

      if (segIdx == 0) {
        // First segment = title
        title = _capitalize(cleanText);
      } else {
        // Subsequent segments = description
        descParts.add(_capitalize(cleanText));
      }
    }

    // If no slash was used, try single-segment parsing
    // (backwards compatible with simple inputs)
    final description = descParts.isNotEmpty ? descParts.join('. ') : null;

    // If only time and no date → use today
    // (handled by caller, but we don't invent data)

    return VoiceTaskResult(
      title: title?.isNotEmpty == true ? title : null,
      description: description?.isNotEmpty == true ? description : null,
      dueDate: dueDate,
      hour: hour,
      minute: minute ?? 0,
      priority: priority,
      locationName: locationName,
      locationAddress: locationAddress,
      assigneeName: assigneeName,
    );
  }

  // ── Pre-normalize: lowercase, strip punctuation, collapse spaces ──
  static String _preNormalize(String text) {
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

  /// Extract all metadata from a text segment and return what's left.
  static _ExtractedMetadata _extractMetadata(String segment) {
    final words = segment.split(RegExp(r'\s+'));
    final remaining = <String>[];

    DateTime? dueDate;
    int? hour;
    int? minute;
    String? priority;
    String? locationName;
    String? locationAddress;
    String? assigneeName;

    int i = 0;
    while (i < words.length) {
      final word = words[i];

      // ── Time: "ora 14", "ora 9 și jumătate" ──
      if (_timeTriggers.contains(word)) {
        i++;
        final parsed = _parseTime(words, i);
        if (parsed != null) {
          hour = parsed.hour;
          minute = parsed.minute;
          i = parsed.endIndex;
        }
        continue;
      }

      // ── Date: "4 aprilie", "20 iunie 2026" ──
      // Check if current word is a day number followed by a month name
      final dayNum = int.tryParse(word);
      if (dayNum != null && dayNum >= 1 && dayNum <= 31 && i + 1 < words.length && _months.containsKey(words[i + 1])) {
        final monthNum = _months[words[i + 1]]!;
        i += 2;
        int? year;
        if (i < words.length) {
          final y = int.tryParse(words[i]);
          if (y != null && y >= 2024 && y <= 2030) { year = y; i++; }
        }
        year ??= DateTime.now().year;
        final candidate = DateTime(year, monthNum, dayNum);
        final now = DateTime.now();
        dueDate = candidate.isBefore(DateTime(now.year, now.month, now.day))
            ? DateTime(year + 1, monthNum, dayNum)
            : candidate;
        continue;
      }

      // ── Address: "adresă strada Solstițiului 11" ──
      if (_addressTriggers.contains(word)) {
        i++;
        final addrParts = <String>[];
        while (i < words.length) {
          // Stop at other known triggers
          if (_isKnownTrigger(words[i]) || _priorityMap.containsKey(words[i])) break;
          addrParts.add(words[i]);
          i++;
        }
        final addrText = addrParts.join(' ').trim();
        if (addrText.toLowerCase().contains('kuziini') || addrText.toLowerCase().contains('kuzini')) {
          locationName = 'Kuziini';
          locationAddress = 'Bulevardul Unirii Nr 63';
        } else {
          locationAddress = _capitalize(addrText);
        }
        continue;
      }

      // ── Assignee: "arond Mădălin", "cc Mădălina" ──
      if (_assigneeTriggers.contains(word)) {
        i++;
        final nameParts = <String>[];
        int count = 0;
        while (i < words.length && count < 3) {
          if (_isKnownTrigger(words[i]) || _priorityMap.containsKey(words[i])) break;
          nameParts.add(words[i]);
          i++;
          count++;
        }
        if (nameParts.isNotEmpty) {
          assigneeName = nameParts.map(_capitalize).join(' ');
        }
        continue;
      }

      // ── Priority: "urgent" → high, "mediu" → medium ──
      if (_priorityMap.containsKey(word)) {
        priority = _priorityMap[word];
        i++;
        continue;
      }

      // ── Not metadata → keep as remaining text ──
      remaining.add(word);
      i++;
    }

    return _ExtractedMetadata(
      remainingText: remaining.join(' '),
      dueDate: dueDate,
      hour: hour,
      minute: minute,
      priority: priority,
      locationName: locationName,
      locationAddress: locationAddress,
      assigneeName: assigneeName,
    );
  }

  /// Check if a word is a known trigger keyword.
  static bool _isKnownTrigger(String word) {
    return _timeTriggers.contains(word) ||
        _addressTriggers.contains(word) ||
        _assigneeTriggers.contains(word);
  }

  /// Parse time from words starting at [start].
  /// Handles: "14", "9 și jumătate", "15:30", "10 30"
  static _TimeResult? _parseTime(List<String> words, int start) {
    int i = start;
    int? h;
    int m = 0;

    // Skip filler words
    while (i < words.length && ['la', 'de', 'pe'].contains(words[i])) { i++; }

    if (i >= words.length) return null;

    // Try "15:30" format
    if (words[i].contains(':')) {
      final parts = words[i].split(':');
      h = int.tryParse(parts[0]);
      if (parts.length > 1) m = int.tryParse(parts[1]) ?? 0;
      i++;
    } else {
      h = int.tryParse(words[i]);
      if (h != null) {
        i++;
        // Check for minutes after hour
        if (i < words.length) {
          if (words[i] == 'și' || words[i] == 'si') {
            i++;
            if (i < words.length) {
              if (words[i] == 'jumătate' || words[i] == 'jumatate' || words[i] == 'juma') {
                m = 30; i++;
              } else if (words[i] == 'un' && i + 1 < words.length && words[i + 1] == 'sfert') {
                m = 15; i += 2;
              } else {
                final mins = int.tryParse(words[i]);
                if (mins != null && mins >= 0 && mins <= 59) { m = mins; i++; }
              }
            }
          } else {
            final mins = int.tryParse(words[i]);
            if (mins != null && mins >= 0 && mins <= 59) { m = mins; i++; }
          }
        }
      }
    }

    if (h != null && h >= 0 && h <= 23) {
      return _TimeResult(h, m, i);
    }
    return null;
  }
}

// ── Internal data classes ──

class _ExtractedMetadata {
  final String remainingText;
  final DateTime? dueDate;
  final int? hour;
  final int? minute;
  final String? priority;
  final String? locationName;
  final String? locationAddress;
  final String? assigneeName;

  _ExtractedMetadata({
    required this.remainingText,
    this.dueDate,
    this.hour,
    this.minute,
    this.priority,
    this.locationName,
    this.locationAddress,
    this.assigneeName,
  });
}

class _TimeResult {
  final int hour;
  final int minute;
  final int endIndex;
  _TimeResult(this.hour, this.minute, this.endIndex);
}
