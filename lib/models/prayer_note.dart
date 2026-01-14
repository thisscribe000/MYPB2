class PrayerNote {
  final String id;
  final String projectId;

  /// Optional text note
  final String? text;

  /// Optional voice note file path
  final String? audioPath;

  final DateTime createdAt;

  PrayerNote({
    required this.id,
    required this.projectId,
    this.text,
    this.audioPath,
    required this.createdAt,
  });
}
