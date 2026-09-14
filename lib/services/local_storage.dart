import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wish_item.dart';
import '../models/mood_state.dart';
import '../models/cycle_tracker.dart';
import '../models/pigeon_message.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class LocalStorage extends ChangeNotifier {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  static const _keyStartDate = 'start_date';
  static const _keyWishes = 'wishes';
  static const _keyMood = 'mood_state';
  static const _keyCycle = 'cycle_info';
  static const _keyPigeons = 'pigeons';
  static const _keyLastPigeonSent = 'last_pigeon_sent';

  DateTime? _startDate;
  List<WishItem> _wishes = [];
  MoodState _mood = const MoodState();
  CycleTracker _cycle = CycleTracker();
  List<PigeonMessage> _pigeons = [];
  DateTime? _lastPigeonSent;
  UserProfile? _myProfile;
  UserProfile? _partnerProfile;
  Map<String, MoodType?> _moodsByUid = {};

  DateTime? get startDate => _startDate;
  List<WishItem> get wishes => List.unmodifiable(_wishes);
  MoodState get mood => _resolvedMood;
  CycleTracker get cycle => _cycle;
  List<PigeonMessage> get pigeons => List.unmodifiable(_pigeons);
  DateTime? get lastPigeonSent => _lastPigeonSent;
  UserProfile? get myProfile => _myProfile;
  UserProfile? get partnerProfile => _partnerProfile;

  List<WishItem> get activeWishes =>
      _wishes.where((w) => !w.isCompleted).toList();
  List<WishItem> get completedWishes =>
      _wishes.where((w) => w.isCompleted).toList();

  bool get isGirl => _myProfile?.role == PartnerRole.girl;
  bool get isGuy => _myProfile?.role == PartnerRole.guy;

  PigeonMessage? get incomingPigeon {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      return _pigeons
          .firstWhere((p) => p.senderId.isNotEmpty && p.senderId != uid);
    } catch (_) {
      return null;
    }
  }

  PigeonMessage? get outgoingPendingPigeon {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    try {
      return _pigeons.firstWhere((p) => p.senderId == uid);
    } catch (_) {
      return null;
    }
  }

  bool get hasUnreadPigeon => incomingPigeon != null;

  bool get canSendPigeonToday {
    final now = DateTime.now();
    final last = _lastPigeonSent ?? _myProfile?.lastPigeonSentAt;
    if (last == null) return true;
    return !(last.year == now.year &&
        last.month == now.month &&
        last.day == now.day);
  }

  MoodState get _resolvedMood {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final partnerUid = _partnerProfile?.uid;
    return MoodState(
      myMood: uid != null ? _moodsByUid[uid] : _mood.myMood,
      partnerMood:
          partnerUid != null ? _moodsByUid[partnerUid] : _mood.partnerMood,
      lastUpdated: _mood.lastUpdated,
    );
  }

  bool _isFirebaseReady = false;
  String? _coupleId;
  final List<StreamSubscription> _subs = [];
  final Set<String> _knownPigeonIds = {};
  bool _pigeonBootstrapDone = false;
  bool _moodBootstrapDone = false;
  String? _lastKnownPartnerMoodKey;

  String? get coupleId => _coupleId;

  String get _pigeonCacheKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final couple = _coupleId ?? 'unpaired';
    return '${_keyPigeons}_${uid}_$couple';
  }

  String get _lastPigeonCacheKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    return '${_keyLastPigeonSent}_$uid';
  }

  void setCoupleId(String id) {
    if (_coupleId == id) return;
    _coupleId = id;
    _pigeons = [];
    _lastPigeonSent = null;
    _pigeonBootstrapDone = false;
    _moodBootstrapDone = false;
    _knownPigeonIds.clear();
    _setupFirestoreListeners();
  }

  void clearCoupleId() {
    _cancelListeners();
    _coupleId = null;
    _myProfile = null;
    _partnerProfile = null;
    _moodsByUid = {};
    _pigeons = [];
    _lastPigeonSent = null;
    _pigeonBootstrapDone = false;
    _moodBootstrapDone = false;
    _knownPigeonIds.clear();
  }

  void _cancelListeners() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final dateStr = prefs.getString(_keyStartDate);
    if (dateStr != null) _startDate = DateTime.parse(dateStr);

    final wishesJson = prefs.getString(_keyWishes);
    if (wishesJson != null) {
      final list = jsonDecode(wishesJson) as List;
      _wishes = list.map((e) => WishItem.fromJson(e)).toList();
    }

    final moodJson = prefs.getString(_keyMood);
    if (moodJson != null) {
      _mood = MoodState.fromJson(jsonDecode(moodJson));
    }

    final cycleJson = prefs.getString(_keyCycle);
    if (cycleJson != null) {
      _cycle = CycleTracker.fromJson(jsonDecode(cycleJson));
    }

    // Pigeons are private to an account/couple. Never revive an old couple's
    // letters while offline on a shared device.
    final pigeonsJson = prefs.getString(_pigeonCacheKey);
    if (pigeonsJson != null) {
      final list = jsonDecode(pigeonsJson) as List;
      _pigeons = list.map((e) => PigeonMessage.fromJson(e)).toList();
    }

    final lastPigeon = prefs.getString(_lastPigeonCacheKey);
    if (lastPigeon != null) _lastPigeonSent = DateTime.parse(lastPigeon);

    notifyListeners();

    try {
      Firebase.app();
      _isFirebaseReady = true;
      await _loadMyProfile();
      _setupFirestoreListeners();
    } catch (e) {
      debugPrint('Firebase is not ready. Using local storage only.');
    }
  }

  Future<void> _loadMyProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (snap.exists && snap.data() != null) {
      _myProfile = UserProfile.fromJson(user.uid, snap.data()!);
      if (_myProfile!.lastPigeonSentAt != null) {
        _lastPigeonSent = _myProfile!.lastPigeonSentAt;
      }
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _myProfile = profile;
    notifyListeners();

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final profileData = profile.toJson()..remove('lastPigeonSentAt');
    await userRef.set({
      ...profileData,
      'email': user.email,
    }, SetOptions(merge: true));

    var coupleId = _coupleId;
    if (coupleId == null) {
      final snap = await userRef.get();
      final raw = snap.data()?['coupleId'];
      if (raw is String && raw.isNotEmpty) coupleId = raw;
    }

    if (coupleId != null) {
      _coupleId ??= coupleId;
      await FirebaseFirestore.instance.collection('couples').doc(coupleId).set({
        'partners': {user.uid: profile.toPartnerMirror()},
      }, SetOptions(merge: true));
    }
  }

  void _setupFirestoreListeners() {
    if (!_isFirebaseReady || _coupleId == null) return;
    _cancelListeners();
    final db = FirebaseFirestore.instance;
    final coupleId = _coupleId!;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    _subs.add(db.collection('couples').doc(coupleId).snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      if (data['startDate'] != null) {
        _startDate = DateTime.parse(data['startDate']);
      }

      // Per-uid moods
      if (data['moods'] is Map) {
        final moods = Map<String, dynamic>.from(data['moods'] as Map);
        _moodsByUid = {};
        for (final entry in moods.entries) {
          final m = entry.value;
          if (m is Map && m['mood'] != null) {
            _moodsByUid[entry.key] = MoodType.values.firstWhere(
              (e) => e.name == m['mood'],
              orElse: () => MoodType.resting,
            );
          }
        }
      } else if (data['mood'] != null) {
        // Legacy blob fallback
        _mood = MoodState.fromJson(Map<String, dynamic>.from(data['mood']));
      }

      if (data['cycle'] != null) {
        _cycle =
            CycleTracker.fromJson(Map<String, dynamic>.from(data['cycle']));
      }

      if (data['partners'] is Map && myUid != null) {
        final partners = Map<String, dynamic>.from(data['partners'] as Map);
        for (final entry in partners.entries) {
          if (entry.value is! Map) continue;
          final p = UserProfile.fromJson(
              entry.key, Map<String, dynamic>.from(entry.value as Map));
          if (entry.key == myUid) {
            _myProfile = _myProfile?.copyWith(
                  displayName: p.displayName,
                  role: p.role,
                  birthday: p.birthday,
                ) ??
                p;
          } else {
            _partnerProfile = p;
          }
        }
      }

      // Do not turn an app launch into a stale mood notification. Subsequent
      // snapshots are genuine changes while this client is listening.
      if (_moodBootstrapDone) _maybeNotifyMood(myUid);
      _moodBootstrapDone = true;

      notifyListeners();
    }));

    if (myUid != null) {
      _subs.add(db.collection('users').doc(myUid).snapshots().listen((snap) {
        if (!snap.exists || snap.data() == null) return;
        _myProfile = UserProfile.fromJson(myUid, snap.data()!);
        if (_myProfile!.lastPigeonSentAt != null) {
          _lastPigeonSent = _myProfile!.lastPigeonSentAt;
        }
        notifyListeners();
      }));
    }

    _subs.add(db
        .collection('couples')
        .doc(coupleId)
        .collection('wishes')
        .snapshots()
        .listen((snapshot) {
      _wishes =
          snapshot.docs.map((doc) => WishItem.fromJson(doc.data())).toList();
      _saveWishes();
      notifyListeners();
    }));

    _subs.add(db
        .collection('couples')
        .doc(coupleId)
        .collection('pigeons')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final list = snapshot.docs
          .map((doc) => PigeonMessage.fromJson(doc.data()))
          .toList();
      _pigeons = list;
      await _savePigeons();

      if (!_pigeonBootstrapDone) {
        _knownPigeonIds.addAll(list.map((p) => p.id));
        _pigeonBootstrapDone = true;
      } else if (myUid != null) {
        for (final p in list) {
          if (_knownPigeonIds.contains(p.id)) continue;
          _knownPigeonIds.add(p.id);
          if (p.senderId != myUid && p.senderId.isNotEmpty) {
            await NotificationService().notifyIncomingPigeon(
              pigeonId: p.id,
              fromName:
                  p.senderName ?? _partnerProfile?.displayName ?? 'Половинка',
            );
          }
        }
        // Remove ids that no longer exist
        _knownPigeonIds.removeWhere((id) => !list.any((p) => p.id == id));
      }

      notifyListeners();
    }));
  }

  void _maybeNotifyMood(String? myUid) {
    if (myUid == null || _partnerProfile == null) return;
    final partnerMood = _moodsByUid[_partnerProfile!.uid];
    if (partnerMood == null) return;
    if (partnerMood != MoodType.wantHug &&
        partnerMood != MoodType.thinkingOfYou) {
      return;
    }
    final key = '${_partnerProfile!.uid}_${partnerMood.name}';
    if (key == _lastKnownPartnerMoodKey) return;
    _lastKnownPartnerMoodKey = key;
    NotificationService().notifyPartnerMood(
      partnerName: _partnerProfile!.displayName,
      moodLabel: '${partnerMood.emoji} ${partnerMood.label}',
      moodKey: key,
    );
  }

  Future<void> _syncMetaToFirestore() async {
    if (!_isFirebaseReady || _coupleId == null) return;
    try {
      final data = <String, dynamic>{
        'startDate': _startDate?.toIso8601String(),
      };
      // Cycle data belongs to her. Avoid both an accidental client write and
      // a rejected Firestore request when he only edits the shared start date.
      if (isGirl) data['cycle'] = _cycle.toJson();
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> setStartDate(DateTime date) async {
    _startDate = date;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartDate, date.toIso8601String());
    notifyListeners();
    await _syncMetaToFirestore();
  }

  Future<void> addWish(WishItem wish) async {
    _wishes.add(wish);
    await _saveWishes();
    notifyListeners();
    if (_isFirebaseReady && _coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('wishes')
          .doc(wish.id)
          .set(wish.toJson());
    }
  }

  Future<void> toggleWish(String id) async {
    final idx = _wishes.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    _wishes[idx].isCompleted = !_wishes[idx].isCompleted;
    _wishes[idx].completedAt = _wishes[idx].isCompleted ? DateTime.now() : null;
    await _saveWishes();
    notifyListeners();
    if (_isFirebaseReady && _coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('wishes')
          .doc(id)
          .update({
        'isCompleted': _wishes[idx].isCompleted,
        'completedAt': _wishes[idx].completedAt?.toIso8601String(),
      });
    }
  }

  Future<void> deleteWish(String id) async {
    _wishes.removeWhere((w) => w.id == id);
    await _saveWishes();
    notifyListeners();
    if (_isFirebaseReady && _coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('wishes')
          .doc(id)
          .delete();
    }
  }

  Future<void> setMyMood(MoodType mood) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _moodsByUid[uid] = mood;
    _mood = _resolvedMood.copyWithLike(mood);
    await _saveMood();
    notifyListeners();

    if (_isFirebaseReady && _coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .set({
        'moods': {
          uid: {
            'mood': mood.name,
            'updatedAt': DateTime.now().toIso8601String(),
          }
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> setCycleStart(DateTime date) async {
    if (!isGirl) return;
    _cycle = _cycle.copyWith(lastPeriodStart: date);
    await _persistCycle();
  }

  Future<void> setCycleSettings({int? cycleLength, int? periodLength}) async {
    if (!isGirl) return;
    _cycle = _cycle.copyWith(
      cycleLength: cycleLength ?? _cycle.cycleLength,
      periodLength: periodLength ?? _cycle.periodLength,
    );
    await _persistCycle();
  }

  Future<void> setCycleStatusOverride(String key) async {
    if (!isGirl) return;
    _cycle = _cycle.copyWith(statusOverride: key);
    await _persistCycle();
  }

  Future<void> _persistCycle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCycle, jsonEncode(_cycle.toJson()));
    notifyListeners();
    await _syncMetaToFirestore();
  }

  Future<bool> sendPigeon(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (!canSendPigeonToday) return false;
    if (outgoingPendingPigeon != null) return false;

    final now = DateTime.now();
    final msg = PigeonMessage(
      id: now.millisecondsSinceEpoch.toString(),
      content: content,
      sentAt: now,
      senderId: user.uid,
      senderName: _myProfile?.displayName ?? 'Я',
    );

    _pigeons.insert(0, msg);
    _lastPigeonSent = now;
    _knownPigeonIds.add(msg.id);
    await _savePigeons();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPigeonCacheKey, now.toIso8601String());
    notifyListeners();

    if (_isFirebaseReady && _coupleId != null) {
      // Keep the local value as an offline fallback, but let Firestore be the
      // source of truth for the daily-send timestamp and letter order.
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final pigeonRef = db
          .collection('couples')
          .doc(_coupleId)
          .collection('pigeons')
          .doc(msg.id);
      batch.set(pigeonRef, {
        ...msg.toJson(),
        'sentAt': FieldValue.serverTimestamp(),
        'sentAtFallback': now.toIso8601String(),
      });
      batch.set(
          db.collection('users').doc(user.uid),
          {
            'lastPigeonSentAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      await batch.commit();
    }
    return true;
  }

  Future<void> markPigeonReadAndDelete(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final pigeon = _pigeons.where((p) => p.id == id).firstOrNull;
    // Only the recipient opens a letter. The sender can see its delivery
    // state, but must not be able to retract or "read" it.
    if (uid == null || pigeon == null || pigeon.senderId == uid) return;
    _pigeons.removeWhere((p) => p.id == id);
    _knownPigeonIds.remove(id);
    await _savePigeons();
    notifyListeners();

    if (_isFirebaseReady && _coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('pigeons')
          .doc(id)
          .delete();
    }
  }

  Future<void> _saveWishes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyWishes, jsonEncode(_wishes.map((w) => w.toJson()).toList()));
  }

  Future<void> _saveMood() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMood, jsonEncode(_resolvedMood.toJson()));
  }

  Future<void> _savePigeons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pigeonCacheKey, jsonEncode(_pigeons.map((p) => p.toJson()).toList()));
  }

  int get daysTogether {
    if (_startDate == null) return 0;
    final now = DateTime.now();
    return now.difference(_startDate!).inDays;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

extension on MoodState {
  MoodState copyWithLike(MoodType my) => MoodState(
        myMood: my,
        partnerMood: partnerMood,
        lastUpdated: DateTime.now(),
      );
}
