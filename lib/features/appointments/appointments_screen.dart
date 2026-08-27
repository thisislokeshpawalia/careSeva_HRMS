import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/providers/appointment_provider.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;
  String _searchQuery = '';
  
  // Date filter mode: 'All', 'Choose Date', 'Yesterday', 'Today', 'Tomorrow'
  String _selectedDateFilterMode = 'All';
  DateTime? _customSelectedDate;

  String _statusFilter = 'All'; // 'All', 'BOOKED', 'WAITING', 'COMPLETED', 'CANCELLED'
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 4 seconds so doctor completions reflect automatically in real-time
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        final authState = ref.read(authProvider);
        final hospitalId = authState.hospitalId ?? 'dummy_hospital_123';
        _refreshAll(hospitalId);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hospitalId = authState.hospitalId ?? 'dummy_hospital_123';

    final deptOverviewAsync = ref.watch(departmentOverviewProvider(hospitalId));
    final appointmentsAsync = ref.watch(
      filteredHospitalAppointmentsProvider(
        HospitalAppointmentFilter(
          hospitalId: hospitalId,
          departmentId: _selectedDepartmentId,
          date: _getDateFilterString(),
          status: _statusFilter == 'All' ? null : _statusFilter,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(hospitalId),
            const SizedBox(height: 20),
            _buildDepartmentTilesSection(deptOverviewAsync, hospitalId),
            const SizedBox(height: 24),
            _buildActiveFilterBanner(),
            const SizedBox(height: 16),
            _buildSearchBarAndFilters(context),
            const SizedBox(height: 16),
            _buildLogsTableContainer(appointmentsAsync, hospitalId),
          ],
        ),
      ),
    );
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
    ref.invalidate(departmentOverviewProvider(hospitalId));
    ref.invalidate(
      filteredHospitalAppointmentsProvider(
        HospitalAppointmentFilter(
          hospitalId: hospitalId,
          departmentId: _selectedDepartmentId,
          date: _getDateFilterString(),
          status: _statusFilter == 'All' ? null : _statusFilter,
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
                const Text(
                  'Appointments & Live Queue Monitor',
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE AUTO-SYNC (IST)',
                        style: TextStyle(
                          color: Colors.green.shade800,
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
              'Real-time department queue status, bookings, and appointment logs (Indian Standard Time)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _refreshAll(hospitalId),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh Live Stats'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentTilesSection(
    AsyncValue<List<Map<String, dynamic>>> deptOverviewAsync,
    String hospitalId,
  ) {
    return deptOverviewAsync.when(
      data: (departments) {
        int grandTotalBookings = 0;
        int grandTotalOngoing = 0;
        for (var d in departments) {
          grandTotalBookings += (d['total_bookings'] as num? ?? 0).toInt();
          grandTotalOngoing += (d['ongoing_queue'] as num? ?? 0).toInt();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Department Live Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Click on any department tile to view its live queue and appointment logs',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "All Departments" Tile
                  _buildAllDepartmentsTile(
                    totalBookings: grandTotalBookings,
                    ongoingQueue: grandTotalOngoing,
                    isSelected: _selectedDepartmentId == null,
                    onTap: () {
                      setState(() {
                        _selectedDepartmentId = null;
                        _selectedDepartmentName = null;
                      });
                    },
                  ),
                  const SizedBox(width: 14),
                  // Individual Department Tiles
                  ...departments.map((dept) {
                    final deptId = dept['id'] as String? ?? '';
                    final name = dept['name'] as String? ?? 'General';
                    final specialty = dept['specialty'] as String? ?? '';
                    final totalBookings = (dept['total_bookings'] as num? ?? 0).toInt();
                    final ongoingQueue = (dept['ongoing_queue'] as num? ?? 0).toInt();
                    final activeDocs = (dept['active_doctors_count'] as num? ?? 0).toInt();
                    final isSelected = _selectedDepartmentId == deptId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _buildDepartmentTile(
                        deptId: deptId,
                        name: name,
                        specialty: specialty,
                        totalBookings: totalBookings,
                        ongoingQueue: ongoingQueue,
                        activeDoctors: activeDocs,
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
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Error loading department stats: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildAllDepartmentsTile({
    required int totalBookings,
    required int ongoingQueue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                    color: isSelected ? Colors.white.withAlpha(30) : const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.domain,
                    color: isSelected ? Colors.white : const Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      '$totalBookings Bookings',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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
                      '$ongoingQueue In Queue',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.amberAccent : Colors.orange.shade800,
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

  Widget _buildDepartmentTile({
    required String deptId,
    required String name,
    required String specialty,
    required int totalBookings,
    required int ongoingQueue,
    required int activeDoctors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData iconData = Icons.local_hospital;
    Color themeColor = const Color(0xFF0284C7);

    final lower = name.toLowerCase();
    if (lower.contains('cardio')) {
      iconData = Icons.favorite;
      themeColor = Colors.red.shade600;
    } else if (lower.contains('pedia') || lower.contains('child')) {
      iconData = Icons.child_care;
      themeColor = Colors.orange.shade600;
    } else if (lower.contains('ortho') || lower.contains('bone')) {
      iconData = Icons.healing;
      themeColor = Colors.teal.shade600;
    } else if (lower.contains('neuro') || lower.contains('brain')) {
      iconData = Icons.psychology;
      themeColor = Colors.purple.shade600;
    } else if (lower.contains('derma') || lower.contains('skin')) {
      iconData = Icons.spa;
      themeColor = Colors.pink.shade600;
    } else if (lower.contains('emer') || lower.contains('icu')) {
      iconData = Icons.emergency;
      themeColor = Colors.deepOrange.shade600;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                    color: isSelected ? Colors.white.withAlpha(30) : themeColor.withAlpha(20),
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
                    color: isSelected
                        ? Colors.white.withAlpha(40)
                        : (ongoingQueue > 0 ? Colors.amber.shade50 : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ongoingQueue > 0 ? Icons.flash_on : Icons.check_circle_outline,
                        size: 12,
                        color: isSelected
                            ? Colors.white
                            : (ongoingQueue > 0 ? Colors.orange.shade800 : Colors.green.shade700),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$ongoingQueue Ongoing',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (ongoingQueue > 0 ? Colors.orange.shade800 : Colors.green.shade700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$totalBookings Bookings',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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
                      '$activeDoctors Doctors',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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

  Widget _buildActiveFilterBanner() {
    if (_selectedDepartmentId == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 20),
            const SizedBox(width: 10),
            const Text(
              'Showing all appointment logs across all hospital departments in Indian Standard Time (IST).',
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
              const Icon(Icons.filter_alt, color: Color(0xFF0D47A1), size: 20),
              const SizedBox(width: 10),
              Text(
                'Department Filter Active: ',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              Text(
                _selectedDepartmentName ?? 'Selected Department',
                style: const TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              setState(() {
                _selectedDepartmentId = null;
                _selectedDepartmentName = null;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Clear Filter',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndFilters(BuildContext context) {
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
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by patient name, phone number, or type...',
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
              const SizedBox(width: 16),
              // Status Filter Dropdown
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'BOOKED', child: Text('Booked')),
                          DropdownMenuItem(value: 'WAITING', child: Text('Waiting')),
                          DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                          DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _statusFilter = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date Filter Bar in exact required sequence:
          // 1. Choose Date (Calendar)
          // 2. Yesterday
          // 3. Today
          // 4. Tomorrow
          // 5. All Dates
          Row(
            children: [
              const Text(
                'Filter Date:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 12),
              // 1. Choose Date (from Calendar)
              ActionChip(
                avatar: const Icon(Icons.calendar_month, size: 16, color: Color(0xFF1565C0)),
                label: Text(
                  _selectedDateFilterMode == 'Choose Date' && _customSelectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_customSelectedDate!)
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

  String _formatRowDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final trimmed = dateStr.trim();
      if (trimmed.startsWith('20')) {
        final parsed = DateTime.parse(trimmed);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final apptDate = DateTime(parsed.year, parsed.month, parsed.day);

        final diffDays = apptDate.difference(today).inDays;
        final formattedDate = DateFormat('dd MMM yyyy').format(parsed);

        if (diffDays == 0) {
          return 'Today, $formattedDate';
        } else if (diffDays == 1) {
          return 'Tomorrow, $formattedDate';
        } else if (diffDays == -1) {
          return 'Yesterday, $formattedDate';
        } else {
          return formattedDate;
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String _formatBookingTime(dynamic rawCreatedAt) {
    if (rawCreatedAt == null) return '';
    try {
      DateTime parsed;
      if (rawCreatedAt is DateTime) {
        parsed = rawCreatedAt;
      } else {
        parsed = DateTime.parse(rawCreatedAt.toString());
      }
      final local = parsed.toLocal();
      return DateFormat('hh:mm a').format(local);
    } catch (e) {
      return '';
    }
  }

  Widget _buildLogsTableContainer(
    AsyncValue<List<Map<String, dynamic>>> appointmentsAsync,
    String hospitalId,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: appointmentsAsync.when(
        data: (appointments) {
          var filtered = appointments;
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((a) {
              final name = (a['patient_name'] ?? '').toString().toLowerCase();
              final phone = (a['patient_phone'] ?? '').toString().toLowerCase();
              final bookingFor = (a['booking_for'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) ||
                  phone.contains(_searchQuery) ||
                  bookingFor.contains(_searchQuery);
            }).toList();
          }

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDepartmentName != null
                          ? 'No appointments logged for $_selectedDepartmentName'
                          : 'No appointment logs found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try switching the date filter or searching for another patient.',
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
                      'Department Appointment Logs (${filtered.length} entries)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
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
                  dataRowMaxHeight: 76,
                  dataRowMinHeight: 76,
                  horizontalMargin: 24,
                  columns: const [
                    DataColumn(label: Text('Date & Time (IST)')),
                    DataColumn(label: Text('Patient Name')),
                    DataColumn(label: Text('Age & Gender')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Booking Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filtered.map((appt) {
                    final apptId = appt['id'] ?? '';
                    final rawDate = appt['appointment_date'] ?? '';
                    final formattedDate = _formatRowDate(rawDate);
                    final bookingTime = _formatBookingTime(appt['created_at']);
                    final name = appt['patient_name'] ?? 'Unknown';
                    final ageGender = '${appt['patient_age'] ?? '-'} / ${appt['patient_gender'] ?? '-'}';
                    final phone = appt['patient_phone'] ?? 'N/A';
                    final bookingFor = appt['booking_for'] ?? 'myself';
                    final status = appt['status'] ?? 'BOOKED';

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_note, size: 15, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              if (bookingTime.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Booked at $bookingTime',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                        DataCell(Text(ageGender)),
                        DataCell(Text(phone)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bookingFor == 'myself' ? 'Self' : 'Family',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(status).withAlpha(60)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
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
                              if (status != 'COMPLETED')
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  onPressed: () async {
                                    final ok = await updateAppointmentStatus(apptId, 'COMPLETED');
                                    if (ok) _refreshAll(hospitalId);
                                  },
                                  tooltip: 'Mark Completed',
                                ),
                              if (status != 'CANCELLED')
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                  onPressed: () async {
                                    final ok = await updateAppointmentStatus(apptId, 'CANCELLED');
                                    if (ok) _refreshAll(hospitalId);
                                  },
                                  tooltip: 'Cancel Appointment',
                                ),
                            ],
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
          child: Center(child: Text('Error loading appointments: $e')),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'BOOKED':
        return Colors.blue.shade700;
      case 'WAITING':
        return Colors.orange.shade800;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
