import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/providers/appointment_provider.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final hospitalId = authState.hospitalId ?? 'dummy_hospital_123';
    
    final appointmentsAsync = ref.watch(hospitalAppointmentsProvider(hospitalId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointments & Queue',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                      ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(hospitalAppointmentsProvider(hospitalId));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search appointments...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownMenu<String>(
                  initialSelection: 'All',
                  onSelected: (String? value) {},
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'All', label: 'All'),
                    DropdownMenuEntry(value: 'Today', label: 'Today'),
                    DropdownMenuEntry(value: 'Tomorrow', label: 'Tomorrow'),
                    DropdownMenuEntry(value: 'This Week', label: 'This Week'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: appointmentsAsync.when(
                  data: (appointments) {
                    if (appointments.isEmpty) {
                      return const Center(child: Text('No appointments found.'));
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                          dataRowMaxHeight: 72,
                          dataRowMinHeight: 72,
                          columns: const [
                            DataColumn(label: Text('Date & Time')),
                            DataColumn(label: Text('Patient')),
                            DataColumn(label: Text('Age & Gender')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: appointments.map((appt) {
                            return DataRow(
                              cells: [
                                DataCell(Text(appt['appointment_date'] ?? 'N/A')),
                                DataCell(Text(appt['patient_name'] ?? 'Unknown')),
                                DataCell(Text('${appt['patient_age'] ?? '-'} / ${appt['patient_gender'] ?? '-'}')),
                                DataCell(Text(appt['patient_phone'] ?? 'N/A')),
                                DataCell(Text(appt['booking_for'] ?? 'myself')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(appt['status']).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      appt['status'] ?? 'BOOKED',
                                      style: TextStyle(
                                        color: _getStatusColor(appt['status']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                        onPressed: () {},
                                        tooltip: 'Mark Completed',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                        onPressed: () {},
                                        tooltip: 'Cancel',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'BOOKED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
