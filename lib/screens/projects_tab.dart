import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/project_storage.dart';
import '../services/prayer_session.dart';
import 'add_project_screen.dart';
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

  List<PrayerProject> _nonUpcoming() =>
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

  void _openAddProject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProjectScreen(
          onAdd: (project) async {
            final updated = [...projects, project];
            await _persist(updated);
          },
          fromPrayNow: false,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcoming();
    final active = [..._nonUpcoming()]
      ..sort((a, b) {
        final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Projects',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Add project',
              onPressed: () => _openAddProject(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (upcoming.isNotEmpty) ...[
          const Text(
            'Upcoming',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...upcoming.map(
            (p) => Card(
              child: ListTile(
                title: Text(p.title),
                subtitle: Text(
                  'Starts: ${_fmtDDMMYYYY(p.plannedStartDate)} • ${p.durationDays} days • ${p.targetHours}h',
                ),
                trailing: const Icon(Icons.lock_outline),
                onTap: () => _openProjectDetail(context, p),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text(
          'All Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (active.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: Text('No projects yet. Tap + to add one.')),
          )
        else
          ...active.map(
            (p) => Card(
              child: ListTile(
                title: Text(p.title),
                subtitle: Text(
                  '${p.statusLabel} • ${p.targetHours}h target • ${(p.progress * 100).toStringAsFixed(0)}%',
                ),
                onTap: () => _openProjectDetail(context, p),
              ),
            ),
          ),

        const SizedBox(height: 80),
      ],
    );
  }
}
