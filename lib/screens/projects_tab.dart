import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import 'add_project_screen.dart';
import 'edit_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsTab extends StatefulWidget {
  final List<PrayerProject> projects;
  final Future<void> Function() onPersist;

  /// If projects list changes (add/edit/delete), we send updated list back to AppShell
  final Future<void> Function(List<PrayerProject> updated) onProjectsChanged;

  const ProjectsTab({
    super.key,
    required this.projects,
    required this.onPersist,
    required this.onProjectsChanged,
  });

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<PrayerProject> get projects => widget.projects;

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }

  String _statusLine(PrayerProject p) {
    if (p.isTargetReached) {
      return 'Completed ✅ • ${p.targetHours}h reached';
    }

    final todayDay = p.dayNumberFor(DateTime.now());

    if (todayDay == 0) {
      final startIn = p.daysUntilStart(DateTime.now());
      return 'Upcoming • Starts in $startIn day(s) • ${_fmtDate(p.plannedStartDate)}';
    }

    if (todayDay == p.durationDays + 1) {
      final prayedHours = (p.totalMinutesPrayed / 60).floor();
      return 'Schedule ended • Prayed $prayedHours/${p.targetHours}h • Ended ${_fmtDate(p.endDate)}';
    }

    return 'Active • Day $todayDay/${p.durationDays} • Ends ${_fmtDate(p.endDate)}';
  }

  Future<void> _addProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProjectScreen()),
    );

    if (result is PrayerProject) {
      final updated = [...projects, result];
      await widget.onProjectsChanged(updated);
      setState(() {});
    }
  }

  void _openProject(PrayerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          project: project,
          onPersist: widget.onPersist,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _showProjectActions(int index) async {
    final project = projects[index];

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.pop(context);
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProjectScreen(project: project),
                    ),
                  );

                  if (updated is PrayerProject) {
                    final list = [...projects];
                    list[index] = updated;
                    await widget.onProjectsChanged(list);
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete project?'),
                      content: Text('Delete "${project.title}" permanently?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final list = [...projects]..removeAt(index);
                    await widget.onProjectsChanged(list);
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
      ),
      body: projects.isEmpty
          ? const Center(
              child: Text(
                'No prayer projects yet.\nTap + to add one.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(project.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target: ${project.targetHours} hrs • '
                          'Daily: ${project.dailyTargetHours.toStringAsFixed(1)} hrs',
                        ),
                        const SizedBox(height: 4),
                        Text(_statusLine(project)),
                      ],
                    ),
                    trailing: Text('${(project.progress * 100).toStringAsFixed(0)}%'),
                    onTap: () => _openProject(project),
                    onLongPress: () => _showProjectActions(index),
                  ),
                );
              },
            ),
    );
  }
}
