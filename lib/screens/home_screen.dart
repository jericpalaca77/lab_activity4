import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/network_diagnostic_state.dart';
import '../providers/network_monitor_state.dart';
import '../widgets/menu_card.dart';
import 'activity_one_screen.dart';
import 'activity_two_screen.dart';
import 'local_mesh_chat_screen.dart';
import 'network_diagnostic_screen.dart';
import 'network_monitor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final monitor = context.watch<NetworkMonitorState>();
    final diagnostic = context.watch<NetworkDiagnosticState>();
    final scheme = Theme.of(context).colorScheme;

    final items = <MenuCard>[
      const MenuCard(
        icon: Icons.looks_one,
        title: 'Activity One',
        subtitle: 'Stateful widgets: counter, favorites, and checklist',
        routeName: ActivityOneScreen.routeName,
      ),
      const MenuCard(
        icon: Icons.looks_two,
        title: 'Activity Two',
        subtitle: 'Task list with stateful state',
        routeName: ActivityTwoScreen.routeName,
      ),
      const MenuCard(
        icon: Icons.network_check,
        title: 'Network Monitor',
        subtitle: 'Live network state and request queue',
        routeName: NetworkMonitorScreen.routeName,
      ),
      const MenuCard(
        icon: Icons.speed,
        title: 'Network Diagnostic',
        subtitle: 'Ping, download and upload health tiers',
        routeName: NetworkDiagnosticScreen.routeName,
      ),
      const MenuCard(
        icon: Icons.forum,
        title: 'Local Mesh Chat',
        subtitle: 'Serverless peer-to-peer messaging',
        routeName: LocalMeshChatScreen.routeName,
      ),
      const MenuCard(
        icon: Icons.settings,
        title: 'Settings',
        subtitle: 'Dark/Light theme and user\'s name',
        routeName: SettingsScreen.routeName,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Activity Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting card: updates instantly when Settings change (global state)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(app.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${app.userName}!',
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text('Theme: ${app.themeLabel}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Network status broadcast from global state
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  monitor.isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 18,
                ),
                label: Text('Network: ${monitor.interfaceLabel}'),
              ),
              Chip(
                avatar: Icon(diagnostic.tier.icon,
                    size: 18, color: diagnostic.tier.color),
                label: Text('Connection health: ${diagnostic.tier.label}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Responsive grid: 1, 2 or 3 columns depending on the width
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
              const gap = 12.0;
              final itemWidth = (w - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(width: itemWidth, child: item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
