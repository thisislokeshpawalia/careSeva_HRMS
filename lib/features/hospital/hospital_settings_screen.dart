import 'package:flutter/material.dart';

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

class _GeneralSettingsCard extends StatelessWidget {
  const _GeneralSettingsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                      TextFormField(
                        initialValue: 'City General Hospital',
                        decoration: const InputDecoration(labelText: 'Hospital Name'),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        initialValue: '+1 234 567 8900',
                        decoration: const InputDecoration(labelText: 'Contact Number'),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: 'City General Hospital',
                        decoration: const InputDecoration(labelText: 'Hospital Name'),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: TextFormField(
                        initialValue: '+1 234 567 8900',
                        decoration: const InputDecoration(labelText: 'Contact Number'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: '123 Health Avenue, Medical District, NY',
              decoration: const InputDecoration(labelText: 'Address'),
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
        ),
      ),
    );
  }
}

class _DepartmentsCard extends StatelessWidget {
  const _DepartmentsCard();

  @override
  Widget build(BuildContext context) {
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
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDeptTile('Cardiology', 'Heart & Vascular', 12),
                _buildDeptTile('Neurology', 'Brain & Nerves', 8),
                _buildDeptTile('Orthopedics', 'Bones & Joints', 15),
                _buildDeptTile('Pediatrics', 'Children & Infants', 20),
              ],
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
