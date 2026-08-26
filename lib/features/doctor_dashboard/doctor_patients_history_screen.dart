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

  PatientHistory({
    required this.id,
    required this.name,
    required this.token,
    required this.status,
    required this.updatedAt,
  });

  factory PatientHistory.fromJson(Map<String, dynamic> json) {
    return PatientHistory(
      id: json['id'],
      name: json['patient_name'] ?? 'Unknown',
      token: json['token_number'].toString(),
      status: json['status'],
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Token: #${patient.token}'),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM dd, yyyy - hh:mm a').format(patient.updatedAt),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
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
