import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnerRole { guy, girl }

class UserProfile {
  final String uid;
  final String displayName;
  final PartnerRole role;
  final DateTime? birthday;
  final DateTime? lastPigeonSentAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.role,
    this.birthday,
    this.lastPigeonSentAt,
  });

  bool get isComplete =>
      displayName.trim().isNotEmpty &&
      (role == PartnerRole.guy || role == PartnerRole.girl);

  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    var years = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      years--;
    }
    return years;
  }

  String get roleLabel => role == PartnerRole.girl ? 'Девушка' : 'Парень';

  factory UserProfile.fromJson(String uid, Map<String, dynamic> json) {
    final roleRaw = json['role'] as String?;
    return UserProfile(
      uid: uid,
      displayName: (json['displayName'] as String?)?.trim() ?? '',
      role: roleRaw == 'girl' ? PartnerRole.girl : PartnerRole.guy,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String)
          : null,
      lastPigeonSentAt: _readDate(json['lastPigeonSentAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'role': role == PartnerRole.girl ? 'girl' : 'guy',
        if (birthday != null) 'birthday': _isoDate(birthday!),
        if (lastPigeonSentAt != null)
          'lastPigeonSentAt': lastPigeonSentAt!.toIso8601String(),
      };

  Map<String, dynamic> toPartnerMirror() => {
        'displayName': displayName,
        'role': role == PartnerRole.girl ? 'girl' : 'guy',
        if (birthday != null) 'birthday': _isoDate(birthday!),
      };

  UserProfile copyWith({
    String? displayName,
    PartnerRole? role,
    DateTime? birthday,
    DateTime? lastPigeonSentAt,
    bool clearBirthday = false,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      lastPigeonSentAt: lastPigeonSentAt ?? this.lastPigeonSentAt,
    );
  }

  static bool isProfileComplete(Map<String, dynamic>? data) {
    if (data == null) return false;
    final name = (data['displayName'] as String?)?.trim() ?? '';
    final role = data['role'] as String?;
    return name.isNotEmpty && (role == 'guy' || role == 'girl');
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
