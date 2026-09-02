import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import 'providers/doctors_provider.dart';
import '../hospital/providers/hospital_provider.dart';
import '../auth/providers/auth_provider.dart';

class DoctorsScreen extends ConsumerWidget {
  const DoctorsScreen({super.key});

  void _promptHospitalPasswordAndEdit(BuildContext context, WidgetRef ref, Map<String, dynamic> doctor) {
    final passwordCtrl = TextEditingController();
    bool isVerifying = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF1565C0)),
                  SizedBox(width: 10),
                  Text('Security Verification'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please enter the Password (used during hospital registration) to unlock and edit doctor credentials.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Hospital Password',
                      prefixIcon: const Icon(Icons.key),
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {},
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final password = passwordCtrl.text.trim();
                          if (password.isEmpty) {
                            setState(() => errorMessage = 'Password is required');
                            return;
                          }
                          setState(() {
                            isVerifying = true;
                            errorMessage = null;
                          });

                          try {
                            final hospitalId = ref.read(authProvider).hospitalId!;
                            final res = await http.post(
                              Uri.parse('${ApiConfig.httpBaseUrl}/api/auth/verify-hospital-password'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'hospital_id': hospitalId,
                                'password': password,
                              }),
                            );

                            if (res.statusCode == 200) {
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                _showAddEditDoctorDialog(context, ref, doctor);
                              }
                            } else {
                              final err = jsonDecode(res.body);
                              if (ctx.mounted) {
                                setState(() {
                                  isVerifying = false;
                                  errorMessage = err['detail'] ?? 'Invalid hospital password';
                                });
                              }
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setState(() {
                                isVerifying = false;
                                errorMessage = 'Verification error: $e';
                              });
                            }
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEditDoctorDialog(BuildContext context, WidgetRef ref, [Map<String, dynamic>? doctor]) {
    final isEdit = doctor != null;
    final nameCtrl = TextEditingController(text: doctor?['name'] ?? '');
    final specCtrl = TextEditingController(text: doctor?['specialization'] ?? '');
    final expCtrl = TextEditingController(text: (doctor?['experience_years'] ?? '').toString());
    final statusCtrl = TextEditingController(text: doctor?['status'] ?? 'ACTIVE');
    final double existingFee = (doctor?['consultation_fee'] as num?)?.toDouble() ?? 0.0;
    final feeCtrl = TextEditingController(text: existingFee > 0 ? existingFee.toStringAsFixed(0) : '');
    final bool isFeeLocked = isEdit && existingFee > 0;
    String? selectedDeptId = doctor?['department_id'];

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return Consumer(
          builder: (ctx, dialogRef, _) {
            return StatefulBuilder(
              builder: (ctx, setState) {
                final deptsAsync = dialogRef.watch(hospitalDepartmentsProvider);

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
                        TextField(
                          controller: feeCtrl,
                          enabled: !isFeeLocked,
                          decoration: InputDecoration(
                            labelText: isFeeLocked ? 'Consultation Fee (₹) [Locked]' : 'Consultation Fee (₹)',
                            prefixText: '₹ ',
                            helperText: isFeeLocked ? 'Fee is locked after initial registration' : null,
                            suffixIcon: isFeeLocked ? const Icon(Icons.lock, size: 18, color: Colors.grey) : null,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        deptsAsync.when(
                          data: (depts) {
                            if (depts.isEmpty) return const Text('No departments available. Add one first.');
                            if (selectedDeptId == null && depts.isNotEmpty) {
                              Future.microtask(() {
                                if (selectedDeptId == null) {
                                  setState(() => selectedDeptId = depts.first['id']);
                                }
                              });
                            }
                            return DropdownButtonFormField<String>(
                              value: selectedDeptId,
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
                          value: statusCtrl.text.isEmpty ? 'ACTIVE' : statusCtrl.text,
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
                        final feeValue = double.tryParse(feeCtrl.text) ?? existingFee;
                        final data = {
                          'name': nameCtrl.text,
                          'specialization': specCtrl.text,
                          'experience_years': int.tryParse(expCtrl.text) ?? 0,
                          'consultation_fee': feeValue,
                          'department_id': selectedDeptId,
                          'status': statusCtrl.text,
                          'qualification': doctor?['qualification'] ?? 'MBBS',
                        };
                        final hospitalId = dialogRef.read(authProvider).hospitalId!;
                        final success = isEdit
                            ? await dialogRef.read(doctorActionsProvider).updateDoctor(hospitalId, doctor['id'], data)
                            : await dialogRef.read(doctorActionsProvider).addDoctor(hospitalId, data);
                        
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
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctors Management',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage doctor profiles, consultation fees, and department assignments.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDoctorDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: doctorsAsync.when(
                data: (doctors) {
                  if (doctors.isEmpty) {
                    return const Center(child: Text('No doctors added yet.'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 390,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doc = doctors[index];
                      return _buildDoctorCard(
                        context,
                        doc,
                        onEdit: () => _promptHospitalPasswordAndEdit(context, ref, doc),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove Doctor'),
                              content: Text('Are you sure you want to remove ${doc['name']}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final hospitalId = ref.read(authProvider).hospitalId;
                            if (hospitalId == null) return;
                            final docId = (doc['id'] ?? doc['_id'] ?? doc['doc_id'])?.toString();
                            if (docId == null) return;

                            final success = await ref.read(doctorActionsProvider).deleteDoctor(hospitalId, docId);
                            ref.invalidate(doctorsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  content: Row(
                                    children: [
                                      Icon(
                                        success ? Icons.check_circle : Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          success
                                              ? '${doc['name']} has been removed successfully.'
                                              : 'Failed to remove doctor. Please try again.',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }
                        },
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

  Widget _buildDoctorCard(
    BuildContext context,
    Map<String, dynamic> doctor, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final status = doctor['status'] ?? 'ACTIVE';
    Color statusColor = Colors.green;
    String statusDisplay = 'Available';

    if (status == 'INACTIVE') {
      statusColor = Colors.grey;
      statusDisplay = 'Inactive';
    } else if (status == 'ON_LEAVE') {
      statusColor = Colors.orange;
      statusDisplay = 'On Leave';
    }

    final fee = (doctor['consultation_fee'] as num?)?.toDouble() ?? 0.0;
    final exp = doctor['experience_years'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE3F2FD),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 12),
            Text(
              doctor['name'] ?? 'Doctor',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              doctor['specialization'] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                'DocID: ${doctor['doc_id'] ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusDisplay,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            const Divider(),
            const SizedBox(height: 4),

            // Fee and Experience display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                      Text(
                        '₹${fee.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('$exp Yrs Exp', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: const Color(0xFF1565C0),
                  tooltip: 'Edit (Requires Hospital Password)',
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
