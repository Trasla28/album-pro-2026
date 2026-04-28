import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioClientProvider));
});

class AuthRepository {
  final DioClient _client;

  // Lazy getters: Firebase only accessed when sign-in is actually attempted,
  // not at construction time (avoids crash when Firebase isn't initialized yet).
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn();

  String? _accessToken;
  String? _refreshToken;

  AuthRepository(this._client);

  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const ApiException('Inicio de sesión cancelado');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      return _userFromFirebase(userCredential.user!);
    } on ApiException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'network-request-failed' => 'Error de red. Verificá tu internet.',
        'too-many-requests' => 'Demasiados intentos, intentá más tarde',
        _ => e.message ?? 'Error de autenticación con Google',
      };
      throw ApiException(msg);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') throw const ApiException('Inicio de sesión cancelado');
      throw ApiException(e.message ?? 'Error al iniciar sesión con Google');
    }
  }

  Future<UserEntity> signInWithMicrosoft() async {
    try {
      final provider = OAuthProvider('microsoft.com');
      final userCredential = await _firebaseAuth.signInWithProvider(provider);
      return _userFromFirebase(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-cancelled' => 'Inicio de sesión cancelado',
        'network-request-failed' => 'Error de red. Verificá tu internet.',
        'popup-closed-by-user' => 'Inicio de sesión cancelado',
        _ => e.message ?? 'Error al iniciar sesión con Microsoft',
      };
      throw ApiException(msg);
    }
  }

  Future<UserEntity> signInWithEmail(String email, String password) async {
    UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No existe una cuenta con ese email',
        'wrong-password' => 'Contraseña incorrecta',
        'invalid-credential' => 'Email o contraseña incorrectos',
        'invalid-email' => 'El email no es válido',
        'too-many-requests' => 'Demasiados intentos, intentá más tarde',
        'network-request-failed' => 'Error de red. Verificá tu internet.',
        _ => e.message ?? 'Error de autenticación',
      };
      throw ApiException(msg);
    }

    return _userFromFirebase(userCredential.user!);
  }

  Future<UserEntity> registerWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user!.updateDisplayName(name);
      await userCredential.user!.reload();
      return _userFromFirebase(_firebaseAuth.currentUser!);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Ya existe una cuenta con ese email',
        'invalid-email' => 'El email no es válido',
        'weak-password' => 'La contraseña es muy débil',
        'network-request-failed' => 'Error de red. Verificá tu internet.',
        _ => e.message ?? 'Error al crear la cuenta',
      };
      throw ApiException(msg);
    }
  }

  // Builds a UserEntity directly from Firebase Auth (no backend call needed).
  Future<UserEntity> _userFromFirebase(User fbUser) async {
    final model = UserModel(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Usuario',
      avatarUrl: fbUser.photoURL,
      firebaseUid: fbUser.uid,
    );
    await _saveUserLocally(model);
    return model.toEntity();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    _client.clearAuthToken();
    _accessToken = null;
    _refreshToken = null;
    await _clearUserLocally();
  }

  Future<UserEntity?> getStoredUser() async {
    // Check Firebase Auth synchronously first (available after cold start on Android)
    var firebaseUser = _firebaseAuth.currentUser;

    // If null, wait briefly for Firebase to finish restoring the persisted session
    firebaseUser ??= await _firebaseAuth
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => null);

    // No Firebase session → clear any stale Hive data and force new login
    if (firebaseUser == null) {
      await _clearUserLocally();
      return null;
    }

    final box = Hive.box<UserModel>(AppConstants.userBox);
    final saved = box.get('current_user');
    // Hive has user → return it; otherwise rebuild from Firebase (e.g. after reinstall)
    return saved?.toEntity() ?? await _userFromFirebase(firebaseUser);
  }

  Future<UserEntity> refreshToken() async {
    if (_refreshToken == null) throw const ApiException('Sesión expirada');

    try {
      final response = await _client.dio.post(
        '/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );
      _accessToken = response.data['access_token'] as String;
      _client.setAuthToken(_accessToken!);

      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>).toEntity();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> _saveUserLocally(UserModel user) async {
    final box = Hive.box<UserModel>(AppConstants.userBox);
    await box.put('current_user', user);
  }

  Future<void> _clearUserLocally() async {
    final userBox = Hive.box<UserModel>(AppConstants.userBox);
    await userBox.delete('current_user');
    final settingsBox = Hive.box(AppConstants.settingsBox);
    await settingsBox.delete('friend_code');
  }
}
