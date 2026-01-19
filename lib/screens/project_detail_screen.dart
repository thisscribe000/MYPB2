import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/prayer_session.dart';

class ProjectDetailScreen extends StatefulWidget {
  final PrayerProject project;
  final PrayerSessionController session;
  final Future<void> Function(List<PrayerProject> updated) onProjectsUpdated;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.session,
    required this.onProjectsUpdated,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _timerText(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${_fmt2(h)}:${_fmt2(m)}:${_fmt2(s)}';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final s = widget.session.state;
        final isActiveProject = (s.activeProjectId == project.id);
        final hasSomeOtherActive =
            (s.activeProjectId != null && s.activeProjectId != project.id);
        final elapsed = widget.session.displayedElapsedSeconds;

        Future<void> stopAndAddHere() async {
          if (!isActiveProject) return;

          final seconds = await widget.session.stopAndReset();
          final minutesToAdd = seconds ~/ 60;
          if (minutesToAdd <= 0) return;

          project.totalMinutesPrayed += minutesToAdd;
          project.lastPrayedAt = DateTime.now();

          _snack('Added $minutesToAdd minute(s) to "${project.title}".');
        }

        return Scaffold(
          appBar: AppBar(title: Text(project.title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${project.statusLabel} • Target ${project.targetHours}h',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: project.progress),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          _timerText(isActiveProject ? elapsed : 0),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!isActiveProject && hasSomeOtherActive)
                          const Text(
                            'A timer is active on another project. You can view details here, but you can’t start a new timer.',
                            textAlign: TextAlign.center,
                          ),
                        if (!isActiveProject && !hasSomeOtherActive)
                          const Text(
                            'Use Pray Now tab to select this project and start praying.',
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: isActiveProject
                                  ? (s.isRunning
                                      ? null
                                      : (s.isPaused
                                          ? widget.session.resume
                                          : widget.session.start))
                                  : null,
                              child: Text(s.isPaused ? 'Resume' : 'Start'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: isActiveProject && s.isRunning
                                  ? widget.session.pause
                                  : null,
                              child: const Text('Pause'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed:
                                  isActiveProject && (s.isRunning || s.isPaused)
                                      ? stopAndAddHere
                                      : null,
                              child: const Text('Stop & Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Notes UI will be restored in the next phase.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
