import 'package:flutter/material.dart';

enum MoodType {
  sleeping('😴', 'Сплю', 'Тихо, я сплю...', Color(0xFF4A3F6B)),
  resting('💆', 'Отдыхаю', 'Расслабляюсь', Color(0xFF3B5A3E)),
  working('💻', 'Работаю', 'Буду занят(а)', Color(0xFF3A4A6B)),
  gaming('🎮', 'Играю', 'Не мешать!', Color(0xFF6B3A4A)),
  wantHug('🤗', 'Хочу обнять', 'Иди ко мне!', Color(0xFF7A3A5A)),
  sad('😢', 'Грустно', 'Мне нужна ты/ты', Color(0xFF4A3A6B)),
  thinkingOfYou('❤️', 'Думаю о тебе', 'Ты у меня в голове', Color(0xFF7A2A4A)),
  goingToSleep('🌙', 'Ложусь спать', 'Спокойной ночи...', Color(0xFF2A2A4A));

  final String emoji;
  final String label;
  final String subtitle;
  final Color accentColor;
  const MoodType(this.emoji, this.label, this.subtitle, this.accentColor);
}

class MoodState {
  final MoodType? myMood;
  final MoodType? partnerMood;
  final DateTime? lastUpdated;

  const MoodState({
    this.myMood,
    this.partnerMood,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'myMood': myMood?.name,
        'partnerMood': partnerMood?.name,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory MoodState.fromJson(Map<String, dynamic> json) => MoodState(
        myMood: json['myMood'] != null
            ? MoodType.values.firstWhere(
                (e) => e.name == json['myMood'],
                orElse: () => MoodType.resting,
              )
            : null,
        partnerMood: json['partnerMood'] != null
            ? MoodType.values.firstWhere(
                (e) => e.name == json['partnerMood'],
                orElse: () => MoodType.resting,
              )
            : null,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : null,
      );
}
