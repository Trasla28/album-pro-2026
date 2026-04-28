import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/friendship_repository.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/friend_request_entity.dart';

// Initializes the user's friend code and Firestore profile on first access.
final friendCodeProvider = FutureProvider<String>((ref) {
  return ref.watch(friendshipRepositoryProvider).getOrCreateFriendCode();
});

final incomingFriendRequestsProvider =
    StreamProvider<List<FriendRequestEntity>>((ref) {
  return ref.watch(friendshipRepositoryProvider).watchIncomingRequests();
});

final friendsProvider = StreamProvider<List<FriendEntity>>((ref) {
  return ref.watch(friendshipRepositoryProvider).watchFriends();
});

final friendQuantitiesProvider =
    StreamProvider.family<Map<int, int>, String>((ref, friendUserId) {
  return ref
      .watch(friendshipRepositoryProvider)
      .watchFriendQuantities(friendUserId);
});

final friendActionsProvider = Provider<FriendActions>((ref) {
  return FriendActions(ref.read(friendshipRepositoryProvider));
});

class FriendActions {
  final FriendshipRepository _repo;
  FriendActions(this._repo);

  Future<void> sendRequest(String code) => _repo.sendFriendRequest(code);

  Future<void> acceptRequest(String requestId, String senderId) =>
      _repo.acceptRequest(requestId, senderId);

  Future<void> rejectRequest(String requestId) =>
      _repo.rejectRequest(requestId);

  Future<void> removeFriend(String friendUserId) =>
      _repo.removeFriend(friendUserId);
}
