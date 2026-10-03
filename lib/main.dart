import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/mesh_chat_state.dart';
import 'screens/local_mesh_chat_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeshChatState()),
      ],
      child: const LabActivityApp(),
    ),
  );
}

class LabActivityApp extends StatelessWidget {
  const LabActivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab Activity 4',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        LocalMeshChatScreen.routeName: (context) => const LocalMeshChatScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Activity 4')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, LocalMeshChatScreen.routeName),
          icon: const Icon(Icons.forum),
          label: const Text('Local Mesh Chat'),
        ),
      ),
    );
  }
}