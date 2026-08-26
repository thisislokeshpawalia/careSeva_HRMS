import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/doctors_provider.dart';
import '../hospital/providers/hospital_provider.dart';
import '../auth/providers/auth_provider.dart';

class DoctorsScreen extends ConsumerWidget {
  const DoctorsScreen({super.key});

  void _showAddEditDoctorDialog(BuildContext context, WidgetRef ref, [Map<String, dynamic>? doctor]) {
    final isEdit = doctor != null;
    final nameCtrl = TextEditingController(text: doctor?['name'] ?? '');
    final specCtrl = TextEditingController(text: doctor?['specialization'] ?? '');
    final expCtrl = TextEditingController(text: (doctor?['experience_years'] ?? '').toString());
    final statusCtrl = TextEditingController(text: doctor?['status'] ?? 'ACTIVE');
    String? selectedDeptId = doctor?['department_id'];

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            final deptsAsync = ref.watch(hospitalDepartmentsProvider);

            return AlertDialog(
              title: Text(isEdit ? 'Edit Doctor' : 'Add Doctor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Doctor Name')),
                    const SizedBox(height: 16),
                    TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Specialization')),
                    const SizedBox(height: 16),
                    TextField(
                      controller: expCtrl, 
                      decoration: const InputDecoration(labelText: 'Experience (Years)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    deptsAsync.when(
                      data: (depts) {
                        if (depts.isEmpty) return const Text('No departments available. Add one first.');
                        if (selectedDeptId == null && depts.isNotEmpty) selectedDeptId = depts.first['id'];
                        return DropdownButtonFormField<String>(
                          initialValue: selectedDeptId,
                          decoration: const InputDecoration(labelText: 'Department'),
                          items: depts.map<DropdownMenuItem<String>>((d) {
                            return DropdownMenuItem<String>(
                              value: d['id'],
                              child: Text(d['name']),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedDeptId = val),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: statusCtrl.text.isEmpty ? 'ACTIVE' : statusCtrl.text,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                        DropdownMenuItem(value: 'ON_LEAVE', child: Text('On Leave')),
                      ],
                      onChanged: (val) => setState(() => statusCtrl.text = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameCtrl.text.isEmpty || specCtrl.text.isEmpty || selectedDeptId == null) return;
                    setState(() => isSaving = true);
                    final data = {
                      'name': nameCtrl.text,
                      'specialization': specCtrl.text,
                      'experience_years': int.tryParse(expCtrl.text) ?? 0,
                      'department_id': selectedDeptId,
                      'status': statusCtrl.text,
                      'qualification': doctor?['qualification'] ?? 'MBBS', // default for now
                    };
                    final hospitalId = ref.read(authProvider).hospitalId!;
                    final success = isEdit
                        ? await ref.read(doctorActionsProvider).updateDoctor(hospitalId, doctor['id'], data)
                        : await ref.read(doctorActionsProvider).addDoctor(hospitalId, data);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Doctor saved successfully' : 'Failed to save doctor')),
                      );
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Doctor'),
        content: Text('Are you sure you want to remove ${doctor['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final hospitalId = ref.read(authProvider).hospitalId!;
              final success = await ref.read(doctorActionsProvider).deleteDoctor(hospitalId, doctor['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Doctor removed' : 'Failed to remove doctor')),
                );
              }
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider);

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
                  'Doctors Management',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDoctorDialog(context, ref),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Doctor'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search doctors by name or department...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownMenu<String>(
                  initialSelection: 'All Departments',
                  onSelected: (String? value) {},
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'All Departments', label: 'All Departments'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: doctorsAsync.when(
                data: (doctors) {
                  final activeDoctors = doctors.where((d) => d['status'] != 'INACTIVE').toList();
                  if (activeDoctors.isEmpty) {
                    return const Center(child: Text('No doctors found. Please add a doctor.'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: activeDoctors.length,
                    itemBuilder: (context, index) {
                      final doc = activeDoctors[index];
                      return _DoctorCard(
                        doctor: doc,
                        onEdit: () => _showAddEditDoctorDialog(context, ref, doc),
                        onDelete: () => _confirmDelete(context, ref, doc),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorCard({
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = doctor['status'] ?? 'ACTIVE';
    final isAvailable = status == 'ACTIVE';
    final statusDisplay = isAvailable ? 'Available' : 'On Leave';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
               radius: 40,
               backgroundColor: Color(0xFFE3F2FD),
               child: Icon(Icons.person, size: 40, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 16),
            Text(
              doctor['name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              doctor['specialization'] ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green.withAlpha(25) : Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusDisplay,
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${doctor['experience_years'] ?? 0} Years', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: const Color(0xFF1565C0),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.red,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
