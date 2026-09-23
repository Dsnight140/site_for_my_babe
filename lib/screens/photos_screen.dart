import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/pair_photo.dart';
import '../services/local_storage.dart';
import '../services/cloudinary_service.dart';
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
  final _cloudinary = CloudinaryService();
  bool _uploading = false;
  bool _showTrash = false;

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

  Future<void> _addPhoto() => _pickAndUpload(ImageSource.camera);

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_uploading) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (picked == null) return;

    final coupleId = _storage.coupleId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || uid == null) {
      _showMessage('Не найден аккаунт или пара. Перезапусти приложение.');
      return;
    }

    setState(() => _uploading = true);
    final id = _uuid.v4();
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('Файл пустой');
      final url = await _cloudinary.uploadImage(
        bytes: bytes,
        fileName: '$id.jpg',
        folder: 'ours/$coupleId/photos',
      );
      final note = await _askNote();
      await _storage.addPhoto(PairPhoto(
        id: id,
        url: url,
        uploadedAt: DateTime.now(),
        uploadedBy: uid,
        note: note,
      ));
    } on CloudinaryException catch (error) {
      debugPrint('Cloudinary photo upload failed: $error');
      if (mounted) {
        _showMessage('Фото не отправлено: $error');
      }
    } on Exception catch (error) {
      debugPrint('Photo upload failed: $error');
      if (mounted) _showMessage('Не получилось загрузить фото: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _askNote() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Добавить момент', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Заметка (необязательно)',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Сохранить момент'),
              ),
            ),
          ],
        ),
      ),
    );
    return result == null || result.isEmpty ? null : result;
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
    final photos = _showTrash ? _storage.deletedPhotos : _storage.photos;
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GradientText(
                          text:
                              _showTrash ? 'Корзина 🗑️' : 'Наша медиатека 📸',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Выбрать из галереи',
                        onPressed: _showTrash
                            ? null
                            : () => _pickAndUpload(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                      ),
                      IconButton(
                        tooltip:
                            _showTrash ? 'Закрыть корзину' : 'Открыть корзину',
                        onPressed: () =>
                            setState(() => _showTrash = !_showTrash),
                        icon: Icon(_showTrash
                            ? Icons.close_rounded
                            : Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _showTrash
                        ? 'Удалённые моменты можно восстановить'
                        : 'Сними момент камерой или выбери фото из галереи',
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
          if (!_showTrash)
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
      onTap: () => _showPhotoActions(photo),
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
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
                          child: CircularProgressIndicator(
                              color: AppTheme.neonPink),
                        ),
                      ),
              ),
              if (photo.note != null && photo.note!.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    photo.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),
            ],
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

  Future<void> _showPhotoActions(PairPhoto photo) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Изменить заметку'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(_showTrash
                  ? Icons.restore_rounded
                  : Icons.delete_outline_rounded),
              title:
                  Text(_showTrash ? 'Восстановить' : 'Переместить в корзину'),
              onTap: () => Navigator.pop(ctx, 'toggle'),
            ),
            if (_showTrash)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded),
                title: const Text('Удалить навсегда'),
                onTap: () => Navigator.pop(ctx, 'permanent'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final note = await _askNote();
      await _storage.updatePhotoNote(photo.id, note);
    } else if (action == 'toggle') {
      if (_showTrash) {
        await _storage.restorePhoto(photo.id);
      } else {
        await _storage.deletePhoto(photo.id);
      }
    } else if (action == 'permanent') {
      await _storage.permanentlyDeletePhoto(photo.id);
    }
  }
}
