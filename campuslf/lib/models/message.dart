class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String? itemId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.itemId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'itemId': itemId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead ? 1 : 0,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    senderId: json['senderId'],
    receiverId: json['receiverId'],
    itemId: json['itemId'],
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] == 1,
  );
}