import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/app_state.dart';
import '../providers/mesh_chat_state.dart';

class LocalMeshChatScreen extends StatefulWidget {
  static const String routeName = '/local-mesh-chat';

  const LocalMeshChatScreen({super.key});

  @override
  State<LocalMeshChatScreen> createState() => _LocalMeshChatScreenState();
}

class _LocalMeshChatScreenState extends State<LocalMeshChatScreen> {
  final _nameCtl = TextEditingController();
  final _msgCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use the profile name from Settings as the default display name
    _nameCtl.text = context.read<AppState>().userName;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _msgCtl.dispose();
    super.dispose();
  }

  void _send(MeshChatState chat) {
    chat.sendMessage(_msgCtl.text);
    _msgCtl.clear();
  }

  @override
  Widget build(BuildContext context) {
    // UI = f(state): whenever the state calls notifyListeners(), this rebuilds.
    final chat = context.watch<MeshChatState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Mesh Chat'),
        actions: [
          if (chat.isRunning)
            TextButton.icon(
              onPressed: chat.stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!chat.isRunning) _buildStartCard(chat),
            if (chat.error != null) _buildError(chat.error!),
            if (chat.pending != null) _buildHandshakeCard(chat),
            if (chat.isRunning) _buildPeers(chat),
            const Divider(height: 1),
            Expanded(child: _buildMessages(chat)),
            _buildInput(chat),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard(MeshChatState chat) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => chat.start(_nameCtl.text),
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.all(8),
      child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
    );
  }

  Widget _buildHandshakeCard(MeshChatState chat) {
    final p = chat.pending!;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.isIncoming
                  ? '${p.endpointName} wants to connect'
                  : 'Connecting to ${p.endpointName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Make sure the code is the SAME on both phones:'),
            Text(
              p.authToken,
              style: const TextStyle(fontSize: 28, letterSpacing: 4),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: chat.rejectPending, child: const Text('Reject')),
                FilledButton(onPressed: chat.acceptPending, child: const Text('Accept')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeers(MeshChatState chat) {
    final peers = chat.peers;
    return SizedBox(
      height: 96,
      child: peers.isEmpty
          ? const Center(child: Text('Searching for nearby devices...'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: peers.length,
              itemBuilder: (context, i) {
                final peer = peers[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(peer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        switch (peer.status) {
                          PeerStatus.discovered => FilledButton.tonal(
                              onPressed: () => chat.connectTo(peer.id),
                              child: const Text('Connect'),
                            ),
                          PeerStatus.connecting => const Text('Connecting...'),
                          PeerStatus.connected => const Chip(
                              label: Text('Connected'),
                              visualDensity: VisualDensity.compact,
                            ),
                        },
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMessages(MeshChatState chat) {
    final msgs = chat.messages.reversed.toList();
    if (msgs.isEmpty) {
      return const Center(child: Text('No messages yet. Tap Start.'));
    }
    return ListView.builder(
      reverse: true, // newest message always at the bottom
      padding: const EdgeInsets.all(8),
      itemCount: msgs.length,
      itemBuilder: (context, i) => _MessageBubble(message: msgs[i]),
    );
  }

  Widget _buildInput(MeshChatState chat) {
    final canSend = chat.connectedPeers.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtl,
              enabled: canSend,
              onSubmitted: (_) => _send(chat),
              decoration: InputDecoration(
                hintText: canSend ? 'Type a message...' : 'Connect to a peer first',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: canSend ? () => _send(chat) : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(message.text,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline, fontSize: 12)),
        ),
      );
    }

    final mine = message.isMine;
    final t = message.time;
    final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(message.sender,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(message.text),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(time, style: TextStyle(fontSize: 10, color: scheme.outline)),
            ),
          ],
        ),
      ),
    );
  }
}
