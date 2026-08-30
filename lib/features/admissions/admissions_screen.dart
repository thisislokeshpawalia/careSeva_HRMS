import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/providers/admissions_provider.dart';
import '../hospital/providers/hospital_provider.dart';
import '../doctors/providers/doctors_provider.dart';

class AdmissionsScreen extends ConsumerStatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  ConsumerState<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends ConsumerState<AdmissionsScreen> {
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Date filter mode: 'All', 'Choose Date', 'Yesterday', 'Today', 'Tomorrow'
  String _selectedDateFilterMode = 'All';
  DateTime? _customSelectedDate;

  // Status filter: 'All', 'ADMITTED', 'ICU', 'OBSERVATION', 'DISCHARGED'
  String _statusFilter = 'All';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Gentle 15-second background auto-refresh
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        final authState = ref.read(authProvider);
        final hospitalId = (authState.hospitalId != null && authState.hospitalId != 'dummy_hospital_123')
            ? authState.hospitalId!
            : '6a8ea49ef17ddb14088aa5f7';
        _refreshAll(hospitalId);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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

  void _refreshAll(String hospitalId) {
    ref.invalidate(admissionsDepartmentOverviewProvider(hospitalId));
    ref.invalidate(
      filteredHospitalAdmissionsProvider(
        HospitalAdmissionFilter(
          hospitalId: hospitalId,
          departmentId: _selectedDepartmentId,
          date: _getDateFilterString(),
          status: _statusFilter == 'All' ? null : _statusFilter,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hospitalId = (authState.hospitalId != null && authState.hospitalId != 'dummy_hospital_123')
        ? authState.hospitalId!
        : '6a8ea49ef17ddb14088aa5f7';

    final deptOverviewAsync = ref.watch(admissionsDepartmentOverviewProvider(hospitalId));
    final admissionsAsync = ref.watch(
      filteredHospitalAdmissionsProvider(
        HospitalAdmissionFilter(
          hospitalId: hospitalId,
          departmentId: _selectedDepartmentId,
          date: _getDateFilterString(),
          status: _statusFilter == 'All' ? null : _statusFilter,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(hospitalId),
            const SizedBox(height: 22),
            _buildDepartmentDrawerSection(deptOverviewAsync, hospitalId),
            const SizedBox(height: 22),
            if (_selectedDepartmentId != null || _statusFilter != 'All' || _selectedDateFilterMode != 'All' || _searchQuery.isNotEmpty)
              _buildActiveFilterBanner(),
            const SizedBox(height: 16),
            _buildSearchBarAndFilters(context),
            const SizedBox(height: 18),
            _buildAdmissionLogsTable(admissionsAsync, hospitalId),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(String hospitalId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hotel_outlined, color: Color(0xFF1565C0), size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Patient Admissions & Inpatient Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time IPD admission registers, ward allocations, and inpatient tracking (Indian Standard Time)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            const _AdmissionLiveClockBadge(),
            const SizedBox(width: 14),
            OutlinedButton.icon(
              onPressed: () => _refreshAll(hospitalId),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Live Stats'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E293B),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              onPressed: () => _openAdmitPatientDialog(context, hospitalId),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                '+ Admit Patient',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentDrawerSection(
    AsyncValue<List<Map<String, dynamic>>> deptOverviewAsync,
    String hospitalId,
  ) {
    return deptOverviewAsync.when(
      skipLoadingOnRefresh: true,
      data: (departments) {
        int totalInpatients = 0;
        int totalIcu = 0;
        int totalDischarged = 0;
        int totalBeds = 0;

        for (var d in departments) {
          totalInpatients += (d['active_admissions'] as num? ?? 0).toInt();
          totalIcu += (d['icu_count'] as num? ?? 0).toInt();
          totalDischarged += (d['discharged_count'] as num? ?? 0).toInt();
          totalBeds += (d['total_beds'] as num? ?? 30).toInt();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Department Inpatient Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(width: 8),
                    Tooltip(
                      message: 'Click any department card to filter admission records',
                      child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  'Horizontal scroll to explore all hospital wards',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 145,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // All Departments Card
                  _buildAllDepartmentsCard(
                    totalInpatients: totalInpatients,
                    totalIcu: totalIcu,
                    totalDischarged: totalDischarged,
                    totalBeds: totalBeds,
                    isSelected: _selectedDepartmentId == null,
                    onTap: () {
                      setState(() {
                        _selectedDepartmentId = null;
                        _selectedDepartmentName = null;
                      });
                    },
                  ),
                  const SizedBox(width: 14),
                  // Department Cards
                  ...departments.map((dept) {
                    final deptId = dept['id'] as String? ?? '';
                    final name = dept['name'] as String? ?? 'General';
                    final specialty = dept['specialty'] as String? ?? '';
                    final activeAdmissions = (dept['active_admissions'] as num? ?? 0).toInt();
                    final icuCount = (dept['icu_count'] as num? ?? 0).toInt();
                    final totalBedCount = (dept['total_beds'] as num? ?? 30).toInt();
                    final availBeds = (dept['available_beds'] as num? ?? (totalBedCount - activeAdmissions)).toInt();
                    final isSelected = _selectedDepartmentId == deptId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _buildDepartmentCard(
                        deptId: deptId,
                        name: name,
                        specialty: specialty,
                        activeAdmissions: activeAdmissions,
                        icuCount: icuCount,
                        totalBeds: totalBedCount,
                        availableBeds: availBeds,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (_selectedDepartmentId == deptId) {
                              _selectedDepartmentId = null;
                              _selectedDepartmentName = null;
                            } else {
                              _selectedDepartmentId = deptId;
                              _selectedDepartmentName = name;
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Error loading admissions overview: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildAllDepartmentsCard({
    required int totalInpatients,
    required int totalIcu,
    required int totalDischarged,
    required int totalBeds,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF0D47A1).withAlpha(40) : Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withAlpha(35) : const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.domain_outlined,
                    color: isSelected ? Colors.white : const Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withAlpha(40) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hospital Wide',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Departments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$totalInpatients Admitted',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white70 : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalIcu in ICU',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.red.shade200 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard({
    required String deptId,
    required String name,
    required String specialty,
    required int activeAdmissions,
    required int icuCount,
    required int totalBeds,
    required int availableBeds,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData iconData = Icons.local_hospital;
    Color themeColor = const Color(0xFF0284C7);

    final lower = name.toLowerCase();
    if (lower.contains('cardio')) {
      iconData = Icons.favorite;
      themeColor = Colors.red.shade600;
    } else if (lower.contains('ortho')) {
      iconData = Icons.healing;
      themeColor = Colors.teal.shade600;
    } else if (lower.contains('icu') || lower.contains('emer') || lower.contains('critical')) {
      iconData = Icons.emergency;
      themeColor = Colors.deepOrange.shade600;
    } else if (lower.contains('gyne') || lower.contains('obs')) {
      iconData = Icons.pregnant_woman;
      themeColor = Colors.purple.shade600;
    } else if (lower.contains('neuro')) {
      iconData = Icons.psychology;
      themeColor = Colors.indigo.shade600;
    } else if (lower.contains('pedia') || lower.contains('child')) {
      iconData = Icons.child_care;
      themeColor = Colors.amber.shade700;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 270,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? themeColor.withAlpha(40) : Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withAlpha(35) : themeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconData,
                    color: isSelected ? Colors.white : themeColor,
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withAlpha(35) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$availableBeds Beds Vacant',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$activeAdmissions Admitted',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (icuCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withAlpha(40) : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$icuCount ICU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 10),
              Text(
                'Active Filters: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13),
              ),
              if (_selectedDepartmentName != null) ...[
                Chip(
                  label: Text('Dept: $_selectedDepartmentName', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  onDeleted: () {
                    setState(() {
                      _selectedDepartmentId = null;
                      _selectedDepartmentName = null;
                    });
                  },
                ),
                const SizedBox(width: 6),
              ],
              if (_statusFilter != 'All') ...[
                Chip(
                  label: Text('Status: $_statusFilter', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => setState(() => _statusFilter = 'All'),
                ),
                const SizedBox(width: 6),
              ],
              if (_selectedDateFilterMode != 'All') ...[
                Chip(
                  label: Text('Date: $_selectedDateFilterMode', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => setState(() {
                    _selectedDateFilterMode = 'All';
                    _customSelectedDate = null;
                  }),
                ),
                const SizedBox(width: 6),
              ],
              if (_searchQuery.isNotEmpty) ...[
                Chip(
                  label: Text('Search: "$_searchQuery"', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  onDeleted: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ],
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDepartmentId = null;
                _selectedDepartmentName = null;
                _statusFilter = 'All';
                _selectedDateFilterMode = 'All';
                _customSelectedDate = null;
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: const Text('Clear All Filters', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndFilters(BuildContext context) {
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
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by Patient Name, IPD No., UHID/PID, Bed No., Doctor, or Diagnosis...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1565C0)),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'ADMITTED', child: Text('Admitted / In-Care')),
                      DropdownMenuItem(value: 'ICU', child: Text('ICU / Critical')),
                      DropdownMenuItem(value: 'OBSERVATION', child: Text('Observation')),
                      DropdownMenuItem(value: 'DISCHARGED', child: Text('Discharged')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _statusFilter = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Date Filter Chips
          Row(
            children: [
              Text(
                'Admission Date: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              _buildDateChip('All', 'All Dates'),
              const SizedBox(width: 6),
              _buildDateChip('Today', 'Today'),
              const SizedBox(width: 6),
              _buildDateChip('Yesterday', 'Yesterday'),
              const SizedBox(width: 6),
              _buildDateChip('Tomorrow', 'Tomorrow'),
              const SizedBox(width: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _customSelectedDate ?? DateTime.now(),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _customSelectedDate = picked;
                      _selectedDateFilterMode = 'Choose Date';
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _selectedDateFilterMode == 'Choose Date'
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDateFilterMode == 'Choose Date'
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                        color: _selectedDateFilterMode == 'Choose Date' ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedDateFilterMode == 'Choose Date' && _customSelectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_customSelectedDate!)
                            : 'Choose Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedDateFilterMode == 'Choose Date' ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String mode, String label) {
    final isSelected = _selectedDateFilterMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1565C0),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (_) {
        setState(() {
          _selectedDateFilterMode = mode;
          if (mode != 'Choose Date') {
            _customSelectedDate = null;
          }
        });
      },
    );
  }

  Widget _buildAdmissionLogsTable(
    AsyncValue<List<Map<String, dynamic>>> admissionsAsync,
    String hospitalId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: admissionsAsync.when(
        data: (admissions) {
          if (admissions.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(50),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.hotel_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No admission records found matching filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try modifying your search term or click "+ Admit Patient" to register an inpatient',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table Header Bar with Record Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Inpatient Department Admission Registers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${admissions.length} Records',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Live Face-Sheet & Clinical Docket',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Data Table with Real Hospital Columns
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 24,
                  columnSpacing: 24,
                  headingRowHeight: 52,
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 86,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('ADMISSION & IPD NO.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text('PATIENT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text('WARD & BED ALLOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text('CLINICAL & ATTENDING DOCTOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text('EMERGENCY KIN / CONTACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text('BILLING / PAYER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                    DataColumn(label: Text('STATUS & ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                  ],
                  rows: admissions.map((item) {
                    return _buildAdmissionRow(context, item, hospitalId);
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading admission logs: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  DataRow _buildAdmissionRow(BuildContext context, Map<String, dynamic> item, String hospitalId) {
    final admissionId = item['id'] as String? ?? '';
    final ipdNo = item['ipd_number'] as String? ?? 'IPD-PENDING';
    final admissionDate = item['admission_date'] as String? ?? '';
    final admissionTime = item['admission_time'] as String? ?? '';
    final admissionType = item['admission_type'] as String? ?? 'PLANNED';

    final patientName = item['patient_name'] as String? ?? 'Unknown';
    final patientId = item['patient_id'] as String? ?? '-';
    final patientAge = item['patient_age'] ?? 0;
    final patientGender = item['patient_gender'] as String? ?? 'Other';
    final patientBlood = item['patient_blood_group'] as String? ?? 'Unknown';
    final patientPhone = item['patient_phone'] as String? ?? '';

    final deptName = item['department_name'] as String? ?? 'General';
    final wardType = item['ward_type'] as String? ?? 'General Ward';
    final bedNumber = item['bed_number'] as String? ?? '-';

    final diagnosis = item['provisional_diagnosis'] as String? ?? 'Under Evaluation';
    final doctorName = item['doctor_name'] as String? ?? 'On Duty Physician';

    final kinName = item['kin_name'] as String? ?? '-';
    final kinRelation = item['kin_relation'] as String? ?? '';
    final kinPhone = item['kin_phone'] as String? ?? '';

    final payerType = item['payer_type'] as String? ?? 'CASH';
    final advanceDeposit = (item['advance_deposit'] as num? ?? 0).toDouble();
    final status = item['status'] as String? ?? 'ADMITTED';

    return DataRow(
      cells: [
        // Column 1: Admission & IPD No.
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ipdNo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: Colors.grey),
                    tooltip: 'Copy IPD No',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ipdNo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $ipdNo to clipboard'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '$admissionDate • $admissionTime',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildAdmissionTypePill(admissionType),
            ],
          ),
        ),

        // Column 2: Patient Details
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _getAvatarColor(patientName),
                child: Text(
                  patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        patientId,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• $patientAge Y • $patientGender',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          patientBlood,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        patientPhone,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Column 3: Ward & Bed Allocation
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deptName,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bed, size: 14, color: Colors.indigo.shade700),
                  const SizedBox(width: 4),
                  Text(
                    bedNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                wardType,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Column 4: Clinical & Attending Doctor
        DataCell(
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  diagnosis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 13, color: Color(0xFF1565C0)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Column 5: Emergency Kin / Contact
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kinRelation.isNotEmpty ? '$kinName ($kinRelation)' : kinName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 3),
              if (kinPhone.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      kinPhone,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Column 6: Billing / Payer
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPayerBadge(payerType),
              const SizedBox(height: 4),
              Text(
                advanceDeposit > 0 ? '₹${advanceDeposit.toStringAsFixed(0)} Deposit' : '₹0 Advance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: advanceDeposit > 0 ? Colors.green.shade800 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Column 7: Status & Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(status),
              const SizedBox(width: 10),
              // View File Button
              ElevatedButton.icon(
                onPressed: () => _openAdmissionFileModal(context, item, hospitalId),
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('View File', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Action menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (action) async {
                  if (action == 'DISCHARGE') {
                    _confirmDischarge(context, admissionId, patientName, hospitalId);
                  } else if (action == 'TRANSFER') {
                    _changeStatusDialog(context, admissionId, status, hospitalId);
                  }
                },
                itemBuilder: (context) => [
                  if (status != 'DISCHARGED')
                    const PopupMenuItem(
                      value: 'DISCHARGE',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Process Discharge'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'TRANSFER',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text('Change Ward / Status'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdmissionTypePill(String type) {
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade800;

    if (type.toUpperCase() == 'EMERGENCY') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (type.toUpperCase() == 'DAYCARE') {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade800;
    } else if (type.toUpperCase() == 'TRANSFER') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildPayerBadge(String payer) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    if (payer.contains('INSURANCE') || payer.contains('TPA')) {
      bg = Colors.teal.shade50;
      fg = Colors.teal.shade800;
    } else if (payer.contains('GOVT') || payer.contains('AYUSHMAN')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        payer,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade800;
    IconData icon = Icons.check_circle_outline;

    if (status == 'ICU') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      icon = Icons.warning_amber_rounded;
    } else if (status == 'OBSERVATION') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      icon = Icons.remove_red_eye_outlined;
    } else if (status == 'DISCHARGED') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      icon = Icons.task_alt;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF0D9488),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF059669),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  void _confirmDischarge(BuildContext context, String admissionId, String patientName, String hospitalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discharge Patient'),
        content: Text('Are you sure you want to process discharge for "$patientName"? This will free the allocated bed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await updateAdmissionStatusApi(admissionId, {'status': 'DISCHARGED'});
              if (!mounted) return;
              if (success) {
                _refreshAll(hospitalId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$patientName has been successfully discharged.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirm Discharge'),
          ),
        ],
      ),
    );
  }

  void _changeStatusDialog(BuildContext context, String admissionId, String currentStatus, String hospitalId) {
    String newStatus = currentStatus;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Update Admission Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('ADMITTED (In-Care)'),
                value: 'ADMITTED',
                groupValue: newStatus,
                onChanged: (val) => setDlgState(() => newStatus = val!),
              ),
              RadioListTile<String>(
                title: const Text('ICU (Critical Care)'),
                value: 'ICU',
                groupValue: newStatus,
                onChanged: (val) => setDlgState(() => newStatus = val!),
              ),
              RadioListTile<String>(
                title: const Text('OBSERVATION'),
                value: 'OBSERVATION',
                groupValue: newStatus,
                onChanged: (val) => setDlgState(() => newStatus = val!),
              ),
              RadioListTile<String>(
                title: const Text('DISCHARGED'),
                value: 'DISCHARGED',
                groupValue: newStatus,
                onChanged: (val) => setDlgState(() => newStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await updateAdmissionStatusApi(admissionId, {'status': newStatus});
                if (!mounted) return;
                if (success) {
                  _refreshAll(hospitalId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Admission status updated to $newStatus')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // "Admit Patient" Modal Dialog
  void _openAdmitPatientDialog(BuildContext context, String hospitalId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AdmitPatientDialog(
        hospitalId: hospitalId,
        onSuccess: () {
          _refreshAll(hospitalId);
        },
      ),
    );
  }

  // "Patient Admission File" Modal
  void _openAdmissionFileModal(BuildContext context, Map<String, dynamic> item, String hospitalId) {
    showDialog(
      context: context,
      builder: (ctx) => _AdmissionFileDocketModal(item: item, hospitalId: hospitalId, onRefresh: () => _refreshAll(hospitalId)),
    );
  }
}

// ==========================================
// 1. ADMIT PATIENT DIALOG
// ==========================================
class _AdmitPatientDialog extends ConsumerStatefulWidget {
  final String hospitalId;
  final VoidCallback onSuccess;

  const _AdmitPatientDialog({
    required this.hospitalId,
    required this.onSuccess,
  });

  @override
  ConsumerState<_AdmitPatientDialog> createState() => _AdmitPatientDialogState();
}

class _AdmitPatientDialogState extends ConsumerState<_AdmitPatientDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _complaintsController = TextEditingController();
  final _bedController = TextEditingController();
  final _roomController = TextEditingController();
  final _kinNameController = TextEditingController();
  final _kinPhoneController = TextEditingController();
  final _depositController = TextEditingController(text: '0');
  final _insuranceProviderController = TextEditingController();

  String _gender = 'Male';
  String _bloodGroup = 'B+';
  String _admissionType = 'PLANNED';
  String _wardType = 'General Ward';
  String _kinRelation = 'Spouse';
  String _payerType = 'CASH';

  String? _selectedDeptId;
  String? _selectedDeptName;
  String? _selectedDocId;
  String? _selectedDocName;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _diagnosisController.dispose();
    _complaintsController.dispose();
    _bedController.dispose();
    _roomController.dispose();
    _kinNameController.dispose();
    _kinPhoneController.dispose();
    _depositController.dispose();
    _insuranceProviderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(hospitalDepartmentsProvider);
    final docsAsync = ref.watch(doctorsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 850),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.hotel_outlined, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'New Inpatient Admission (IPD File Creation)',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: Patient Identity
                      _buildSectionHeader('1. Patient Identity & Personal Record', Icons.person_outline),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Patient Full Name *', border: OutlineInputBorder()),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder()),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age (Years) *', border: OutlineInputBorder()),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male')),
                                DropdownMenuItem(value: 'Female', child: Text('Female')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _bloodGroup,
                              decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'A+', child: Text('A+')),
                                DropdownMenuItem(value: 'A-', child: Text('A-')),
                                DropdownMenuItem(value: 'B+', child: Text('B+')),
                                DropdownMenuItem(value: 'B-', child: Text('B-')),
                                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                                DropdownMenuItem(value: 'O+', child: Text('O+')),
                                DropdownMenuItem(value: 'O-', child: Text('O-')),
                                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                              ],
                              onChanged: (v) => setState(() => _bloodGroup = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(labelText: 'Residential Address / City', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // SECTION 2: Ward & Bed Allocation
                      _buildSectionHeader('2. Inpatient Department & Bed Allocation', Icons.bed_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Department Dropdown
                          Expanded(
                            child: deptsAsync.when(
                              data: (depts) {
                                if (_selectedDeptId == null && depts.isNotEmpty) {
                                  _selectedDeptId = depts[0]['id'] ?? depts[0]['_id'];
                                  _selectedDeptName = depts[0]['name'];
                                }
                                return DropdownButtonFormField<String>(
                                  value: _selectedDeptId,
                                  decoration: const InputDecoration(labelText: 'Admitting Department *', border: OutlineInputBorder()),
                                  items: depts.map<DropdownMenuItem<String>>((d) {
                                    final id = d['id'] ?? d['_id'];
                                    return DropdownMenuItem(value: id, child: Text(d['name'] ?? 'Dept'));
                                  }).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedDeptId = v;
                                      final found = depts.firstWhere((d) => (d['id'] ?? d['_id']) == v, orElse: () => null);
                                      _selectedDeptName = found != null ? found['name'] : 'General';
                                    });
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => const Text('Failed to load depts'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Attending Doctor Dropdown
                          Expanded(
                            child: docsAsync.when(
                              data: (docs) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedDocId,
                                  decoration: const InputDecoration(labelText: 'Attending Doctor', border: OutlineInputBorder()),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Duty Physician (Auto)')),
                                    ...docs.map<DropdownMenuItem<String>>((doc) {
                                      final id = doc['id'] ?? doc['_id'];
                                      return DropdownMenuItem(value: id, child: Text(doc['name'] ?? 'Doctor'));
                                    }),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedDocId = v;
                                      if (v != null) {
                                        final found = docs.firstWhere((d) => (d['id'] ?? d['_id']) == v, orElse: () => null);
                                        _selectedDocName = found != null ? found['name'] : null;
                                      } else {
                                        _selectedDocName = null;
                                      }
                                    });
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => const Text('Failed to load doctors'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _wardType,
                              decoration: const InputDecoration(labelText: 'Ward Type *', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'General Ward', child: Text('General Ward')),
                                DropdownMenuItem(value: 'Semi-Private', child: Text('Semi-Private')),
                                DropdownMenuItem(value: 'Deluxe Private', child: Text('Deluxe Private')),
                                DropdownMenuItem(value: 'ICU / CCU', child: Text('ICU / CCU')),
                                DropdownMenuItem(value: 'Emergency Ward', child: Text('Emergency Ward')),
                              ],
                              onChanged: (v) => setState(() => _wardType = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _roomController,
                              decoration: const InputDecoration(labelText: 'Room / Ward No (e.g. Ward 4)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _bedController,
                              decoration: const InputDecoration(labelText: 'Allocated Bed No * (e.g. Bed 102-B)', border: OutlineInputBorder()),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Bed required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // SECTION 3: Clinical & Admission Details
                      _buildSectionHeader('3. Clinical Details & Admission Category', Icons.medical_information_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _admissionType,
                              decoration: const InputDecoration(labelText: 'Admission Category *', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'PLANNED', child: Text('Planned / Elective')),
                                DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency / Urgent')),
                                DropdownMenuItem(value: 'DAYCARE', child: Text('Daycare Procedure')),
                                DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer from other facility')),
                              ],
                              onChanged: (v) => setState(() => _admissionType = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _diagnosisController,
                              decoration: const InputDecoration(labelText: 'Provisional Diagnosis / Reason *', border: OutlineInputBorder()),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Diagnosis required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _complaintsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Chief Complaints / Presenting Symptoms',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Severe chest pain, shortness of breath for 3 hours...',
                        ),
                      ),

                      const SizedBox(height: 24),
                      // SECTION 4: Emergency Kin / Contact
                      _buildSectionHeader('4. Emergency Contact / Next of Kin', Icons.contact_phone_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _kinNameController,
                              decoration: const InputDecoration(labelText: 'Kin / Guardian Full Name', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _kinRelation,
                              decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                                DropdownMenuItem(value: 'Father', child: Text('Father')),
                                DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                                DropdownMenuItem(value: 'Child', child: Text('Child')),
                                DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                                DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
                              ],
                              onChanged: (v) => setState(() => _kinRelation = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _kinPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Emergency Phone Number', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // SECTION 5: Billing & Payer Category
                      _buildSectionHeader('5. Insurance & Advance Billing Clearance', Icons.account_balance_wallet_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _payerType,
                              decoration: const InputDecoration(labelText: 'Billing Category', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'CASH', child: Text('Direct Cash / Card')),
                                DropdownMenuItem(value: 'TPA / INSURANCE', child: Text('TPA / Private Insurance')),
                                DropdownMenuItem(value: 'AYUSHMAN / GOVT SCHEME', child: Text('Ayushman Bharat / Govt Scheme')),
                              ],
                              onChanged: (v) => setState(() => _payerType = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_payerType != 'CASH') ...[
                            Expanded(
                              child: TextFormField(
                                controller: _insuranceProviderController,
                                decoration: const InputDecoration(labelText: 'TPA / Provider (e.g. Star Health)', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: TextFormField(
                              controller: _depositController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Initial Deposit (₹)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAdmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Admit Patient & Generate IPD File', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Future<void> _submitAdmission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      'patient_name': _nameController.text.trim(),
      'patient_phone': _phoneController.text.trim(),
      'patient_age': int.tryParse(_ageController.text.trim()) ?? 0,
      'patient_gender': _gender,
      'patient_blood_group': _bloodGroup,
      'patient_address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      'hospital_id': widget.hospitalId,
      'department_id': _selectedDeptId ?? 'general_dept',
      'department_name': _selectedDeptName ?? 'General Medicine',
      'doctor_id': _selectedDocId,
      'doctor_name': _selectedDocName ?? 'Duty Physician',
      'ward_type': _wardType,
      'room_number': _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
      'bed_number': _bedController.text.trim(),
      'admission_type': _admissionType,
      'provisional_diagnosis': _diagnosisController.text.trim(),
      'chief_complaints': _complaintsController.text.trim().isNotEmpty ? _complaintsController.text.trim() : null,
      'kin_name': _kinNameController.text.trim().isNotEmpty ? _kinNameController.text.trim() : null,
      'kin_relation': _kinRelation,
      'kin_phone': _kinPhoneController.text.trim().isNotEmpty ? _kinPhoneController.text.trim() : null,
      'payer_type': _payerType,
      'insurance_provider': _insuranceProviderController.text.trim().isNotEmpty ? _insuranceProviderController.text.trim() : null,
      'advance_deposit': double.tryParse(_depositController.text.trim()) ?? 0.0,
      'payment_status': 'DONE',
    };

    final result = await admitPatientApi(payload);
    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.pop(context);
      widget.onSuccess();
      final ipdNo = result['ipd_number'] ?? 'Assigned';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient successfully admitted! IPD Admission No: $ipdNo'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to admit patient. Please check your inputs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ==========================================
// 2. PATIENT ADMISSION FILE / FACE-SHEET MODAL
// ==========================================
class _AdmissionFileDocketModal extends StatelessWidget {
  final Map<String, dynamic> item;
  final String hospitalId;
  final VoidCallback onRefresh;

  const _AdmissionFileDocketModal({
    required this.item,
    required this.hospitalId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ipdNo = item['ipd_number'] ?? 'IPD-FILE';
    final patientName = item['patient_name'] ?? 'Unknown';
    final patientId = item['patient_id'] ?? '-';
    final age = item['patient_age'] ?? 0;
    final gender = item['patient_gender'] ?? '-';
    final blood = item['patient_blood_group'] ?? 'Unknown';
    final phone = item['patient_phone'] ?? '-';
    final address = item['patient_address'] ?? 'Not Specified';

    final dept = item['department_name'] ?? 'General';
    final ward = item['ward_type'] ?? 'General Ward';
    final bed = item['bed_number'] ?? '-';
    final room = item['room_number'] ?? '-';

    final admDate = item['admission_date'] ?? '-';
    final admTime = item['admission_time'] ?? '-';
    final admType = item['admission_type'] ?? 'PLANNED';
    final diagnosis = item['provisional_diagnosis'] ?? 'Under Observation';
    final complaints = item['chief_complaints'] ?? 'No complaints recorded.';
    final doctor = item['doctor_name'] ?? 'On Duty Physician';

    final kinName = item['kin_name'] ?? '-';
    final kinRelation = item['kin_relation'] ?? '-';
    final kinPhone = item['kin_phone'] ?? '-';

    final payer = item['payer_type'] ?? 'CASH';
    final insurance = item['insurance_provider'];
    final deposit = (item['advance_deposit'] as num? ?? 0).toDouble();
    final status = item['status'] ?? 'ADMITTED';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 880),
        child: Column(
          children: [
            // Docket Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CareQueue HMS • IPD Face Sheet & Admission Docket',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Official Hospital Inpatient Record • Indian Standard Time',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ipdNo,
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Docket Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Bio Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1565C0),
                            child: Text(
                              patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      patientName,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'UHID: $patientId',
                                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$age Years • $gender • Blood: $blood • Phone: $phone',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Address: $address',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Two Column Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Bed Allocation & Clinical Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDocketCard(
                                title: 'Ward & Bed Allocation',
                                icon: Icons.bed_outlined,
                                items: [
                                  {'label': 'Department', 'value': dept},
                                  {'label': 'Ward Type', 'value': ward},
                                  {'label': 'Room Number', 'value': room.isNotEmpty ? room : 'Standard'},
                                  {'label': 'Allocated Bed', 'value': bed},
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDocketCard(
                                title: 'Clinical Evaluation',
                                icon: Icons.medical_services_outlined,
                                items: [
                                  {'label': 'Attending Doctor', 'value': doctor},
                                  {'label': 'Admission Category', 'value': admType},
                                  {'label': 'Admission Timestamp', 'value': '$admDate at $admTime (IST)'},
                                  {'label': 'Provisional Diagnosis', 'value': diagnosis},
                                  {'label': 'Presenting Complaints', 'value': complaints},
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 18),

                        // Right Column: Kin & Financial
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDocketCard(
                                title: 'Emergency Contact / Next of Kin',
                                icon: Icons.phone_in_talk_outlined,
                                items: [
                                  {'label': 'Kin / Guardian', 'value': kinName},
                                  {'label': 'Relationship', 'value': kinRelation},
                                  {'label': 'Contact Phone', 'value': kinPhone},
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDocketCard(
                                title: 'Billing & Financial Clearance',
                                icon: Icons.payments_outlined,
                                items: [
                                  {'label': 'Payer Category', 'value': payer},
                                  if (insurance != null && insurance.isNotEmpty)
                                    {'label': 'Insurance / TPA', 'value': insurance},
                                  {'label': 'Advance Deposit', 'value': '₹${deposit.toStringAsFixed(2)} Paid'},
                                  {'label': 'Admission Status', 'value': status},
                                ],
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

            // Modal Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Form verified by HMS Inpatient Registrar',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printing admission face-sheet...')),
                          );
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Docket'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocketCard({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
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
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const Divider(height: 18),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      it['label'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      it['value'] ?? '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. LIVE CLOCK BADGE
// ==========================================
class _AdmissionLiveClockBadge extends StatefulWidget {
  const _AdmissionLiveClockBadge();

  @override
  State<_AdmissionLiveClockBadge> createState() => _AdmissionLiveClockBadgeState();
}

class _AdmissionLiveClockBadgeState extends State<_AdmissionLiveClockBadge> {
  late Timer _clockTimer;
  late DateTime _nowIst;

  @override
  void initState() {
    super.initState();
    _nowIst = _getIstNow();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _nowIst = _getIstNow();
        });
      }
    });
  }

  DateTime _getIstNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_nowIst);
    final timeStr = DateFormat('hh:mm:ss a').format(_nowIst);

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
