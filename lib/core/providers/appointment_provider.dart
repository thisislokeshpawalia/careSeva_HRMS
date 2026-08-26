import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';

final hospitalAppointmentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, hospitalId) async {
  try {
    final response = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/appointments/hospital/$hospitalId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch (e) {
    // Error handling
  }
  return [];
});
