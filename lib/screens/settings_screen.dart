import 'package:flutter/material.dart';
import 'dart:math';

import '../models/prayer_project.dart';
import '../services/project_storage.dart';

class SettingsScreen extends StatelessWidget {
  final List<PrayerProject> projects;
  final Future<void> Function(List<PrayerProject> updated) onProjectsUpdated;

  const SettingsScreen({
    super.key,
    required this.projects,
    required this.onProjectsUpdated,
  });

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  Future<void> _createDummyProjects(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final today = _dateOnly(DateTime.now());

    // Avoid duplicates by title
    bool exists(String title) =>
        projects.any((p) => p.title.toLowerCase() == title.toLowerCase());

    final updated = [...projects];

    // 1) Active project (starts today)
    const activeTitle = '🔥 Dummy Active: 20 Days';
    if (!exists(activeTitle)) {
      final p = PrayerProject(
        id: Random().nextInt(999999).toString(),
        title: activeTitle,
        targetHours: 50,
        durationDays: 20,
        plannedStartDate: today,
      );
      p.totalMinutesPrayed = 90; // 1h 30m
      p.carrySeconds = 22;
      p.lastPrayedAt = DateTime.now().subtract(const Duration(hours: 2));
      updated.add(p);
    }

    // 2) Upcoming project (starts in 3 days)
    const upcomingTitle = '⏳ Dummy Upcoming: Starts Soon';
    if (!exists(upcomingTitle)) {
      final p = PrayerProject(
        id: Random().nextInt(999999).toString(),
        title: upcomingTitle,
        targetHours: 10,
        durationDays: 7,
        plannedStartDate: today.add(const Duration(days: 3)),
      );
      updated.add(p);
    }

    // 3) Completed-ish project (started 10 days ago; some progress)
    const doneTitle = '✅ Dummy Completed-ish';
    if (!exists(doneTitle)) {
      final p = PrayerProject(
        id: Random().nextInt(999999).toString(),
        title: doneTitle,
        targetHours: 5,
        durationDays: 10,
        plannedStartDate: today.subtract(const Duration(days: 9)),
      );
      p.totalMinutesPrayed = 5 * 60; // hit target
      p.carrySeconds = 0;
      p.lastPrayedAt = DateTime.now().subtract(const Duration(days: 1));
      updated.add(p);
    }

    await ProjectStorage.saveProjects(updated);
    await onProjectsUpdated(updated);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Dummy projects added. Today: ${_fmtDDMMYYYY(today)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Reminders'),
            subtitle: Text('Coming soon: schedule prayer sessions & notifications'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup / Restore'),
            subtitle: Text('Coming soon: export/import your prayer data'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.tune),
            title: Text('Timer behavior'),
            subtitle: Text('Coming soon: rounding rules and preferences'),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Developer / Testing'),
            subtitle: const Text('Create sample projects to test quickly'),
            trailing: ElevatedButton(
              onPressed: () => _createDummyProjects(context),
              child: const Text('Create'),
            ),
          ),
        ),
      ],
    );
  }
}
