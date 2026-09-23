import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_entry.dart';
import '../services/local_storage.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/neon_card.dart';
import '../widgets/particle_bg.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _storage = LocalStorage();
  final _picker = ImagePicker();
  final _uuid = const Uuid();
  final _cloudinary = CloudinaryService();
  bool _uploading = false;
  DateTime? _selectedDate;

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

  Future<void> _addMemory() async {
    if (_uploading) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (picked == null) return;

    final coupleId = _storage.coupleId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (coupleId == null || uid == null) return;

    setState(() => _uploading = true);
    final id = _uuid.v4();
    try {
      final bytes = await picked.readAsBytes();
      final url = await _cloudinary.uploadImage(
        bytes: bytes,
        fileName: '$id.jpg',
        folder: 'ours/$coupleId/memories',
      );

      final date = _selectedDate ?? DateTime.now();
      await _storage.addMemory(MemoryEntry(
        id: id,
        title: formatDateRussian(date),
        note: '',
        date: date,
        photoUrl: url,
        createdAt: DateTime.now(),
        creatorId: uid,
      ));
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Не получилось загрузить фото: ${error.toString()}');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addTextMemory() async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<bool>(
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
                text: 'Новая запись ✍️',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавь заметку к дате — она сохранится для вас двоих.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Что вспомнил(а)?',
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 88,
                    maxWidth: 2400,
                  );
                  if (picked == null || _storage.coupleId == null) {
                    return;
                  }
                  setState(() => _uploading = true);
                  try {
                    final bytes = await picked.readAsBytes();
                    if (bytes.isEmpty) throw Exception('Файл пустой');
                    final uploadId = _uuid.v4();
                    final url = await _cloudinary.uploadImage(
                      bytes: bytes,
                      fileName: '$uploadId.jpg',
                      folder: 'ours/${_storage.coupleId}/memories',
                    );
                    if (mounted) setState(() => _pendingPhotoUrl = url);
                  } on Exception catch (error) {
                    if (mounted)
                      _showMessage('Не получилось загрузить фото: $error');
                  } finally {
                    if (mounted) setState(() => _uploading = false);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColorLight,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.neonPink.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined,
                          color: AppTheme.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _pendingPhotoUrl != null
                            ? 'Фото выбрано ✅'
                            : 'Добавить фото',
                        style: TextStyle(
                            color: _pendingPhotoUrl != null
                                ? AppTheme.neonPinkLight
                                : AppTheme.textSecondary,
                            fontSize: 13),
                      ),
                    ],
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
                      'Сохранить в память 💕',
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

    if (result == true && controller.text.trim().isNotEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final memory = MemoryEntry(
        id: _uuid.v4(),
        title: _selectedDate != null
            ? formatDateRussian(_selectedDate!)
            : DateFormat('d MMM', 'ru').format(DateTime.now()),
        note: controller.text.trim(),
        date: _selectedDate ?? DateTime.now(),
        photoUrl: _pendingPhotoUrl,
        createdAt: DateTime.now(),
        creatorId: uid,
      );
      await _storage.addMemory(memory);
      _pendingPhotoUrl = null;
      _selectedDate = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Запись сохранена 📝'),
          backgroundColor: AppTheme.neonPink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    _pendingPhotoUrl = null;
  }

  String? _pendingPhotoUrl;

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
    final memories = _storage.memories;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['📝', '💕', '✨', '🌹', '📸'],
            particleCount: 12,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: GradientText(
                    text: 'Воспоминания 📝',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Записи по датам — с фото и заметками',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: memories.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          itemCount: memories.length,
                          itemBuilder: (_, index) =>
                              _buildMemoryTile(memories[index], index),
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 110,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _addTextMemory,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.neonPurple, AppTheme.neonPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonPurple.withOpacity(0.45),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 26),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.05, duration: 1500.ms),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addMemory,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      shape: BoxShape.circle,
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
                        : const Icon(Icons.photo_camera_rounded,
                            color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
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
              const Text('📝', style: TextStyle(fontSize: 58)),
              const SizedBox(height: 14),
              const Text(
                'Здесь будут ваши воспоминания',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавьте первую запись — текст или фото с датой',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.94, 0.94)),
      ),
    );
  }

  Widget _buildMemoryTile(MemoryEntry memory, int index) {
    return GestureDetector(
      onTap: () {
        _selectedDate = memory.date;
        _addTextMemory();
      },
      child: Hero(
        tag: memory.id,
        child: NeonCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (memory.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    memory.photoUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColorLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppTheme.textMuted),
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.neonPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.neonPink.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.text_fields_rounded,
                      color: AppTheme.neonPink, size: 28),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary),
                    ),
                    if (memory.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        memory.note,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      formatDateRussian(memory.date),
                      style: TextStyle(
                          color: AppTheme.neonPinkLight, fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _storage.deleteMemory(memory.id);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppTheme.textMuted, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50), duration: 350.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
