import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/project_storage.dart';
import '../services/prayer_session.dart';

import 'pray_now_screen.dart';
import 'projects_tab.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'add_project_screen.dart';

class AppShell extends StatefulWidget {
  final PrayerSessionController session;

  const AppShell({
    super.key,
    required this.session,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _isLoading = true;
  List<PrayerProject> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final loaded = await ProjectStorage.loadProjects();
    if (!mounted) return;
    setState(() {
      _projects = loaded;
      _isLoading = false;
    });
  }

  Future<void> _updateProjects(List<PrayerProject> updated) async {
    await ProjectStorage.saveProjects(updated);
    if (!mounted) return;
    setState(() {
      _projects = updated;
    });
  }

  Future<void> _openAddProject() async {
    final nav = Navigator.of(context);

    await nav.push(
      MaterialPageRoute(
        builder: (_) => AddProjectScreen(
          onAdd: (PrayerProject newProject) async {
            final nav2 = Navigator.of(context);

            final updated = [..._projects, newProject];
            await _updateProjects(updated);

            await widget.session.selectProject(
              newProject.id,
              initialElapsedSeconds: 0,
            );

            nav2.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      PrayNowScreen(
        projects: _projects,
        session: widget.session,
        onProjectsUpdated: _updateProjects,
      ),
      ProjectsTab(
        projects: _projects,
        session: widget.session,
        onProjectsUpdated: _updateProjects,
      ),
      AnalyticsScreen(projects: _projects),
      const SettingsScreen(),
    ];

    final showFab = _index != 3; // hide on Settings

    return Scaffold(
      extendBody: false, // ✅ helps avoid transparency weirdness
      appBar: AppBar(
        title: Text(
          switch (_index) {
            0 => 'Pray Now',
            1 => 'Projects',
            2 => 'Analytics',
            _ => 'Settings',
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_index],
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _openAddProject,
              child: const Icon(Icons.add),
            )
          : null,

      // ✅ Bottom tabs with visible background (light red placeholder)
      bottomNavigationBar: Material(
        color: Colors.red.shade50,
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.red.shade50,
            type: BottomNavigationBarType.fixed,
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.timer),
                label: 'Pray Now',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Projects',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
