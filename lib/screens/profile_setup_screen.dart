import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/local_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/particle_bg.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;
  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  PartnerRole? _role;
  DateTime? _birthday;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = LocalStorage().myProfile;
    if (existing != null) {
      _nameCtrl.text = existing.displayName;
      _role = existing.role;
      _birthday = existing.birthday;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
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
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Как тебя зовут?');
      return;
    }
    if (_role == null) {
      setState(() => _error = 'Выбери, кто ты в паре');
      return;
    }
    if (_birthday == null) {
      setState(() => _error = 'Укажи день рождения');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = UserProfile(
        uid: uid,
        displayName: name,
        role: _role!,
        birthday: _birthday,
        lastPigeonSentAt: LocalStorage().myProfile?.lastPigeonSentAt,
      );
      await LocalStorage().saveProfile(profile);
      if (widget.isEditing && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Не удалось сохранить профиль');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['💕', '✨', '🌸', '💫'],
            particleCount: 12,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEditing)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                  const Text('🪞',
                          style: TextStyle(fontSize: 56),
                          textAlign: TextAlign.center)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1, end: 1.08, duration: 1400.ms),
                  const SizedBox(height: 16),
                  GradientText(
                    text: widget.isEditing ? 'Профиль' : 'Расскажи о себе',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Имя, роль и день рождения —\nчтобы приложение понимало вас двоих.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: _fieldDecoration('Имя', Icons.person_rounded),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Кто ты?',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleChip(
                          emoji: '👦',
                          label: 'Парень',
                          selected: _role == PartnerRole.guy,
                          onTap: () => setState(() => _role = PartnerRole.guy),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleChip(
                          emoji: '👧',
                          label: 'Девушка',
                          selected: _role == PartnerRole.girl,
                          onTap: () => setState(() => _role = PartnerRole.girl),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickBirthday,
                    child: NeonCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_rounded,
                              color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _birthday == null
                                  ? 'День рождения'
                                  : _formatDate(_birthday!),
                              style: TextStyle(
                                color: _birthday == null
                                    ? AppTheme.textMuted
                                    : AppTheme.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (_birthday != null)
                            Text(
                              '${UserProfile(uid: '', displayName: 'x', role: PartnerRole.guy, birthday: _birthday).age} лет',
                              style: const TextStyle(
                                  color: AppTheme.neonPinkLight, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.neonGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonPink.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                widget.isEditing
                                    ? 'Сохранить'
                                    : 'Продолжить 💕',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          LocalStorage().clearCoupleId();
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                        child: Text(
                          'Выйти из аккаунта',
                          style: TextStyle(
                            color: Colors.redAccent.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      filled: true,
      fillColor: AppTheme.cardColorLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.neonPink.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.neonPink.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.neonPink, width: 1.5),
      ),
    );
  }

  String _formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _RoleChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.neonGradient : null,
          color: selected ? null : AppTheme.cardColorLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.neonPink.withOpacity(0.2),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.neonPink.withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
