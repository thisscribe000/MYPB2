import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import 'project_detail_screen.dart';

class PrayNowScreen extends StatelessWidget {
  final List<PrayerProject> projects;
  final Future<void> Function() onPersist;

  const PrayNowScreen({
    super.key,
    required this.projects,
    required this.onPersist,
  });

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final activeToday = <PrayerProject>[];
    final upcoming = <PrayerProject>[];
    final endedOrCompleted = <PrayerProject>[];

    for (final p in projects) {
      if (p.isTargetReached) {
        endedOrCompleted.add(p);
        continue;
      }

      final day = p.dayNumberFor(now);
      if (day == 0) {
        upcoming.add(p);
      } else if (day == p.durationDays + 1) {
        endedOrCompleted.add(p);
      } else {
        activeToday.add(p);
      }
    }

    // Simple suggestion: pick the least-progress active project (if any)
    PrayerProject? suggestion;
    if (activeToday.isNotEmpty) {
      activeToday.sort((a, b) => a.progress.compareTo(b.progress));
      suggestion = activeToday.first;
    } else if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) => a.plannedStartDate.compareTo(b.plannedStartDate));
      suggestion = upcoming.first;
    }

    void openProject(PrayerProject p) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            project: p,
            onPersist: onPersist,
          ),
        ),
      );
    }

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );

    Widget projectCard(PrayerProject p, {String? subtitleOverride}) {
      final prayedHours = (p.totalMinutesPrayed / 60).floor();
      final pct = (p.progress * 100).toStringAsFixed(0);

      final defaultSubtitle = '${p.statusLabel} • $prayedHours/${p.targetHours}h • $pct%';

      return Card(
        child: ListTile(
          title: Text(p.title),
          subtitle: Text(subtitleOverride ?? defaultSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openProject(p),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pray Now')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Start a prayer session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Pick a project and begin. Your timer and notes are inside the project.'),

            const SizedBox(height: 16),

            if (suggestion != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suggested',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        suggestion.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        suggestion.dayNumberFor(now) == 0
                            ? 'Starts on ${_fmtDate(suggestion.plannedStartDate)}'
                            : 'Active today • Day ${suggestion.dayNumberFor(now)}/${suggestion.durationDays}',
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => openProject(suggestion),
                        child: const Text('Open & Pray'),
                      ),
                    ],
                  ),
                ),
              ),

            sectionTitle('Active today'),
            if (activeToday.isEmpty)
              const Text('No active projects today.')
            else
              ...activeToday.map((p) {
                final day = p.dayNumberFor(now);
                return projectCard(
                  p,
                  subtitleOverride: 'Active • Day $day/${p.durationDays} • Ends ${_fmtDate(p.endDate)}',
                );
              }),

            sectionTitle('Upcoming'),
            if (upcoming.isEmpty)
              const Text('No upcoming projects.')
            else
              ...upcoming.map((p) {
                final startIn = p.daysUntilStart(now);
                return projectCard(
                  p,
                  subtitleOverride: 'Starts in $startIn day(s) • ${_fmtDate(p.plannedStartDate)}',
                );
              }),

            sectionTitle('Ended / Completed'),
            if (endedOrCompleted.isEmpty)
              const Text('Nothing here yet.')
            else
              ...endedOrCompleted.map((p) => projectCard(p)),
          ],
        ),
      ),
    );
  }
}
