import 'package:flutter/material.dart';
import '../services/timer_service.dart';

class PrayerTimer extends StatefulWidget {
  final void Function(int minutes) onCompleted;

  const PrayerTimer({super.key, required this.onCompleted});

  @override
  State<PrayerTimer> createState() => _PrayerTimerState();
}

class _PrayerTimerState extends State<PrayerTimer> {
  final TimerService _timerService = TimerService();
  Duration _elapsed = Duration.zero;

  String get _formattedTime {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _start() {
    _timerService.start((elapsed) {
      setState(() => _elapsed = elapsed);
    });
  }

  void _stop() {
    final minutes = _timerService.stop();
    setState(() => _elapsed = Duration.zero);
    widget.onCompleted(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formattedTime,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _timerService.isRunning ? null : _start,
              child: const Text('Start'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _timerService.isRunning ? _stop : null,
              child: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }
}
