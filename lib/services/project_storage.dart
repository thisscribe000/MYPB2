import 'package:hive/hive.dart';
import '../models/prayer_project.dart';

class ProjectStorage {
  static const String boxName = 'prayer_projects';

  static Future<Box> _openBox() async {
    return await Hive.openBox(boxName);
  }

  /// Save all projects
  static Future<void> saveProjects(List<PrayerProject> projects) async {
    final box = await _openBox();
    final data = projects.map((p) => p.toMap()).toList();
    await box.put('projects', data);
  }

  /// Load all projects
  static Future<List<PrayerProject>> loadProjects() async {
    final box = await _openBox();
    final data = box.get('projects', defaultValue: []);

    return (data as List)
        .map((item) => PrayerProject.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
