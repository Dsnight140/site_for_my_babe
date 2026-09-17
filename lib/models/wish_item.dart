enum WishCategory {
  food('🍕', 'Еда'),
  travel('✈️', 'Путешествия'),
  movie('🎬', 'Кино'),
  gift('💝', 'Подарки'),
  date('🌹', 'Свидания'),
  music('🎵', 'Музыка');

  final String emoji;
  final String label;
  const WishCategory(this.emoji, this.label);
}

class WishItem {
  final String id;
  String title;
  String? note;
  WishCategory category;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;
  String? creatorId;

  WishItem({
    required this.id,
    required this.title,
    this.note,
    this.category = WishCategory.gift,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.creatorId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'category': category.name,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'creatorId': creatorId,
      };

  factory WishItem.fromJson(Map<String, dynamic> json) => WishItem(
        id: json['id'],
        title: json['title'],
        note: json['note'],
        category: WishCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => WishCategory.gift,
        ),
        isCompleted: json['isCompleted'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        creatorId: json['creatorId'],
      );
}
