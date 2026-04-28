import 'package:flutter_test/flutter_test.dart';
import 'package:album_mundial/presentation/providers/auth_provider.dart';

void main() {
  test('AuthState unauthenticated has no user', () {
    const state = AuthState.unauthenticated();
    expect(state.isAuthenticated, isFalse);
    expect(state.user, isNull);
  });
}
