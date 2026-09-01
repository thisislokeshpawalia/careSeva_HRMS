import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

final hospitalPatientsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, hospitalId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/patients/hospital/$hospitalId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      // print('Failed to load patients: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    // print('Error in hospitalPatientsProvider: $e');
    return [];
  }
});

final hospitalPatientDirectoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, hospitalId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/patients/hospital/$hospitalId/directory'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
});

class RegisterPatientResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? existingAppointment;
  final String? errorMessage;
  final int statusCode;

  RegisterPatientResult({
    required this.isSuccess,
    this.data,
    this.existingAppointment,
    this.errorMessage,
    required this.statusCode,
  });
}

Future<RegisterPatientResult> registerPatientApi(Map<String, dynamic> patientData) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/patients/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patientData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return RegisterPatientResult(
        isSuccess: true,
        data: decoded,
        statusCode: response.statusCode,
      );
    } else {
      Map<String, dynamic>? existingAppt;
      String? message;
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map<String, dynamic>) {
          final detail = errJson['detail'];
          if (detail is Map<String, dynamic>) {
            message = detail['message']?.toString();
            if (detail['existing_appointment'] is Map<String, dynamic>) {
              existingAppt = detail['existing_appointment'] as Map<String, dynamic>;
            }
          } else if (detail != null) {
            message = detail.toString();
          }
        }
      } catch (_) {}

      return RegisterPatientResult(
        isSuccess: false,
        existingAppointment: existingAppt,
        errorMessage: message ?? 'Registration failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  } catch (e) {
    return RegisterPatientResult(
      isSuccess: false,
      errorMessage: 'Network error: $e',
      statusCode: 500,
    );
  }
}

Future<Map<String, dynamic>?> completePatientPaymentApi(String patientId) async {
  try {
    final response = await http.patch(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/patients/$patientId/complete-payment'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}
