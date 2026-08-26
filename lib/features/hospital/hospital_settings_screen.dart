import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/hospital_provider.dart';
import '../auth/providers/auth_provider.dart';

class HospitalSettingsScreen extends StatelessWidget {
  const HospitalSettingsScreen({super.key});

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
              'Hospital Configuration',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                  ),
            ),
            const SizedBox(height: 32),
            const _GeneralSettingsCard(),
            const SizedBox(height: 32),
            const _DepartmentsCard(),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettingsCard extends ConsumerWidget {
  const _GeneralSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalDetailsAsync = ref.watch(hospitalDetailsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hospitalDetailsAsync.when(
          data: (details) {
            if (details == null) {
              return const Center(child: Text('Failed to load hospital details'));
            }
            return _GeneralSettingsForm(details: details);
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          )),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _GeneralSettingsForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> details;
  const _GeneralSettingsForm({required this.details});
  @override
  ConsumerState<_GeneralSettingsForm> createState() => _GeneralSettingsFormState();
}

class _GeneralSettingsFormState extends ConsumerState<_GeneralSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _pincodeCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.details['name'] ?? '');
    _contactCtrl = TextEditingController(text: widget.details['contact_person'] ?? '');
    _emailCtrl = TextEditingController(text: widget.details['email'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.details['phone'] ?? '');
    _cityCtrl = TextEditingController(text: widget.details['city'] ?? '');
    _stateCtrl = TextEditingController(text: widget.details['state'] ?? '');
    _addressCtrl = TextEditingController(text: widget.details['address'] ?? '');
    _pincodeCtrl = TextEditingController(text: widget.details['pincode'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final data = {
      'name': _nameCtrl.text,
      'contact_person': _contactCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'city': _cityCtrl.text,
      'state': _stateCtrl.text,
      'address': _addressCtrl.text,
      'pincode': _pincodeCtrl.text,
    };
    final success = await ref.read(hospitalActionsProvider).updateHospitalDetails(widget.details['id'], data);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Settings saved successfully' : 'Failed to save settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return Column(
                  children: [
                    TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_outlined))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person (Admin)', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
                    const SizedBox(height: 24),
                    TextFormField(controller: _pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined))),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_outlined)))),
                      const SizedBox(width: 24),
                      Expanded(child: TextFormField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person (Admin)', prefixIcon: Icon(Icons.person_outline)))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)))),
                      const SizedBox(width: 24),
                      Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)))),
                      const SizedBox(width: 24),
                      Expanded(child: TextFormField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined)))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)))),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: TextFormField(controller: _pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined)))),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentsCard extends ConsumerWidget {
  const _DepartmentsCard();

  void _showAddEditDepartmentDialog(BuildContext context, WidgetRef ref, [Map<String, dynamic>? dept]) {
    final isEdit = dept != null;
    final nameCtrl = TextEditingController(text: dept?['name'] ?? '');
    final specialtyCtrl = TextEditingController(text: dept?['specialty'] ?? '');
    final descCtrl = TextEditingController(text: dept?['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Department' : 'Add Department'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Department Name')),
                    const SizedBox(height: 16),
                    TextField(controller: specialtyCtrl, decoration: const InputDecoration(labelText: 'Specialty')),
                    const SizedBox(height: 16),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameCtrl.text.isEmpty || specialtyCtrl.text.isEmpty) return;
                    setState(() => isSaving = true);
                    final data = {
                      'name': nameCtrl.text,
                      'specialty': specialtyCtrl.text,
                      'description': descCtrl.text,
                    };
                    final hospitalId = ref.read(authProvider).hospitalId!;
                    final success = isEdit
                        ? await ref.read(hospitalActionsProvider).updateDepartment(hospitalId, dept['id'], data)
                        : await ref.read(hospitalActionsProvider).addDepartment(hospitalId, data);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Department saved' : 'Failed to save department')),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(hospitalDepartmentsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Departments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDepartmentDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Department'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            deptsAsync.when(
              data: (depts) {
                if (depts.isEmpty) {
                  return const Text('No departments found.');
                }
                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: depts.map((d) {
                    return _buildDeptTile(context, ref, d);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptTile(BuildContext context, WidgetRef ref, Map<String, dynamic> dept) {
    final name = dept['name'] ?? 'Unknown';
    final desc = dept['specialty'] ?? '';
    final doctors = 0; // Mock until API supports it
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE3F2FD),
        child: Icon(Icons.local_hospital, color: Color(0xFF1565C0)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$desc • $doctors Doctors'),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _showAddEditDepartmentDialog(context, ref, dept),
      ),
    );
  }
}
