import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/project_storage.dart';
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

  bool _isUpcoming(PrayerProject p) => p.dayNumberFor(DateTime.now()) == 0;

  List<PrayerProject> _upcoming() =>
      projects.where((p) => _isUpcoming(p)).toList();

  List<PrayerProject> _activeOrEnded() =>
      projects.where((p) => !_isUpcoming(p)).toList();

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  Future<void> _persist(List<PrayerProject> updated) async {
    await ProjectStorage.saveProjects(updated);
    await onProjectsUpdated(updated);
  }

  void _openProjectDetail(BuildContext context, PrayerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          project: project,
          projects: projects,
          session: session,
          onProjectsUpdated: (updated) async {
            if (updated.isNotEmpty) {
              await _persist(updated);
            } else {
              await _persist([...projects]);
            }
          },
        ),
      ),
    );
  }

  String _dayLabel(PrayerProject p) {
    final d = p.dayNumberFor(DateTime.now());
    if (d == 0) return 'Upcoming';
    if (d == p.durationDays + 1) return 'Ended';
    return 'Day $d/${p.durationDays}';
    }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcoming()
      ..sort((a, b) => a.plannedStartDate.compareTo(b.plannedStartDate));

    final active = _activeOrEnded()
      ..sort((a, b) {
        final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ✅ ACTIVE FIRST
        const Text(
          'Active / Completed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 18),
            child: Text('No active projects yet. Tap + to add one.'),
          )
        else
          ...active.map((p) {
            final dayText = _dayLabel(p);
            return Card(
              child: ListTile(
                title: Text(p.title),
                subtitle: Text(
                  '$dayText • Daily: ${p.dailyTargetHours.toStringAsFixed(1)}h/day • ${(p.progress * 100).toStringAsFixed(0)}%',
                ),
                trailing: Text(p.statusLabel),
                onTap: () => _openProjectDetail(context, p),
              ),
            );
          }),

        const SizedBox(height: 16),

        // ✅ UPCOMING SECOND
        const Text(
          'Upcoming',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('No upcoming projects.'),
          )
        else
          ...upcoming.map((p) => Card(
                child: ListTile(
                  title: Text(p.title),
                  subtitle: Text(
                    'Starts: ${_fmtDDMMYYYY(p.plannedStartDate)} • ${p.durationDays} days • Daily: ${p.dailyTargetHours.toStringAsFixed(1)}h/day',
                  ),
                  trailing: const Icon(Icons.lock_outline),
                  onTap: () => _openProjectDetail(context, p),
                ),
              )),

        const SizedBox(height: 80),
      ],
    );
  }
}
