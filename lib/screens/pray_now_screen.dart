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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  PrayerProject? _findProject(String? id) {
    if (id == null) return null;
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
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

  bool _isUpcoming(PrayerProject p) => p.dayNumberFor(DateTime.now()) == 0;

  void _snack(ScaffoldMessengerState messenger, String msg) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _canTapProject(PrayerSessionState s, PrayerProject p) {
    if (_isUpcoming(p)) return false;

    if (s.activeProjectId == null) return true;
    if (s.activeProjectId == p.id) return true;

    if (s.isRunning) return false;
    if (s.isPaused && s.elapsedSeconds > 0) return false;

    return true;
  }

  Future<void> _showManualAddDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = session.state;

    // ✅ do not allow manual add while running (so no surprises)
    if (s.isRunning) {
      _snack(messenger, 'Pause or stop the timer before adding time manually.');
      return;
    }

    if (projects.isEmpty) {
      _snack(messenger, 'No projects yet.');
      return;
    }

    // Prefer currently selected project if any, else first non-upcoming project
    PrayerProject? selected = _findProject(s.activeProjectId);
    selected ??= projects.firstWhere(
      (p) => !_isUpcoming(p),
      orElse: () => projects.first,
    );

    // If selected is upcoming, switch to first non-upcoming if possible
    if (_isUpcoming(selected)) {
      final nonUpcoming = projects.where((p) => !_isUpcoming(p)).toList();
      if (nonUpcoming.isEmpty) {
        _snack(messenger, 'All projects are upcoming. You can add time on the start date.');
        return;
      }
      selected = nonUpcoming.first;
    }

    String chosenProjectId = selected.id;

    // Day selection: only up to "today's day number" within schedule
    int maxDayForProject(PrayerProject p) {
      final d = p.dayNumberFor(DateTime.now());
      if (d <= 0) return 0;
      if (d > p.durationDays) return p.durationDays;
      return d;
    }

    int chosenMinutes = 15;
    int chosenDay = maxDayForProject(selected);
    if (chosenDay < 1) chosenDay = 1;

    DateTime dateForDay(PrayerProject p, int day) =>
        _dateOnly(p.plannedStartDate).add(Duration(days: day - 1));

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add time manually'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              final p = projects.firstWhere((x) => x.id == chosenProjectId);
              final maxDay = maxDayForProject(p);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownMenu<String>(
                    initialSelection: chosenProjectId,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Project'),
                    dropdownMenuEntries: projects
                        .map(
                          (proj) => DropdownMenuEntry(
                            value: proj.id,
                            label: proj.title,
                            enabled: !_isUpcoming(proj), // ✅ upcoming locked
                          ),
                        )
                        .toList(),
                    onSelected: (v) {
                      if (v == null) return;
                      final proj = projects.firstWhere((x) => x.id == v);
                      if (_isUpcoming(proj)) return;

                      setLocal(() {
                        chosenProjectId = v;
                        final newMax = maxDayForProject(proj);
                        chosenDay = newMax >= 1 ? newMax : 1;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownMenu<int>(
                    initialSelection: chosenMinutes,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Minutes'),
                    dropdownMenuEntries: List.generate(24, (i) => (i + 1) * 15)
                        .map(
                          (m) => DropdownMenuEntry(
                            value: m,
                            label: '$m minutes',
                          ),
                        )
                        .toList(),
                    onSelected: (v) {
                      if (v == null) return;
                      setLocal(() => chosenMinutes = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  if (maxDay < 1)
                    const Text(
                      'This project has not started yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    DropdownMenu<int>(
                      initialSelection: chosenDay.clamp(1, maxDay),
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Day'),
                      dropdownMenuEntries: List.generate(maxDay, (i) => i + 1)
                          .reversed
                          .map((d) {
                        final date = dateForDay(p, d);
                        return DropdownMenuEntry(
                          value: d,
                          label: '${_fmtDDMMYYYY(date)} (Day $d)',
                        );
                      }).toList(),
                      onSelected: (v) {
                        if (v == null) return;
                        setLocal(() => chosenDay = v);
                      },
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    // Apply the manual log
    final updated = [...projects];
    final idx = updated.indexWhere((p) => p.id == chosenProjectId);
    if (idx == -1) return;

    // block if upcoming (extra safety)
    if (_isUpcoming(updated[idx])) {
      _snack(messenger, 'You can’t add time until the start date.');
      return;
    }

    // clamp day for safety
    final maxDay = maxDayForProject(updated[idx]);
    final safeDay = chosenDay.clamp(1, maxDay >= 1 ? maxDay : 1);

    updated[idx].totalMinutesPrayed += chosenMinutes;
    updated[idx].markDayPrayed(safeDay);
    updated[idx].lastPrayedAt = DateTime.now();

    await onProjectsUpdated(updated);

    _snack(
      messenger,
      'Added $chosenMinutes min to "${updated[idx].title}" • Day $safeDay',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedProjects();

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final messenger = ScaffoldMessenger.of(context);

        final s = session.state;
        final active = _findProject(s.activeProjectId);
        final elapsed = (active == null) ? 0 : session.displayedElapsedSeconds;

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

          await session.selectProject(
            active.id,
            initialElapsedSeconds: remainderSeconds,
          );

          if (minutesToAdd > 0) {
            _snack(messenger, 'Added $minutesToAdd minute(s) to "${active.title}".');
          } else {
            _snack(messenger, 'Saved ${remainderSeconds}s for "${active.title}".');
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

              // ✅ Manual add button (restored)
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _showManualAddDialog(context),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Add time manually'),
                ),
              ),

              const SizedBox(height: 10),

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
                  final isUpcoming = _isUpcoming(p);

                  return Card(
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text('${p.statusLabel} • ${p.targetHours}h target'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle)
                          : (isUpcoming ? const Icon(Icons.lock_outline) : null),
                      onTap: () async {
                        if (!_canTapProject(s, p)) {
                          _snack(
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
