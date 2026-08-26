import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/api_config.dart';
import '../../auth/providers/auth_provider.dart';

final hospitalDetailsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);
  final hospitalId = authState.hospitalId;
  
  if (hospitalId == null || hospitalId == 'dummy_hospital_123') return null;

  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/hospitals/$hospitalId'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    // print('Error fetching hospital details: $e');
    return null;
  }
});

final hospitalDepartmentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  final hospitalId = authState.hospitalId;
  
  if (hospitalId == null || hospitalId == 'dummy_hospital_123') return [];

  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/departments'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  } catch (e) {
    // print('Error fetching hospital departments: $e');
    return [];
  }
});

final hospitalActionsProvider = Provider((ref) => HospitalActions(ref));

class HospitalActions {
  final Ref ref;
  HospitalActions(this.ref);

  Future<bool> updateHospitalDetails(String hospitalId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/hospitals/$hospitalId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        ref.invalidate(hospitalDetailsProvider);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> addDepartment(String hospitalId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/departments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        ref.invalidate(hospitalDepartmentsProvider);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> updateDepartment(String hospitalId, String deptId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/departments/$deptId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        ref.invalidate(hospitalDepartmentsProvider);
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }
}
