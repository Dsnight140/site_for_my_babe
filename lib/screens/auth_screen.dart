import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/particle_bg.dart';
import '../widgets/neon_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'coupleId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();

      if (email.isEmpty || pass.isEmpty) {
        throw Exception('Заполни все поля');
      }
      if (!_isLogin && pass.length < 6) {
        throw Exception('Пароль должен быть не короче 6 символов');
      }

      if (_isLogin) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
        if (cred.user != null) {
          await _ensureUserDoc(cred.user!);
        }
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        if (cred.user != null) {
          await _ensureUserDoc(cred.user!);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        final details = '${e.message} ${e.toString()}'.toLowerCase();
        if (details.contains('configuration_not_found') ||
            e.code == 'internal-error' ||
            e.code == 'CONFIGURATION_NOT_FOUND') {
          _error =
              'Firebase Auth не включён.\nОткрой Console → Authentication → Sign-in method → Email/Password → Enable';
          return;
        }
        switch (e.code) {
          case 'user-not-found':
            _error = 'Пользователь не найден';
          case 'wrong-password':
          case 'invalid-credential':
            _error = 'Неверный email или пароль';
          case 'email-already-in-use':
            _error = 'Такой email уже зарегистрирован';
          case 'invalid-email':
            _error = 'Некорректный email';
          case 'weak-password':
            _error = 'Слишком простой пароль';
          case 'too-many-requests':
            _error = 'Слишком много попыток. Подожди немного';
          case 'network-request-failed':
            _error = 'Нет сети. Проверь интернет';
          default:
            _error = 'Ошибка авторизации (${e.code})';
        }
      });
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('CONFIGURATION_NOT_FOUND')) {
        setState(() => _error =
            'Firebase Auth не включён.\nОткрой Console → Authentication → Sign-in method → Email/Password → Enable');
      } else {
        setState(() => _error = raw.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            particleCount: 15,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('💕',
                            style: TextStyle(fontSize: 72),
                            textAlign: TextAlign.center)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1, end: 1.1, duration: 1200.ms),
                    const SizedBox(height: 24),
                    GradientText(
                      text: _isLogin ? 'С возвращением!' : 'Создать аккаунт',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ours — только для вас двоих',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 48),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn().shakeX(),
                    _buildTextField(
                        _emailCtrl, 'Email', Icons.email_rounded, false),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _passCtrl, 'Пароль', Icons.lock_rounded, true),
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
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isLogin ? 'Войти' : 'Продолжить',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isLogin = !_isLogin;
                                _error = null;
                              });
                            },
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: TextStyle(
                            color: AppTheme.neonPinkLight, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
      onSubmitted: obscure ? (_) => _submit() : null,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
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
      ),
    );
  }
}
