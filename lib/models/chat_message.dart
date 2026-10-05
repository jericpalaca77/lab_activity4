enum PeerStatus { discovered, connecting, connected }

class Peer {
  final String id;
  String name;
  PeerStatus status;

  Peer({required this.id, required this.name, this.status = PeerStatus.discovered});
}

class PendingConnection {
  final String endpointId;
  final String endpointName;
  final String authToken;
  final bool isIncoming;

  PendingConnection({
    required this.endpointId,
    required this.endpointName,
    required this.authToken,
    required this.isIncoming,
  });
}

class ChatMessage {
  final String text;
  final String sender;
  final bool isMine;
  final bool isSystem;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.sender,
    this.isMine = false,
    this.isSystem = false,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}
