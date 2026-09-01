import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../auth/providers/auth_provider.dart';
import '../../../core/api_config.dart';

class PatientHistory {
  final String id;
  final String name;
  final String token;
  final String status;
  final DateTime updatedAt;
  final String? appointmentDate;
  final String? appointmentTime;
  final DateTime? createdAt;
  final String? timeSlot;
  final String? patientPhone;
  final int? patientAge;
  final String? patientGender;

  PatientHistory({
    required this.id,
    required this.name,
    required this.token,
    required this.status,
    required this.updatedAt,
    this.appointmentDate,
    this.appointmentTime,
    this.createdAt,
    this.timeSlot,
    this.patientPhone,
    this.patientAge,
    this.patientGender,
  });

  static DateTime _parseDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw.toLocal();
    try {
      String str = raw.toString().trim();
      if (!str.endsWith('Z') && !str.contains('+')) {
        return DateTime.parse('${str}Z').toLocal();
      }
      return DateTime.parse(str).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  factory PatientHistory.fromJson(Map<String, dynamic> json) {
    return PatientHistory(
      id: json['id'] ?? '',
      name: json['patient_name'] ?? 'Unknown',
      token: json['token_number'].toString(),
      status: json['status'] ?? 'COMPLETED',
      updatedAt: _parseDateTime(json['updated_at']),
      appointmentDate: json['appointment_date'],
      appointmentTime: json['appointment_time'],
      createdAt: json['created_at'] != null ? _parseDateTime(json['created_at']) : null,
      timeSlot: json['time_slot'],
      patientPhone: json['patient_phone'],
      patientAge: json['patient_age'] is int ? json['patient_age'] : int.tryParse(json['patient_age']?.toString() ?? ''),
      patientGender: json['patient_gender'],
    );
  }
}

class DoctorPatientsHistoryScreen extends ConsumerStatefulWidget {
  const DoctorPatientsHistoryScreen({super.key});

  @override
  ConsumerState<DoctorPatientsHistoryScreen> createState() => _DoctorPatientsHistoryScreenState();
}

class _DoctorPatientsHistoryScreenState extends ConsumerState<DoctorPatientsHistoryScreen> {
  List<PatientHistory> _history = [];
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    final authState = ref.read(authProvider);
    final doctorId = authState.doctorId;
    
    if (doctorId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      String url = '${ApiConfig.httpBaseUrl}/api/queue/$doctorId/history';
      if (_selectedDate != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        url += '?date=$dateStr';
      }
      
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _history = data.map((e) => PatientHistory.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchHistory();
    }
  }

  String _formatRowDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final trimmed = dateStr.trim();
      if (trimmed.startsWith('20')) {
        final parsed = DateTime.parse(trimmed);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final apptDate = DateTime(parsed.year, parsed.month, parsed.day);

        final diffDays = apptDate.difference(today).inDays;
        final formattedDate = DateFormat('dd MMM yyyy').format(parsed);

        if (diffDays == 0) {
          return 'Today, $formattedDate';
        } else if (diffDays == 1) {
          return 'Tomorrow, $formattedDate';
        } else if (diffDays == -1) {
          return 'Yesterday, $formattedDate';
        } else {
          return formattedDate;
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime24(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Patients History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Row(
                  children: [
                    if (_selectedDate != null)
                      Text(
                        'Filtering by: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Filter Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Clear Filter',
                        onPressed: () {
                          setState(() => _selectedDate = null);
                          _fetchHistory();
                        },
                      ),
                    ]
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                _selectedDate == null
                                    ? 'No patient history found.'
                                    : 'No patients found on this date.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(0),
                            itemCount: _history.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final patient = _history[index];
                              
                              Color statusColor = Colors.green;
                              IconData statusIcon = Icons.check_circle;
                              
                              if (patient.status == 'CANCELLED') {
                                statusColor = Colors.red;
                                statusIcon = Icons.cancel;
                              } else if (patient.status == 'NO_SHOW') {
                                statusColor = Colors.orange;
                                statusIcon = Icons.person_off;
                              }
                              
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1565C0).withAlpha(20),
                                  child: Text(
                                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  patient.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Builder(
                                  builder: (context) {
                                    final displayDate = (patient.appointmentDate != null && patient.appointmentDate!.isNotEmpty)
                                        ? _formatRowDate(patient.appointmentDate)
                                        : DateFormat('dd MMM yyyy').format(patient.updatedAt);
                                    final completedTime = _formatTime24(patient.updatedAt);
                                    final bookedTime = patient.appointmentTime ?? (patient.createdAt != null ? _formatTime24(patient.createdAt) : '');
                                    
                                    final details = [
                                      if (patient.patientAge != null && patient.patientAge! > 0) '${patient.patientAge} yrs',
                                      if (patient.patientGender != null && patient.patientGender != '-') patient.patientGender,
                                      if (patient.patientPhone != null && patient.patientPhone!.isNotEmpty) patient.patientPhone,
                                    ].join(' • ');

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Token: #${patient.token}',
                                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                                            ),
                                            if (details.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text('($details)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF1565C0)),
                                            const SizedBox(width: 4),
                                            Text(
                                              displayDate,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.access_time, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              bookedTime.isNotEmpty
                                                  ? 'Booked $bookedTime • Completed $completedTime'
                                                  : 'Completed $completedTime',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withAlpha(50)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        patient.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
