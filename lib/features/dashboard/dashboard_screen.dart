import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Welcome back! Here is what is happening today.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _StatCard(
                  title: 'Total Patients',
                  value: '1,482',
                  trend: '+12% this month',
                  icon: Icons.people_alt_outlined,
                  color: const Color(0xFF1565C0),
                ),
                _StatCard(
                  title: 'Appointments Today',
                  value: '146',
                  trend: '24 pending',
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF00BFA5),
                ),
                _StatCard(
                  title: 'Available Doctors',
                  value: '38',
                  trend: 'Out of 50',
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFF00B0FF),
                ),
                _StatCard(
                  title: 'Today\'s Revenue',
                  value: '\$12,450',
                  trend: '+5% vs yesterday',
                  icon: Icons.payments_outlined,
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
            const _RecentAppointmentsTable(),
          ],
        ),
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
  const _RecentAppointmentsTable();

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
          rows: [],
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

