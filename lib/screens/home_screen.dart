import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_bg.dart';
import '../widgets/neon_card.dart';
import '../services/local_storage.dart';
import 'mens_tracker_screen.dart';
import 'pigeon_screen.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late LocalStorage _storage;
  late AnimationController _heartCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _storage.load().then((_) => setState(() {}));
    _storage.addListener(_onStorageUpdate);

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _heartScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    _heartCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _storage.startDate ?? now,
      firstDate: DateTime(2000),
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
      await _storage.setStartDate(picked);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['💕', '✨', '🌸', '💫', '⭐', '🌙'],
            particleCount: 20,
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
                  _buildCycleCard(),
                  const SizedBox(height: 16),
                  _buildDaysCounter(),
                  const SizedBox(height: 24),
                  _buildMiniCards(),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 8),
                  _buildAccountActions(),
                  const SizedBox(height: 24),
                  _buildMilestonesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final me = _storage.myProfile?.displayName;
    final partner = _storage.partnerProfile?.displayName;
    final subtitle = (me != null && partner != null)
        ? '$me & $partner'
        : (me != null ? 'привет, $me' : 'только ты и я');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                text: 'Ours 💕',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileSetupScreen(isEditing: true),
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _heartScale,
            builder: (_, __) => Transform.scale(
              scale: _heartScale.value,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonPink, AppTheme.neonPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPink.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('❤️', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0, 0)),
      ],
    );
  }

  Widget _buildCycleCard() {
    final cycle = _storage.cycle;
    final isGirl = _storage.isGirl;
    final partner = _storage.partnerProfile?.displayName ?? 'она';
    final title = isGirl ? 'Сейчас у меня' : 'У $partner сегодня';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MensTrackerScreen()),
      ),
      child: NeonCard(
        borderRadius: 22,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(cycle.statusEmoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cycle.status(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (cycle.dayInCycle() != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'День цикла: ${cycle.dayInCycle()}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildDaysCounter() {
    final days = _storage.daysTogether;
    final hasDate = _storage.startDate != null;

    return GestureDetector(
      onTap: _pickStartDate,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1030), Color(0xFF0D0D1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppTheme.neonPink.withOpacity(0.2 + _pulse.value * 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppTheme.neonPink.withOpacity(0.08 + _pulse.value * 0.12),
                blurRadius: 32,
                spreadRadius: -4,
              ),
              BoxShadow(
                color:
                    AppTheme.neonPurple.withOpacity(0.05 + _pulse.value * 0.08),
                blurRadius: 60,
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        ),
        child: Column(
          children: [
            Text(
              'ВМЕСТЕ',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (hasDate)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppTheme.neonGradient.createShader(bounds),
                child: Text(
                  '$days',
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -4,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).then(delay: 2000.ms).custom(
                    duration: 200.ms,
                    builder: (_, value, child) => child,
                  )
            else
              Column(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    'Нажми, чтобы\nвыбрать нашу дату',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.neonPink.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              hasDate
                  ? (days == 1
                      ? 'день'
                      : days < 5
                          ? 'дня'
                          : 'дней')
                  : '',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            if (hasDate) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.neonPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.neonPink.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'с ${_formatDate(_storage.startDate!)} 💕',
                  style: const TextStyle(
                    color: AppTheme.neonPinkLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildMiniCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            emoji: '🎁',
            title: 'Вишлист',
            value: '${_storage.activeWishes.length}',
            subtitle: 'желаний',
            delay: 400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            emoji: '💭',
            title: 'Настрой',
            value: _storage.mood.myMood?.emoji ?? '—',
            subtitle: _storage.mood.myMood?.label ?? 'не выбрано',
            delay: 500,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
    required int delay,
  }) {
    return NeonCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.neonPinkLight,
              fontSize: value.length <= 2 ? 28 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildMilestonesCard() {
    final days = _storage.daysTogether;
    final milestones = [
      (30, '1 месяц', '🌸'),
      (100, '100 дней', '💯'),
      (180, 'Полгода', '🌺'),
      (365, '1 год', '🎊'),
      (500, '500 дней', '⭐'),
      (730, '2 года', '💎'),
    ];

    final nextMilestone = milestones.firstWhere(
      (m) => m.$1 > days,
      orElse: () => (days + 365, 'следующий', '✨'),
    );
    final daysLeft = nextMilestone.$1 - days;
    final progress =
        days / nextMilestone.$1 > 1 ? 1.0 : days / nextMilestone.$1;

    return NeonCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(nextMilestone.$3, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'До ${nextMilestone.$2}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonPink, AppTheme.neonPurple],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft дн.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.cardColorLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.neonPink),
            ),
          ).animate().custom(
                delay: 800.ms,
                duration: 1200.ms,
                curve: Curves.easeOutCubic,
                builder: (_, value, child) => ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: child,
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: milestones.map((m) {
              final done = days >= m.$1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.neonPink.withOpacity(0.2)
                      : AppTheme.cardColorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: done
                        ? AppTheme.neonPink.withOpacity(0.5)
                        : AppTheme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${m.$3} ${m.$2}',
                  style: TextStyle(
                    color: done ? AppTheme.neonPinkLight : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildQuickActions() {
    final hasPigeon = _storage.hasUnreadPigeon;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MensTrackerScreen())),
            child: NeonCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text(
                    _storage.isGirl ? 'Мой цикл' : 'Её цикл',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storage.cycle.status(),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PigeonScreen())),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                NeonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 18,
                  borderOpacity: hasPigeon ? 0.55 : 0.3,
                  glowOpacity: hasPigeon ? 0.28 : 0.12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasPigeon ? '💌' : '✉️',
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 8),
                      const Text('Голубь',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        hasPigeon
                            ? 'Новое письмо!'
                            : (_storage.canSendPigeonToday
                                ? '1 письмо в день'
                                : 'Уже отправлено'),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasPigeon
                              ? AppTheme.neonPinkLight
                              : AppTheme.textSecondary,
                          fontWeight:
                              hasPigeon ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPigeon)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.neonPink,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1, end: 1.4, duration: 800.ms),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileSetupScreen(isEditing: true),
              ),
            );
          },
          child: const Text(
            'Редактировать профиль',
            style: TextStyle(color: AppTheme.neonPinkLight, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () async {
            HapticFeedback.selectionClick();
            LocalStorage().clearCoupleId();
            await FirebaseAuth.instance.signOut();
          },
          child: const Text(
            'Выйти из аккаунта',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
