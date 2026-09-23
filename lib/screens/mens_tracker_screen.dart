import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/date_format.dart';
import '../services/local_storage.dart';
import '../models/cycle_tracker.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_bg.dart';
import '../widgets/neon_card.dart';

class MensTrackerScreen extends StatefulWidget {
  const MensTrackerScreen({super.key});

  @override
  State<MensTrackerScreen> createState() => _MensTrackerScreenState();
}

class _MensTrackerScreenState extends State<MensTrackerScreen> {
  final _storage = LocalStorage();

  @override
  void initState() {
    super.initState();
    _storage.load().then((_) => setState(() {}));
    _storage.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _storage.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _pickPeriodStart() async {
    if (!_storage.isGirl) return;
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _storage.cycle.lastPeriodStart ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonPink,
            onPrimary: Colors.white,
            surface: AppTheme.cardColor,
            onSurface: AppTheme.textPrimary,
          ),
          dialogTheme:
              const DialogThemeData(backgroundColor: AppTheme.backgroundDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      await _storage.setCycleStart(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _storage.cycle;
    final status = cycle.status();
    final day = cycle.dayInCycle();
    final isGirl = _storage.isGirl;
    final partnerName = _storage.partnerProfile?.displayName ?? 'она';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          ParticleBackground(
            emojis: cycle.statusKey() == 'period'
                ? const ['🌸', '❤️', '🥀']
                : cycle.statusKey() == 'ovulation'
                    ? const ['✨', '💕', '🌸']
                    : const ['🌙', '⭐', '✨'],
            particleCount: 12,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.cardColorLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GradientText(
                        text: isGirl ? 'Мой цикл 🌸' : 'Её цикл 🌸',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      children: [
                        NeonCard(
                          borderRadius: 28,
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Text(cycle.statusEmoji,
                                      style: const TextStyle(fontSize: 64))
                                  .animate(
                                      onPlay: (c) => c.repeat(reverse: true))
                                  .scaleXY(end: 1.1, duration: 1500.ms),
                              const SizedBox(height: 16),
                              Text(
                                isGirl ? 'Сейчас у меня' : 'У $partnerName сегодня',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              GradientText(
                                text: status,
                                style: const TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                day != null
                                    ? 'День цикла: $day'
                                    : isGirl
                                        ? 'Можно указать дату начала ниже'
                                        : 'Она ещё не указала детали',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                        if (isGirl) ...[
                          const SizedBox(height: 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Быстрый статус для него',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: CycleTracker.plaqueOptions.map((opt) {
                              final selected = cycle.statusOverride == opt.$1 ||
                                  (cycle.statusOverride == null &&
                                      cycle.statusKey() == opt.$1);
                              return GestureDetector(
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  await _storage.setCycleStatusOverride(opt.$1);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient:
                                        selected ? AppTheme.neonGradient : null,
                                    color: selected
                                        ? null
                                        : AppTheme.cardColorLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.transparent
                                          : AppTheme.neonPink.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    '${opt.$3} ${opt.$2}',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          NeonCard(
                            onTap: _pickPeriodStart,
                            borderRadius: 20,
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                const Text('📅', style: TextStyle(fontSize: 28)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Дата начала последних',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cycle.lastPeriodStart == null
                                            ? 'Не указана — нажми, чтобы выбрать'
                                            : _fmt(cycle.lastPeriodStart!),
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          NeonCard(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline,
                                    color: AppTheme.neonPinkLight, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Статус обновляет только она. Ты видишь актуальную плашку в реальном времени.',
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 13,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.day} ${kMonthNames[d.month - 1]} ${d.year}';
  }
}
