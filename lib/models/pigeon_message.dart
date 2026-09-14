import 'package:cloud_firestore/cloud_firestore.dart';

class PigeonMessage {
  final String id;
  final String content;
  final DateTime sentAt;
  final String senderId;
  final String? senderName;

  PigeonMessage({
    required this.id,
    required this.content,
    required this.sentAt,
    required this.senderId,
    this.senderName,
  });

  bool isMine(String? myUid) => myUid != null && senderId == myUid;

  PigeonMessage copyWith({
    String? id,
    String? content,
    DateTime? sentAt,
    String? senderId,
    String? senderName,
  }) {
    return PigeonMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
    );
  }

  factory PigeonMessage.fromJson(Map<String, dynamic> json) {
    return PigeonMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      // A newly-created server timestamp can briefly be null in a local
      // snapshot, so retain the client fallback for a stable UI order.
      sentAt: _readDate(json['sentAt']) ??
          _readDate(json['sentAtFallback']) ??
          DateTime.now(),
      senderId: (json['senderId'] as String?) ?? '',
      senderName: json['senderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'sentAt': sentAt.toIso8601String(),
        'senderId': senderId,
        'senderName': senderName,
      };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
