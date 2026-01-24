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

    // Hours can be 1–3+ digits; minutes/seconds always 2 digits
    return '$h:${_fmt2(m)}:${_fmt2(s)}';
  }

  String _dayLabel(PrayerProject p) {
    final d = p.dayNumberFor(DateTime.now());
    if (d == 0) {
      final days = p.daysUntilStart(DateTime.now());
      final safe = days < 0 ? 0 : days;
      if (safe == 0) return 'Starts today';
      if (safe == 1) return 'Starts in 1 day';
      return 'Starts in $safe days';
    }
    if (d == p.durationDays + 1) return 'Schedule ended';
    return 'Day $d/${p.durationDays}';
  }

  PrayerProject? _findProject(String? id) {
    if (id == null) return null;
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool _isUpcoming(PrayerProject p) => p.dayNumberFor(DateTime.now()) == 0;

  List<PrayerProject> _sortedProjects() {
  final list = [...projects];

  // sort by most recent prayed
  list.sort((a, b) {
    final ad = a.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.lastPrayedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });

  return list;
}

  void _snack(ScaffoldMessengerState messenger, String msg) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _canTapProject(PrayerSessionState s, PrayerProject p) {
    // Upcoming never selectable here
    if (_isUpcoming(p)) return false;

    // If no project selected, allow selecting
    if (s.activeProjectId == null) return true;

    // If same project, allow tapping (no-op)
    if (s.activeProjectId == p.id) return true;

    // If running, block switching
    if (s.isRunning) return false;

    // If paused with some time, block switching (protect the session)
    if (s.isPaused && s.elapsedSeconds > 0) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedProjects()
    .where((p) => !p.isLockedForPrayNow)
    .toList();

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final messenger = ScaffoldMessenger.of(context);

        final s = session.state;
        final active = _findProject(s.activeProjectId);

        // elapsed = current session value (includes carrySeconds if that’s how your controller is set up)
        final elapsed = (active == null) ? 0 : session.displayedElapsedSeconds;

        // TOTAL = minutes already saved + what is currently on the timer
        final totalSeconds =
            (active == null) ? 0 : (active.totalMinutesPrayed * 60) + elapsed;

        // THIS SESSION = elapsed minus carrySeconds (carrySeconds is from last stop)
        final sessionSeconds = (active == null)
            ? 0
            : (elapsed - active.carrySeconds).clamp(0, 999999999);

        Future<void> stopAndAdd() async {
          if (active == null) return;

          final seconds = await session.stopAndReset();
          final minutesToAdd = seconds ~/ 60;
          final remainderSeconds = seconds % 60;

          final updated = [...projects];
          final idx = updated.indexWhere((p) => p.id == active.id);
          if (idx == -1) return;

          final todayDay = updated[idx].dayNumberFor(DateTime.now());
          if (seconds > 0 &&
              todayDay >= 1 &&
              todayDay <= updated[idx].durationDays) {
            updated[idx].markDayPrayed(todayDay);
          }

          if (minutesToAdd > 0) {
            updated[idx].totalMinutesPrayed += minutesToAdd;
          }

          updated[idx].carrySeconds = remainderSeconds;
          updated[idx].lastPrayedAt = DateTime.now();

          await onProjectsUpdated(updated);

          // Re-select with only leftover seconds
          await session.selectProject(
            active.id,
            initialElapsedSeconds: remainderSeconds,
          );

          if (minutesToAdd > 0) {
            _snack(
              messenger,
              'Added $minutesToAdd minute(s) to "${active.title}".',
            );
          } else {
            _snack(
              messenger,
              'Saved ${remainderSeconds}s for "${active.title}".',
            );
          }
        }

        // Single main button logic
        String mainLabel;
        VoidCallback? mainAction;

        if (active == null) {
          mainLabel = 'Start';
          mainAction = null;
        } else if (s.isRunning) {
          mainLabel = 'Pause';
          mainAction = () => session.pause();
        } else if (s.isPaused) {
          mainLabel = 'Resume';
          mainAction = () => session.resume();
        } else {
          mainLabel = 'Start';
          mainAction = () => session.start();
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
                          '${active.statusLabel} • ${_dayLabel(active)} • '
                          'Target ${active.targetHours}h • '
                          '${(active.progress * 100).toStringAsFixed(0)}%',
                        )
                      else
                        const Text('Tap a project below to select it.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // TOTAL timer (big)
              Center(
                child: Text(
                  _timerText(totalSeconds),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),

              // Session timer (small)
              Center(
                child: Text(
                  'This session: ${_timerText(sessionSeconds)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: mainAction,
                    child: Text(mainLabel),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (active != null && (s.isRunning || s.isPaused))
                        ? stopAndAdd
                        : null,
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
                const Text('No active projects yet. Upcoming projects will appear on the start date.')
              else
                ...sorted.map((p) {
                  final isSelected = (s.activeProjectId == p.id);

                  return Card(
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text(
                        '${p.statusLabel} • ${_dayLabel(p)}\n'
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
