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
  int durationDays;

  /// When the user plans to start (can be in the future)
  final DateTime plannedStartDate;

  /// Logged prayer time in minutes (internal)
  int totalMinutesPrayed;

  /// Notes grouped by day number (1..durationDays)
  Map<int, List<PrayerNote>> dayNotes;

  PrayerProject({
    required this.id,
    required this.title,
    required this.targetHours,
    required this.durationDays,
    required this.plannedStartDate,
    this.totalMinutesPrayed = 0,
    Map<int, List<PrayerNote>>? dayNotes,
  }) : dayNotes = dayNotes ?? {};

  /// End date = plannedStartDate + (durationDays - 1)
  DateTime get endDate => plannedStartDate.add(Duration(days: durationDays - 1));

  int get targetMinutes => targetHours * 60;

  /// Completion logic
  bool get isTargetReached => targetMinutes > 0 && totalMinutesPrayed >= targetMinutes;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns day number for a given date (1..durationDays), or:
  /// - 0 if before start date
  /// - durationDays+1 if after end date
  int dayNumberFor(DateTime date) {
    final start = _dateOnly(plannedStartDate);
    final current = _dateOnly(date);

    final diffDays = current.difference(start).inDays;
    if (diffDays < 0) return 0;

    final day = diffDays + 1;
    if (day > durationDays) return durationDays + 1;

    return day;
  }

  bool get isScheduleEnded {
    final day = dayNumberFor(DateTime.now());
    return day == durationDays + 1;
  }

  bool isActiveOn(DateTime date) {
    final day = dayNumberFor(date);
    return day >= 1 && day <= durationDays;
  }

  int daysUntilStart(DateTime date) {
    final start = _dateOnly(plannedStartDate);
    final current = _dateOnly(date);
    return start.difference(current).inDays;
  }

  /// Status label (gentle)
  String get statusLabel {
    if (isTargetReached) return 'Completed ✅';
    final d = dayNumberFor(DateTime.now());
    if (d == 0) return 'Upcoming';
    if (d == durationDays + 1) return 'Schedule ended';
    return 'Active';
  }

  /// Progress toward target hours (time-based)
  double get progress {
    if (targetMinutes <= 0) return 0;
    return (totalMinutesPrayed / targetMinutes).clamp(0, 1);
  }

  /// Daily target in hours (time-based)
  double get dailyTargetHours {
    if (durationDays <= 0) return 0;
    return targetHours / durationDays;
  }

  /// Adds a note under a specific day number
  void addNoteForDay(int dayNumber, PrayerNote note) {
    dayNotes.putIfAbsent(dayNumber, () => []);
    dayNotes[dayNumber]!.insert(0, note);
  }

  /// Extend schedule by extra days (keeps start date)
  void extendByDays(int extraDays) {
    if (extraDays <= 0) return;
    durationDays += extraDays;
  }

  Map<String, dynamic> toMap() {
    final notesMap = <String, dynamic>{};
    dayNotes.forEach((day, notes) {
      notesMap[day.toString()] = notes.map((n) => n.toMap()).toList();
    });

    return {
      'id': id,
      'title': title,
      'targetHours': targetHours,
      'durationDays': durationDays,
      'plannedStartDate': plannedStartDate.toIso8601String(),
      'totalMinutesPrayed': totalMinutesPrayed,
      'dayNotes': notesMap,
    };
  }

  factory PrayerProject.fromMap(Map<String, dynamic> map) {
    DateTime plannedStart;
    if (map['plannedStartDate'] is String) {
      plannedStart = DateTime.parse(map['plannedStartDate'] as String);
    } else if (map['startDate'] is String) {
      plannedStart = DateTime.parse(map['startDate'] as String);
    } else {
      plannedStart = DateTime.now();
    }

    final Map<int, List<PrayerNote>> parsedDayNotes = {};
    final rawDayNotes = map['dayNotes'];

    if (rawDayNotes is Map) {
      rawDayNotes.forEach((k, v) {
        final day = int.tryParse(k.toString());
        if (day == null) return;
        if (v is List) {
          parsedDayNotes[day] = v
              .map((item) => PrayerNote.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        }
      });
    } else {
      final rawNotes = map['notes'];
      if (rawNotes is List) {
        parsedDayNotes[1] = rawNotes
            .map((item) => PrayerNote.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else if (rawNotes is String && rawNotes.trim().isNotEmpty) {
        parsedDayNotes[1] = [
          PrayerNote(text: rawNotes.trim(), createdAt: DateTime.now()),
        ];
      }
    }

    return PrayerProject(
      id: map['id'] as String,
      title: map['title'] as String,
      targetHours: map['targetHours'] as int,
      durationDays: map['durationDays'] as int,
      plannedStartDate: plannedStart,
      totalMinutesPrayed: (map['totalMinutesPrayed'] as int?) ?? 0,
      dayNotes: parsedDayNotes,
    );
  }
}
