import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/api_config.dart';

enum UserRole { admin, doctor, none }

class AuthState {
  final bool isAuthenticated;
  final UserRole role;
  final String? userId;
  final String? hospitalId;
  final String? doctorId;

  const AuthState({
    this.isAuthenticated = false,
    this.role = UserRole.none,
    this.userId,
    this.hospitalId,
    this.doctorId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? userId,
    String? hospitalId,
    String? doctorId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      hospitalId: hospitalId ?? this.hospitalId,
      doctorId: doctorId ?? this.doctorId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<bool> login(String email, String password, UserRole role) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        state = state.copyWith(
          isAuthenticated: true, 
          role: role,
          userId: data['id'],
          hospitalId: data['hospital_id'] ?? 'dummy_hospital_123', // fallback if null for demo
          doctorId: role == UserRole.doctor ? data['id'] : null,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
