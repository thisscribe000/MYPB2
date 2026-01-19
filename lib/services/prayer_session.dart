import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class PrayerSessionState {
  final String? activeProjectId;
  final bool isRunning;
  final bool isPaused;
  final int elapsedSeconds; // accumulated seconds (paused time)
  final int? startedAtEpochMs; // when running, start instant

  const PrayerSessionState({
    required this.activeProjectId,
    required this.isRunning,
    required this.isPaused,
    required this.elapsedSeconds,
    required this.startedAtEpochMs,
  });

  factory PrayerSessionState.idle() => const PrayerSessionState(
        activeProjectId: null,
        isRunning: false,
        isPaused: false,
        elapsedSeconds: 0,
        startedAtEpochMs: null,
      );

  PrayerSessionState copyWith({
    String? activeProjectId,
    bool? isRunning,
    bool? isPaused,
    int? elapsedSeconds,
    int? startedAtEpochMs,
  }) {
    return PrayerSessionState(
      activeProjectId: activeProjectId ?? this.activeProjectId,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startedAtEpochMs: startedAtEpochMs ?? this.startedAtEpochMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'activeProjectId': activeProjectId,
        'isRunning': isRunning,
        'isPaused': isPaused,
        'elapsedSeconds': elapsedSeconds,
        'startedAtEpochMs': startedAtEpochMs,
      };

  factory PrayerSessionState.fromMap(Map<String, dynamic> map) {
    return PrayerSessionState(
      activeProjectId: map['activeProjectId'] as String?,
      isRunning: (map['isRunning'] as bool?) ?? false,
      isPaused: (map['isPaused'] as bool?) ?? false,
      elapsedSeconds: (map['elapsedSeconds'] as int?) ?? 0,
      startedAtEpochMs: map['startedAtEpochMs'] as int?,
    );
  }
}

class PrayerSessionController extends ChangeNotifier {
  static const String boxName = 'prayer_session_box';
  static const String keyName = 'session';

  PrayerSessionState _state = PrayerSessionState.idle();
  Timer? _ticker;

  PrayerSessionState get state => _state;

  Future<void> init() async {
    final box = await Hive.openBox(boxName);
    final raw = box.get(keyName);

    if (raw is Map) {
      _state = PrayerSessionState.fromMap(Map<String, dynamic>.from(raw));
    } else {
      _state = PrayerSessionState.idle();
    }

    _ensureTicker();
    notifyListeners();
  }

  Future<void> _save() async {
    final box = await Hive.openBox(boxName);
    await box.put(keyName, _state.toMap());
  }

  void _setState(PrayerSessionState next) {
    _state = next;
    notifyListeners();
  }

  void _ensureTicker() {
    _ticker?.cancel();

    if (_state.isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        // ✅ legal now (ChangeNotifier)
        notifyListeners();
      });
    }
  }

  int get displayedElapsedSeconds {
    if (!_state.isRunning || _state.startedAtEpochMs == null) {
      return _state.elapsedSeconds;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = ((now - _state.startedAtEpochMs!) / 1000).floor();
    return _state.elapsedSeconds + delta;
  }

  bool canSelectProject(String projectId) {
    if (_state.activeProjectId == null) return true;
    if (_state.activeProjectId == projectId) return true;
    if (_state.isRunning) return false;
    if (_state.isPaused && _state.elapsedSeconds > 0) return false;
    return true;
  }

  Future<bool> selectProject(String projectId) async {
    if (!canSelectProject(projectId)) return false;

    _setState(
      PrayerSessionState(
        activeProjectId: projectId,
        isRunning: false,
        isPaused: false,
        elapsedSeconds: 0,
        startedAtEpochMs: null,
      ),
    );

    await _save();
    _ensureTicker();
    return true;
  }

  Future<void> start() async {
    if (_state.activeProjectId == null) return;
    if (_state.isRunning) return;

    _setState(
      _state.copyWith(
        isRunning: true,
        isPaused: false,
        startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await _save();
    _ensureTicker();
  }

  Future<void> pause() async {
    if (!_state.isRunning || _state.startedAtEpochMs == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = ((now - _state.startedAtEpochMs!) / 1000).floor();

    _setState(
      _state.copyWith(
        isRunning: false,
        isPaused: true,
        elapsedSeconds: _state.elapsedSeconds + delta,
        startedAtEpochMs: null,
      ),
    );

    await _save();
    _ensureTicker();
  }

  Future<void> resume() async {
    if (_state.activeProjectId == null) return;
    if (_state.isRunning) return;
    if (!_state.isPaused) return;

    _setState(
      _state.copyWith(
        isRunning: true,
        isPaused: false,
        startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await _save();
    _ensureTicker();
  }

  Future<int> stopAndReset() async {
    final seconds = displayedElapsedSeconds;

    _setState(PrayerSessionState.idle());

    await _save();
    _ensureTicker();
    return seconds;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
