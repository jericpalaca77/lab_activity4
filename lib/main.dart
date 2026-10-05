import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'providers/mesh_chat_state.dart';
import 'providers/network_diagnostic_state.dart';
import 'providers/network_monitor_state.dart';
import 'screens/activity_one_screen.dart';
import 'screens/activity_two_screen.dart';
import 'screens/home_screen.dart';
import 'screens/local_mesh_chat_screen.dart';
import 'screens/network_diagnostic_screen.dart';
import 'screens/network_monitor_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => NetworkMonitorState()),
        ChangeNotifierProvider(create: (_) => NetworkDiagnosticState()),
        ChangeNotifierProvider(create: (_) => MeshChatState()),
      ],
      child: const LabActivityHubApp(),
    ),
  );
}

class LabActivityHubApp extends StatelessWidget {
  const LabActivityHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Global state: the theme mode comes from AppState and updates the whole app.
    final app = context.watch<AppState>();

    return MaterialApp(
      title: 'Lab Activity Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: app.themeMode,
      home: const HomeScreen(),
      routes: {
        ActivityOneScreen.routeName: (context) => const ActivityOneScreen(),
        ActivityTwoScreen.routeName: (context) => const ActivityTwoScreen(),
        NetworkMonitorScreen.routeName: (context) => const NetworkMonitorScreen(),
        NetworkDiagnosticScreen.routeName: (context) =>
            const NetworkDiagnosticScreen(),
        LocalMeshChatScreen.routeName: (context) => const LocalMeshChatScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }
}
