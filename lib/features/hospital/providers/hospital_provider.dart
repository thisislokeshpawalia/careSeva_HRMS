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
