import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/pair_photo.dart';
import '../services/local_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/particle_bg.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _storage = LocalStorage();
  final _picker = ImagePicker();
  final _uuid = const Uuid();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _storage.load();
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

  Future<void> _addPhoto() async {
    if (_uploading) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (picked == null) return;

    final coupleId = _storage.coupleId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || uid == null) {
      return;
    }

    setState(() => _uploading = true);
    final id = _uuid.v4();
    try {
      final bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('couples/$coupleId/photos/$id.jpg');
      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      await _storage.addPhoto(PairPhoto(
        id: id,
        url: url,
        uploadedAt: DateTime.now(),
        uploadedBy: uid,
      ));
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(
            'Не получилось загрузить фото: ${error.message ?? error.code}');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.cardColorLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _storage.photos;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['📸', '💕', '✨', '🌸'],
            particleCount: 12,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: GradientText(
                    text: 'Наша медиатека 📸',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Новые моменты сверху, старые остаются с нами',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: photos.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.86,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (_, index) =>
                              _buildPhotoTile(photos[index], index),
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 110,
            child: GestureDetector(
              onTap: _addPhoto,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.neonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPink.withOpacity(0.45),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: _uploading
                    ? const Padding(
                        padding: EdgeInsets.all(17),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_a_photo_rounded,
                        color: Colors.white),
              ),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.05, duration: 1400.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        child: NeonCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📷', style: TextStyle(fontSize: 58)),
              const SizedBox(height: 14),
              const Text(
                'Здесь будут ваши моменты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавьте первое фото вашей пары',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.94, 0.94)),
      ),
    );
  }

  Widget _buildPhotoTile(PairPhoto photo, int index) {
    return GestureDetector(
      onLongPress: () async {
        await _storage.deletePhoto(photo.id);
      },
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            photo.url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.cardColorLight,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppTheme.textMuted),
            ),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    color: AppTheme.cardColorLight,
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.neonPink),
                    ),
                  ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 60), duration: 400.ms)
        .slideY(
          begin: 0.08,
          end: 0,
        );
  }
}
