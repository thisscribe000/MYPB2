import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/project_storage.dart';
import 'add_project_screen.dart';
import 'edit_project_screen.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PrayerProject> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final loadedProjects = await ProjectStorage.loadProjects();
    setState(() {
      projects = loadedProjects;
      isLoading = false;
    });
  }

  Future<void> _persist() async {
    await ProjectStorage.saveProjects(projects);
  }

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }

  String _statusText(PrayerProject p) {
    final todayDay = p.dayNumberFor(DateTime.now());

    if (todayDay == 0) {
      final startIn = p.daysUntilStart(DateTime.now());
      return 'Starts in $startIn day(s) • ${_fmtDate(p.plannedStartDate)}';
    }

    if (todayDay == p.durationDays + 1) {
      return 'Schedule complete • Ended ${_fmtDate(p.endDate)}';
    }

    return 'Day $todayDay / ${p.durationDays} • Ends ${_fmtDate(p.endDate)}';
  }

  Future<void> _addProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProjectScreen()),
    );

    if (result is PrayerProject) {
      setState(() => projects.add(result));
      await _persist();
    }
  }

  void _openProject(PrayerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          project: project,
          onPersist: () async {
            await _persist();
            setState(() {});
          },
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
                    setState(() => projects[index] = updated);
                    await _persist();
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
                    setState(() => projects.removeAt(index));
                    await _persist();
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
      appBar: AppBar(title: const Text('My Prayer Bank')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(
                  child: Text(
                    'No prayer projects yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
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
                            Text(_statusText(project)),
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
