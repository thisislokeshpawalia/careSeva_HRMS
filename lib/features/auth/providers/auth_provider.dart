import 'package:flutter_riverpod/flutter_riverpod.dart';

// A simple mock auth state for the MVP scaffolding phase
class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false);

  void login(String email, String password) {
    // Mock login logic
    state = true;
  }

  void logout() {
    state = false;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});
