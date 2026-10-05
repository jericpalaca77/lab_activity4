import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum JobStatus { idle, running, queued, completed }

class NetworkDropException implements Exception {
  final String message;
  const NetworkDropException(this.message);

  @override
  String toString() => message;
}

/// Activity 2: listens to connectivity changes and keeps a long-running
/// request alive across handovers by queueing and resuming it.
class NetworkMonitorState extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;

  List<ConnectivityResult> _results = const [];
  bool _simulatedOffline = false;

  JobStatus jobStatus = JobStatus.idle;
  int progress = 0;
  int retries = 0;
  final List<String> log = [];

  NetworkMonitorState() {
    _init();
  }

  Future<void> _init() async {
    try {
      _results = await _connectivity.checkConnectivity();
    } catch (_) {}
    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
    notifyListeners();
  }

  // ---------- Getters (read by the UI) ----------
  bool get simulatedOffline => _simulatedOffline;

  bool get isOnline =>
      !_simulatedOffline && _results.any((r) => r != ConnectivityResult.none);

  String get interfaceLabel {
    if (!isOnline) return 'Offline';
    if (_results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (_results.contains(ConnectivityResult.mobile)) return 'Cellular';
    if (_results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Other';
  }

  String get jobStatusLabel => switch (jobStatus) {
        JobStatus.idle => 'Idle',
        JobStatus.running => 'Downloading dataset...',
        JobStatus.queued => 'Queued - waiting for a stable connection',
        JobStatus.completed => 'Completed',
      };

  // ---------- Connectivity stream ----------
  void _onChanged(List<ConnectivityResult> results) {
    _results = results;
    _addLog('Network changed: $interfaceLabel');
    _reactToConnectionChange();
    notifyListeners();
  }

  void setSimulatedOffline(bool value) {
    _simulatedOffline = value;
    _addLog(value
        ? 'Simulated connection drop (handover)'
        : 'Simulated connection restored');
    _reactToConnectionChange();
    notifyListeners();
  }

  void _reactToConnectionChange() {
    // Graceful recovery: resume the queued request as soon as we are online.
    if (isOnline && jobStatus == JobStatus.queued) {
      _resume();
    }
    // If we go offline while running, the next step catches the failure
    // and moves the request to the queue.
  }

  // ---------- Simulated long-running request ----------
  void startRequest() {
    if (jobStatus == JobStatus.running || jobStatus == JobStatus.queued) return;
    progress = 0;
    retries = 0;
    _addLog('Request started: downloading a large dataset');
    _begin();
  }

  void _begin() {
    jobStatus = JobStatus.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _step());
    notifyListeners();
  }

  void _step() {
    try {
      if (!isOnline) {
        throw const NetworkDropException('Connection lost during transfer');
      }
      progress = (progress + 4).clamp(0, 100);
      if (progress >= 100) {
        _timer?.cancel();
        jobStatus = JobStatus.completed;
        _addLog('Request completed');
      }
    } on NetworkDropException catch (e) {
      // Catch the error and queue the request instead of crashing.
      _timer?.cancel();
      jobStatus = JobStatus.queued;
      _addLog('${e.message}. Request queued at $progress%');
    }
    notifyListeners();
  }

  void _resume() {
    retries++;
    _addLog(
        'Connection restored ($interfaceLabel). Resuming from $progress% (retry $retries)');
    _begin();
  }

  void resetRequest() {
    _timer?.cancel();
    jobStatus = JobStatus.idle;
    progress = 0;
    retries = 0;
    notifyListeners();
  }

  void _addLog(String text) {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    log.insert(0, '${two(t.hour)}:${two(t.minute)}:${two(t.second)}  $text');
    if (log.length > 50) log.removeLast();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
