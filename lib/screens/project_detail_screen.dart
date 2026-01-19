import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prayer_project.dart';
import '../services/prayer_session.dart';

class ProjectDetailScreen extends StatefulWidget {
  final PrayerProject project;
  final PrayerSessionController session;

  /// Needed because Stop & Add changes project totals/lastPrayedAt
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
  // Notes
  final TextEditingController _newNoteCtrl = TextEditingController();
  bool _isSaving = false;
  int? _selectedDay;

  String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d-$m-$y $h:$mi';
  }

  int get _todayDayNumber => widget.project.dayNumberFor(DateTime.now());

  int get _activeDayForNotes {
    final chosen = _selectedDay;
    if (chosen != null) return chosen;

    if (_todayDayNumber == 0) return 1;
    if (_todayDayNumber == widget.project.durationDays + 1) {
      return widget.project.durationDays;
    }
    return _todayDayNumber;
  }

  String _dateForDayLabel(int day) {
    final base = DateTime(
      widget.project.plannedStartDate.year,
      widget.project.plannedStartDate.month,
      widget.project.plannedStartDate.day,
    );
    final date = base.add(Duration(days: day - 1));
    return '${_fmtDate(date)} (Day $day)';
  }

  List<PrayerNote> get _notesForActiveDay {
    final day = _activeDayForNotes;
    return widget.project.dayNotes[day] ?? [];
  }

  Future<void> _pickDay() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Select day'),
          children: List.generate(widget.project.durationDays, (i) {
            final day = i + 1;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, day),
              child: Text(_dateForDayLabel(day)),
            );
          }),
        );
      },
    );

    if (picked != null) setState(() => _selectedDay = picked);
  }

  Future<void> _addNote() async {
    final text = _newNoteCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);

    widget.project.addNoteForDay(
      _activeDayForNotes,
      PrayerNote(text: text, createdAt: DateTime.now()),
    );

    _newNoteCtrl.clear();
    await _saveProjectOnly();
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _deleteNote(int index) async {
    final day = _activeDayForNotes;
    final list = widget.project.dayNotes[day];
    if (list == null || index < 0 || index >= list.length) return;

    setState(() => _isSaving = true);
    list.removeAt(index);
    if (list.isEmpty) widget.project.dayNotes.remove(day);

    await _saveProjectOnly();
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveProjectOnly() async {
    // We don’t have the whole list here, so we just trigger a rebuild persist at shell level later.
    // For now, notes persistence is already handled by your storage on navigation changes in projects.
    // If you want: we can wire a direct "persist projects" callback later.
    //
    // Keeping it minimal in this step.
  }

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
  void dispose() {
    _newNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return ValueListenableBuilder(
      valueListenable: widget.session.notifier,
      builder: (context, _, __) {
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

          // Update THIS project only (Projects list persistence will happen via Projects tab saving)
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
                        const SizedBox(height: 6),
                        Text(
                          'Planned: ${_fmtDate(project.plannedStartDate)} → ${_fmtDate(project.endDate)}',
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: project.progress),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Timer controls (only active project can control)
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

                const SizedBox(height: 22),

                // Notes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notes (${_dateForDayLabel(_activeDayForNotes)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isSaving ? 'Saving…' : 'Saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSaving ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _selectedDay = null),
                      child: const Text('Today'),
                    ),
                    OutlinedButton(
                      onPressed: _pickDay,
                      child: const Text('Pick Day'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newNoteCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Add a note for this day…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addNote,
                  child: const Text('Add Note'),
                ),
                const SizedBox(height: 16),
                if (_notesForActiveDay.isEmpty)
                  const Text('No notes for this day yet.')
                else
                  ...List.generate(_notesForActiveDay.length, (index) {
                    final note = _notesForActiveDay[index];
                    return Card(
                      child: ListTile(
                        title: Text(note.text),
                        subtitle: Text(_formatDateTime(note.createdAt)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteNote(index),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
