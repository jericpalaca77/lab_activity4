import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_monitor_state.dart';

class NetworkMonitorScreen extends StatelessWidget {
  static const String routeName = '/network-monitor';

  const NetworkMonitorScreen({super.key});

  IconData _iconFor(String label) => switch (label) {
        'Wi-Fi' => Icons.wifi,
        'Cellular' => Icons.signal_cellular_alt,
        'Ethernet' => Icons.settings_ethernet,
        'Offline' => Icons.wifi_off,
        _ => Icons.public,
      };

  @override
  Widget build(BuildContext context) {
    final m = context.watch<NetworkMonitorState>();
    final scheme = Theme.of(context).colorScheme;
    final label = m.interfaceLabel;
    final busy =
        m.jobStatus == JobStatus.running || m.jobStatus == JobStatus.queued;

    return Scaffold(
      appBar: AppBar(title: const Text('Network Monitor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Real-time interface card (driven by the connectivity stream)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: m.isOnline
                        ? scheme.primaryContainer
                        : scheme.errorContainer,
                    child: Icon(_iconFor(label), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active network'),
                        Text(label,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Request queue card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Long-running request',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Status: ${m.jobStatusLabel}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: m.progress / 100),
                  const SizedBox(height: 4),
                  Text('${m.progress}%   |   Retries: ${m.retries}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : m.startRequest,
                        icon: const Icon(Icons.download),
                        label: const Text('Start request'),
                      ),
                      OutlinedButton.icon(
                        onPressed: m.resetRequest,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Simulate connection drop'),
              subtitle: const Text(
                  'Demo a Wi-Fi/Cellular handover without leaving the app'),
              value: m.simulatedOffline,
              onChanged: m.setSimulatedOffline,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event log',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (m.log.isEmpty)
                    const Text('No events yet.')
                  else
                    for (final line in m.log)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(line,
                            style: const TextStyle(fontFamily: 'monospace')),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
