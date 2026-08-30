import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';

class HospitalAdmissionFilter {
  final String hospitalId;
  final String? departmentId;
  final String? date;
  final String? status;
  final String? search;

  const HospitalAdmissionFilter({
    required this.hospitalId,
    this.departmentId,
    this.date,
    this.status,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HospitalAdmissionFilter &&
          runtimeType == other.runtimeType &&
          hospitalId == other.hospitalId &&
          departmentId == other.departmentId &&
          date == other.date &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode =>
      hospitalId.hashCode ^
      (departmentId?.hashCode ?? 0) ^
      (date?.hashCode ?? 0) ^
      (status?.hashCode ?? 0) ^
      (search?.hashCode ?? 0);
}

final filteredHospitalAdmissionsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, HospitalAdmissionFilter>((ref, filter) async {
  try {
    String url = '${ApiConfig.httpBaseUrl}/api/admissions/hospital/${filter.hospitalId}?';
    if (filter.departmentId != null && filter.departmentId!.isNotEmpty) {
      url += 'department_id=${Uri.encodeComponent(filter.departmentId!)}&';
    }
    if (filter.date != null && filter.date!.isNotEmpty) {
      url += 'date=${Uri.encodeComponent(filter.date!)}&';
    }
    if (filter.status != null && filter.status!.isNotEmpty && filter.status != 'All') {
      url += 'status=${Uri.encodeComponent(filter.status!)}&';
    }
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      url += 'search=${Uri.encodeComponent(filter.search!.trim())}&';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch (e) {
    // print('Error fetching admissions: $e');
  }
  return [];
});

final admissionsDepartmentOverviewProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, hospitalId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/admissions/hospital/$hospitalId/overview'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch (e) {
    // print('Error fetching admissions overview: $e');
  }
  return [];
});

Future<Map<String, dynamic>?> admitPatientApi(Map<String, dynamic> data) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/admissions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (e) {
    // print('Error admitting patient: $e');
  }
  return null;
}

Future<bool> updateAdmissionStatusApi(String admissionId, Map<String, dynamic> updateData) async {
  try {
    final response = await http.patch(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/admissions/$admissionId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
    return response.statusCode == 200;
  } catch (e) {
    // print('Error updating admission status: $e');
    return false;
  }
}
