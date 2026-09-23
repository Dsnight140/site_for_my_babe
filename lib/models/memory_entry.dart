import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryEntry {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final String? photoUrl;
  final String? creatorId;
  final DateTime createdAt;

  const MemoryEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    this.photoUrl,
    this.creatorId,
    required this.createdAt,
  });

  bool isMine(String? myUid) => myUid != null && creatorId == myUid;

  MemoryEntry copyWith({
    String? title,
    String? note,
    DateTime? date,
    String? photoUrl,
  }) {
    return MemoryEntry(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      creatorId: creatorId,
    );
  }

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        note: json['note'] as String? ?? '',
        date: _readDate(json['date']) ?? DateTime.now(),
        photoUrl: json['photoUrl'] as String?,
        creatorId: (json['creatorId'] as String?) ?? '',
        createdAt: _readDate(json['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'photoUrl': photoUrl,
        'creatorId': creatorId ?? '',
        'createdAt': createdAt.toIso8601String(),
      };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
