import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_event_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/sticker_entity.dart';
import '../../presentation/providers/auth_provider.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return GroupRepository(
    userId: user?.id ?? 'anonymous',
    userName: user?.name ?? 'Usuario',
  );
});

class GroupRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;
  final String userName;

  GroupRepository({required this.userId, required this.userName});

  // ── Hive helpers ───────────────────────────────────────────────

  Box<int> get _quantitiesBox =>
      Hive.box<int>(AppConstants.stickerQuantitiesBox);
  Box<int> get _backupBox => Hive.box<int>(AppConstants.personalBackupBox);

  Map<int, int> _readBox(Box<int> box) => {
        for (final key in box.keys) int.parse(key as String): box.get(key) ?? 0,
      };

  Future<void> _writeBox(Box<int> box, Map<int, int> data) async {
    await box.clear();
    for (final e in data.entries) {
      if (e.value > 0) await box.put(e.key.toString(), e.value);
    }
  }

  // ── Current group ──────────────────────────────────────────────

  /// Returns the user's current group ID, or null if not in any group.
  Future<String?> getCurrentGroupId() async {
    final snap = await _db
        .collection('group_members')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first['groupId'] as String?;
  }

  Stream<String?> watchCurrentGroupId() => _db
      .collection('group_members')
      .where('userId', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : s.docs.first['groupId'] as String?);

  // ── Create / Join / Leave ──────────────────────────────────────

  Future<GroupEntity> createGroup(String name) async {
    final existing = await getCurrentGroupId();
    if (existing != null) {
      throw Exception(
          'Ya pertenecés a un grupo. Salí primero para crear uno nuevo.');
    }

    // Backup personal collection so it can be restored on leave.
    final currentQty = _readBox(_quantitiesBox);
    await _writeBox(_backupBox, currentQty);

    final code = _generateInviteCode();
    final qtyMap = {for (final e in currentQty.entries) e.key.toString(): e.value};

    final docRef = await _db.collection('groups').add({
      'name': name,
      'ownerId': userId,
      'ownerName': userName,
      'inviteCode': code,
      'memberCount': 1,
      'quantities': qtyMap,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('group_members').doc('${docRef.id}_$userId').set({
      'groupId': docRef.id,
      'userId': userId,
      'userName': userName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    return GroupEntity(
      id: docRef.id,
      name: name,
      ownerId: userId,
      ownerName: userName,
      inviteCode: code,
      memberCount: 1,
      createdAt: DateTime.now(),
    );
  }

  Future<GroupEntity> joinGroup(String code) async {
    final existing = await getCurrentGroupId();
    if (existing != null) {
      throw Exception(
          'Ya pertenecés a un grupo. Salí primero para unirte a otro.');
    }

    final snap = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) throw Exception('Código de invitación inválido');

    final groupDoc = snap.docs.first;
    final groupId = groupDoc.id;

    // Backup personal collection before overwriting with group's.
    await _writeBox(_backupBox, _readBox(_quantitiesBox));

    // Replace local quantities with the group's shared collection.
    final raw =
        (groupDoc.data()['quantities'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), (v as int?) ?? 0));
    await _writeBox(_quantitiesBox, raw);

    await _db.runTransaction((tx) async {
      tx.set(_db.collection('group_members').doc('${groupId}_$userId'), {
        'groupId': groupId,
        'userId': userId,
        'userName': userName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      tx.update(_db.collection('groups').doc(groupId), {
        'memberCount': FieldValue.increment(1),
      });
    });

    return GroupEntity.fromMap(groupId, groupDoc.data());
  }

  Future<void> leaveGroup(String groupId) async {
    // Restore personal collection from backup.
    await _writeBox(_quantitiesBox, _readBox(_backupBox));
    await _backupBox.clear();

    await _db.runTransaction((tx) async {
      tx.delete(
          _db.collection('group_members').doc('${groupId}_$userId'));
      tx.update(_db.collection('groups').doc(groupId), {
        'memberCount': FieldValue.increment(-1),
      });
    });
  }

  // ── Shared quantities ──────────────────────────────────────────

  Stream<Map<int, int>> watchGroupQuantities(String groupId) => _db
      .collection('groups')
      .doc(groupId)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return {};
        final raw =
            snap.data()?['quantities'] as Map<String, dynamic>? ?? {};
        return raw.map((k, v) => MapEntry(int.parse(k), (v as int?) ?? 0));
      });

  Future<void> setGroupQuantity(
      String groupId, int globalNumber, int quantity) async {
    if (quantity <= 0) {
      await _db.collection('groups').doc(groupId).update({
        'quantities.$globalNumber': FieldValue.delete(),
      });
    } else {
      await _db.collection('groups').doc(groupId).update({
        'quantities.$globalNumber': quantity,
      });
    }
  }

  // ── Streams ────────────────────────────────────────────────────

  Stream<List<GroupEntity>> watchUserGroups() async* {
    await for (final membersSnap in _db
        .collection('group_members')
        .where('userId', isEqualTo: userId)
        .snapshots()) {
      final groupIds =
          membersSnap.docs.map((d) => d['groupId'] as String).toList();
      if (groupIds.isEmpty) {
        yield [];
        continue;
      }
      final results = <GroupEntity>[];
      for (int i = 0; i < groupIds.length; i += 10) {
        final batch = groupIds.sublist(i, min(i + 10, groupIds.length));
        final groupSnap = await _db
            .collection('groups')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        results
            .addAll(groupSnap.docs.map((d) => GroupEntity.fromMap(d.id, d.data())));
      }
      yield results;
    }
  }

  Stream<List<GroupMemberEntity>> watchGroupMembers(String groupId) => _db
      .collection('group_members')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => GroupMemberEntity.fromMap(d.data())).toList());

  Stream<List<GroupEventEntity>> watchActivityFeed(String groupId) => _db
      .collection('group_events')
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => GroupEventEntity.fromMap(d.id, d.data())).toList());

  Stream<List<GroupEventEntity>> watchGroupStickers(String groupId) =>
      watchActivityFeed(groupId).map((events) {
        final seen = <int>{};
        return events.where((e) => seen.add(e.stickerGlobalNumber)).toList();
      });

  // ── Mutations ──────────────────────────────────────────────────

  Future<void> registerSticker(String groupId, StickerEntity sticker) async {
    await _db.collection('group_events').add({
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'stickerGlobalNumber': sticker.globalNumber,
      'stickerTeamPosition': sticker.teamPosition,
      'playerName': sticker.playerName,
      'eventType': 'obtained',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }

  // ── Helpers ────────────────────────────────────────────────────

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
