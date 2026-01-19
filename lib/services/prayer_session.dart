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

class PrayerSessionController {
  static const String boxName = 'prayer_session_box';
  static const String keyName = 'session';

  final ValueNotifier<PrayerSessionState> notifier =
      ValueNotifier<PrayerSessionState>(PrayerSessionState.idle());

  Timer? _ticker;

  PrayerSessionState get state => notifier.value;

  Future<void> init() async {
    final box = await Hive.openBox(boxName);
    final raw = box.get(keyName);

    if (raw is Map) {
      notifier.value =
          PrayerSessionState.fromMap(Map<String, dynamic>.from(raw));
    } else {
      notifier.value = PrayerSessionState.idle();
    }

    _ensureTicker();
  }

  Future<void> _save() async {
    final box = await Hive.openBox(boxName);
    await box.put(keyName, state.toMap());
  }

  void _ensureTicker() {
    _ticker?.cancel();
    if (state.isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        // just trigger listeners so UI updates every second
        notifier.value = notifier.value;
      });
    }
  }

  int get displayedElapsedSeconds {
    if (!state.isRunning || state.startedAtEpochMs == null) {
      return state.elapsedSeconds;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = ((now - state.startedAtEpochMs!) / 1000).floor();
    return state.elapsedSeconds + delta;
  }

  /// Select project ONLY when not running.
  /// If paused with elapsed > 0, we also lock switching to protect the session.
  bool canSelectProject(String projectId) {
    if (state.activeProjectId == null) return true;
    if (state.activeProjectId == projectId) return true;
    if (state.isRunning) return false;
    if (state.isPaused && state.elapsedSeconds > 0) return false;
    return true;
  }

  Future<bool> selectProject(String projectId) async {
    if (!canSelectProject(projectId)) return false;

    notifier.value = PrayerSessionState(
      activeProjectId: projectId,
      isRunning: false,
      isPaused: false,
      elapsedSeconds: 0,
      startedAtEpochMs: null,
    );

    await _save();
    _ensureTicker();
    return true;
  }

  Future<void> start() async {
    if (state.activeProjectId == null) return;
    if (state.isRunning) return;

    notifier.value = state.copyWith(
      isRunning: true,
      isPaused: false,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    await _save();
    _ensureTicker();
  }

  Future<void> pause() async {
    if (!state.isRunning || state.startedAtEpochMs == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final delta = ((now - state.startedAtEpochMs!) / 1000).floor();

    notifier.value = state.copyWith(
      isRunning: false,
      isPaused: true,
      elapsedSeconds: state.elapsedSeconds + delta,
      startedAtEpochMs: null,
    );

    await _save();
    _ensureTicker();
  }

  Future<void> resume() async {
    if (state.activeProjectId == null) return;
    if (state.isRunning) return;
    if (!state.isPaused) return;

    notifier.value = state.copyWith(
      isRunning: true,
      isPaused: false,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    await _save();
    _ensureTicker();
  }

  /// Returns the elapsed seconds and resets session to idle (keeps activeProjectId = null)
  Future<int> stopAndReset() async {
    final seconds = displayedElapsedSeconds;

    notifier.value = PrayerSessionState.idle();

    await _save();
    _ensureTicker();
    return seconds;
  }

  void dispose() {
    _ticker?.cancel();
    notifier.dispose();
  }
}
