import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, doctor, none }

class AuthState {
  final bool isAuthenticated;
  final UserRole role;

  const AuthState({
    this.isAuthenticated = false,
    this.role = UserRole.none,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
    );
  }
}

// A simple mock auth state for the MVP scaffolding phase
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void login(String email, String password, UserRole role) {
    // Mock login logic
    state = state.copyWith(isAuthenticated: true, role: role);
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
