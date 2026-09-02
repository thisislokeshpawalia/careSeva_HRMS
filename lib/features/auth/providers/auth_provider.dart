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
  final String verificationStatus; // 'APPROVED', 'PENDING', 'REJECTED', 'SUSPENDED'
  final String? hopId;
  final String? hospitalName;
  final String? rejectionReason;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.role = UserRole.none,
    this.userId,
    this.hospitalId,
    this.doctorId,
    this.verificationStatus = 'APPROVED',
    this.hopId,
    this.hospitalName,
    this.rejectionReason,
    this.errorMessage,
  });

  bool get isApproved => verificationStatus.toUpperCase() == 'APPROVED';
  bool get isPending => verificationStatus.toUpperCase() == 'PENDING';
  bool get isRejected => verificationStatus.toUpperCase() == 'REJECTED';
  bool get isSuspended => verificationStatus.toUpperCase() == 'SUSPENDED';

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? userId,
    String? hospitalId,
    String? doctorId,
    String? verificationStatus,
    String? hopId,
    String? hospitalName,
    String? rejectionReason,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      hospitalId: hospitalId ?? this.hospitalId,
      doctorId: doctorId ?? this.doctorId,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      hopId: hopId ?? this.hopId,
      hospitalName: hospitalName ?? this.hospitalName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      errorMessage: errorMessage ?? this.errorMessage,
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
        final vStatus = (data['verification_status'] ?? 'APPROVED').toString().toUpperCase();
        
        state = state.copyWith(
          isAuthenticated: true, 
          role: role,
          userId: data['id'],
          hospitalId: data['hospital_id'] ?? '6a8ea49ef17ddb14088aa5f7',
          doctorId: role == UserRole.doctor ? data['id'] : null,
          verificationStatus: vStatus,
          hopId: data['hop_id'],
          hospitalName: data['hospital_name'],
          rejectionReason: data['rejection_reason'],
          errorMessage: null,
        );
        return true;
      } else {
        final err = jsonDecode(response.body);
        final detail = err['detail']?.toString() ?? 'Login failed. Check your credentials.';
        state = state.copyWith(errorMessage: detail);
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network connection error. Please try again.');
      return false;
    }
  }

  Future<bool> doctorLogin(String hopId, String docId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/auth/doctor-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hop_id': hopId, 'doc_id': docId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        state = state.copyWith(
          isAuthenticated: true, 
          role: UserRole.doctor,
          userId: data['id'],
          hospitalId: data['hospital_id'],
          doctorId: data['id'],
          verificationStatus: 'APPROVED',
          hopId: data['hop_id'],
          hospitalName: data['hospital_name'],
          errorMessage: null,
        );
        return true;
      } else {
        final err = jsonDecode(response.body);
        final detail = err['detail']?.toString() ?? 'Doctor login failed.';
        state = state.copyWith(errorMessage: detail);
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error during doctor login.');
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkHospitalStatus() async {
    final hid = state.hospitalId ?? state.hopId;
    if (hid == null) return null;
    try {
      final res = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/auth/hospital-status/$hid'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final vStatus = (data['verification_status'] ?? 'PENDING').toString().toUpperCase();
        state = state.copyWith(
          verificationStatus: vStatus,
          hopId: data['hop_id'] ?? state.hopId,
          hospitalName: data['name'] ?? state.hospitalName,
          rejectionReason: data['rejection_reason'],
        );
        return data;
      }
    } catch (_) {}
    return null;
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
