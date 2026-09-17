import 'package:cloud_firestore/cloud_firestore.dart';

class PairPhoto {
  final String id;
  final String url;
  final DateTime uploadedAt;
  final String uploadedBy;

  const PairPhoto({
    required this.id,
    required this.url,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory PairPhoto.fromJson(Map<String, dynamic> json) => PairPhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        uploadedAt: _readDate(json['uploadedAt']) ?? DateTime.now(),
        uploadedBy: (json['uploadedBy'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'uploadedAt': uploadedAt.toIso8601String(),
        'uploadedBy': uploadedBy,
      };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
