import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/prayer_session.dart';
import 'project_detail_screen.dart';

class ProjectsTab extends StatelessWidget {
  final List<PrayerProject> projects;
  final PrayerSessionController session;
  final Future<void> Function(List<PrayerProject> updated) onProjectsUpdated;

  const ProjectsTab({
    super.key,
    required this.projects,
    required this.session,
    required this.onProjectsUpdated,
  });

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  String _dayLabel(PrayerProject p) {
    final d = p.dayNumberFor(DateTime.now());
    if (d == 0) {
      final days = p.daysUntilStart(DateTime.now());
      final safe = days < 0 ? 0 : days;
      if (safe == 0) return 'Starts today';
      if (safe == 1) return 'Starts in 1 day';
      return 'Starts in $safe days';
    }
    if (d == p.durationDays + 1) return 'Schedule ended';
    return 'Day $d/${p.durationDays}';
  }

  bool _isUpcoming(PrayerProject p) => p.dayNumberFor(DateTime.now()) == 0;
  bool _isEnded(PrayerProject p) => p.dayNumberFor(DateTime.now()) == p.durationDays + 1;

  @override
  Widget build(BuildContext context) {
    final active = projects
        .where((p) => !p.isArchived && !_isUpcoming(p) && !_isEnded(p))
        .toList();
    final upcoming = projects.where((p) => !p.isArchived && _isUpcoming(p)).toList();
    final ended = projects.where((p) => !p.isArchived && _isEnded(p)).toList();
    final archived = projects.where((p) => p.isArchived).toList();

    // Sort active by most recent prayed
    active.sort((a, b) {
      final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    // Sort upcoming by start date
    upcoming.sort((a, b) => a.plannedStartDate.compareTo(b.plannedStartDate));

    // Sort ended by most recently prayed (or end date as fallback)
    ended.sort((a, b) {
      final ad = a.lastPrayedAt ?? a.endDate;
      final bd = b.lastPrayedAt ?? b.endDate;
      return bd.compareTo(ad);
    });

    // Sort archived by most recent prayed (fallback planned start)
    archived.sort((a, b) {
      final ad = a.lastPrayedAt ?? a.plannedStartDate;
      final bd = b.lastPrayedAt ?? b.plannedStartDate;
      return bd.compareTo(ad);
    });

    Widget sectionTitle(String title) => Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );

    Widget projectCard(PrayerProject p) {
      return Card(
        child: ListTile(
          title: Text(p.title),
          subtitle: Text(
            '${p.statusLabel} • ${_dayLabel(p)}\n'
            'Target: ${p.targetHours}h • Daily: ${p.dailyTargetHours.toStringAsFixed(1)}h/day\n'
            'Start: ${_fmtDDMMYYYY(_dateOnly(p.plannedStartDate))}  →  End: ${_fmtDDMMYYYY(_dateOnly(p.endDate))}',
          ),
          isThreeLine: true,
          trailing: Text('${(p.progress * 100).toStringAsFixed(0)}%'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(
                  project: p,
                  projects: projects,
                  session: session,
                  onProjectsUpdated: onProjectsUpdated,
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            sectionTitle('Active'),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No active projects yet.'),
              )
            else
              ...active.map(projectCard),

            const SizedBox(height: 8),

            sectionTitle('Upcoming'),
            if (upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No upcoming projects.'),
              )
            else
              ...upcoming.map(projectCard),

            const SizedBox(height: 8),

            sectionTitle('Ended'),
            if (ended.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No ended projects.'),
              )
            else
              ...ended.map(projectCard),

            const SizedBox(height: 8),

            sectionTitle('Archived'),
            if (archived.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No archived projects.'),
              )
            else
              ...archived.map(projectCard),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
