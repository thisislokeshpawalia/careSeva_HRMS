import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

final hospitalPatientsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, hospitalId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/patients/hospital/$hospitalId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load patients: ${response.statusCode}');
    }
  } catch (e) {
    return [];
  }
});

Future<Map<String, dynamic>?> registerPatientApi(Map<String, dynamic> patientData) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/patients/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patientData),
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
