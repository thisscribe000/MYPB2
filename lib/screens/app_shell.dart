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
    setState(() {
      _projects = loaded;
      _isLoading = false;
    });
  }

  Future<void> _updateProjects(List<PrayerProject> updated) async {
    await ProjectStorage.saveProjects(updated);
    setState(() {
      _projects = updated;
    });
  }

  String _titleForIndex(int i) {
    if (i == 0) return 'Pray Now';
    if (i == 1) return 'Projects';
    if (i == 2) return 'Analytics';
    return 'Settings';
  }

  void _openAddProjectFromProjects() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProjectScreen(
          onAdd: (project) async {
            final updated = [..._projects, project];
            await _updateProjects(updated);
          },
          fromPrayNow: false,
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
      SettingsScreen(
  projects: _projects,
  onProjectsUpdated: _updateProjects,
),

    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_index],

      // ✅ Bring back the floating + button only on Projects tab
      floatingActionButton: (_index == 1)
          ? FloatingActionButton(
              onPressed: _openAddProjectFromProjects,
              child: const Icon(Icons.add),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Pray Now',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
