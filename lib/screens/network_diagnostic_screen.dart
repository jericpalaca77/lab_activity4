import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_diagnostic_state.dart';

class NetworkDiagnosticScreen extends StatelessWidget {
  static const String routeName = '/network-diagnostic';

  const NetworkDiagnosticScreen({super.key});

  String _fmt(double? v, String unit, {int digits = 1}) =>
      v == null ? '-' : '${v.toStringAsFixed(digits)} $unit';

  @override
  Widget build(BuildContext context) {
    final d = context.watch<NetworkDiagnosticState>();
    final tier = d.tier;

    return Scaffold(
      appBar: AppBar(title: const Text('Network Diagnostic Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health tier card
          Card(
            color: tier.color.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(tier.icon, size: 48, color: tier.color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connection health'),
                        Text(tier.label,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: tier.color)),
                        Text(tier.rule),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.phaseLabel),
                  const SizedBox(height: 8),
                  if (d.isRunning) const LinearProgressIndicator(),
                  if (d.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(d.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: d.isRunning ? null : d.runDiagnostics,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run test now'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-test every 60 seconds'),
                    value: d.autoTest,
                    onChanged: d.setAutoTest,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Metrics
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(label: 'Idle ping', value: _fmt(d.idlePingMs, 'ms', digits: 0)),
              _MetricTile(label: 'Download', value: _fmt(d.downloadMbps, 'Mbps')),
              _MetricTile(label: 'Download ping', value: _fmt(d.downloadPingMs, 'ms', digits: 0)),
              _MetricTile(label: 'Upload', value: _fmt(d.uploadMbps, 'Mbps')),
              _MetricTile(label: 'Upload ping', value: _fmt(d.uploadPingMs, 'ms', digits: 0)),
              _MetricTile(label: 'Packet loss', value: _fmt(d.packetLossPercent, '%', digits: 0)),
            ],
          ),
          const SizedBox(height: 12),
          // The UI adapts to the connection tier
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adaptive media preview',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _AdaptiveMedia(tier: tier),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switches between rich media and a lightweight placeholder by health tier.
class _AdaptiveMedia extends StatelessWidget {
  final HealthTier tier;

  const _AdaptiveMedia({required this.tier});

  @override
  Widget build(BuildContext context) {
    final lightweight =
        tier == HealthTier.poor || tier == HealthTier.degraded;

    if (lightweight) {
      return Container(
        height: 90,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 32),
            Text('Lightweight placeholder (slow connection)'),
          ],
        ),
      );
    }

    final hd = tier == HealthTier.excellent;
    return Container(
      height: hd ? 170 : 110,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: hd
              ? [Colors.indigo, Colors.purple, Colors.pink]
              : [Colors.indigo.shade300, Colors.indigo.shade200],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        hd ? 'High-resolution media' : 'Standard-quality media',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
