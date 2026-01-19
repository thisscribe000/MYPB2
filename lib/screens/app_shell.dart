import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/project_storage.dart';
import '../services/prayer_session.dart';
import 'pray_now_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'projects_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  bool _loading = true;
  List<PrayerProject> _projects = [];

  final PrayerSessionController _session = PrayerSessionController();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final data = await ProjectStorage.loadProjects();
    await _session.init();

    setState(() {
      _projects = data;
      _loading = false;
    });
  }

  Future<void> _persistProjects() async {
    await ProjectStorage.saveProjects(_projects);
    setState(() {});
  }

  Future<void> _applyProjects(List<PrayerProject> updated) async {
    _projects = updated;
    await _persistProjects();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PrayNowScreen(
        projects: _projects,
        session: _session,
        onProjectsUpdated: _applyProjects,
      ),
      ProjectsTab(
        projects: _projects,
        session: _session,
        onProjectsChanged: _applyProjects,
        onPersist: _persistProjects,
      ),
      AnalyticsScreen(projects: _projects),
      const SettingsScreen(),
    ];

    final titles = ['Pray Now', 'Projects', 'Analytics', 'Settings'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Pray Now',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
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
