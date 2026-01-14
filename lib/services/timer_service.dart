import 'dart:async';

class TimerService {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  /// Called every second while timer is running
  void start(void Function(Duration elapsed) onTick) {
    if (_stopwatch.isRunning) return;

    _stopwatch.start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onTick(_stopwatch.elapsed),
    );
  }

  /// Stops timer and returns total minutes prayed
  int stop() {
    _ticker?.cancel();
    _stopwatch.stop();

    final minutes = _stopwatch.elapsed.inMinutes;
    _stopwatch.reset();

    return minutes;
  }

  void pause() {
    _ticker?.cancel();
    _stopwatch.stop();
  }

  bool get isRunning => _stopwatch.isRunning;
}
