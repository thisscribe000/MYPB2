import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PrayerProject> projects = [];

  void _openProject(PrayerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project),
      ),
    ).then((_) => setState(() {}));
  }

  void _addProject(PrayerProject project) {
    setState(() {
      projects.add(project);
    });
  }

  void _openAddProject() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProjectScreen(onAdd: _addProject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prayer Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddProject,
          ),
        ],
      ),
      body: projects.isEmpty
          ? const Center(child: Text('No prayer projects yet'))
          : ListView(
              padding: const EdgeInsets.all(8),
              children: projects
                  .map(
                    (p) => ProjectCard(
                      project: p,
                      onTap: () => _openProject(p),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
