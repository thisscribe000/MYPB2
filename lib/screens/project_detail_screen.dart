import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/prayer_session.dart';

class ProjectDetailScreen extends StatefulWidget {
  final PrayerProject project;
  final List<PrayerProject> projects;
  final PrayerSessionController session;
  final Future<void> Function(List<PrayerProject> updated) onProjectsUpdated;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.projects,
    required this.session,
    required this.onProjectsUpdated,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  int _selectedDay = 0;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _timerText(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    // Hours can grow (no padding), mins/secs stay 2 digits
    return '$h:${_fmt2(m)}:${_fmt2(s)}';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  DateTime _dateForDay(PrayerProject p, int dayNumber) {
    return _dateOnly(p.plannedStartDate).add(Duration(days: dayNumber - 1));
  }

  String _dayProgressLabel(PrayerProject p) {
    final d = p.dayNumberFor(DateTime.now());
    if (d == 0) return 'Upcoming';
    if (d == p.durationDays + 1) return 'Schedule ended';
    return 'Day $d/${p.durationDays}';
  }

  Future<void> _editNoteDialog({
    required String initialText,
    required Future<void> Function(String newText) onSave,
  }) async {
    final ctrl = TextEditingController(text: initialText);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit note'),
          content: TextField(
            controller: ctrl,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Note',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final newText = ctrl.text.trim();
    if (newText.isEmpty) {
      _snack('Note can’t be empty.');
      return;
    }

    await onSave(newText);
    _snack('Note updated.');
  }

  Future<void> _confirmDelete({
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text('This can’t be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await onDelete();
    _snack('Note deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        // ✅ Always use the latest copy from the list (not the stale widget.project)
        final current = widget.projects.firstWhere(
          (p) => p.id == widget.project.id,
          orElse: () => widget.project,
        );

        final s = widget.session.state;
        final isActiveProject = (s.activeProjectId == current.id);
        final hasSomeOtherActive =
            (s.activeProjectId != null && s.activeProjectId != current.id);

        final elapsed = widget.session.displayedElapsedSeconds;

        // Default selected day
        final availableDays = current.availableNoteDays;
        if (_selectedDay == 0) {
          final todayDay = current.dayNumberFor(DateTime.now());
          if (availableDays.isNotEmpty) {
            _selectedDay = availableDays.first;
          } else if (todayDay >= 1 && todayDay <= current.durationDays) {
            _selectedDay = todayDay;
          } else {
            _selectedDay = 1;
          }
        }

        Future<void> stopAndAddHere() async {
          if (!isActiveProject) return;

          final seconds = await widget.session.stopAndReset();
          final minutesToAdd = seconds ~/ 60;
          final remainderSeconds = seconds % 60;

          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
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

          await widget.onProjectsUpdated(updated);

          await widget.session.selectProject(
            current.id,
            initialElapsedSeconds: remainderSeconds,
          );

          if (minutesToAdd > 0) {
            _snack('Added $minutesToAdd minute(s) to "${current.title}".');
          } else {
            _snack('Saved ${remainderSeconds}s for "${current.title}".');
          }

          if (mounted) {
            setState(() {});
          }
        }

        Future<void> addNote() async {
          final text = _noteCtrl.text.trim();
          if (text.isEmpty) return;

          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
          if (idx == -1) return;

          if (!updated[idx].prayedDays.contains(_selectedDay)) {
            _snack('You can only add notes for days you have prayed.');
            return;
          }

          updated[idx].addNoteForDay(
            _selectedDay,
            PrayerNote(text: text, createdAt: DateTime.now()),
          );

          await widget.onProjectsUpdated(updated);
          _noteCtrl.clear();
          _snack('Note saved.');

          if (mounted) {
            setState(() {});
          }
        }

        Future<void> addTimeInRetrospect() async {
          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
          if (idx == -1) return;

          final nowDay = updated[idx].dayNumberFor(DateTime.now());
          final maxDay = (nowDay <= 0)
              ? 1
              : (nowDay > updated[idx].durationDays
                  ? updated[idx].durationDays
                  : nowDay);

          int chosenDay = maxDay;
          int chosenMinutes = 15;

          final ok = await showDialog<bool>(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text('Add time in retrospect'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu<int>(
                      initialSelection: chosenDay,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Day'),
                      dropdownMenuEntries:
                          List.generate(maxDay, (i) => i + 1).reversed.map((d) {
                        final date = _dateForDay(updated[idx], d);
                        return DropdownMenuEntry(
                          value: d,
                          label: '${_fmtDDMMYYYY(date)} (Day $d)',
                        );
                      }).toList(),
                      onSelected: (v) {
                        if (v != null) chosenDay = v;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<int>(
                      initialSelection: chosenMinutes,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Minutes'),
                      dropdownMenuEntries: const [
                        15,
                        30,
                        45,
                        60,
                        75,
                        90,
                        105,
                        120
                      ]
                          .map(
                            (m) => DropdownMenuEntry(
                              value: m,
                              label: '$m minutes',
                            ),
                          )
                          .toList(),
                      onSelected: (v) {
                        if (v != null) chosenMinutes = v;
                      },
                    ),
                  ],
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

          updated[idx].totalMinutesPrayed += chosenMinutes;
          updated[idx].markDayPrayed(chosenDay);
          updated[idx].lastPrayedAt = DateTime.now();

          await widget.onProjectsUpdated(updated);
          _snack('Added $chosenMinutes min to Day $chosenDay.');

          if (mounted) {
            setState(() {});
          }
        }

        final notesForSelectedDay = current.dayNotes[_selectedDay] ?? [];
        final selectedDate = _dateForDay(current, _selectedDay);

        return Scaffold(
          appBar: AppBar(
            title: Text(current.title),
            actions: [
              // This assumes your model has: bool isArchived + you handle it later in batch 4.
              // If you haven't added isArchived yet, REMOVE this IconButton for now.
              if (current.toMap().containsKey('isArchived'))
                IconButton(
                  tooltip: (current as dynamic).isArchived ? 'Unarchive' : 'Archive',
                  icon: Icon((current as dynamic).isArchived
                      ? Icons.unarchive
                      : Icons.archive_outlined),
                  onPressed: () async {
                    final updated = [...widget.projects];
                    final idx = updated.indexWhere((p) => p.id == current.id);
                    if (idx == -1) return;

                    final map = updated[idx].toMap();
                    final isArchived = (map['isArchived'] as bool?) ?? false;
                    map['isArchived'] = !isArchived;

                    // Re-create project from map (keeps it consistent with your storage style)
                    updated[idx] = PrayerProject.fromMap(map);

                    await widget.onProjectsUpdated(updated);
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
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
                          '${current.statusLabel} • ${_dayProgressLabel(current)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Target: ${current.targetHours}h • Daily: ${current.dailyTargetHours.toStringAsFixed(1)}h/day',
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: current.progress),
                        const SizedBox(height: 6),
                        Text(
                          '${(current.progress * 100).toStringAsFixed(0)}% complete',
                        ),
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
                          _timerText(isActiveProject ? elapsed : current.carrySeconds),
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
                            'No timer is running. Start from Pray Now by selecting this project.',
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
                              onPressed: isActiveProject && (s.isRunning || s.isPaused)
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

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Add time in retrospect'),
                    subtitle: const Text('Log minutes for a previous day (15-min blocks)'),
                    onTap: addTimeInRetrospect,
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes — ${_fmtDDMMYYYY(selectedDate)} (Day $_selectedDay)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),

                        DropdownMenu<int>(
                          initialSelection: (current.prayedDays.contains(_selectedDay))
                              ? _selectedDay
                              : (availableDays.isNotEmpty ? availableDays.first : _selectedDay),
                          expandedInsets: EdgeInsets.zero,
                          label: const Text('Select day'),
                          dropdownMenuEntries: availableDays.map((d) {
                            final date = _dateForDay(current, d);
                            return DropdownMenuEntry(
                              value: d,
                              label: '${_fmtDDMMYYYY(date)} (Day $d)',
                            );
                          }).toList(),
                          onSelected: (v) {
                            if (v != null) setState(() => _selectedDay = v);
                          },
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: _noteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Write a note',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: addNote,
                            icon: const Icon(Icons.save),
                            label: const Text('Save note'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (availableDays.isEmpty)
                          const Text(
                            'No prayed days yet. Once you record time, days will appear here.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else if (notesForSelectedDay.isEmpty)
                          const Text(
                            'No notes for this day yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...List.generate(notesForSelectedDay.length, (i) {
                            final note = notesForSelectedDay[i];
                            return Card(
                              child: ListTile(
                                title: Text(note.text),
                                subtitle: Text(_fmtDDMMYYYY(_dateOnly(note.createdAt))),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        await _editNoteDialog(
                                          initialText: note.text,
                                          onSave: (newText) async {
                                            final updated = [...widget.projects];
                                            final idx =
                                                updated.indexWhere((p) => p.id == current.id);
                                            if (idx == -1) return;

                                            final list = updated[idx].dayNotes[_selectedDay];
                                            if (list == null || i < 0 || i >= list.length) return;

                                            final old = list[i];
                                            list[i] = PrayerNote(
                                              text: newText,
                                              createdAt: old.createdAt,
                                            );

                                            await widget.onProjectsUpdated(updated);

                                            if (mounted) {
                                              setState(() {});
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await _confirmDelete(
                                          onDelete: () async {
                                            final updated = [...widget.projects];
                                            final idx =
                                                updated.indexWhere((p) => p.id == current.id);
                                            if (idx == -1) return;

                                            final list = updated[idx].dayNotes[_selectedDay];
                                            if (list == null || i < 0 || i >= list.length) return;

                                            list.removeAt(i);

                                            if (list.isEmpty) {
                                              updated[idx].dayNotes.remove(_selectedDay);
                                            }

                                            await widget.onProjectsUpdated(updated);

                                            if (mounted) {
                                              setState(() {});
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
