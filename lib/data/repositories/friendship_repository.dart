import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/friend_request_entity.dart';
import '../../presentation/providers/auth_provider.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return FriendshipRepository(
    userId: user?.id ?? 'anonymous',
    userName: user?.name ?? 'Usuario',
    avatarUrl: user?.avatarUrl,
  );
});

class FriendshipRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;
  final String userName;
  final String? avatarUrl;

  FriendshipRepository({
    required this.userId,
    required this.userName,
    this.avatarUrl,
  });

  // ── Friend code ────────────────────────────────────────────────

  Future<String> getOrCreateFriendCode() async {
    final box = Hive.box(AppConstants.settingsBox);
    final cached = box.get('friend_code') as String?;
    if (cached != null) return cached;

    final doc = await _db.collection('user_profiles').doc(userId).get();
    if (doc.exists) {
      final code = doc.data()?['friendCode'] as String?;
      if (code != null) {
        await box.put('friend_code', code);
        return code;
      }
    }

    final code = _generateCode();
    await _db.collection('user_profiles').doc(userId).set({
      'friendCode': code,
      'displayName': userName,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _db
        .collection('user_quantities')
        .doc(userId)
        .set({'quantities': {}}, SetOptions(merge: true));
    await box.put('friend_code', code);
    return code;
  }

  // ── Quantity sync for friend visibility ───────────────────────

  Future<void> syncQuantity(int globalNumber, int quantity) async {
    try {
      if (quantity <= 0) {
        await _db.collection('user_quantities').doc(userId).update({
          'quantities.$globalNumber': FieldValue.delete(),
        });
      } else {
        await _db.collection('user_quantities').doc(userId).update({
          'quantities.$globalNumber': quantity,
        });
      }
    } catch (_) {
      if (quantity > 0) {
        await _db.collection('user_quantities').doc(userId).set({
          'quantities': {globalNumber.toString(): quantity},
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> syncAllQuantities(Map<int, int> quantities) async {
    final map = {
      for (final e in quantities.entries) e.key.toString(): e.value,
    };
    await _db.collection('user_quantities').doc(userId).set({'quantities': map});
  }

  // ── Friend requests ────────────────────────────────────────────

  Future<void> sendFriendRequest(String code) async {
    final snap = await _db
        .collection('user_profiles')
        .where('friendCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) throw Exception('Código de amigo inválido');

    final receiverId = snap.docs.first.id;
    if (receiverId == userId) throw Exception('No podés agregarte a vos mismo');

    final friendshipId = _friendshipDocId(userId, receiverId);
    final alreadyFriends =
        await _db.collection('friendships').doc(friendshipId).get();
    if (alreadyFriends.exists) throw Exception('Ya son amigos');

    final pending = await _db
        .collection('friend_requests')
        .where('senderId', isEqualTo: userId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (pending.docs.isNotEmpty) {
      throw Exception('Ya enviaste una solicitud a este usuario');
    }

    await _db.collection('friend_requests').add({
      'senderId': userId,
      'senderName': userName,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptRequest(String requestId, String senderId) async {
    final friendshipId = _friendshipDocId(userId, senderId);
    await _db.runTransaction((tx) async {
      tx.update(_db.collection('friend_requests').doc(requestId),
          {'status': 'accepted'});
      tx.set(_db.collection('friendships').doc(friendshipId), {
        'users': [userId, senderId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _db
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  Future<void> removeFriend(String friendUserId) async {
    await _db
        .collection('friendships')
        .doc(_friendshipDocId(userId, friendUserId))
        .delete();
  }

  // ── Streams ────────────────────────────────────────────────────

  Stream<List<FriendRequestEntity>> watchIncomingRequests() => _db
      .collection('friend_requests')
      .where('receiverId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs
          .map((d) => FriendRequestEntity.fromMap(d.id, d.data()))
          .toList());

  Stream<List<FriendEntity>> watchFriends() async* {
    await for (final snap in _db
        .collection('friendships')
        .where('users', arrayContains: userId)
        .snapshots()) {
      if (snap.docs.isEmpty) {
        yield [];
        continue;
      }
      final friendIds = snap.docs
          .expand((d) => (d['users'] as List).cast<String>())
          .where((id) => id != userId)
          .toList();

      final profiles = <FriendEntity>[];
      for (final friendId in friendIds) {
        final doc =
            await _db.collection('user_profiles').doc(friendId).get();
        if (doc.exists) {
          profiles.add(FriendEntity.fromMap(friendId, doc.data()!));
        }
      }
      yield profiles;
    }
  }

  Stream<Map<int, int>> watchFriendQuantities(String friendUserId) => _db
      .collection('user_quantities')
      .doc(friendUserId)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return {};
        final raw =
            snap.data()?['quantities'] as Map<String, dynamic>? ?? {};
        return raw.map((k, v) => MapEntry(int.parse(k), (v as int?) ?? 0));
      });

  // ── Helpers ────────────────────────────────────────────────────

  static String _friendshipDocId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
