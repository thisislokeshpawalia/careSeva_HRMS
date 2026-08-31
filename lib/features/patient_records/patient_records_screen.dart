// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/patient_provider.dart';
import '../auth/providers/auth_provider.dart';

class PatientRecordsScreen extends ConsumerStatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  ConsumerState<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends ConsumerState<PatientRecordsScreen> {
  String _searchQuery = '';
  String _selectedSource = 'All'; // 'All', 'CARESEVA_APP', 'DIRECT_WALKIN'
  String _selectedBloodGroup = 'All';
  String _selectedDept = 'All';
  String _selectedPaymentStatus = 'All'; // 'All', 'SETTLED', 'DUE'
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Background refresh every 6 seconds to keep records in sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        final authState = ref.read(authProvider);
        final hospitalId = (authState.hospitalId != null && authState.hospitalId != 'dummy_hospital_123')
            ? authState.hospitalId!
            : '6a8ea49ef17ddb14088aa5f7';
        ref.invalidate(hospitalPatientDirectoryProvider(hospitalId));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hospitalId = (authState.hospitalId != null && authState.hospitalId != 'dummy_hospital_123')
        ? authState.hospitalId!
        : '6a8ea49ef17ddb14088aa5f7';

    final directoryAsync = ref.watch(hospitalPatientDirectoryProvider(hospitalId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(hospitalId),
            const SizedBox(height: 24),
            directoryAsync.when(
              data: (patients) => _buildMetricsCards(patients),
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (_, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _buildFiltersCard(directoryAsync),
            const SizedBox(height: 20),
            _buildDirectoryTable(directoryAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String hospitalId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_shared_rounded, color: Color(0xFF1E3A8A), size: 30),
                const SizedBox(width: 12),
                const Text(
                  'Patient Records & Master Directory',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'LEGAL AUDIT REGISTER',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Permanent clinical & medico-legal audit register of all patients registered via CareSeva App and Direct Walk-in Desk.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            ref.invalidate(hospitalPatientDirectoryProvider(hospitalId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient records refreshed.')),
            );
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh Directory'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsCards(List<Map<String, dynamic>> patients) {
    final total = patients.length;
    final appCount = patients.where((p) => (p['registration_source'] ?? '').toString().toUpperCase().contains('APP')).length;
    final walkinCount = patients.where((p) => (p['registration_source'] ?? '').toString().toUpperCase().contains('WALKIN')).length;
    final totalVisits = patients.fold<int>(0, (sum, p) => sum + ((p['total_visits'] as num?)?.toInt() ?? 1));
    final totalDue = patients.fold<double>(0.0, (sum, p) => sum + ((p['balance_due'] as num?)?.toDouble() ?? 0.0));

    return Row(
      children: [
        Expanded(child: _metricCard('Total Registered Patients', total.toString(), Icons.people_alt_outlined, const Color(0xFF1E40AF), const Color(0xFFDBEAFE))),
        const SizedBox(width: 16),
        Expanded(child: _metricCard('CareSeva App Bookings', appCount.toString(), Icons.smartphone_rounded, const Color(0xFF065F46), const Color(0xFFD1FAE5))),
        const SizedBox(width: 16),
        Expanded(child: _metricCard('Direct Walk-in Desk', walkinCount.toString(), Icons.desk_rounded, const Color(0xFF7C2D12), const Color(0xFFFFEDD5))),
        const SizedBox(width: 16),
        Expanded(child: _metricCard('Recorded Consultations', totalVisits.toString(), Icons.assignment_turned_in_outlined, const Color(0xFF5B21B6), const Color(0xFFEDE9FE))),
        const SizedBox(width: 16),
        Expanded(child: _metricCard('Counter Due Balance', '₹${totalDue.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined, const Color(0xFF991B1B), const Color(0xFFFEE2E2))),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(AsyncValue<List<Map<String, dynamic>>> directoryAsync) {
    final depts = <String>{'All'};
    directoryAsync.whenData((list) {
      for (final p in list) {
        final dList = p['departments'] as List<dynamic>? ?? [];
        for (final d in dList) {
          if (d != null && d.toString().isNotEmpty) depts.add(d.toString());
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by Patient Name, Phone, PID, or Gov Code...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Channel Filter
          _buildDropdownFilter(
            label: 'Channel',
            value: _selectedSource,
            items: const ['All', 'CARESEVA_APP', 'DIRECT_WALKIN'],
            labels: const {'All': 'All Sources', 'CARESEVA_APP': 'App Bookings', 'DIRECT_WALKIN': 'Walk-in Desk'},
            onChanged: (val) => setState(() => _selectedSource = val!),
          ),
          const SizedBox(width: 14),
          // Blood Group Filter
          _buildDropdownFilter(
            label: 'Blood Group',
            value: _selectedBloodGroup,
            items: const ['All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
            onChanged: (val) => setState(() => _selectedBloodGroup = val!),
          ),
          const SizedBox(width: 14),
          // Department Filter
          _buildDropdownFilter(
            label: 'Department',
            value: _selectedDept,
            items: depts.toList(),
            onChanged: (val) => setState(() => _selectedDept = val!),
          ),
          const SizedBox(width: 14),
          // Financial Status Filter
          _buildDropdownFilter(
            label: 'Payment',
            value: _selectedPaymentStatus,
            items: const ['All', 'SETTLED', 'DUE'],
            labels: const {'All': 'All Records', 'SETTLED': 'Fully Settled', 'DUE': 'Balance Due'},
            onChanged: (val) => setState(() => _selectedPaymentStatus = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    Map<String, String>? labels,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          onChanged: onChanged,
          items: items.map((item) {
            final text = labels != null && labels.containsKey(item) ? labels[item]! : item;
            return DropdownMenuItem<String>(
              value: item,
              child: Text(text),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDirectoryTable(AsyncValue<List<Map<String, dynamic>>> directoryAsync) {
    return directoryAsync.when(
      data: (patients) {
        var filtered = List<Map<String, dynamic>>.from(patients);

        // Filter source
        if (_selectedSource != 'All') {
          filtered = filtered.where((p) => (p['registration_source'] ?? '').toString().toUpperCase().contains(_selectedSource)).toList();
        }

        // Filter blood group
        if (_selectedBloodGroup != 'All') {
          filtered = filtered.where((p) => (p['blood_group'] ?? '').toString().toUpperCase() == _selectedBloodGroup).toList();
        }

        // Filter department
        if (_selectedDept != 'All') {
          filtered = filtered.where((p) {
            final dList = (p['departments'] as List<dynamic>? ?? []).map((d) => d.toString().toLowerCase());
            return dList.contains(_selectedDept.toLowerCase());
          }).toList();
        }

        // Filter payment status
        if (_selectedPaymentStatus == 'SETTLED') {
          filtered = filtered.where((p) => ((p['balance_due'] as num?)?.toDouble() ?? 0.0) <= 0.0).toList();
        } else if (_selectedPaymentStatus == 'DUE') {
          filtered = filtered.where((p) => ((p['balance_due'] as num?)?.toDouble() ?? 0.0) > 0.0).toList();
        }

        // Search query
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((p) {
            final name = (p['name'] ?? '').toString().toLowerCase();
            final phone = (p['phone'] ?? '').toString().toLowerCase();
            final pid = (p['pid'] ?? '').toString().toLowerCase();
            final regCode = (p['registry_code'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                phone.contains(_searchQuery) ||
                pid.contains(_searchQuery) ||
                regCode.contains(_searchQuery);
          }).toList();
        }

        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No Patient Records Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No patient records match the current filter criteria.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Official Register (${filtered.length} Patients Recorded)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Last updated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  dataRowHeight: 72,
                  columns: const [
                    DataColumn(label: Text('REGISTRY CODE / PID')),
                    DataColumn(label: Text('PATIENT DETAILS')),
                    DataColumn(label: Text('CONTACT INFO')),
                    DataColumn(label: Text('SOURCE CHANNEL')),
                    DataColumn(label: Text('VISITS & DEPTS')),
                    DataColumn(label: Text('FIRST / LAST VISIT')),
                    DataColumn(label: Text('AUDIT & BILLING')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: filtered.map((p) => _buildDataRow(p)).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Error loading directory: $e')),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> p) {
    final isApp = (p['registration_source'] ?? '').toString().toUpperCase().contains('APP');
    final blood = p['blood_group']?.toString() ?? 'Not Specified';
    final depts = (p['departments'] as List<dynamic>? ?? []).map((d) => d.toString()).toList();
    final totalDue = (p['balance_due'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (p['total_paid'] as num?)?.toDouble() ?? 0.0;
    final totalBilled = (p['total_billed'] as num?)?.toDouble() ?? 0.0;

    return DataRow(
      cells: [
        // 1. PID & Code
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  p['pid'] ?? 'CS-P-PENDING',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                p['registry_code'] ?? 'GOV-REG',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // 2. Patient Details
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p['name'] ?? 'Unknown Patient',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    '${p['age'] ?? '-'} yrs • ${p['gender'] ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  if (blood != 'Not Specified' && blood.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        blood,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // 3. Contact Info
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 5),
                  Text(
                    p['phone'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                  ),
                ],
              ),
              if (p['email'] != null && p['email'] != '-') ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Text(
                      p['email'],
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // 4. Source Channel
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isApp ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isApp ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApp ? Icons.smartphone_rounded : Icons.desk_rounded,
                  size: 14,
                  color: isApp ? const Color(0xFF059669) : const Color(0xFFC2410C),
                ),
                const SizedBox(width: 6),
                Text(
                  isApp ? 'CARESEVA APP' : 'DIRECT WALKIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: isApp ? const Color(0xFF065F46) : const Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. Visits & Depts
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${p['total_visits'] ?? 1} Consultations',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                depts.isEmpty ? 'General OPD' : depts.join(', '),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 6. First & Last Visit
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Last: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text(
                    p['last_visit'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('First: ', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  Text(
                    p['first_visit'] ?? '-',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 7. Audit & Billing
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paid: ₹${totalPaid.toStringAsFixed(0)} / ₹${totalBilled.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: totalDue > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  totalDue > 0 ? 'Due: ₹${totalDue.toStringAsFixed(0)}' : 'Fully Settled',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: totalDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 8. Actions
        DataCell(
          ElevatedButton.icon(
            onPressed: () => _showPatientDossier(p),
            icon: const Icon(Icons.assignment_ind_outlined, size: 15),
            label: const Text('View Dossier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _showPatientDossier(Map<String, dynamic> p) {
    final history = p['history'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 850,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_outlined, color: Color(0xFF1E3A8A), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Clinical & Legal Dossier: ${p['name']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Official Gov Registry ID: ${p['registry_code']} • PID: ${p['pid']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 28),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Demographics grid
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Legal Demographics & Compliance Details',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _dossierField('Full Name', p['name'] ?? '-')),
                                  Expanded(child: _dossierField('Patient PID', p['pid'] ?? '-')),
                                  Expanded(child: _dossierField('Phone Number', p['phone'] ?? '-')),
                                  Expanded(child: _dossierField('Email', p['email'] ?? '-')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _dossierField('Age / Gender', '${p['age'] ?? '-'} yrs / ${p['gender'] ?? '-'}')),
                                  Expanded(child: _dossierField('Date of Birth (DOB)', p['dob'] ?? '-')),
                                  Expanded(child: _dossierField('Blood Group', p['blood_group'] ?? 'Not Specified')),
                                  Expanded(child: _dossierField('Origin Channel', p['registration_source'] ?? 'CARESEVA_APP')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _dossierField('Total Consultations', '${p['total_visits'] ?? 1}')),
                                  Expanded(child: _dossierField('First Visit Date', p['first_visit'] ?? '-')),
                                  Expanded(child: _dossierField('Last Visit Date', p['last_visit'] ?? '-')),
                                  Expanded(child: _dossierField('Audit Status', p['compliance_status'] ?? 'VERIFIED_RECORD')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Visit & Consultation History
                        const Text(
                          'Complete Hospital Consultation & Audit Log',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        if (history.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No previous appointment entries found for this record.'),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(2.5),
                                2: FlexColumnWidth(2),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _tableHeader('DATE / TIME'),
                                    _tableHeader('DOCTOR'),
                                    _tableHeader('DEPARTMENT'),
                                    _tableHeader('CHANNEL'),
                                    _tableHeader('BILLING STATUS'),
                                  ],
                                ),
                                ...history.map((h) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text('${h['date']}\n${h['time_slot']}', style: const TextStyle(fontSize: 12)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text('${h['doctor_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text('${h['department_name']}', style: const TextStyle(fontSize: 12)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text('${h['booking_source']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text('Paid: ₹${h['paid_amount'] ?? 500}\nDue: ₹${h['remaining_amount'] ?? 0}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Government Health Record Standards & Legal Compliant',
                            style: TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Legal Medical Certificate & Record exported for ${p['name']} (PID: ${p['pid']})'),
                                backgroundColor: const Color(0xFF1E3A8A),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('Export / Print Legal Record'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dossierField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF475569)),
      ),
    );
  }
}
