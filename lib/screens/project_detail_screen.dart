import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myprayerbank/models/prayer_project.dart';

class ProjectDetailScreen extends StatefulWidget {
  final PrayerProject project;
  final Future<void> Function() onPersist;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.onPersist,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // Notes
  final TextEditingController _newNoteCtrl = TextEditingController();
  bool _isSaving = false;

  int get _totalMinutes => widget.project.totalMinutesPrayed;
  int get _hoursPrayed => _totalMinutes ~/ 60;
  int get _minsRemainder => _totalMinutes % 60;
  int get _minsToNextHour => _minsRemainder == 0 ? 0 : (60 - _minsRemainder);

  String get _timerDisplay {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDateTime(DateTime dt) {
    // Simple readable format without extra packages
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  void _startTimer() {
    if (_stopwatch.isRunning) return;

    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  Future<void> _stopTimerAndAdd() async {
    if (!_stopwatch.isRunning) return;

    _ticker?.cancel();
    _stopwatch.stop();

    final minutes = _stopwatch.elapsed.inMinutes;
    _stopwatch.reset();

    setState(() => _elapsed = Duration.zero);

    if (minutes > 0) {
      await _addMinutes(minutes);
    }
  }

  void _pauseTimer() {
    _ticker?.cancel();
    _stopwatch.stop();
  }

  Future<void> _addMinutes(int minutes) async {
    setState(() {
      widget.project.totalMinutesPrayed += minutes;
    });
    await widget.onPersist();
  }

  Future<void> _roundDownToHour() async {
    final remainder = widget.project.totalMinutesPrayed % 60;
    if (remainder == 0) return;

    setState(() {
      widget.project.totalMinutesPrayed -= remainder;
    });
    await widget.onPersist();
  }

  Future<void> _roundUpToHour() async {
    final remainder = widget.project.totalMinutesPrayed % 60;
    if (remainder == 0) return;

    setState(() {
      widget.project.totalMinutesPrayed += (60 - remainder);
    });
    await widget.onPersist();
  }

  Future<void> _addNote() async {
    final text = _newNoteCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);

    widget.project.notes.insert(
      0,
      PrayerNote(text: text, createdAt: DateTime.now()),
    );

    _newNoteCtrl.clear();
    await widget.onPersist();

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _deleteNote(int index) async {
    setState(() => _isSaving = true);
    widget.project.notes.removeAt(index);
    await widget.onPersist();
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _newNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Target: ${project.targetHours} hours'),
            Text('Daily target: ${project.dailyTargetHours.toStringAsFixed(2)} hours'),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: project.progress),
            const SizedBox(height: 22),

            // Hour-first display
            Text(
              'Prayed: $_hoursPrayed hours',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_minsToNextHour > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('$_minsToNextHour mins to complete the next hour'),
              ),

            const SizedBox(height: 18),

            // Timer
            Text(
              _timerDisplay,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? null : _startTimer,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? _pauseTimer : null,
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopwatch.isRunning ? _stopTimerAndAdd : null,
                  child: const Text('Stop & Add'),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Manual add
            const Text(
              'Add time manually',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => _addMinutes(15),
                  child: const Text('+15 min'),
                ),
                ElevatedButton(
                  onPressed: () => _addMinutes(30),
                  child: const Text('+30 min'),
                ),
                ElevatedButton(
                  onPressed: () => _addMinutes(60),
                  child: const Text('+1 hour'),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Rounding options
            ExpansionTile(
              title: const Text('Rounding options'),
              children: [
                ListTile(
                  title: const Text('Round down to the hour'),
                  subtitle: Text(
                    _minsRemainder == 0
                        ? 'Already on an exact hour.'
                        : 'Removes $_minsRemainder minute(s).',
                  ),
                  trailing: TextButton(
                    onPressed: _minsRemainder == 0 ? null : _roundDownToHour,
                    child: const Text('Round down'),
                  ),
                ),
                ListTile(
                  title: const Text('Round up to the next hour'),
                  subtitle: Text(
                    _minsRemainder == 0
                        ? 'Already on an exact hour.'
                        : 'Adds $_minsToNextHour minute(s).',
                  ),
                  trailing: TextButton(
                    onPressed: _minsRemainder == 0 ? null : _roundUpToHour,
                    child: const Text('Round up'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Notes journal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prayer Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 10),

            TextField(
              controller: _newNoteCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a new note (scripture, direction, prayer points)…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addNote,
              child: const Text('Add Note'),
            ),

            const SizedBox(height: 16),

            if (project.notes.isEmpty)
              const Text('No notes yet.')
            else
              ...List.generate(project.notes.length, (index) {
                final note = project.notes[index];
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
  }
}
