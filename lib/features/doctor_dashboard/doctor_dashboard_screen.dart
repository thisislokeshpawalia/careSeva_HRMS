import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/providers/auth_provider.dart';
import '../../../core/api_config.dart';

class Patient {
  final String name;
  final String time;
  final String reason;
  final String? patientId;
  final String? appointmentId;
  final int tokenNumber;
  final Map<String, dynamic>? prescription;

  Patient(
    this.name, 
    this.time, 
    this.reason, {
    this.patientId, 
    this.appointmentId, 
    this.tokenNumber = 0,
    this.prescription,
  });
}

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  Patient? _currentPatient;
  final List<Patient> _queue = [];
  final List<Patient> _completedQueue = [];
  int _currentToken = 0;
  int _totalTokens = 0;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWebSocket();
      _fetchQueueStatus();
    });

    // Fail-safe background polling every 8 seconds:
    // Guarantees all devices stay 100% in sync even if WebSocket is reconnecting
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _fetchQueueStatus();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Send ping every 12 seconds to prevent Railway/cloud proxies from killing the connection
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_channel != null && _isConnected) {
        try {
          _channel!.sink.add(jsonEncode({'action': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    if (_reconnectTimer?.isActive ?? false) return;
    
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isReconnecting = true;
      });
    }

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _initWebSocket();
        _fetchQueueStatus();
      }
    });
  }

  void _initWebSocket() {
    final authState = ref.read(authProvider);
    final doctorId = authState.doctorId;
    
    if (doctorId != null) {
      try {
        _channel?.sink.close();
      } catch (_) {}

      try {
        _channel = WebSocketChannel.connect(
          Uri.parse('${ApiConfig.wsBaseUrl}/api/queue/ws/$doctorId'),
        );
        
        if (mounted) {
          setState(() {
            _isConnected = true;
            _isReconnecting = false;
          });
        }

        _startHeartbeat();

        _channel!.stream.listen((message) {
          try {
            final data = jsonDecode(message);
            if (data['event'] == 'pong') {
              // Heartbeat acknowledged
              return;
            }
            if (mounted) {
              setState(() {
                if (data['event'] == 'new_patient') {
                  _totalTokens = data['total_tokens'] ?? _totalTokens;
                  _fetchQueueStatus();
                } else if (data['event'] == 'queue_advanced') {
                  _currentToken = data['current_token'] ?? _currentToken;
                  _fetchQueueStatus();
                }
              });
            }
          } catch (_) {}
        }, onError: (error) {
          _scheduleReconnect();
        }, onDone: () {
          _scheduleReconnect();
        });
      } catch (e) {
        _scheduleReconnect();
      }
    }
  }

  Future<void> _fetchQueueStatus() async {
    final authState = ref.read(authProvider);
    final doctorId = authState.doctorId;
    
    if (doctorId != null) {
      try {
        final statusRes = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/queue/$doctorId/status'));
        final entriesRes = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/queue/$doctorId/entries'));
        
        if (statusRes.statusCode == 200 && entriesRes.statusCode == 200 && mounted) {
          final statusData = jsonDecode(statusRes.body);
          final List<dynamic> entriesData = jsonDecode(entriesRes.body);
          
          setState(() {
            _currentToken = statusData['current_token'] ?? 0;
            _totalTokens = statusData['total_tokens'] ?? 0;
            
            _queue.clear();
            _completedQueue.clear();
            _currentPatient = null;
            
            for (var entry in entriesData) {
              int token = entry['token_number'] ?? 0;
              String name = entry['patient_name'] ?? 'Unknown';
              String state = entry['status'] ?? 'WAITING';
              String? apptId = entry['appointment_id'];
              String? pid = entry['patient_id'];
              
              if (token == _currentToken && (state == 'CALLED' || state == 'IN_PROGRESS' || state == 'WAITING')) {
                _currentPatient = Patient(
                  '$name (Token #$token)', 
                  'Now', 
                  'Consultation',
                  patientId: pid,
                  appointmentId: apptId,
                  tokenNumber: token,
                );
              } else if (state == 'WAITING' || (token > _currentToken && state != 'COMPLETED')) {
                _queue.add(Patient(
                  '$name (Token #$token)', 
                  'Waiting', 
                  'Consultation',
                  patientId: pid,
                  appointmentId: apptId,
                  tokenNumber: token,
                ));
              } else if (state == 'COMPLETED') {
                _completedQueue.add(Patient(
                  '$name (Token #$token)', 
                  'Completed', 
                  'Consultation',
                  patientId: pid,
                  appointmentId: apptId,
                  tokenNumber: token,
                ));
              }
            }
          });
        }
      } catch (e) {
        // fail silently
      }
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _callNext() async {
    if (_queue.isNotEmpty || _currentToken < _totalTokens) {
      final authState = ref.read(authProvider);
      final doctorId = authState.doctorId;
      
      try {
        final response = await http.post(Uri.parse('${ApiConfig.httpBaseUrl}/api/queue/$doctorId/next'));
        if (response.statusCode == 200) {
          _fetchQueueStatus();
        }
      } catch (e) {
        // fail silently
      }
    }
  }

  Future<void> _completeCurrent({Map<String, dynamic>? consultationData}) async {
    if (_currentPatient != null) {
      final authState = ref.read(authProvider);
      final doctorId = authState.doctorId;
      
      try {
        final uri = Uri.parse('${ApiConfig.httpBaseUrl}/api/queue/$doctorId/complete');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(consultationData != null ? {'consultation': consultationData} : {}),
        );
        if (response.statusCode == 200) {
          _fetchQueueStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      consultationData != null 
                          ? 'Consultation & Digital Prescription saved for ${_currentPatient?.name ?? 'patient'}!'
                          : 'Patient consultation marked completed.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // fail silently
      }
    }
  }

  void _showConsultationDialog() {
    if (_currentPatient == null) return;

    final diagCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final followUpCtrl = TextEditingController(text: '7 days');

    final List<Map<String, TextEditingController>> medicines = [
      {
        'name': TextEditingController(text: 'Paracetamol 650mg'),
        'dosage': TextEditingController(text: '1-0-1'),
        'timing': TextEditingController(text: 'After Food'),
        'duration': TextEditingController(text: '3 days'),
      }
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication_liquid_rounded, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Consultation & Issue Prescription',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currentPatient?.name ?? 'Patient',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diagnosis / Symptoms',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: diagCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Viral Fever / Acute Bronchitis / Hypertension',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Prescribed Medicines',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                medicines.add({
                                  'name': TextEditingController(),
                                  'dosage': TextEditingController(text: '1-0-1'),
                                  'timing': TextEditingController(text: 'After Food'),
                                  'duration': TextEditingController(text: '5 days'),
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Medicine'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...medicines.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var med = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: med['name'],
                                  decoration: InputDecoration(
                                    labelText: 'Medicine ${idx + 1}',
                                    hintText: 'e.g. Amoxicillin 500mg',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: med['dosage'],
                                  decoration: InputDecoration(
                                    labelText: 'Dosage',
                                    hintText: '1-0-1',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: med['duration'],
                                  decoration: InputDecoration(
                                    labelText: 'Duration',
                                    hintText: '5 days',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              if (medicines.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      medicines.removeAt(idx);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Doctor Advice / Instructions',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: notesCtrl,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Drink warm fluids, avoid oily foods, get plenty of rest.',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Follow-up Review',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: followUpCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. In 7 days',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _completeCurrent();
                  },
                  child: const Text('Quick Complete (No Rx)', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final medsPayload = medicines
                        .where((m) => m['name']!.text.trim().isNotEmpty)
                        .map((m) => {
                              'name': m['name']!.text.trim(),
                              'dosage': m['dosage']!.text.trim(),
                              'timing': m['timing']!.text.trim(),
                              'duration': m['duration']!.text.trim(),
                            })
                        .toList();

                    final consultationData = {
                      'diagnosis': diagCtrl.text.trim().isNotEmpty ? diagCtrl.text.trim() : 'General Consultation',
                      'medicines': medsPayload,
                      'notes': notesCtrl.text.trim(),
                      'follow_up_date': followUpCtrl.text.trim(),
                    };

                    Navigator.pop(dialogCtx);
                    _completeCurrent(consultationData: consultationData);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Save Prescription & Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _callNext,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _callNext,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _callNext,
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (_currentPatient != null) {
            _showConsultationDialog();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Doctor Overview & Queue',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _initWebSocket();
                    _fetchQueueStatus();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.green.shade50
                          : (_isReconnecting ? Colors.amber.shade50 : Colors.red.shade50),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isConnected
                            ? Colors.green.shade300
                            : (_isReconnecting ? Colors.amber.shade300 : Colors.red.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isReconnecting)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                          )
                        else
                          Icon(
                            _isConnected ? Icons.wifi : Icons.wifi_off,
                            color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                            size: 16,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? 'Live'
                              : (_isReconnecting ? 'Reconnecting...' : 'Disconnected (Tap to sync)'),
                          style: TextStyle(
                            color: _isConnected
                                ? Colors.green.shade800
                                : (_isReconnecting ? Colors.amber.shade900 : Colors.red.shade800),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCurrentPatientCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildQueueList(),
                      const SizedBox(height: 24),
                      _buildCompletedList(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildCurrentPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENTLY CONSULTING',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          if (_currentPatient != null) ...[
            Text(
              _currentPatient!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Token: $_currentToken',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ] else ...[
            const Text(
              'No active patient',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Call the next patient from the queue to begin.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    bool hasMore = _currentToken < _totalTokens || _queue.isNotEmpty;
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: hasMore ? _callNext : null,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Call Next Patient [Enter / →]'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: _currentPatient != null ? _showConsultationDialog : null,
            icon: const Icon(Icons.medication_outlined),
            label: const Text('Prescribe & Complete [↓]'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: _currentPatient != null ? _completeCurrent : null,
          tooltip: 'Quick Complete (Skip Rx)',
          icon: const Icon(Icons.check_circle_outline),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_totalTokens - _currentToken} waiting',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_totalTokens - _currentToken <= 0)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Queue is empty',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _queue.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final patient = _queue[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      '${_currentToken + index + 1}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    patient.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(patient.reason),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedList() {
    if (_completedQueue.isEmpty) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recently Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_completedQueue.length}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _completedQueue.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final patient = _completedQueue[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.check, color: Colors.green),
                ),
                title: Text(
                  patient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                subtitle: Text('Consultation Finished'),
              );
            },
          ),
        ],
      ),
    );
  }
}
