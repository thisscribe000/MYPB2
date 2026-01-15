class PrayerNote {
  final String text;
  final DateTime createdAt;

  PrayerNote({
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PrayerNote.fromMap(Map<String, dynamic> map) {
    return PrayerNote(
      text: (map['text'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class PrayerProject {
  final String id;
  final String title;
  final int targetHours;
  final int durationDays;
  final DateTime startDate;

  int totalMinutesPrayed;

  /// NEW: journal-style notes
  List<PrayerNote> notes;

  PrayerProject({
    required this.id,
    required this.title,
    required this.targetHours,
    required this.durationDays,
    required this.startDate,
    this.totalMinutesPrayed = 0,
    List<PrayerNote>? notes,
  }) : notes = notes ?? [];

  double get progress {
    final targetMinutes = targetHours * 60;
    if (targetMinutes <= 0) return 0;
    return (totalMinutesPrayed / targetMinutes).clamp(0, 1);
  }

  double get dailyTargetHours {
    if (durationDays <= 0) return 0;
    return targetHours / durationDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetHours': targetHours,
      'durationDays': durationDays,
      'startDate': startDate.toIso8601String(),
      'totalMinutesPrayed': totalMinutesPrayed,

      // NEW storage shape
      'notes': notes.map((n) => n.toMap()).toList(),
    };
  }

  factory PrayerProject.fromMap(Map<String, dynamic> map) {
    // ✅ Backward compatibility:
    // Old versions stored notes as a single string: 'notes': 'some text'
    // New version stores notes as a list of maps: 'notes': [{'text':..., 'createdAt':...}, ...]
    final rawNotes = map['notes'];

    List<PrayerNote> parsedNotes = [];

    if (rawNotes is List) {
      parsedNotes = rawNotes
          .map((item) => PrayerNote.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } else if (rawNotes is String && rawNotes.trim().isNotEmpty) {
      parsedNotes = [
        PrayerNote(text: rawNotes.trim(), createdAt: DateTime.now())
      ];
    }

    return PrayerProject(
      id: map['id'] as String,
      title: map['title'] as String,
      targetHours: map['targetHours'] as int,
      durationDays: map['durationDays'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      totalMinutesPrayed: (map['totalMinutesPrayed'] as int?) ?? 0,
      notes: parsedNotes,
    );
  }
}
