import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_config.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/providers/patient_provider.dart';
import '../../core/providers/appointment_provider.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String _searchQuery = '';
  String _selectedViaFilter = 'All'; // 'All', 'DIRECT_WALKIN', 'CARESEVA_APP'
  String _selectedDeptFilter = 'All'; // 'All' or specific department name
  String _selectedDateFilterMode = 'All'; // 'All', 'Choose Date', 'Yesterday', 'Today', 'Tomorrow'
  String _selectedPaymentFilter = 'All'; // 'All', 'DONE', 'PENDING'
  DateTime? _customSelectedDate;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    // Real-time background auto-sync every 20 seconds
    // Ensures new patient bookings appear while preventing network congestion
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        final authState = ref.read(authProvider);
        final hospitalId = (authState.hospitalId != null && authState.hospitalId != 'dummy_hospital_123')
            ? authState.hospitalId!
            : '6a8ea49ef17ddb14088aa5f7';
        ref.invalidate(hospitalPatientsProvider(hospitalId));
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hospitalId = (authState.hospitalId != null && authState.hospitalId != 'dummy_hospital_123')
        ? authState.hospitalId!
        : '6a8ea49ef17ddb14088aa5f7';

    final patientsAsync = ref.watch(hospitalPatientsProvider(hospitalId));
    final deptOverviewAsync = ref.watch(departmentOverviewProvider(hospitalId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(hospitalId, deptOverviewAsync),
            const SizedBox(height: 20),
            _buildSearchBarAndFilters(deptOverviewAsync),
            const SizedBox(height: 16),
            _buildActiveFilterBanner(),
            const SizedBox(height: 16),
            _buildRegistryTable(patientsAsync, hospitalId),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    String hospitalId,
    AsyncValue<List<Map<String, dynamic>>> deptOverviewAsync,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Patients Registry',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF1565C0)),
                      const SizedBox(width: 6),
                      Text(
                        'CROSS-PLATFORM (APP + HMS DESK)',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Unified patient directory from CareSeva Mobile App and Hospital Walk-in Registrations sequenced by timestamp',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            const _LiveClockBadge(),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _openRegisterPatientDialog(hospitalId, deptOverviewAsync),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Register Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBarAndFilters(AsyncValue<List<Map<String, dynamic>>> deptOverviewAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search Field + Platform Filter + Department Filter + Payment Status Filter
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by patient name, PID (e.g. CS-P-10001), phone, or department...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Filter by Platform (Via)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedViaFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Platforms (Both)')),
                        DropdownMenuItem(value: 'CARESEVA_APP', child: Text('📱 CareSeva App')),
                        DropdownMenuItem(value: 'DIRECT_WALKIN', child: Text('🏥 Direct Walk-in')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedViaFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filter by Department
              Expanded(
                flex: 3,
                child: deptOverviewAsync.when(
                  data: (departments) {
                    final deptNames = ['All', ...departments.map((d) => d['name'] as String? ?? '').where((n) => n.isNotEmpty).toSet()];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: deptNames.contains(_selectedDeptFilter) ? _selectedDeptFilter : 'All',
                          items: deptNames.map((name) {
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name == 'All' ? 'All Departments' : name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDeptFilter = val;
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 48),
                  error: (e, s) => const SizedBox(height: 48),
                ),
              ),
              const SizedBox(width: 10),
              // Filter by Payment Status
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPaymentFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Payments')),
                        DropdownMenuItem(value: 'DONE', child: Text('✓ Paid (100%)')),
                        DropdownMenuItem(value: 'PENDING', child: Text('⚠ Pending (80% Due)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPaymentFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Row 2: Date Filter Bar
          Row(
            children: [
              const Text(
                'Filter Date:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 12),
              // 1. Choose Date (Calendar)
              ActionChip(
                avatar: const Icon(Icons.calendar_month, size: 16, color: Color(0xFF1565C0)),
                label: Text(
                  _selectedDateFilterMode == 'Choose Date' && _customSelectedDate != null
                      ? DateFormat('yyyy/MM/dd').format(_customSelectedDate!)
                      : 'Choose Date',
                  style: TextStyle(
                    color: _selectedDateFilterMode == 'Choose Date' ? const Color(0xFF1565C0) : Colors.grey.shade800,
                    fontWeight: _selectedDateFilterMode == 'Choose Date' ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                backgroundColor: _selectedDateFilterMode == 'Choose Date'
                    ? const Color(0xFF1565C0).withAlpha(25)
                    : Colors.grey.shade100,
                side: BorderSide(
                  color: _selectedDateFilterMode == 'Choose Date'
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade300,
                ),
                onPressed: () => _openDatePicker(context),
              ),
              const SizedBox(width: 8),
              // 2. Yesterday
              ChoiceChip(
                label: const Text('Yesterday'),
                selected: _selectedDateFilterMode == 'Yesterday',
                selectedColor: const Color(0xFF1565C0).withAlpha(25),
                onSelected: (val) {
                  setState(() {
                    _selectedDateFilterMode = val ? 'Yesterday' : 'All';
                    _customSelectedDate = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              // 3. Today
              ChoiceChip(
                label: const Text('Today'),
                selected: _selectedDateFilterMode == 'Today',
                selectedColor: const Color(0xFF1565C0).withAlpha(25),
                onSelected: (val) {
                  setState(() {
                    _selectedDateFilterMode = val ? 'Today' : 'All';
                    _customSelectedDate = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              // 4. Tomorrow
              ChoiceChip(
                label: const Text('Tomorrow'),
                selected: _selectedDateFilterMode == 'Tomorrow',
                selectedColor: const Color(0xFF1565C0).withAlpha(25),
                onSelected: (val) {
                  setState(() {
                    _selectedDateFilterMode = val ? 'Tomorrow' : 'All';
                    _customSelectedDate = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              // 5. All Dates (Reset)
              ChoiceChip(
                label: const Text('All Dates'),
                selected: _selectedDateFilterMode == 'All',
                selectedColor: const Color(0xFF1565C0).withAlpha(25),
                onSelected: (val) {
                  setState(() {
                    _selectedDateFilterMode = 'All';
                    _customSelectedDate = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    final hasFilters = _selectedViaFilter != 'All' ||
        _selectedDeptFilter != 'All' ||
        _selectedDateFilterMode != 'All' ||
        _selectedPaymentFilter != 'All' ||
        _searchQuery.isNotEmpty;

    if (!hasFilters) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 18),
            const SizedBox(width: 10),
            const Text(
              'Showing all registered patients from CareSeva App and Direct HMS Desk, sorted chronologically by timestamp.',
              style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0D47A1).withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, color: Color(0xFF0D47A1), size: 18),
              const SizedBox(width: 8),
              const Text('Active Filters: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (_selectedViaFilter != 'All')
                _buildActiveChip(
                  _selectedViaFilter == 'CARESEVA_APP' ? '📱 CareSeva App' : '🏥 Direct Walk-in',
                  () => setState(() => _selectedViaFilter = 'All'),
                ),
              if (_selectedDeptFilter != 'All')
                _buildActiveChip(
                  'Dept: $_selectedDeptFilter',
                  () => setState(() => _selectedDeptFilter = 'All'),
                ),
              if (_selectedPaymentFilter != 'All')
                _buildActiveChip(
                  _selectedPaymentFilter == 'DONE' ? '✓ Paid' : '⚠ Pending',
                  () => setState(() => _selectedPaymentFilter = 'All'),
                ),
              if (_selectedDateFilterMode != 'All')
                _buildActiveChip(
                  'Date: $_selectedDateFilterMode',
                  () => setState(() {
                    _selectedDateFilterMode = 'All';
                    _customSelectedDate = null;
                  }),
                ),
              if (_searchQuery.isNotEmpty)
                _buildActiveChip(
                  'Search: "$_searchQuery"',
                  () => setState(() => _searchQuery = ''),
                ),
            ],
          ),
          InkWell(
            onTap: () {
              setState(() {
                _selectedViaFilter = 'All';
                _selectedDeptFilter = 'All';
                _selectedPaymentFilter = 'All';
                _selectedDateFilterMode = 'All';
                _customSelectedDate = null;
                _searchQuery = '';
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text('Clear All Filters', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? DateTime.now(),
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
        _selectedDateFilterMode = 'Choose Date';
        _customSelectedDate = picked;
      });
    }
  }

  String? _getDateFilterString() {
    final now = DateTime.now();
    if (_selectedDateFilterMode == 'Choose Date' && _customSelectedDate != null) {
      return DateFormat('yyyy-MM-dd').format(_customSelectedDate!);
    } else if (_selectedDateFilterMode == 'Yesterday') {
      return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    } else if (_selectedDateFilterMode == 'Today') {
      return DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedDateFilterMode == 'Tomorrow') {
      return DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    }
    return null; // 'All'
  }

  DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (raw is DateTime) return raw.toLocal();
    try {
      String str = raw.toString().trim();
      if (!str.endsWith('Z') && !str.contains('+')) {
        return DateTime.parse('${str}Z').toLocal();
      }
      return DateTime.parse(str).toLocal();
    } catch (e) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Widget _buildRegistryTable(
    AsyncValue<List<Map<String, dynamic>>> patientsAsync,
    String hospitalId,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: patientsAsync.when(
        skipLoadingOnRefresh: true,
        data: (patients) {
          // 1. Sort by latest activity / visit timestamp descending (newest activity / registrations at top)
          var filtered = List<Map<String, dynamic>>.from(patients);
          filtered.sort((a, b) {
            final timeA = _parseTimestamp(a['updated_at'] ?? a['created_at']);
            final timeB = _parseTimestamp(b['updated_at'] ?? b['created_at']);
            return timeB.compareTo(timeA);
          });

          // 2. Filter by Platform (Via)
          if (_selectedViaFilter != 'All') {
            filtered = filtered.where((p) {
              final src = (p['registration_source'] ?? '').toString().toUpperCase();
              return src.contains(_selectedViaFilter);
            }).toList();
          }

          // 3. Filter by Department
          if (_selectedDeptFilter != 'All') {
            filtered = filtered.where((p) {
              final dept = (p['department_name'] ?? '').toString().toLowerCase();
              return dept == _selectedDeptFilter.toLowerCase();
            }).toList();
          }

          // 4. Filter by Payment Status
          if (_selectedPaymentFilter != 'All') {
            filtered = filtered.where((p) {
              final pay = (p['payment_status'] ?? 'DONE').toString().toUpperCase();
              return pay == _selectedPaymentFilter;
            }).toList();
          }

          // 5. Filter by Date
          final dateTarget = _getDateFilterString();
          if (dateTarget != null) {
            filtered = filtered.where((p) {
              final createdDt = _parseTimestamp(p['created_at']);
              final createdStr = DateFormat('yyyy-MM-dd').format(createdDt);
              final lastVisit = (p['last_visit'] ?? '').toString().replaceAll('/', '-');
              return createdStr == dateTarget || lastVisit == dateTarget;
            }).toList();
          }

          // 6. Search query
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((p) {
              final name = (p['name'] ?? '').toString().toLowerCase();
              final pid = (p['pid'] ?? '').toString().toLowerCase();
              final phone = (p['phone'] ?? '').toString().toLowerCase();
              final dept = (p['department_name'] ?? '').toString().toLowerCase();
              final src = (p['registration_source'] ?? '').toString().toLowerCase();
              final pay = (p['payment_status'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) ||
                  pid.contains(_searchQuery) ||
                  phone.contains(_searchQuery) ||
                  dept.contains(_searchQuery) ||
                  src.contains(_searchQuery) ||
                  pay.contains(_searchQuery);
            }).toList();
          }

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No matching patients found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your platform, department, payment, or date filters.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Registered Patients (${filtered.length} entries • Arranged Chronologically by Timestamp)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Refresh Patient Registry',
                      onPressed: () => ref.invalidate(hospitalPatientsProvider(hospitalId)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  dataRowMaxHeight: 74,
                  dataRowMinHeight: 74,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn(label: Text('Patient ID (PID)')),
                    DataColumn(label: Text('Patient Name')),
                    DataColumn(label: Text('DOB & Age')),
                    DataColumn(label: Text('Gender')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Last Visit')),
                    DataColumn(label: Text('Via (Platform)')),
                    DataColumn(label: Text('Payment Status')),
                    DataColumn(label: Text('Registered At (IST)')),
                  ],
                  rows: filtered.map((p) {
                    final pid = p['pid'] ?? 'N/A';
                    final name = p['name'] ?? 'Unknown';
                    final dob = p['dob'] ?? '';
                    final age = p['age'] ?? 0;
                    final gender = p['gender'] ?? '-';
                    final phone = p['phone'] ?? 'N/A';
                    final deptName = p['department_name'] ?? 'General';
                    final lastVisit = p['last_visit'] ?? '-';
                    final rawSource = (p['registration_source'] ?? 'DIRECT_WALKIN').toString().toUpperCase();
                    final isDirect = rawSource.contains('DIRECT') || rawSource.contains('WALKIN') || rawSource.contains('HMS');
                    final registeredAt = _formatTimestamp(p['created_at']);

                    // Payment status breakdown
                    final paymentStatus = (p['payment_status'] ?? 'DONE').toString().toUpperCase();
                    final isPaidDone = paymentStatus == 'DONE';
                    final totalFee = (p['total_fee'] ?? 500).toString();
                    final remainingAmount = (p['remaining_amount'] ?? (isPaidDone ? 0 : 400)).toString();

                    return DataRow(
                      cells: [
                        // PID Cell
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D47A1).withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0D47A1).withAlpha(40)),
                            ),
                            child: Text(
                              pid,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        // Patient Name Cell
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1565C0).withAlpha(20),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        // DOB & Age Cell
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$age Yrs',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if (dob.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dob.replaceAll('-', '/'),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Gender Cell
                        DataCell(Text(gender)),
                        // Phone Cell
                        DataCell(Text(phone)),
                        // Department Cell
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withAlpha(18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.local_hospital, size: 13, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                deptName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Last Visit Cell
                        DataCell(Text(lastVisit.replaceAll('-', '/'))),
                        // Via (Platform Source) Cell
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDirect ? Colors.purple.shade50 : const Color(0xFF1565C0).withAlpha(18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDirect ? Colors.purple.shade200 : const Color(0xFF1565C0).withAlpha(40),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDirect ? Icons.how_to_reg : Icons.phone_android,
                                  size: 13,
                                  color: isDirect ? Colors.purple.shade700 : const Color(0xFF1565C0),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isDirect ? 'Direct Walk-in' : 'CareSeva App',
                                  style: TextStyle(
                                    color: isDirect ? Colors.purple.shade800 : const Color(0xFF0D47A1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Payment Status Cell
                        DataCell(
                          isPaidDone
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Done (100%)',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '₹$totalFee Paid',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Tooltip(
                                  message: 'Click to collect remaining 80% fee at counter',
                                  child: InkWell(
                                    onTap: () => _openPaymentSettlementDialog(p, hospitalId),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.shade400),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.pending_actions, size: 14, color: Colors.amber.shade900),
                                          const SizedBox(width: 6),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Pending (80%)',
                                                    style: TextStyle(
                                                      color: Colors.amber.shade900,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.shade300,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text('Pay', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Due: ₹$remainingAmount',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Registered At Timestamp Cell
                        DataCell(
                          Text(
                            registeredAt,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('Error loading patient registry: $e')),
        ),
      ),
    );
  }

  void _openPaymentSettlementDialog(Map<String, dynamic> patient, String hospitalId) {
    final pid = patient['pid'] ?? 'N/A';
    final name = patient['name'] ?? 'Patient';
    final totalFee = (patient['total_fee'] ?? 500).toString();
    final paidAmount = (patient['paid_amount'] ?? 100).toString();
    final remainingAmount = (patient['remaining_amount'] ?? 400).toString();
    final patientId = patient['id'] ?? patient['pid'];

    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.payment, color: Color(0xFF1565C0)),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Counter Fee Settlement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Patient Name:', style: TextStyle(color: Colors.grey)),
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Patient ID (PID):', style: TextStyle(color: Colors.grey)),
                              Text(pid, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Appointment Fee:', style: TextStyle(color: Colors.grey)),
                              Text('₹$totalFee', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Advance Paid Online (20%):', style: TextStyle(color: Colors.grey)),
                              Text('₹$paidAmount (Done)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining Due to Collect (80%):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('₹$remainingAmount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.point_of_sale, color: Color(0xFF1565C0), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Counter Payment Gateway / Cash Settlement. Marks remaining fees as collected.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isProcessing ? null : () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isProcessing ? null : () async {
                            setDialogState(() => isProcessing = true);
                            final res = await completePatientPaymentApi(patientId);
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (mounted) {
                              ref.invalidate(hospitalPatientsProvider(hospitalId));
                              if (res != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.green.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Payment Successful! Remaining ₹$remainingAmount collected. Status updated to Done.',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('Failed to update payment status. Please try again.'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: isProcessing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.done_all, size: 18),
                          label: const Text('Confirm Payment & Mark as Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic rawCreatedAt) {
    if (rawCreatedAt == null) return '-';
    try {
      DateTime parsed = _parseTimestamp(rawCreatedAt);
      return DateFormat('dd MMM yyyy, HH:mm').format(parsed);
    } catch (e) {
      return rawCreatedAt.toString();
    }
  }

  void _openRegisterPatientDialog(
    String hospitalId,
    AsyncValue<List<Map<String, dynamic>>> deptOverviewAsync,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _RegisterPatientDialog(
        hospitalId: hospitalId,
        deptOverviewAsync: deptOverviewAsync,
        onSuccess: () {
          ref.invalidate(hospitalPatientsProvider(hospitalId));
          ref.invalidate(departmentOverviewProvider(hospitalId));
        },
      ),
    );
  }
}

class _RegisterPatientDialog extends StatefulWidget {
  final String hospitalId;
  final AsyncValue<List<Map<String, dynamic>>> deptOverviewAsync;
  final VoidCallback onSuccess;

  const _RegisterPatientDialog({
    required this.hospitalId,
    required this.deptOverviewAsync,
    required this.onSuccess,
  });

  @override
  State<_RegisterPatientDialog> createState() => _RegisterPatientDialogState();
}

class _RegisterPatientDialogState extends State<_RegisterPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _selectedDob;
  int _calculatedAge = 0;
  String _gender = 'Male';
  String? _selectedDeptId;
  String? _selectedDeptName;
  
  List<Map<String, dynamic>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  double _selectedDoctorFee = 500.0;
  bool _isLoadingDoctors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch doctors when initial department is available
    widget.deptOverviewAsync.whenData((depts) {
      if (depts.isNotEmpty) {
        _selectedDeptId = depts.first['id'];
        _selectedDeptName = depts.first['name'];
        _fetchDoctorsForDept(_selectedDeptId!);
      }
    });
  }

  Future<void> _fetchDoctorsForDept(String deptId) async {
    setState(() => _isLoadingDoctors = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.httpBaseUrl}/api/management/${widget.hospitalId}/doctors'));
      if (res.statusCode == 200) {
        final List<dynamic> allDocs = jsonDecode(res.body);
        final filtered = allDocs.where((d) => d['department_id'] == deptId && (d['status'] == 'ACTIVE' || d['status'] == null)).toList();
        if (mounted) {
          setState(() {
            _doctors = filtered.cast<Map<String, dynamic>>();
            _isLoadingDoctors = false;
            if (_doctors.isNotEmpty) {
              _selectedDoctorId = _doctors.first['id'];
              _selectedDoctorName = _doctors.first['name'];
              final fee = (_doctors.first['consultation_fee'] as num?)?.toDouble() ?? 0.0;
              _selectedDoctorFee = fee > 0 ? fee : 500.0;
            } else {
              _selectedDoctorId = null;
              _selectedDoctorName = null;
              _selectedDoctorFee = 500.0;
            }
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  /// Exact age calculation using YYYY/MM/DD
  int _calculateAgeFromDob(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  Future<void> _pickDob(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
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
        _selectedDob = picked;
        _calculatedAge = _calculateAgeFromDob(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth (DOB)')),
      );
      return;
    }

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please select an attending doctor. Selecting a doctor is mandatory.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dobStr = DateFormat('yyyy/MM/dd').format(_selectedDob!);
    final todayStr = DateFormat('yyyy/MM/dd').format(DateTime.now());

    final payload = {
      'name': _nameController.text.trim(),
      'dob': dobStr,
      'age': _calculatedAge,
      'gender': _gender,
      'phone': _phoneController.text.trim(),
      'department_id': _selectedDeptId,
      'department_name': _selectedDeptName,
      'doctor_id': _selectedDoctorId,
      'doctor_name': _selectedDoctorName,
      'last_visit': todayStr,
      'registration_source': 'DIRECT_WALKIN',
      'hospital_id': widget.hospitalId,
      'payment_status': 'DONE',
      'payment_option': 'full',
      'total_fee': _selectedDoctorFee,
      'paid_amount': _selectedDoctorFee,
      'remaining_amount': 0.0,
    };

    final result = await registerPatientApi(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null) {
        Navigator.of(context).pop();
        widget.onSuccess();
        final token = result['token_number'];
        final dept = _selectedDeptName ?? 'Department';
        final queueMsg = token != null ? ' & Queued in $dept (Token #$token)' : '';

        // Dropdown notification confirming counter payment and registration success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment Successful! ₹${_selectedDoctorFee.toStringAsFixed(0)} fee collected at counter for Dr. $_selectedDoctorName. Patient registered (PID: ${result['pid']})$queueMsg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to register patient. Please check your inputs.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('yyyy/MM/dd').format(DateTime.now());

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(28),
          child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_add, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Register Walk-in Patient',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'A unique Patient ID (PID) will be generated and full consultation fee (100%) will be recorded as collected at the counter.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Divider(height: 24),

                // 1. Patient Name
                const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter patient full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter patient name' : null,
                ),
                const SizedBox(height: 16),

                // 2. DOB (Calendar) & Auto-Calculated Age (using YYYY/MM/DD)
                Row(
                  children: [
                    // DOB Picker
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date of Birth (DOB) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickDob(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDob != null
                                        ? DateFormat('yyyy/MM/dd').format(_selectedDob!)
                                        : 'Select DOB (YYYY/MM/DD)',
                                    style: TextStyle(
                                      color: _selectedDob != null ? Colors.black87 : Colors.grey.shade500,
                                      fontWeight: _selectedDob != null ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_month, size: 18, color: Color(0xFF1565C0)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Auto-calculated Age (Read-only)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Age (Calculated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF1565C0)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDob != null ? '$_calculatedAge Years' : 'Auto from DOB',
                                  style: const TextStyle(
                                    color: Color(0xFF0D47A1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Gender & Phone
                Row(
                  children: [
                    // Gender
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _gender,
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _gender = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Phone Number
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: '10-digit mobile number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) => (val == null || val.trim().length < 8) ? 'Enter valid phone' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Department Dropdown
                const Text('Department *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                widget.deptOverviewAsync.when(
                  data: (departments) {
                    if (_selectedDeptId == null && departments.isNotEmpty) {
                      _selectedDeptId = departments.first['id'];
                      _selectedDeptName = departments.first['name'];
                      _fetchDoctorsForDept(_selectedDeptId!);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedDeptId,
                          hint: const Text('Select Medical Department'),
                          items: departments.map((d) {
                            return DropdownMenuItem<String>(
                              value: d['id'] as String,
                              child: Text(d['name'] as String? ?? 'General'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final matched = departments.firstWhere((d) => d['id'] == val, orElse: () => {});
                              setState(() {
                                _selectedDeptId = val;
                                _selectedDeptName = matched['name'] ?? 'General';
                              });
                              _fetchDoctorsForDept(val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const Text('Failed to load departments'),
                ),
                const SizedBox(height: 16),

                // 5. Attending Doctor (MANDATORY)
                const Text('Attending Doctor * (Mandatory)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                if (_isLoadingDoctors)
                  const LinearProgressIndicator()
                else if (_doctors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No active doctors found in this department. Please assign a doctor first in Doctors Management.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _selectedDoctorId == null ? Colors.red.shade300 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDoctorId,
                        hint: const Text('Select Doctor (Mandatory)'),
                        items: _doctors.map((doc) {
                          final fee = (doc['consultation_fee'] as num?)?.toDouble() ?? 0.0;
                          final feeLabel = fee > 0 ? ' (Fee: ₹${fee.toStringAsFixed(0)})' : ' (Fee: ₹500)';
                          return DropdownMenuItem<String>(
                            value: doc['id'] as String,
                            child: Text('${doc['name']}$feeLabel'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final matched = _doctors.firstWhere((d) => d['id'] == val, orElse: () => {});
                            setState(() {
                              _selectedDoctorId = val;
                              _selectedDoctorName = matched['name'] ?? 'Doctor';
                              final fee = (matched['consultation_fee'] as num?)?.toDouble() ?? 0.0;
                              _selectedDoctorFee = fee > 0 ? fee : 500.0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 6. Last Visit & Registration Source
                Row(
                  children: [
                    // Last Visit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Visit Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  todayFormatted,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Via (Read-only)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Via (Registration Source)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.how_to_reg, size: 16, color: Colors.purple),
                                SizedBox(width: 8),
                                Text(
                                  'Direct Walk-in (HMS)',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 7. Fee & Counter Payment Gateway Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.payments_outlined, color: Colors.green.shade800, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Counter Payment (100% Full Fees): ₹${_selectedDoctorFee.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDoctorName != null 
                                  ? 'Determined by Dr. $_selectedDoctorName fee schedule. Marked as Done at counter.' 
                                  : 'Select doctor above to confirm fee schedule.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Status: Done', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Complete Registration & Generate PID [Enter]', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
