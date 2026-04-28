import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_event_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/sticker_entity.dart';

// Real-time list of the user's groups (max 1 enforced at creation/join)
final userGroupsProvider = StreamProvider<List<GroupEntity>>((ref) {
  return ref.watch(groupRepositoryProvider).watchUserGroups();
});

// The single active group entity, or null
final activeGroupProvider = Provider<GroupEntity?>((ref) {
  return ref.watch(userGroupsProvider).valueOrNull?.firstOrNull;
});

// The active group's ID as a stream (used by album provider)
final currentGroupIdProvider = StreamProvider<String?>((ref) {
  return ref.watch(groupRepositoryProvider).watchCurrentGroupId();
});

// Real-time shared quantities for the active group
final currentGroupQuantitiesProvider =
    StreamProvider<Map<int, int>?>((ref) {
  final groupIdAsync = ref.watch(currentGroupIdProvider);
  if (!groupIdAsync.hasValue) return const Stream.empty();
  final groupId = groupIdAsync.requireValue;
  if (groupId == null) return Stream.value(null);
  return ref
      .read(groupRepositoryProvider)
      .watchGroupQuantities(groupId)
      .map<Map<int, int>?>((qty) => qty);
});

// Real-time members of a specific group
final groupMembersProvider =
    StreamProvider.family<List<GroupMemberEntity>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchGroupMembers(groupId);
});

// Real-time activity feed of a specific group
final groupActivityProvider =
    StreamProvider.family<List<GroupEventEntity>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchActivityFeed(groupId);
});

// Deduplicated stickers obtained by the group
final groupStickersProvider =
    StreamProvider.family<List<GroupEventEntity>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchGroupStickers(groupId);
});

// Actions (create, join, leave, register)
final groupActionsProvider = Provider<GroupActions>((ref) {
  return GroupActions(ref.read(groupRepositoryProvider));
});

class GroupActions {
  final GroupRepository _repo;
  GroupActions(this._repo);

  Future<GroupEntity> createGroup(String name) => _repo.createGroup(name);
  Future<GroupEntity> joinGroup(String code) => _repo.joinGroup(code);
  Future<void> leaveGroup(String groupId) => _repo.leaveGroup(groupId);

  Future<void> registerSticker(String groupId, StickerEntity sticker) =>
      _repo.registerSticker(groupId, sticker);
}
