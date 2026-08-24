import 'package:flutter/material.dart';
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

  Patient(this.name, this.time, this.reason);
}

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  Patient? _currentPatient;
  List<Patient> _queue = [];
  int _currentToken = 0;
  int _totalTokens = 0;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWebSocket();
      _fetchQueueStatus();
    });
  }

  void _initWebSocket() {
    final authState = ref.read(authProvider);
    final doctorId = authState.doctorId;
    
    if (doctorId != null) {
      _channel = WebSocketChannel.connect(
        Uri.parse('${ApiConfig.wsBaseUrl}/api/queue/ws/$doctorId'),
      );
      
      setState(() => _isConnected = true);

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        setState(() {
          if (data['event'] == 'new_patient') {
            _totalTokens = data['total_tokens'];
            _queue.add(Patient('Token #$_totalTokens', 'Now', 'Consultation'));
          } else if (data['event'] == 'queue_advanced') {
            _currentToken = data['current_token'];
          }
        });
      }, onError: (error) {
        setState(() => _isConnected = false);
      }, onDone: () {
        setState(() => _isConnected = false);
      });
    }
  }

  Future<void> _fetchQueueStatus() async {
    final authState = ref.read(authProvider);
    final doctorId = authState.doctorId;
    
    if (doctorId != null) {
      try {
        final response = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/queue/$doctorId/status'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _currentToken = data['current_token'];
            _totalTokens = data['total_tokens'];
            
            // Rebuild mock queue based on diff
            _queue.clear();
            for (int i = _currentToken + 1; i <= _totalTokens; i++) {
              _queue.add(Patient('Token #$i', 'Waiting', 'Consultation'));
            }
          });
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  void dispose() {
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
          setState(() {
            if (_queue.isNotEmpty) {
              _currentPatient = _queue.removeAt(0);
            } else {
              _currentPatient = Patient('Token #${_currentToken + 1}', 'Now', 'Consultation');
            }
          });
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void _completeCurrent() {
    setState(() {
      _currentPatient = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: _isConnected ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected ? 'Live' : 'Disconnected',
                        style: TextStyle(
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildQueueList(),
                ),
              ],
            ),
          ],
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
          child: ElevatedButton.icon(
            onPressed: hasMore ? _callNext : null,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Call Next Patient'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentPatient != null ? _completeCurrent : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Complete Current'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              foregroundColor: Colors.blue.shade800,
              side: BorderSide(color: Colors.blue.shade800),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
}
