import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/particle_bg.dart';
import '../models/mood_state.dart';
import '../services/local_storage.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with TickerProviderStateMixin {
  late LocalStorage _storage;
  late AnimationController _heartbeatCtrl;
  late AnimationController _particleCtrl;
  MoodType? _selectedMood;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _storage.load().then((_) {
      if (mounted) {
        setState(() {
          _selectedMood = _storage.mood.myMood;
        });
      }
    });
    _storage.addListener(_onStorageUpdate);

    _heartbeatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _onStorageUpdate() {
    if (mounted) {
      setState(() {
        _selectedMood = _storage.mood.myMood;
      });
    }
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    _heartbeatCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _selectMood(MoodType mood) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedMood = mood);
    await _storage.setMyMood(mood);

    if (mood == MoodType.thinkingOfYou || mood == MoodType.wantHug) {
      _heartbeatCtrl.repeat(reverse: true);
    } else {
      _heartbeatCtrl.stop();
      _heartbeatCtrl.reset();
    }

    if (mood == MoodType.sad) {
      _showLoveBomb();
    }
  }

  void _showLoveBomb() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.neonCardDecoration(
            borderOpacity: 0.4,
            glowOpacity: 0.3,
            radius: 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💝', style: TextStyle(fontSize: 64))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.2, duration: 800.ms),
              const SizedBox(height: 16),
              const GradientText(
                text: 'Я рядом 💕',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Всё будет хорошо.\nТы не одна/один ❤️',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.neonGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonPink.withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Text(
                    '💕 Спасибо',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(
            begin: const Offset(0.8, 0.8),
            duration: 400.ms,
            curve: Curves.elasticOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['💭', '💕', '✨', '🌸', '💫'],
            particleCount: 14,
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildMoodSummary(),
                  const SizedBox(height: 20),
                  const Text('Моё настроение',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _buildMyMoodGrid(),
                  const SizedBox(height: 20),
                  _buildPartnerView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (Navigator.of(context).canPop()) ...[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.textSecondary,
            tooltip: 'Назад',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientText(
              text: 'Настроение 💭',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'как ты сейчас?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildMoodSummary() {
    final mine = _storage.mood.myMood;
    final partner = _storage.mood.partnerMood;
    final partnerName = _storage.partnerProfile?.displayName ?? 'Партнёр';
    return Row(
      children: [
        Expanded(child: _summaryCard('Моё', mine, 'Выбери своё настроение')),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(partnerName, partner, 'Пока не выбрано')),
      ],
    );
  }

  Widget _summaryCard(String title, MoodType? mood, String emptyLabel) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          Text(mood?.emoji ?? '—', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 5),
          Text(mood?.label ?? emptyLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMyMoodGrid() {
    return GridView.builder(
      key: const ValueKey('my'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: MoodType.values.length,
      itemBuilder: (ctx, i) => _buildMoodCard(MoodType.values[i], i),
    );
  }

  Widget _buildMoodCard(MoodType mood, int index) {
    final isSelected = _selectedMood == mood;

    return GestureDetector(
      onTap: () => _selectMood(mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    mood.accentColor.withOpacity(0.8),
                    mood.accentColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF1E1030), Color(0xFF12121A)],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.neonPink.withOpacity(0.6)
                : AppTheme.neonPink.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.accentColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppTheme.neonPink.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: -8,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mood.emoji,
                    style: TextStyle(fontSize: isSelected ? 30 : 26)),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.neonGradient,
                    ),
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  mood.subtitle,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildPartnerView() {
    final partnerMood = _storage.mood.partnerMood;
    final partnerName = _storage.partnerProfile?.displayName ?? 'Партнёр';

    return Column(
      key: const ValueKey('partner'),
      children: [
        if (partnerMood == null)
          _buildNoMoodCard()
        else
          _buildPartnerMoodCard(partnerMood),
        const SizedBox(height: 16),
        NeonCard(
          borderRadius: 20,
          child: Row(
            children: [
              const Icon(Icons.sync, color: AppTheme.neonPinkLight, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Настроение $partnerName обновляется автоматически, когда она/он меняет его у себя.',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoMoodCard() {
    return NeonCard(
      borderRadius: 24,
      child: Column(
        children: [
          const Text('💤', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          GradientText(
            text: 'Партнёр молчит',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Настроение ещё не выбрано',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerMoodCard(MoodType mood) {
    final isThinkingOfYou = mood == MoodType.thinkingOfYou;
    final isWantHug = mood == MoodType.wantHug;
    final isSad = mood == MoodType.sad;

    return AnimatedBuilder(
      animation: _heartbeatCtrl,
      builder: (_, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mood.accentColor.withOpacity(0.6),
              mood.accentColor.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: (isThinkingOfYou || isWantHug)
                ? AppTheme.neonPink
                    .withOpacity(0.3 + _heartbeatCtrl.value * 0.4)
                : AppTheme.neonPink.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: mood.accentColor.withOpacity(
                  0.2 + (isThinkingOfYou ? _heartbeatCtrl.value * 0.2 : 0)),
              blurRadius: 30,
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
      ),
      child: Column(
        children: [
          Text(
            mood.emoji,
            style: const TextStyle(fontSize: 64),
          )
              .animate(
                onPlay: (c) => (isThinkingOfYou || isWantHug || isSad)
                    ? c.repeat(reverse: true)
                    : null,
              )
              .scaleXY(
                begin: 1,
                end: (isThinkingOfYou || isWantHug) ? 1.15 : 1.0,
                duration: 800.ms,
              ),
          const SizedBox(height: 12),
          GradientText(
            text: mood.label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mood.subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
            ),
          ),
          if (isThinkingOfYou || isWantHug) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.neonPink.withOpacity(0.3),
                ),
              ),
              child: Text(
                isWantHug ? '🤗 Она/он хочет тебя обнять!' : '❤️ Думает о тебе',
                style: const TextStyle(
                  color: AppTheme.neonPinkLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (isSad) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showLoveBomb,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.neonGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPink.withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Text(
                  '💝 Отправить поддержку',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
