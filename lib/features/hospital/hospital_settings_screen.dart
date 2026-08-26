import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/hospital_provider.dart';

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
            return Column(
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
                          TextFormField(
                            initialValue: details['name'] ?? '',
                            decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_outlined)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['contact_person'] ?? '',
                            decoration: const InputDecoration(labelText: 'Contact Person (Admin)', prefixIcon: Icon(Icons.person_outline)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['email'] ?? '',
                            decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['phone'] ?? '',
                            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['city'] ?? '',
                            decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['state'] ?? '',
                            decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['address'] ?? '',
                            decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: details['pincode'] ?? '',
                            decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined)),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: details['name'] ?? '',
                                decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_outlined)),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: TextFormField(
                                initialValue: details['contact_person'] ?? '',
                                decoration: const InputDecoration(labelText: 'Contact Person (Admin)', prefixIcon: Icon(Icons.person_outline)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: details['email'] ?? '',
                                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: TextFormField(
                                initialValue: details['phone'] ?? '',
                                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: details['city'] ?? '',
                                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: TextFormField(
                                initialValue: details['state'] ?? '',
                                decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: details['address'] ?? '',
                                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: details['pincode'] ?? '',
                                decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_outlined)),
                              ),
                            ),
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
                    onPressed: () {},
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _DepartmentsCard extends ConsumerWidget {
  const _DepartmentsCard();

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
                  onPressed: () {},
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
                    return _buildDeptTile(d['name'] ?? 'Unknown', d['specialty'] ?? '', 0);
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

  Widget _buildDeptTile(String name, String desc, int doctors) {
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
        onPressed: () {},
      ),
    );
  }
}
