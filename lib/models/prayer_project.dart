class PrayerProject {
  final String id;
  final String title;

  /// Stored internally as minutes
  final int targetMinutes;

  final int durationDays;
  final DateTime startDate;

  /// This changes as the user prays
  int totalMinutesPrayed;

  PrayerProject({
    required this.id,
    required this.title,
    required this.targetMinutes,
    required this.durationDays,
    required this.startDate,
    this.totalMinutesPrayed = 0,
  });

  /// Create project using hours (user-friendly)
  factory PrayerProject.fromHours({
    required String id,
    required String title,
    required int targetHours,
    required int durationDays,
    required DateTime startDate,
  }) {
    return PrayerProject(
      id: id,
      title: title,
      targetMinutes: targetHours * 60,
      durationDays: durationDays,
      startDate: startDate,
    );
  }

  /// Target shown to user
  int get targetHours => (targetMinutes / 60).round();

  /// Minutes to pray per day
  int get dailyTargetMinutes => (targetMinutes / durationDays).ceil();

  /// Hours per day (UI display)
  double get dailyTargetHours => dailyTargetMinutes / 60;

  /// Progress between 0.0 and 1.0
  double get progress => totalMinutesPrayed / targetMinutes;
}
