import 'package:flutter/material.dart';
import '../models/prayer_project.dart';

class AnalyticsScreen extends StatelessWidget {
  final List<PrayerProject> projects;

  const AnalyticsScreen({super.key, required this.projects});

  int get _totalMinutesAll =>
      projects.fold(0, (sum, p) => sum + p.totalMinutesPrayed);

  int _toHours(int minutes) => minutes ~/ 60;

  String _statusFor(PrayerProject p) {
    if (p.isTargetReached) return 'Completed ✅';
    final day = p.dayNumberFor(DateTime.now());
    if (day == 0) return 'Upcoming';
    if (day == p.durationDays + 1) return 'Schedule ended';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final totalHoursAll = _toHours(_totalMinutesAll);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total prayed: $totalHoursAll hours',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('Projects: ${projects.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'By project',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (projects.isEmpty)
              const Text('No projects yet.')
            else
              ...projects.map((p) {
                final prayedHours = _toHours(p.totalMinutesPrayed);
                final progressPct = (p.progress * 100).toStringAsFixed(0);

                return Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(
                      '${_statusFor(p)} • $prayedHours/${p.targetHours}h • $progressPct%',
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
