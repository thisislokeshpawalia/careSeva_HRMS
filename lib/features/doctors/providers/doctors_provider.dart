import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/api_config.dart';
import '../../auth/providers/auth_provider.dart';

final doctorsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  final hospitalId = authState.hospitalId;
  
  if (hospitalId == null || hospitalId == 'dummy_hospital_123') return [];

  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/doctors'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  } catch (e) {
    return [];
  }
});

final doctorActionsProvider = Provider((ref) => DoctorActions(ref));

class DoctorActions {
  final Ref ref;
  DoctorActions(this.ref);

  Future<bool> addDoctor(String hospitalId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/doctors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        ref.invalidate(doctorsProvider);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> updateDoctor(String hospitalId, String docId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/doctors/$docId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        ref.invalidate(doctorsProvider);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> deleteDoctor(String hospitalId, String docId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/doctors/$docId'),
      );
      if (response.statusCode == 200) {
        ref.invalidate(doctorsProvider);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}
