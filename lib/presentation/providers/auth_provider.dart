import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

class AuthState {
  final UserEntity? user;
  final bool isAuthenticated;

  const AuthState({this.user, this.isAuthenticated = false});

  const AuthState.authenticated(UserEntity this.user) : isAuthenticated = true;

  const AuthState.unauthenticated()
      : user = null,
        isAuthenticated = false;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final storedUser = await repo.getStoredUser();
    if (storedUser != null) {
      return AuthState.authenticated(storedUser);
    }
    return const AuthState.unauthenticated();
  }

  Future<void> signInWithMicrosoft() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithMicrosoft();
      return AuthState.authenticated(user);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithGoogle();
      return AuthState.authenticated(user);
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmail(email, password);
      return AuthState.authenticated(user);
    });
  }

  Future<void> registerWithEmail(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.registerWithEmail(email, password, name);
      return AuthState.authenticated(user);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      return const AuthState.unauthenticated();
    });
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});
