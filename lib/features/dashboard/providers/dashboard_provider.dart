import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/api_config.dart';
import '../../../core/services/safe_http_client.dart';
import '../../auth/providers/auth_provider.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);
  final hospitalId = authState.hospitalId;
  
  if (hospitalId == null || hospitalId == 'dummy_hospital_123') {
    return {
      'total_patients': 1482,
      'appointments_today': 146,
      'available_doctors': 38,
      'todays_revenue': 12450,
      'recent_appointments': [
        {
          'patient_name': 'Sarah Johnson',
          'doctor_name': 'Dr. Robert Smith',
          'department_name': 'Cardiology',
          'time': '10:00 AM',
          'status': 'Completed'
        }
      ]
    };
  }

  try {
    final response = await SafeHttpClient.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/dashboard-stats'),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  } catch (e) {
    // print('Error fetching dashboard stats: $e');
    return null;
  }
});
