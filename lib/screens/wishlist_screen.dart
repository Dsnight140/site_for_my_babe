import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/particle_bg.dart';
import '../models/wish_item.dart';
import '../services/local_storage.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late LocalStorage _storage;
  WishCategory? _filterCategory;
  late TabController _tabController;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _storage.load().then((_) => setState(() {}));
    _storage.addListener(_onStorageUpdate);
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ParticleBackground(
            emojis: ['🎁', '⭐', '💫', '✨', '🌟'],
            particleCount: 12,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                _buildCategoryFilter(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWishList(completed: false),
                      _buildWishList(completed: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 110,
            child: _buildFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                text: 'Наш вишлист 🎁',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${_storage.activeWishes.length} мечт ждут воплощения',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.neonPink.withOpacity(0.15),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppTheme.neonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: '✨ Желания (${_storage.activeWishes.length})'),
            Tab(text: '✅ Исполнено (${_storage.completedWishes.length})'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: [
          _filterChip(null, '🔮', 'Все'),
          ...WishCategory.values.map(
            (c) => _filterChip(c, c.emoji, c.label),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(WishCategory? cat, String emoji, String label) {
    final selected = _filterCategory == cat;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterCategory = cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.neonGradient : null,
          color: selected ? null : AppTheme.cardColorLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.neonPink.withOpacity(0.15),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.neonPink.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : [],
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildWishList({required bool completed}) {
    var wishes = completed ? _storage.completedWishes : _storage.activeWishes;
    if (_filterCategory != null) {
      wishes = wishes.where((w) => w.category == _filterCategory).toList();
    }

    if (wishes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(completed ? '✅' : '✨',
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              completed
                  ? 'Пока ничего не исполнено'
                  : 'Список желаний пуст\nДобавь первое! 💕',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: wishes.length,
      itemBuilder: (ctx, i) => _buildWishTile(wishes[i], i),
    );
  }

  Widget _buildWishTile(WishItem wish, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(wish.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                _storage.deleteWish(wish.id);
              },
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Удалить',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _storage.toggleWish(wish.id);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: wish.isCompleted
                  ? const LinearGradient(
                      colors: [Color(0xFF1A2A1A), Color(0xFF121812)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF1E1030), Color(0xFF12121A)],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: wish.isCompleted
                    ? Colors.green.withOpacity(0.3)
                    : AppTheme.neonPink.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: wish.isCompleted
                        ? Colors.green.withOpacity(0.15)
                        : AppTheme.neonPink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      wish.isCompleted ? '✅' : wish.category.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wish.title,
                        style: TextStyle(
                          color: wish.isCompleted
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: wish.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppTheme.textSecondary,
                        ),
                      ),
                      if (wish.note != null && wish.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          wish.note!,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${wish.category.emoji} ${wish.category.label}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms)
          .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showAddWishSheet,
      child: Container(
        width: 56,
        height: 56,
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
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut);
  }

  void _showAddWishSheet() {
    HapticFeedback.mediumImpact();
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    WishCategory selectedCat = WishCategory.gift;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                // Handle
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
                  text: 'Новое желание ✨',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                _buildNeonTextField(titleCtrl, 'Название желания'),
                const SizedBox(height: 12),
                _buildNeonTextField(noteCtrl, 'Заметка (опционально)'),
                const SizedBox(height: 16),
                Text('Категория',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WishCategory.values.map((c) {
                    final isSelected = selectedCat == c;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCat = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.neonGradient : null,
                          color: isSelected ? null : AppTheme.cardColorLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppTheme.dividerColor,
                          ),
                        ),
                        child: Text(
                          '${c.emoji} ${c.label}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
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
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        HapticFeedback.mediumImpact();
                        _storage.addWish(WishItem(
                          id: _uuid.v4(),
                          title: titleCtrl.text.trim(),
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                          category: selectedCat,
                          createdAt: DateTime.now(),
                        ));
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Добавить желание 💕',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.cardColorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.neonPink.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.neonPink.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.neonPink, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
