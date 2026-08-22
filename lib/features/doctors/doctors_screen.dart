import 'package:flutter/material.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {},
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
                    DropdownMenuEntry(value: 'Cardiology', label: 'Cardiology'),
                    DropdownMenuEntry(value: 'Neurology', label: 'Neurology'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.85,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return _DoctorCard(
                    name: 'Dr. Jane Smith',
                    specialty: 'Cardiology',
                    experience: '12 Years',
                    email: 'jane.smith@hospital.com',
                    status: index % 3 == 0 ? 'On Leave' : 'Available',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String experience;
  final String email;
  final String status;

  const _DoctorCard({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.email,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'Available';
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
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              specialty,
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
                status,
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
                Text(experience, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                  color: const Color(0xFF1565C0),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
