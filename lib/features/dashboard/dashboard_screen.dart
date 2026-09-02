import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: statsAsyncValue.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text('Failed to load dashboard stats'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxTitleWidth = constraints.maxWidth > 600 ? constraints.maxWidth - 200 : constraints.maxWidth;
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxTitleWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Dashboard Overview',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D47A1),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Welcome back! Here is what is happening today in Indian Standard Time.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const _LiveClockBadge(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _StatCard(
                      title: 'Total Patients',
                      value: stats['total_patients'].toString(),
                      trend: 'Total Registered',
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF1565C0),
                    ),
                    _StatCard(
                      title: 'Appointments Today',
                      value: stats['appointments_today'].toString(),
                      trend: 'Today',
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF00BFA5),
                    ),
                    _StatCard(
                      title: 'Available Doctors',
                      value: stats['available_doctors'].toString(),
                      trend: 'Active',
                      icon: Icons.medical_services_outlined,
                      color: const Color(0xFF00B0FF),
                    ),
                    _StatCard(
                      title: 'Total Revenue',
                      value: '₹${NumberFormat('#,##,###').format(stats['total_revenue'] ?? stats['todays_revenue'] ?? 0)}',
                      trend: 'Today: ₹${NumberFormat('#,##,###').format(stats['todays_revenue'] ?? 0)}',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF5E35B1),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  'Recent Appointments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _RecentAppointmentsTable(appointments: stats['recent_appointments'] ?? []),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Icon(Icons.more_horiz, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _RecentAppointmentsTable extends StatelessWidget {
  final List<dynamic> appointments;
  const _RecentAppointmentsTable({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
          dataRowMaxHeight: 64,
          dataRowMinHeight: 64,
          columns: const [
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Doctor')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: appointments.map((appt) {
            Color statusColor = Colors.blue;
            if (appt['status'] == 'COMPLETED') statusColor = Colors.green;
            if (appt['status'] == 'CANCELLED') statusColor = Colors.red;
            
            return _buildRow(
              appt['patient_name'] ?? 'Unknown',
              appt['doctor_name'] ?? 'Unknown',
              appt['department_name'] ?? 'Unknown',
              appt['time'] ?? '',
              appt['status'] ?? 'SCHEDULED',
              statusColor,
            );
          }).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(String patient, String doctor, String dept, String time, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(patient, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(doctor)),
        DataCell(Text(dept, style: const TextStyle(color: Colors.grey))),
        DataCell(Text(time)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {},
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class _LiveClockBadge extends StatefulWidget {
  const _LiveClockBadge();

  @override
  State<_LiveClockBadge> createState() => _LiveClockBadgeState();
}

class _LiveClockBadgeState extends State<_LiveClockBadge> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_currentTime);
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'IST (LIVE)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

