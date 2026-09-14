class CycleTracker {
  final DateTime? lastPeriodStart;
  final int cycleLength;
  final int periodLength;
  /// Manual plaque override: period | ovulation | calm | unknown | null (auto)
  final String? statusOverride;

  CycleTracker({
    this.lastPeriodStart,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.statusOverride,
  });

  CycleTracker copyWith({
    DateTime? lastPeriodStart,
    int? cycleLength,
    int? periodLength,
    String? statusOverride,
    bool clearOverride = false,
    bool clearStart = false,
  }) {
    return CycleTracker(
      lastPeriodStart:
          clearStart ? null : (lastPeriodStart ?? this.lastPeriodStart),
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      statusOverride:
          clearOverride ? null : (statusOverride ?? this.statusOverride),
    );
  }

  factory CycleTracker.fromJson(Map<String, dynamic> json) {
    return CycleTracker(
      lastPeriodStart: json['lastPeriodStart'] != null
          ? DateTime.parse(json['lastPeriodStart'])
          : null,
      cycleLength: json['cycleLength'] ?? 28,
      periodLength: json['periodLength'] ?? 5,
      statusOverride: json['statusOverride'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastPeriodStart': lastPeriodStart?.toIso8601String(),
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'statusOverride': statusOverride,
      };

  int? dayInCycle([DateTime? now]) {
    if (lastPeriodStart == null) return null;
    final today = now ?? DateTime.now();
    final diff = today
        .difference(DateTime(lastPeriodStart!.year, lastPeriodStart!.month,
            lastPeriodStart!.day))
        .inDays;
    if (diff < 0) return null;
    return (diff % cycleLength) + 1;
  }

  /// Machine key: period | ovulation | calm | unknown
  String statusKey([DateTime? now]) {
    if (statusOverride != null && statusOverride!.isNotEmpty) {
      return statusOverride!;
    }
    final day = dayInCycle(now);
    if (day == null) return 'unknown';
    if (day <= periodLength) return 'period';
    final ovulationDay = (cycleLength / 2).round();
    if ((day - ovulationDay).abs() <= 2) return 'ovulation';
    return 'calm';
  }

  String status([DateTime? now]) {
    switch (statusKey(now)) {
      case 'period':
        return 'сейчас месячные';
      case 'ovulation':
        return 'сейчас овуляция';
      case 'calm':
        return 'спокойно';
      default:
        return 'неизвестно';
    }
  }

  String get statusEmoji {
    switch (statusKey()) {
      case 'period':
        return '🌸';
      case 'ovulation':
        return '✨';
      case 'calm':
        return '🌿';
      default:
        return '💭';
    }
  }

  static const plaqueOptions = <(String key, String label, String emoji)>[
    ('period', 'Месячные', '🌸'),
    ('ovulation', 'Овуляция', '✨'),
    ('calm', 'Спокойно', '🌿'),
    ('unknown', 'Неизвестно', '💭'),
  ];
}
