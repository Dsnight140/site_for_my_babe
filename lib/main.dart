import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/local_storage.dart';
import 'services/notification_service.dart';
import 'models/user_profile.dart';
import 'screens/auth_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/mood_screen.dart';
import 'screens/photos_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
    ),
  );
  runApp(const OursApp());
}

class OursApp extends StatelessWidget {
  const OursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ours 💕',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.neonPink),
            ),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.backgroundDark,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.neonPink),
                ),
              );
            }

            final data = userSnapshot.data?.data() as Map<String, dynamic>?;
            final rawCoupleId = data?['coupleId'];
            final coupleId = (rawCoupleId is String && rawCoupleId.isNotEmpty)
                ? rawCoupleId
                : null;

            if (coupleId == null) {
              return const PairingScreen();
            }

            if (!UserProfile.isProfileComplete(data)) {
              return const ProfileSetupScreen();
            }

            return MainShell(coupleId: coupleId);
          },
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final String coupleId;
  const MainShell({super.key, required this.coupleId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _bgController;

  final List<Widget> _screens = const [
    HomeScreen(),
    WishlistScreen(),
    MoodScreen(),
    PhotosScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final storage = LocalStorage();
    storage.setCoupleId(widget.coupleId);
    storage.load();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coupleId != widget.coupleId) {
      LocalStorage().setCoupleId(widget.coupleId);
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (ctx, _) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(t * 2 * math.pi) * 0.3,
                      math.cos(t * 2 * math.pi) * 0.3,
                    ),
                    radius: 1.2,
                    colors: [
                      AppTheme.neonPink.withOpacity(0.06),
                      AppTheme.neonPurple.withOpacity(0.04),
                      AppTheme.backgroundDark,
                    ],
                  ),
                ),
              );
            },
          ),
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: '🏠',
            label: 'Главная',
            index: 0,
            currentIndex: _currentIndex,
            onTap: _onTap,
          ),
          _NavItem(
            icon: '🎁',
            label: 'Виш',
            index: 1,
            currentIndex: _currentIndex,
            onTap: _onTap,
          ),
          _NavItem(
            icon: '☁️',
            label: 'Настрой',
            index: 2,
            currentIndex: _currentIndex,
            onTap: _onTap,
          ),
          _NavItem(
            icon: '📸',
            label: 'Фото',
            index: 3,
            currentIndex: _currentIndex,
            onTap: _onTap,
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, curve: Curves.easeOutCubic, duration: 600.ms)
        .fadeIn();
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppTheme.neonPink, AppTheme.neonPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.neonPink.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            if (isActive) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
