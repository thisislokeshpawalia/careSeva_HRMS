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

final departmentOverviewProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, hospitalId) async {
  try {
    final response = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/management/$hospitalId/department-overview'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch (e) {
    // Error handling
  }
  return [];
});

class HospitalAppointmentFilter {
  final String hospitalId;
  final String? departmentId;
  final String? date;
  final String? status;

  const HospitalAppointmentFilter({
    required this.hospitalId,
    this.departmentId,
    this.date,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HospitalAppointmentFilter &&
          runtimeType == other.runtimeType &&
          hospitalId == other.hospitalId &&
          departmentId == other.departmentId &&
          date == other.date &&
          status == other.status;

  @override
  int get hashCode =>
      hospitalId.hashCode ^
      (departmentId?.hashCode ?? 0) ^
      (date?.hashCode ?? 0) ^
      (status?.hashCode ?? 0);
}

final filteredHospitalAppointmentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, HospitalAppointmentFilter>((ref, filter) async {
  try {
    String url = '${ApiConfig.httpBaseUrl}/api/appointments/hospital/${filter.hospitalId}?';
    if (filter.departmentId != null && filter.departmentId!.isNotEmpty) {
      url += 'department_id=${filter.departmentId}&';
    }
    if (filter.date != null && filter.date!.isNotEmpty) {
      url += 'date=${filter.date}&';
    }
    if (filter.status != null && filter.status!.isNotEmpty && filter.status != 'All') {
      url += 'status=${filter.status}&';
    }
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch (e) {
    // Error handling
  }
  return [];
});

class DoctorAppointmentFilter {
  final String doctorId;
  final String? date;

  const DoctorAppointmentFilter({required this.doctorId, this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorAppointmentFilter &&
          runtimeType == other.runtimeType &&
          doctorId == other.doctorId &&
          date == other.date;

  @override
  int get hashCode => doctorId.hashCode ^ (date?.hashCode ?? 0);
}

final doctorAppointmentsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, DoctorAppointmentFilter>((ref, filter) async {
  try {
    String url = '${ApiConfig.httpBaseUrl}/api/appointments/doctor/${filter.doctorId}';
    if (filter.date != null && filter.date!.isNotEmpty) {
      url += '?date=${filter.date}';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch (e) {
    // Error handling
  }
  return [];
});

Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiConfig.httpBaseUrl}/api/appointments/$appointmentId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}


