import 'package:flutter/material.dart';
import '../models/prayer_project.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<PrayerProject> projects;

  const AnalyticsScreen({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinutes = projects.fold<int>(0, (sum, p) => sum + p.totalMinutesPrayed);
    final totalHours = totalMinutes / 60.0;

    // Average per day across active projects (rough baseline)
    final activeProjects = projects.where((p) {
      final d = p.dayNumberFor(DateTime.now());
      return d >= 1 && d <= p.durationDays;
    }).toList();

    double avgPerDay = 0;
    if (activeProjects.isNotEmpty) {
      // naive: sum totalMinutes / number of elapsed days (min 1)
      int denom = 0;
      for (final p in activeProjects) {
        final day = p.dayNumberFor(DateTime.now()).clamp(1, p.durationDays);
        denom += day;
      }
      if (denom > 0) avgPerDay = totalMinutes / denom;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            child: ListTile(
              title: const Text('Total prayed'),
              subtitle: Text('${totalHours.toStringAsFixed(1)} hours'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              title: const Text('Average per day (rough)'),
              subtitle: Text('${(avgPerDay / 60.0).toStringAsFixed(2)} hours/day'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'More analytics coming:\n• average per project\n• streaks\n• daily goal timer + reminders\n• fun progress insights',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
