import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/chat_message.dart';

/// Activity 4: serverless peer-to-peer chat using Google Nearby Connections.
class MeshChatState extends ChangeNotifier {
  static const String _serviceId = 'com.example.lab_activity_hub.meshchat';
  static const Strategy _strategy = Strategy.P2P_CLUSTER; // mesh: many peers

  String userName = 'User-${Random().nextInt(9000) + 1000}';
  bool isRunning = false;
  String? error;

  final Map<String, Peer> _peers = {};
  final List<ChatMessage> _messages = [];
  final List<PendingConnection> _pendingQueue = [];
  final Set<String> _seenIds = {}; // prevents relaying the same message twice

  // ---------- Getters (read by the UI) ----------
  List<Peer> get peers => _peers.values.toList();
  List<Peer> get connectedPeers =>
      _peers.values.where((p) => p.status == PeerStatus.connected).toList();
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  PendingConnection? get pending =>
      _pendingQueue.isEmpty ? null : _pendingQueue.first;

  // ---------- Permissions ----------
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    final locationOk = statuses[Permission.location]?.isGranted ?? false;
    if (!locationOk) return false;

    // Android 11 and below: Location services must be turned ON
    final locationOn = await Permission.location.serviceStatus.isEnabled;
    if (!locationOn) {
      error = 'Please turn ON Location (GPS) on your phone, then tap Start again.';
      return false;
    }
    return true;
  }

  // ---------- 1) Discovery: advertise + scan ----------
  Future<void> start(String name) async {
    if (isRunning) return;
    if (name.trim().isNotEmpty) userName = name.trim();
    error = null;

    if (kIsWeb) {
      error = 'Local Mesh Chat works on Android phones only (not in the browser).';
      notifyListeners();
      return;
    }

    if (!await _ensurePermissions()) {
      error ??= 'Permissions required (Location/Bluetooth/Nearby devices).';
      notifyListeners();
      return;
    }

    try {
      // Make this device visible to others
      await Nearby().startAdvertising(
        userName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: (id, info) => _onConnectionInitiated(id, info, true),
        onConnectionResult: (id, status) => _onConnectionResult(id, status),
        onDisconnected: (id) => _onDisconnected(id),
      );

      // Look for other devices
      await Nearby().startDiscovery(
        userName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) {
          _peers.putIfAbsent(id, () => Peer(id: id, name: name));
          notifyListeners();
        },
        onEndpointLost: (id) {
          final peer = _peers[id];
          if (peer != null && peer.status != PeerStatus.connected) {
            _peers.remove(id);
            notifyListeners();
          }
        },
      );

      isRunning = true;
      _addSystem('Started: advertising and searching for nearby devices...');
    } catch (e) {
      error = 'Unable to start: $e';
      await stop();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _stopNearby();
    _peers.clear();
    _pendingQueue.clear();
    isRunning = false;
    _addSystem('Local Mesh stopped.');
    notifyListeners();
  }

  Future<void> _stopNearby() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}
  }

  // ---------- 2) Connection & handshake ----------
  Future<void> connectTo(String endpointId) async {
    final peer = _peers[endpointId];
    if (peer == null || peer.status != PeerStatus.discovered) return;

    peer.status = PeerStatus.connecting;
    notifyListeners();

    try {
      await Nearby().requestConnection(
        userName,
        endpointId,
        onConnectionInitiated: (id, info) => _onConnectionInitiated(id, info, false),
        onConnectionResult: (id, status) => _onConnectionResult(id, status),
        onDisconnected: (id) => _onDisconnected(id),
      );
    } catch (e) {
      peer.status = PeerStatus.discovered;
      error = 'Unable to connect: $e';
      notifyListeners();
    }
  }

  // Called on BOTH sides. The auth token must be identical on both screens.
  void _onConnectionInitiated(String id, ConnectionInfo info, bool incoming) {
    _peers.putIfAbsent(id, () => Peer(id: id, name: info.endpointName));
    _peers[id]!
      ..name = info.endpointName
      ..status = PeerStatus.connecting;

    _pendingQueue.add(PendingConnection(
      endpointId: id,
      endpointName: info.endpointName,
      authToken: info.authenticationToken,
      isIncoming: incoming,
    ));
    notifyListeners();
  }

  Future<void> acceptPending() async {
    final p = pending;
    if (p == null) return;
    _pendingQueue.remove(p);
    notifyListeners();

    try {
      await Nearby().acceptConnection(
        p.endpointId,
        onPayLoadRecieved: (endpointId, payload) =>
            _onPayloadReceived(endpointId, payload),
        onPayloadTransferUpdate: (endpointId, update) {},
      );
    } catch (e) {
      error = 'Unable to accept: $e';
      notifyListeners();
    }
  }

  Future<void> rejectPending() async {
    final p = pending;
    if (p == null) return;
    _pendingQueue.remove(p);
    _peers[p.endpointId]?.status = PeerStatus.discovered;
    notifyListeners();

    try {
      await Nearby().rejectConnection(p.endpointId);
    } catch (_) {}
  }

  void _onConnectionResult(String id, Status status) {
    final peer = _peers[id];
    if (status == Status.CONNECTED) {
      peer?.status = PeerStatus.connected;
      _addSystem('Connected to ${peer?.name ?? id}');
    } else {
      peer?.status = PeerStatus.discovered;
      _addSystem('Connection to ${peer?.name ?? id} failed');
    }
    notifyListeners();
  }

  void _onDisconnected(String id) {
    final peer = _peers.remove(id);
    _addSystem('${peer?.name ?? id} disconnected');
    notifyListeners();
  }

  // ---------- 3) Payload routing ----------
  Future<void> sendMessage(String text) async {
    final t = text.trim();
    if (t.isEmpty || connectedPeers.isEmpty) return;

    final msgId = '${DateTime.now().microsecondsSinceEpoch}-$userName';
    _seenIds.add(msgId);
    _messages.add(ChatMessage(text: t, sender: userName, isMine: true));
    notifyListeners();

    await _broadcast({'id': msgId, 'sender': userName, 'text': t, 'ttl': 3});
  }

  void _onPayloadReceived(String fromId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

    try {
      final map = jsonDecode(utf8.decode(payload.bytes!)) as Map<String, dynamic>;
      final id = map['id'] as String;
      if (!_seenIds.add(id)) return; // already seen, do not duplicate

      _messages.add(ChatMessage(
        text: map['text'] as String,
        sender: map['sender'] as String,
      ));
      notifyListeners();

      // Mesh relay: forward to the other peers (not back to the sender)
      final ttl = (map['ttl'] as int) - 1;
      if (ttl > 0) {
        map['ttl'] = ttl;
        _broadcast(map, exceptId: fromId);
      }
    } catch (_) {
      // invalid payload, ignore
    }
  }

  Future<void> _broadcast(Map<String, dynamic> data, {String? exceptId}) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    for (final p in connectedPeers) {
      if (p.id == exceptId) continue;
      try {
        await Nearby().sendBytesPayload(p.id, bytes);
      } catch (_) {}
    }
  }

  void _addSystem(String text) {
    _messages.add(ChatMessage(text: text, sender: 'system', isSystem: true));
  }

  @override
  void dispose() {
    _stopNearby();
    super.dispose();
  }
}
