import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum HealthTier { unknown, excellent, fair, poor, degraded }

enum DiagnosticPhase { idle, idlePing, download, upload, done }

extension HealthTierX on HealthTier {
  String get label => switch (this) {
        HealthTier.unknown => 'Not tested',
        HealthTier.excellent => 'Excellent',
        HealthTier.fair => 'Fair',
        HealthTier.poor => 'Poor',
        HealthTier.degraded => 'Degraded',
      };

  String get rule => switch (this) {
        HealthTier.unknown => 'Run a test to measure your connection',
        HealthTier.excellent => 'Download above 10 Mbps',
        HealthTier.fair => 'Download between 2 and 10 Mbps',
        HealthTier.poor => 'Download below 2 Mbps',
        HealthTier.degraded => 'Heavy packet loss or extreme latency',
      };

  Color get color => switch (this) {
        HealthTier.unknown => Colors.grey,
        HealthTier.excellent => Colors.green,
        HealthTier.fair => Colors.amber.shade800,
        HealthTier.poor => Colors.deepOrange,
        HealthTier.degraded => Colors.red,
      };

  IconData get icon => switch (this) {
        HealthTier.unknown => Icons.help_outline,
        HealthTier.excellent => Icons.signal_wifi_4_bar,
        HealthTier.fair => Icons.network_wifi_3_bar,
        HealthTier.poor => Icons.network_wifi_1_bar,
        HealthTier.degraded => Icons.signal_wifi_connected_no_internet_4,
      };
}

/// Activity 3: measures idle ping, download (+ping) and upload (+ping),
/// classifies the connection and exposes the tier as global state.
class NetworkDiagnosticState extends ChangeNotifier {
  static const String _base = 'https://speed.cloudflare.com';
  static const int _downloadBytes = 5000000;
  static const int _uploadBytes = 1500000;
  static const Duration _autoInterval = Duration(seconds: 60);

  DiagnosticPhase phase = DiagnosticPhase.idle;
  HealthTier tier = HealthTier.unknown;

  double? idlePingMs;
  double? downloadPingMs;
  double? uploadPingMs;
  double? downloadMbps;
  double? uploadMbps;
  double packetLossPercent = 0;

  String? error;
  DateTime? lastRun;
  bool autoTest = false;
  Timer? _autoTimer;

  bool get isRunning =>
      phase == DiagnosticPhase.idlePing ||
      phase == DiagnosticPhase.download ||
      phase == DiagnosticPhase.upload;

  String get phaseLabel => switch (phase) {
        DiagnosticPhase.idle => 'Ready',
        DiagnosticPhase.idlePing => 'Step 1/3: measuring idle ping...',
        DiagnosticPhase.download =>
          'Step 2/3: measuring download + ping...',
        DiagnosticPhase.upload => 'Step 3/3: measuring upload + ping...',
        DiagnosticPhase.done => 'Finished',
      };

  void setAutoTest(bool value) {
    autoTest = value;
    _autoTimer?.cancel();
    if (value) {
      runDiagnostics();
      _autoTimer = Timer.periodic(_autoInterval, (_) => runDiagnostics());
    }
    notifyListeners();
  }

  Future<void> runDiagnostics() async {
    if (isRunning) return;
    error = null;
    var sent = 0;
    var failed = 0;

    try {
      // Step 1: baseline idle ping
      phase = DiagnosticPhase.idlePing;
      notifyListeners();

      final idle = <double>[];
      for (var i = 0; i < 5; i++) {
        sent++;
        final ms = await _pingOnce();
        if (ms == null) {
          failed++;
        } else {
          idle.add(ms);
        }
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (idle.isEmpty) {
        throw Exception('No response from the test server');
      }
      idlePingMs = _avg(idle);

      // Step 2: download bandwidth with concurrent ping
      phase = DiagnosticPhase.download;
      notifyListeners();

      var received = 0;
      final down = await _measure(() async {
        final r = await http
            .get(Uri.parse('$_base/__down?bytes=$_downloadBytes'))
            .timeout(const Duration(seconds: 30));
        if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
        received = r.bodyBytes.length;
      }, () => received);
      downloadMbps = down.mbps;
      downloadPingMs = down.pingMs;
      sent += down.sent;
      failed += down.failed;

      // Step 3: upload bandwidth with concurrent ping
      phase = DiagnosticPhase.upload;
      notifyListeners();

      final up = await _measure(() async {
        final r = await http
            .post(Uri.parse('$_base/__up'), body: Uint8List(_uploadBytes))
            .timeout(const Duration(seconds: 30));
        if (r.statusCode >= 400) throw Exception('HTTP ${r.statusCode}');
      }, () => _uploadBytes);
      uploadMbps = up.mbps;
      uploadPingMs = up.pingMs;
      sent += up.sent;
      failed += up.failed;

      packetLossPercent = sent == 0 ? 0 : failed / sent * 100;
      tier = _classify();
    } catch (e) {
      error = 'Diagnostic failed: $e';
      packetLossPercent = sent == 0 ? 100 : failed / sent * 100;
      tier = HealthTier.degraded;
    }

    lastRun = DateTime.now();
    phase = DiagnosticPhase.done;
    notifyListeners();
  }

  // Runs [transfer] while pinging in parallel, returns Mbps and average ping.
  Future<({double mbps, double? pingMs, int sent, int failed})> _measure(
    Future<void> Function() transfer,
    int Function() bytes,
  ) async {
    var active = true;
    final pings = <double>[];
    var sent = 0;
    var failed = 0;

    final pinger = () async {
      while (active) {
        sent++;
        final ms = await _pingOnce();
        if (ms == null) {
          failed++;
        } else {
          pings.add(ms);
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }();

    final sw = Stopwatch()..start();
    try {
      await transfer();
    } finally {
      sw.stop();
      active = false;
    }
    await pinger;

    // bits per microsecond equals megabits per second
    final mbps = (bytes() * 8) / max(sw.elapsedMicroseconds, 1);
    return (mbps: mbps, pingMs: _avg(pings), sent: sent, failed: failed);
  }

  Future<double?> _pingOnce() async {
    final sw = Stopwatch()..start();
    try {
      await http
          .get(Uri.parse('$_base/__down?bytes=0'))
          .timeout(const Duration(seconds: 3));
      sw.stop();
      return sw.elapsedMicroseconds / 1000.0;
    } catch (_) {
      return null;
    }
  }

  double? _avg(List<double> values) =>
      values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

  HealthTier _classify() {
    final pings = [idlePingMs, downloadPingMs, uploadPingMs].whereType<double>();
    final worstPing = pings.isEmpty ? double.infinity : pings.reduce(max);

    if (packetLossPercent >= 20 || worstPing > 1000) return HealthTier.degraded;

    final mbps = downloadMbps ?? 0;
    if (mbps > 10) return HealthTier.excellent;
    if (mbps >= 2) return HealthTier.fair;
    return HealthTier.poor;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}
