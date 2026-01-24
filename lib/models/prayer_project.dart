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

  final DateTime plannedStartDate;

  int totalMinutesPrayed;

  /// Used for sorting on Pray Now
  DateTime? lastPrayedAt;

  /// Notes grouped by day number (1..durationDays)
  Map<int, List<PrayerNote>> dayNotes;

  /// Days where we have logged prayer time (timer or manual/retro add).
  Set<int> prayedDays;

  /// leftover seconds after Stop & Add
  int carrySeconds;

  /// ✅ Archive completed/old projects (hidden from Pray Now)
  bool isArchived;

  PrayerProject({
    required this.id,
    required this.title,
    required this.targetHours,
    required this.durationDays,
    required this.plannedStartDate,
    this.totalMinutesPrayed = 0,
    this.lastPrayedAt,
    Map<int, List<PrayerNote>>? dayNotes,
    Set<int>? prayedDays,
    this.carrySeconds = 0,
    this.isArchived = false,
  })  : dayNotes = dayNotes ?? {},
        prayedDays = prayedDays ?? {};

  DateTime get endDate =>
      plannedStartDate.add(Duration(days: durationDays - 1));

  int get targetMinutes => targetHours * 60;

  bool get isTargetReached =>
      targetMinutes > 0 && totalMinutesPrayed >= targetMinutes;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

  int daysUntilStart(DateTime date) {
    final start = _dateOnly(plannedStartDate);
    final current = _dateOnly(date);
    return start.difference(current).inDays;
  }

  String get statusLabel {
    if (isArchived) return 'Archived';
    if (isTargetReached) return 'Completed ✅';
    final d = dayNumberFor(DateTime.now());
    if (d == 0) return 'Upcoming';
    if (d == durationDays + 1) return 'Schedule ended';
    return 'Active';
  }

  double get progress {
    if (targetMinutes <= 0) return 0;
    return (totalMinutesPrayed / targetMinutes).clamp(0, 1);
  }

  double get dailyTargetHours {
    if (durationDays <= 0) return 0;
    return targetHours / durationDays;
  }

  void addNoteForDay(int dayNumber, PrayerNote note) {
    dayNotes.putIfAbsent(dayNumber, () => []);
    dayNotes[dayNumber]!.insert(0, note);
  }

  void extendByDays(int extraDays) {
    if (extraDays <= 0) return;
    durationDays += extraDays;
  }

  void markDayPrayed(int dayNumber) {
    if (dayNumber < 1 || dayNumber > durationDays) return;
    prayedDays.add(dayNumber);
  }

  List<int> get availableNoteDays {
    final list = prayedDays.toList()..sort((a, b) => b.compareTo(a));
    return list;
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
      'lastPrayedAt': lastPrayedAt?.toIso8601String(),
      'dayNotes': notesMap,
      'prayedDays': prayedDays.toList(),
      'carrySeconds': carrySeconds,
      'isArchived': isArchived,
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

    DateTime? lastPrayedAt;
    if (map['lastPrayedAt'] is String) {
      lastPrayedAt = DateTime.tryParse(map['lastPrayedAt'] as String);
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

    final Set<int> parsedPrayedDays = {};
    final rawPrayed = map['prayedDays'];
    if (rawPrayed is List) {
      for (final item in rawPrayed) {
        final n = int.tryParse(item.toString());
        if (n != null) parsedPrayedDays.add(n);
      }
    }

    // Migration safety: older data may have minutes but no prayedDays
    if (parsedPrayedDays.isEmpty) {
      final minutes = (map['totalMinutesPrayed'] as int?) ?? 0;
      if (minutes > 0) parsedPrayedDays.add(1);
    }

    return PrayerProject(
      id: map['id'] as String,
      title: map['title'] as String,
      targetHours: map['targetHours'] as int,
      durationDays: map['durationDays'] as int,
      plannedStartDate: plannedStart,
      totalMinutesPrayed: (map['totalMinutesPrayed'] as int?) ?? 0,
      lastPrayedAt: lastPrayedAt,
      dayNotes: parsedDayNotes,
      prayedDays: parsedPrayedDays,
      carrySeconds: (map['carrySeconds'] as int?) ?? 0,
      isArchived: (map['isArchived'] as bool?) ?? false,
    );
  }
}
