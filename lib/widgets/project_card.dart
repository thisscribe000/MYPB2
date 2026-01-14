import 'package:flutter/material.dart';
import '../models/prayer_project.dart';

class ProjectCard extends StatelessWidget {
  final PrayerProject project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(project.title),
        subtitle: Text(
          'Progress: ${(project.progress * 100).toStringAsFixed(1)}%',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
