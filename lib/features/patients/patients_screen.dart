import 'package:flutter/material.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

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
                  'Patients Registry',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register Patient'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients by name, ID, or phone...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                    dataRowMaxHeight: 72,
                    dataRowMinHeight: 72,
                    columns: const [
                      DataColumn(label: Text('Patient ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Age / Gender')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Last Visit')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: [
                      _buildPatientRow('PT-10042', 'John Smith', '45 / M', '+1 234-567-8901', 'Oct 12, 2023'),
                      _buildPatientRow('PT-10043', 'Sarah Connor', '32 / F', '+1 234-567-8902', 'Sep 28, 2023'),
                      _buildPatientRow('PT-10044', 'Michael Johnson', '58 / M', '+1 234-567-8903', 'Oct 20, 2023'),
                      _buildPatientRow('PT-10045', 'Emily Davis', '28 / F', '+1 234-567-8904', 'Oct 21, 2023'),
                      _buildPatientRow('PT-10046', 'Robert Wilson', '64 / M', '+1 234-567-8905', 'Aug 15, 2023'),
                      _buildPatientRow('PT-10047', 'Linda Taylor', '41 / F', '+1 234-567-8906', 'Oct 22, 2023'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildPatientRow(String id, String name, String details, String phone, String lastVisit) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)))),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text(name[0], style: const TextStyle(color: Color(0xFF1565C0), fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        DataCell(Text(details, style: TextStyle(color: Colors.grey.shade600))),
        DataCell(Text(phone)),
        DataCell(Text(lastVisit)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: const Color(0xFF1565C0),
                onPressed: () {},
                tooltip: 'View Profile',
              ),
              IconButton(
                icon: const Icon(Icons.history_edu_outlined, size: 20),
                color: const Color(0xFF00BFA5),
                onPressed: () {},
                tooltip: 'EMR History',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
