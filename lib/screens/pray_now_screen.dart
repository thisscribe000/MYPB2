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
    // Hours can be 1–3+ digits, mins/secs always 2 digits
    return '$h:${_fmt2(m)}:${_fmt2(s)}';
  }

  void _snack(ScaffoldMessengerState messenger, String msg) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  PrayerProject? _findProject(List<PrayerProject> list, String? id) {
    if (id == null) return null;
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool _isUpcoming(PrayerProject p) => p.dayNumberFor(DateTime.now()) == 0;
  bool _isActiveWindow(PrayerProject p) {
    final d = p.dayNumberFor(DateTime.now());
    return d >= 1 && d <= p.durationDays;
  }

  List<PrayerProject> _sortedPrayNowProjects() {
    final list = projects
        .where((p) => !p.isArchived)
        .where((p) => _isActiveWindow(p)) // ✅ hide upcoming + schedule ended
        .toList();

    list.sort((a, b) {
      final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return list;
  }

  bool _canTapProject(PrayerSessionState s, PrayerProject p) {
    if (p.isArchived) return false;
    if (_isUpcoming(p)) return false;

    if (s.activeProjectId == null) return true;
    if (s.activeProjectId == p.id) return true;

    // ✅ lock switching while running OR paused-with-progress
    if (s.isRunning) return false;
    if (s.isPaused && s.elapsedSeconds > 0) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final prayNowList = _sortedPrayNowProjects();

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final messenger = ScaffoldMessenger.of(context);

        final s = session.state;
        final active = _findProject(projects, s.activeProjectId);

        // session seconds shown on top timer
        final sessionSeconds = (active == null) ? 0 : session.displayedElapsedSeconds;

        // total cumulative seconds prayed for this project (minutes + current session)
        final totalSecondsForActive = (active == null)
            ? 0
            : (active.totalMinutesPrayed * 60) + sessionSeconds;

        Future<void> stopAndAdd() async {
          if (active == null) return;

          final seconds = await session.stopAndReset();
          final minutesToAdd = seconds ~/ 60;
          final remainderSeconds = seconds % 60;

          final updated = [...projects];
          final idx = updated.indexWhere((p) => p.id == active.id);
          if (idx == -1) return;

          final todayDay = updated[idx].dayNumberFor(DateTime.now());
          if (seconds > 0 && todayDay >= 1 && todayDay <= updated[idx].durationDays) {
            updated[idx].markDayPrayed(todayDay);
          }

          if (minutesToAdd > 0) {
            updated[idx].totalMinutesPrayed += minutesToAdd;
          }

          updated[idx].carrySeconds = remainderSeconds;
          updated[idx].lastPrayedAt = DateTime.now();

          await onProjectsUpdated(updated);

          // keep project selected with leftover seconds
          await session.selectProject(
            active.id,
            initialElapsedSeconds: remainderSeconds,
          );

          _snack(
            messenger,
            minutesToAdd > 0
                ? 'Added $minutesToAdd minute(s) to "${active.title}".'
                : 'Saved ${_timerText(remainderSeconds)} for "${active.title}".',
          );
        }

        Future<void> toggleStartPauseResume() async {
          if (active == null) return;

          if (s.isRunning) {
            await session.pause();
            return;
          }
          if (s.isPaused) {
            await session.resume();
            return;
          }
          await session.start();
        }

        String mainButtonLabel() {
          if (s.isRunning) return 'Pause';
          if (s.isPaused) return 'Resume';
          return 'Start';
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
                child: Column(
                  children: [
                    Text(
                      _timerText(sessionSeconds),
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (active != null)
                      Text(
                        'Total: ${_timerText(totalSecondsForActive)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (active == null) ? null : toggleStartPauseResume,
                    child: Text(mainButtonLabel()),
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

              if (prayNowList.isEmpty)
                const Text('No active projects right now. (Upcoming/Archived are hidden here.)')
              else
                ...prayNowList.map((p) {
                  final isSelected = (s.activeProjectId == p.id);

                  return Card(
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text(
                        '${p.statusLabel} • Day ${p.dayNumberFor(DateTime.now())}/${p.durationDays}\n'
                        'Target: ${p.targetHours}h • Daily: ${p.dailyTargetHours.toStringAsFixed(1)}h/day',
                      ),
                      isThreeLine: true,
                      trailing: isSelected ? const Icon(Icons.check_circle) : null,
                      onTap: () async {
                        if (!_canTapProject(s, p)) {
                          _snack(messenger, 'Stop the timer to switch project.');
                          return;
                        }

                        final ok = await session.selectProject(
                          p.id,
                          initialElapsedSeconds: p.carrySeconds,
                        );

                        if (!ok) {
                          _snack(messenger, 'Stop the timer to switch project.');
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
