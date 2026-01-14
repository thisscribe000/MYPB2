import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../widgets/prayer_timer.dart';

class ProjectDetailScreen extends StatefulWidget {
  final PrayerProject project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  void _onPrayerCompleted(int minutes) {
    setState(() {
      widget.project.totalMinutesPrayed += minutes;
    });
  }

  void _addManualMinutes(int minutes) {
    setState(() {
      widget.project.totalMinutesPrayed += minutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${project.targetHours} hours'),
            Text(
              'Daily target: ${project.dailyTargetHours.toStringAsFixed(1)} hrs',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: project.progress),
            const SizedBox(height: 24),
            PrayerTimer(onCompleted: _onPrayerCompleted),
            const SizedBox(height: 16),
            const Text(
              'Add prayer time manually',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _addManualMinutes(15),
                  child: const Text('+15 min'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addManualMinutes(30),
                  child: const Text('+30 min'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addManualMinutes(60),
                  child: const Text('+1 hour'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total prayed: ${project.totalMinutesPrayed} minutes',
            ),
          ],
        ),
      ),
    );
  }
}
