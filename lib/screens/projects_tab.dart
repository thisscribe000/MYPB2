import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/project_storage.dart';
import '../services/prayer_session.dart';
import 'add_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsTab extends StatefulWidget {
  final List<PrayerProject> projects;
  final PrayerSessionController session;

  /// Parent owns persistence, but we still accept updates and notify parent.
  final Future<void> Function(List<PrayerProject> updated) onProjectsUpdated;

  const ProjectsTab({
    super.key,
    required this.projects,
    required this.session,
    required this.onProjectsUpdated,
  });

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<PrayerProject> get projects => widget.projects;

  List<PrayerProject> get upcomingProjects =>
      projects.where((p) => p.dayNumberFor(DateTime.now()) == 0).toList();

  List<PrayerProject> get activeOrEndedProjects =>
      projects.where((p) => p.dayNumberFor(DateTime.now()) != 0).toList();

  Future<void> _persist(List<PrayerProject> updated) async {
    // Save
    await ProjectStorage.saveProjects(updated);
    // Notify parent
    await widget.onProjectsUpdated(updated);
  }

  void _openAddProject() {
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

  void _openProjectDetail(PrayerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          project: project,
          projects: projects, // ✅ required now
          session: widget.session,
          onProjectsUpdated: (updated) async {
            // If the detail screen gave us a full list, persist it.
            // (It will, for Stop & Add sync.)
            if (updated.isNotEmpty) {
              await _persist(updated);
            } else {
              // Safety fallback: re-save current projects list.
              await _persist([...projects]);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort: most recent prayed first (nulls last)
    final sortedActive = [...activeOrEndedProjects]
      ..sort((a, b) {
        final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProject,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (upcomingProjects.isNotEmpty) ...[
            const Text(
              'Upcoming',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingProjects.map((p) => Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(
                      'Starts: ${_fmtDDMMYYYY(p.plannedStartDate)} • ${p.durationDays} days • ${p.targetHours}h',
                    ),
                    trailing: const Icon(Icons.lock_outline),
                    onTap: () => _openProjectDetail(p),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          const Text(
            'All Projects',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (sortedActive.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('No projects yet. Tap + to add one.')),
            )
          else
            ...sortedActive.map((p) => Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(
                      '${p.statusLabel} • ${p.targetHours}h target • ${(p.progress * 100).toStringAsFixed(0)}%',
                    ),
                    onTap: () => _openProjectDetail(p),
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }
}
