import 'package:cloud_firestore/cloud_firestore.dart';

class PairPhoto {
  final String id;
  final String url;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? note;
  final bool isDeleted;

  const PairPhoto({
    required this.id,
    required this.url,
    required this.uploadedAt,
    required this.uploadedBy,
    this.note,
    this.isDeleted = false,
  });

  factory PairPhoto.fromJson(Map<String, dynamic> json) => PairPhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        uploadedAt: _readDate(json['uploadedAt']) ?? DateTime.now(),
        uploadedBy: (json['uploadedBy'] as String?) ?? '',
        note: json['note'] as String?,
        isDeleted: json['isDeleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'uploadedAt': uploadedAt.toIso8601String(),
        'uploadedBy': uploadedBy,
        'note': note,
        'isDeleted': isDeleted,
      };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
