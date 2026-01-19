import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/prayer_session.dart';

class PrayNowScreen extends StatelessWidget {
  final List<PrayerProject> projects;
  final PrayerSessionController session;
  final Future<void> Function(List<PrayerProject> updated) onProjectsUpdated;

  const PrayNowScreen({
    super.key,
    required this.projects,
    required this.session,
    required this.onProjectsUpdated,
  });

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _timerText(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${_fmt2(h)}:${_fmt2(m)}:${_fmt2(s)}';
  }

  PrayerProject? _activeProject() {
    final id = session.state.activeProjectId;
    if (id == null) return null;
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PrayerProject> _sortedProjects() {
    final list = [...projects];
    list.sort((a, b) {
      final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return list;
  }

  bool _canTapProject(PrayerSessionState s, PrayerProject p) {
    if (p.statusLabel == 'Upcoming') return false; // upcoming not selectable to pray
    if (s.activeProjectId == null) return true;
    if (s.activeProjectId == p.id) return true;
    if (s.isRunning) return false;
    if (s.isPaused && s.elapsedSeconds > 0) return false;
    return true;
  }

  void _showSnack(ScaffoldMessengerState messenger, String msg) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedProjects();

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final s = session.state;
        final active = _activeProject();
        final elapsed = session.displayedElapsedSeconds;

        Future<void> stopAndAdd() async {
          if (active == null) return;

          final messenger = ScaffoldMessenger.of(context);

          final seconds = await session.stopAndReset();
          final minutesToAdd = seconds ~/ 60;
          final remainderSeconds = seconds % 60;

          // Update project totals
          final updated = [...projects];
          final idx = updated.indexWhere((p) => p.id == active.id);
          if (idx == -1) return;

          if (minutesToAdd > 0) {
            updated[idx].totalMinutesPrayed += minutesToAdd;
          }
          updated[idx].carrySeconds = remainderSeconds;
          updated[idx].lastPrayedAt = DateTime.now();

          await onProjectsUpdated(updated);

          // Keep it selected and show carrySeconds immediately
          await session.selectProject(active.id, initialElapsedSeconds: remainderSeconds);

          if (minutesToAdd > 0) {
            _showSnack(messenger, 'Added $minutesToAdd minute(s) to "${active.title}".');
          } else {
            _showSnack(messenger, 'Saved ${remainderSeconds}s for "${active.title}".');
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active?.title ?? 'Select a project to pray for',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (active != null)
                        Text(
                          '${active.statusLabel} • Target ${active.targetHours}h • ${(active.progress * 100).toStringAsFixed(0)}%',
                        )
                      else
                        const Text('Tap a project below to select it.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  _timerText(elapsed),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (active == null)
                        ? null
                        : (s.isRunning
                            ? null
                            : (s.isPaused ? session.resume : session.start)),
                    child: Text(s.isPaused ? 'Resume' : 'Start'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: s.isRunning ? session.pause : null,
                    child: const Text('Pause'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (s.isRunning || s.isPaused) ? stopAndAdd : null,
                    child: const Text('Stop & Add'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Projects (most recent first)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (sorted.isEmpty)
                const Text('No projects yet. Go to Projects tab and add one.')
              else
                ...sorted.map((p) {
                  final isSelected = (s.activeProjectId == p.id);
                  final isUpcoming = p.statusLabel == 'Upcoming';

                  return Card(
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text('${p.statusLabel} • ${p.targetHours}h target'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle)
                          : (isUpcoming ? const Icon(Icons.lock_outline) : null),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        if (!_canTapProject(s, p)) {
                          _showSnack(
                            messenger,
                            isUpcoming
                                ? 'This project starts later. You can pray on the start date.'
                                : 'Stop the timer to switch project.',
                          );
                          return;
                        }

                        final ok = await session.selectProject(
                          p.id,
                          initialElapsedSeconds: p.carrySeconds,
                        );

                        if (!ok) {
                          _showSnack(messenger, 'Stop the timer to switch project.');
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
