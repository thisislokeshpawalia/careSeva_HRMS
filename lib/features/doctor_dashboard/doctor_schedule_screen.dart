import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/providers/appointment_provider.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  ConsumerState<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All'; // 'All', 'BOOKED', 'COMPLETED', 'CANCELLED'
  bool _isAvailable = true;
  final String _shiftTiming = '09:00 AM - 05:00 PM';
  String _selectedQuickDate = 'Today'; // 'Today', 'Tomorrow', 'All'

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final doctorId = authState.doctorId ?? '';

    final filterDate = _selectedQuickDate == 'All' 
        ? null 
        : DateFormat('yyyy-MM-dd').format(_selectedDate);

    final appointmentsAsync = ref.watch(
      doctorAppointmentsProvider(
        DoctorAppointmentFilter(doctorId: doctorId, date: filterDate),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, doctorId),
            const SizedBox(height: 20),
            _buildScheduleOverview(appointmentsAsync),
            const SizedBox(height: 20),
            _buildFilterBar(),
            const SizedBox(height: 16),
            Expanded(
              child: appointmentsAsync.when(
                data: (appointments) => _buildAppointmentsList(appointments, doctorId),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading schedule: $e'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _refreshSchedule(doctorId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshSchedule(String doctorId) {
    final filterDate = _selectedQuickDate == 'All' 
        ? null 
        : DateFormat('yyyy-MM-dd').format(_selectedDate);
    ref.invalidate(
      doctorAppointmentsProvider(
        DoctorAppointmentFilter(doctorId: doctorId, date: filterDate),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String doctorId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Schedule & Appointments',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your daily consultation slots and patient bookings',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isAvailable ? Colors.green.shade300 : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAvailable ? Icons.check_circle : Icons.pause_circle_filled,
                    color: _isAvailable ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAvailable ? 'Available for Walk-ins' : 'On Break / Busy',
                    style: TextStyle(
                      color: _isAvailable ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isAvailable,
                    activeThumbColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        _isAvailable = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val ? 'Status updated: Available for Consultations' : 'Status updated: On Break',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: () => _refreshSchedule(doctorId),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Schedule',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleOverview(AsyncValue<List<Map<String, dynamic>>> asyncAppts) {
    int total = 0;
    int completed = 0;
    int booked = 0;

    asyncAppts.whenData((list) {
      total = list.length;
      completed = list.where((a) => a['status'] == 'COMPLETED').length;
      booked = list.where((a) => a['status'] == 'BOOKED' || a['status'] == 'CONFIRMED' || a['status'] == 'WAITING').length;
    });

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Selected Schedule',
            value: _selectedQuickDate == 'All' 
                ? 'All Dates' 
                : DateFormat('EEE, MMM dd').format(_selectedDate),
            icon: Icons.calendar_month,
            accentColor: const Color(0xFF1565C0),
            subtitle: 'Shift: $_shiftTiming',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Total Appointments',
            value: '$total',
            icon: Icons.people_alt_outlined,
            accentColor: const Color(0xFF00838F),
            subtitle: 'Booked patients for slot',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Pending Consultations',
            value: '$booked',
            icon: Icons.hourglass_top,
            accentColor: Colors.orange.shade700,
            subtitle: 'In queue & scheduled',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Completed',
            value: '$completed',
            icon: Icons.check_circle_outline,
            accentColor: Colors.green.shade700,
            subtitle: 'Consultations finished',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Today'),
                selected: _selectedQuickDate == 'Today',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedQuickDate = 'Today';
                      _selectedDate = DateTime.now();
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Tomorrow'),
                selected: _selectedQuickDate == 'Tomorrow',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedQuickDate = 'Tomorrow';
                      _selectedDate = DateTime.now().add(const Duration(days: 1));
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Upcoming'),
                selected: _selectedQuickDate == 'All',
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedQuickDate = 'All';
                    });
                  }
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _pickCustomDate(context),
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(
                  _selectedQuickDate == 'Custom' 
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate)
                      : 'Pick Date',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(
                    color: _selectedQuickDate == 'Custom' ? const Color(0xFF1565C0) : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Status Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'BOOKED', child: Text('Booked / Waiting')),
                  DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFilter = val;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
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
        _selectedQuickDate = 'Custom';
      });
    }
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, String doctorId) {
    var filtered = appointments;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((a) => a['status'] == _selectedFilter).toList();
    }

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, size: 64, color: Colors.blue.shade200),
              const SizedBox(height: 16),
              Text(
                'No appointments found for this selection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have no scheduled appointments matching the filters.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final appt = filtered[index];
          final String apptId = appt['id'] ?? '';
          final String patientName = appt['patient_name'] ?? 'Unknown Patient';
          final String date = appt['appointment_date'] ?? 'Today';
          final String status = appt['status'] ?? 'BOOKED';
          final String phone = appt['patient_phone'] ?? 'N/A';
          final String ageGender = '${appt['patient_age'] ?? '-'} yrs / ${appt['patient_gender'] ?? '-'}';
          final String bookingType = appt['booking_for'] ?? 'myself';

          Color statusColor = Colors.blue;
          IconData statusIcon = Icons.schedule;
          if (status == 'COMPLETED') {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
          } else if (status == 'CANCELLED') {
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1565C0).withAlpha(20),
                  child: Text(
                    patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bookingType == 'myself' ? 'Self' : 'Family Member',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(ageGender, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(width: 16),
                          Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(phone, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(date, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (status != 'COMPLETED' && status != 'CANCELLED') ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    tooltip: 'Mark as Completed',
                    onPressed: () async {
                      final success = await updateAppointmentStatus(apptId, 'COMPLETED');
                      if (success) {
                        _refreshSchedule(doctorId);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Cancel Appointment',
                    onPressed: () async {
                      final success = await updateAppointmentStatus(apptId, 'CANCELLED');
                      if (success) {
                        _refreshSchedule(doctorId);
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
