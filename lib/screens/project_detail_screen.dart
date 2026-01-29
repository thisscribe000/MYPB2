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

  // ✅ Batch 8: Calendar helpers
  Color _dayColor(PrayerProject p, int day) {
    final mins = p.dayMinutes[day] ?? 0;

    if (mins == 0) return Colors.grey.shade300;
    if (mins < 30) return Colors.green.shade200;
    if (mins < 60) return Colors.green.shade400;
    return Colors.green.shade700;
  }

  // ✅ Batch 9.1: weekday header
  Widget _buildWeekdayHeader() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: labels
          .map(
            (t) => Expanded(
              child: Center(
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ✅ Batch 9.1: real calendar (aligned to weekdays + shows actual date numbers)
  Widget _buildCalendarGrid(PrayerProject p) {
    final totalDays = p.durationDays;

    // Monday=1..Sunday=7 (Dart already uses this)
    final startWeekday = _dateOnly(p.plannedStartDate).weekday;
    final leadingBlanks = startWeekday - 1; // Mon -> 0, Tue -> 1, ... Sun -> 6
    final totalCells = leadingBlanks + totalDays;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        // leading empty tiles
        if (index < leadingBlanks) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }

        final day = (index - leadingBlanks) + 1; // 1..durationDays
        final isSelected = day == _selectedDay;

        final date = _dateForDay(p, day);
        final dateNumber = date.day.toString(); // show actual day-of-month

        final mins = p.dayMinutes[day] ?? 0;
        final hasMinutes = mins > 0;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDay = day);
          },
          child: Container(
            decoration: BoxDecoration(
              color: _dayColor(p, day),
              borderRadius: BorderRadius.circular(6),
              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: hasMinutes ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'D$day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasMinutes ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        // Always use the latest copy from the list (not stale widget.project)
        final current = widget.projects.firstWhere(
          (p) => p.id == widget.project.id,
          orElse: () => widget.project,
        );

        final s = widget.session.state;
        final isActiveProject = (s.activeProjectId == current.id);
        final hasSomeOtherActive = (s.activeProjectId != null && s.activeProjectId != current.id);

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

        int maxDayForProject(PrayerProject p) {
          final nowDay = p.dayNumberFor(DateTime.now());
          if (nowDay <= 0) return 1;
          if (nowDay > p.durationDays) return p.durationDays;
          return nowDay;
        }

        Future<void> toggleArchive() async {
          // Prevent archiving while timer is running/paused on THIS project
          if (isActiveProject && (s.isRunning || s.isPaused)) {
            _snack('Stop the timer before archiving/unarchiving this project.');
            return;
          }

          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
          if (idx == -1) return;

          updated[idx].isArchived = !updated[idx].isArchived;
          await widget.onProjectsUpdated(updated);

          _snack(updated[idx].isArchived ? 'Project archived.' : 'Project unarchived.');

          if (mounted) {
            setState(() {});
          }
        }

        Future<void> stopAndAddHere() async {
          if (!isActiveProject) return;
          if (current.isArchived) {
            _snack('This project is archived. Unarchive it to log time.');
            return;
          }

          final seconds = await widget.session.stopAndReset();
          final minutesToAdd = seconds ~/ 60;
          final remainderSeconds = seconds % 60;

          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
          if (idx == -1) return;

          final todayDay = updated[idx].dayNumberFor(DateTime.now());

          if (minutesToAdd > 0 && todayDay >= 1 && todayDay <= updated[idx].durationDays) {
            updated[idx].totalMinutesPrayed += minutesToAdd;
            updated[idx].addMinutesForDay(todayDay, minutesToAdd);
          } else if (seconds > 0 && todayDay >= 1 && todayDay <= updated[idx].durationDays) {
            updated[idx].markDayPrayed(todayDay);
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

        // ✅ NEW: Manual add time (moved here from Pray Now)
        Future<void> addTimeManually() async {
          if (current.isArchived) {
            _snack('This project is archived. Unarchive it to log time.');
            return;
          }

          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
          if (idx == -1) return;

          final maxDay = maxDayForProject(updated[idx]);
          int chosenDay = maxDay;
          int chosenMinutes = 15;

          final ok = await showDialog<bool>(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: const Text('Add time manually'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu<int>(
                      initialSelection: chosenDay,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Day'),
                      dropdownMenuEntries: List.generate(maxDay, (i) => i + 1)
                          .reversed
                          .map((d) {
                            final date = _dateForDay(updated[idx], d);
                            return DropdownMenuEntry(
                              value: d,
                              label: '${_fmtDDMMYYYY(date)} (Day $d)',
                            );
                          })
                          .toList(),
                      onSelected: (v) {
                        if (v != null) chosenDay = v;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<int>(
                      initialSelection: chosenMinutes,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Minutes'),
                      dropdownMenuEntries: List.generate(24, (i) => (i + 1) * 15)
                          .map((m) => DropdownMenuEntry(value: m, label: '$m minutes'))
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

          // Safety clamp
          final safeDay = chosenDay.clamp(1, maxDay);

          updated[idx].totalMinutesPrayed += chosenMinutes;
          updated[idx].addMinutesForDay(safeDay, chosenMinutes);
          updated[idx].lastPrayedAt = DateTime.now();

          await widget.onProjectsUpdated(updated);
          _snack('Added $chosenMinutes min to Day $safeDay.');

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
          if (current.isArchived) {
            _snack('This project is archived. Unarchive it to log time.');
            return;
          }

          final updated = [...widget.projects];
          final idx = updated.indexWhere((p) => p.id == current.id);
          if (idx == -1) return;

          final maxDay = maxDayForProject(updated[idx]);

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
                      dropdownMenuEntries: List.generate(maxDay, (i) => i + 1).reversed.map((d) {
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
                      dropdownMenuEntries: const [15, 30, 45, 60, 75, 90, 105, 120]
                          .map((m) => DropdownMenuEntry(value: m, label: '$m minutes'))
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
          updated[idx].addMinutesForDay(chosenDay, chosenMinutes);
          updated[idx].lastPrayedAt = DateTime.now();

          await widget.onProjectsUpdated(updated);
          _snack('Added $chosenMinutes min to Day $chosenDay.');

          if (mounted) {
            setState(() {});
          }
        }

        // History list (latest first)
        final historyDays = current.prayedDays.toList()..sort((a, b) => b.compareTo(a));

        final notesForSelectedDay = current.dayNotes[_selectedDay] ?? [];
        final selectedDate = _dateForDay(current, _selectedDay);

        final bool timerButtonsEnabled = isActiveProject && !current.isArchived;
        final bool canStartTimerHere = timerButtonsEnabled && !hasSomeOtherActive;

        return Scaffold(
          appBar: AppBar(
            title: Text(current.title),
            actions: [
              IconButton(
                tooltip: current.isArchived ? 'Unarchive' : 'Archive',
                icon: Icon(current.isArchived ? Icons.unarchive : Icons.archive_outlined),
                onPressed: toggleArchive,
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
                        Text('${(current.progress * 100).toStringAsFixed(0)}% complete'),
                        if (current.isArchived) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'This project is archived. Unarchive it to log time.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Batch 7: Streak + History
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Streak',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text('Current: ${current.currentStreak} day(s)'),
                        Text('Best: ${current.bestStreak} day(s)'),
                        const Divider(height: 24),
                        const Text(
                          'History',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (historyDays.isEmpty)
                          const Text(
                            'No logged days yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...historyDays.map((d) {
                            final date = _dateForDay(current, d);
                            final mins = current.dayMinutes[d] ?? 0;
                            final notesCount = current.dayNotes[d]?.length ?? 0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${_fmtDDMMYYYY(date)} (Day $d)'),
                              subtitle: Text('$mins min • $notesCount note(s)'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                setState(() => _selectedDay = d);
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Batch 9.1: Calendar Grid (weekday aligned)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calendar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        _buildWeekdayHeader(),
                        const SizedBox(height: 10),
                        _buildCalendarGrid(current),
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
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
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
                              onPressed: canStartTimerHere
                                  ? (s.isRunning
                                      ? null
                                      : (s.isPaused ? widget.session.resume : widget.session.start))
                                  : null,
                              child: Text(s.isPaused ? 'Resume' : 'Start'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: timerButtonsEnabled && s.isRunning ? widget.session.pause : null,
                              child: const Text('Pause'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: timerButtonsEnabled && (s.isRunning || s.isPaused) ? stopAndAddHere : null,
                              child: const Text('Stop & Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ NEW BUTTON (Batch 6)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_calendar),
                    title: const Text('Add time manually'),
                    subtitle: const Text('Log minutes to a chosen day (15-min blocks)'),
                    onTap: current.isArchived ? null : addTimeManually,
                  ),
                ),

                const SizedBox(height: 10),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Add time in retrospect'),
                    subtitle: const Text('Quick log (15-min blocks)'),
                    onTap: current.isArchived ? null : addTimeInRetrospect,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                            final idx = updated.indexWhere((p) => p.id == current.id);
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
                                            final idx = updated.indexWhere((p) => p.id == current.id);
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
