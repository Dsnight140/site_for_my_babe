import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/local_storage.dart';
import '../models/pigeon_message.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_bg.dart';
import '../widgets/neon_card.dart';

class PigeonScreen extends StatefulWidget {
  const PigeonScreen({super.key});

  @override
  State<PigeonScreen> createState() => _PigeonScreenState();
}

class _PigeonScreenState extends State<PigeonScreen> {
  final _storage = LocalStorage();
  bool _opening = false;
  bool _letterOpen = false;

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

  Future<void> _compose() async {
    if (!_storage.canSendPigeonToday ||
        _storage.outgoingPendingPigeon != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_storage.outgoingPendingPigeon != null
              ? 'Письмо ещё ждёт прочтения'
              : 'Сегодня голубь уже улетел. Завтра снова ⏳'),
          backgroundColor: AppTheme.cardColorLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final controller = TextEditingController();
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientText(
                text: 'Написать письмо ✉️',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Одно письмо в день. После прочтения оно исчезнет у обоих.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 6,
                autofocus: true,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Милый текст...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.cardColorLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppTheme.neonPink.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppTheme.neonPink.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.neonPink, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.neonGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Отправить голубя 🕊️',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (res == true && controller.text.trim().isNotEmpty) {
      final ok = await _storage.sendPigeon(controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Голубь улетел! 🕊️'
              : 'Сегодня уже отправляли или письмо ждёт прочтения'),
          backgroundColor: ok ? AppTheme.neonPink : AppTheme.cardColorLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openIncoming(PigeonMessage msg) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _letterOpen = false;
    });
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _letterOpen = true);
  }

  Future<void> _finishReading(PigeonMessage msg) async {
    HapticFeedback.lightImpact();
    await _storage.markPigeonReadAndDelete(msg.id);
    if (!mounted) return;
    setState(() {
      _opening = false;
      _letterOpen = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Письмо прочитано и исчезло ✨'),
        backgroundColor: AppTheme.neonPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incoming = _storage.incomingPigeon;
    final outgoing = _storage.outgoingPendingPigeon;
    final partnerName =
        _storage.partnerProfile?.displayName ?? 'половинке';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['🕊️', '💌', '✨', '☁️', '💕'],
            particleCount: 15,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                        text: 'Голубь 🕊️',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Одно письмо в день. Открой — и оно исчезнет навсегда.',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      if (incoming != null) ...[
                        if (!_opening)
                          _SealedEnvelope(
                            fromName: incoming.senderName ?? partnerName,
                            onOpen: () => _openIncoming(incoming),
                          )
                        else
                          _OpenLetter(
                            msg: incoming,
                            revealed: _letterOpen,
                            onDone: () => _finishReading(incoming),
                          ),
                        const SizedBox(height: 20),
                      ],
                      if (outgoing != null)
                        NeonCard(
                          borderRadius: 22,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Text('✈️', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Письмо в пути',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ждёт, пока $partnerName откроет его.\nПосле прочтения исчезнет у обоих.',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                          height: 1.35),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat('d MMM, HH:mm')
                                          .format(outgoing.sentAt.toLocal()),
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                      if (incoming == null && outgoing == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            children: [
                              const Text('📭', style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                'Пока тихо',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _storage.canSendPigeonToday
                                    ? 'Напиши $partnerName первое письмо сегодня'
                                    : 'Сегодня ты уже отправлял(а). До завтра!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ).animate().fadeIn(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 90,
            child: GestureDetector(
              onTap: _compose,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.neonGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPink.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 28),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.05, duration: 1500.ms),
          ),
        ],
      ),
    );
  }
}

class _SealedEnvelope extends StatelessWidget {
  final String fromName;
  final VoidCallback onOpen;

  const _SealedEnvelope({required this.fromName, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: NeonCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(28),
        glowOpacity: 0.22,
        borderOpacity: 0.45,
        child: Column(
          children: [
            const Text('💌', style: TextStyle(fontSize: 72))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.08, duration: 1200.ms)
                .shimmer(duration: 2200.ms, color: AppTheme.neonPinkLight),
            const SizedBox(height: 16),
            GradientText(
              text: 'Письмо от $fromName',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажми, чтобы вскрыть конверт',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.neonGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Открыть письмо',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.12, end: 0);
  }
}

class _OpenLetter extends StatelessWidget {
  final PigeonMessage msg;
  final bool revealed;
  final VoidCallback onDone;

  const _OpenLetter({
    required this.msg,
    required this.revealed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: revealed ? 1 : 0.35,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1A30), Color(0xFF1A1224)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.neonPink.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPink.withOpacity(0.2),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🕊️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'От ${msg.senderName ?? 'половинки'}',
                  style: const TextStyle(
                      color: AppTheme.neonPinkLight,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM').format(msg.sentAt.toLocal()),
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!revealed)
              const Center(
                child: Text('Вскрываем конверт...',
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              Text(
                msg.content,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0),
            if (revealed) ...[
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.neonGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Прочитано — отпустить письмо',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
