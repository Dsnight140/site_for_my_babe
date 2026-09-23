import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_bg.dart';
import '../widgets/neon_card.dart';
import '../services/local_storage.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isJoining = false;
  String? _myCode;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _coupleWatch;

  @override
  void initState() {
    super.initState();
    _checkOrCreateInviteCode();
  }

  @override
  void dispose() {
    _coupleWatch?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _checkOrCreateInviteCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(user.uid).get();
      final existing = userDoc.data()?['myInviteCode'] as String?;

      if (existing != null && existing.isNotEmpty) {
        _myCode = existing;
      } else {
        String code;
        DocumentSnapshot? coupleSnap;
        do {
          code = _generateCode();
          coupleSnap = await db.collection('couples').doc(code).get();
        } while (coupleSnap.exists);

        _myCode = code;

        await db.collection('users').doc(user.uid).set({
          'email': user.email,
          'myInviteCode': _myCode,
          'coupleId': null,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await db.collection('couples').doc(_myCode).set({
          'partner1_uid': user.uid,
          'partner2_uid': null,
          'inviteCode': _myCode,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (_myCode != null) {
        _watchForPartner(_myCode!);
      }
    } catch (e) {
      _error = 'Ошибка создания кода';
      debugPrint('Invite code error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _watchForPartner(String code) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _coupleWatch?.cancel();
    _coupleWatch = FirebaseFirestore.instance
        .collection('couples')
        .doc(code)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final p2 = snap.data()?['partner2_uid'];
      if (p2 == null || p2.toString().isEmpty) return;
      // Partner joined — set our own coupleId so AuthWrapper opens MainShell
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'coupleId': code,
      }, SetOptions(merge: true));
    });
  }

  Future<void> _joinCouple() async {
    HapticFeedback.mediumImpact();
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      setState(() => _error = 'Введите 6-символьный код');
      return;
    }

    if (code == _myCode) {
      setState(() => _error = 'Нельзя ввести свой собственный код');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      final myDoc = await db.collection('users').doc(user.uid).get();
      final myCoupleId = myDoc.data()?['coupleId'];
      if (myCoupleId is String && myCoupleId.isNotEmpty) {
        setState(() => _error = 'Ты уже в паре');
        return;
      }

      await db.runTransaction((tx) async {
        final coupleRef = db.collection('couples').doc(code);
        final coupleSnap = await tx.get(coupleRef);

        if (!coupleSnap.exists) {
          throw Exception('Код не найден');
        }

        final data = coupleSnap.data()!;
        final p1 = data['partner1_uid'] as String?;
        final p2 = data['partner2_uid'];

        if (p1 == user.uid) {
          throw Exception('Нельзя ввести свой собственный код');
        }
        if (p2 != null && p2.toString().isNotEmpty) {
          throw Exception('Эта пара уже заполнена');
        }

        tx.update(coupleRef, {'partner2_uid': user.uid});
        tx.set(
          db.collection('users').doc(user.uid),
          {
            'coupleId': code,
            'email': user.email,
          },
          SetOptions(merge: true),
        );
      });
      // Partner1 picks up partner2 via their couple listener and sets own coupleId.
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg.contains('Код') ||
              msg.contains('пар') ||
              msg.contains('свой')
          ? msg
          : 'Ошибка соединения');
      debugPrint('Join couple error: $e');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['💍', '💕', '✨', '🌸'],
            particleCount: 15,
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonPink))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('💍',
                                style: TextStyle(fontSize: 64),
                                textAlign: TextAlign.center)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 1, end: 1.1, duration: 2000.ms),
                        const SizedBox(height: 24),
                        GradientText(
                          text: 'Поиск половинки',
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Чтобы войти в ваше пространство,\nнужно связать аккаунты.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 48),
                        NeonCard(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'Твой код приглашения',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              SelectableText(
                                _myCode ?? '------',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 8,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Отправь его своей половинке',
                                    style: TextStyle(
                                        color: AppTheme.neonPinkLight,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      if (_myCode != null) {
                                        Clipboard.setData(
                                            ClipboardData(text: _myCode!));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Код скопирован ✅'),
                                            backgroundColor:
                                                AppTheme.neonPink,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonPink
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.copy_outlined,
                                          color: AppTheme.neonPinkLight,
                                          size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 40),
                        const Row(
                          children: [
                            Expanded(
                                child: Divider(color: AppTheme.dividerColor)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('ИЛИ',
                                  style: TextStyle(color: AppTheme.textMuted)),
                            ),
                            Expanded(
                                child: Divider(color: AppTheme.dividerColor)),
                          ],
                        ),
                        const SizedBox(height: 40),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 14),
                              textAlign: TextAlign.center,
                            ).animate().shakeX(),
                          ),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ВВЕДИ КОД',
                            counterText: '',
                            hintStyle: TextStyle(
                                color: AppTheme.textMuted.withOpacity(0.5)),
                            filled: true,
                            fillColor: AppTheme.cardColorLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: AppTheme.neonPink.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: AppTheme.neonPink.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppTheme.neonPink, width: 2),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),
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
                              onPressed: _isJoining ? null : _joinCouple,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isJoining
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Присоединиться 💕',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () async {
                            LocalStorage().clearCoupleId();
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text(
                            'Выйти из аккаунта',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
