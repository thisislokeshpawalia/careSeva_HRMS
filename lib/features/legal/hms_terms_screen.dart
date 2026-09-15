import 'package:flutter/material.dart';

class HmsTermsScreen extends StatelessWidget {
  const HmsTermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HMS Terms of Service (B2B SaaS)'),
        backgroundColor: Colors.blueGrey.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'CareSeva™ HMS Terms of Service',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            SizedBox(height: 8),
            Text(
              'Effective Date: September 15, 2026 | Version 1.0\n'
              'SaaS Service Provider: Softkrest Infotech (Proprietor: Mr. Sarthak Srivastava)\n'
              'MSME Udyam Reg: UDYAM-UP-75-0200308 | Trademark: CARESEVA™ Class 42\n'
              'Contact Email: softkrestinfotech@gmail.com | Helpline: +91 9369309644',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Divider(height: 24, thickness: 1),
            Text(
              '1. B2B SaaS Platform Licensing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Softkrest Infotech grants registered hospitals, administrators, doctors, receptionists, and authorized staff a non-exclusive license to use CareSeva HMS for OPD queue management, walk-in registration, and IPD admissions.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Hospital Clinical & Operational Responsibility',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'The registered hospital and doctors assume EXCLUSIVE clinical, medical, legal, and regulatory liability for all diagnoses, treatments, prescriptions, and advice issued through CareSeva HMS. All onboarded doctors must possess active National Medical Commission (NMC) licenses.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Account Security & RBAC',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Hospital staff must use individual credentials. Sharing accounts across staff is strictly prohibited. The hospital must immediately revoke credentials when a staff member resigns.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Patient Confidentiality',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Hospital staff must maintain strict patient confidentiality and process records solely for clinical treatment under the Digital Personal Data Protection Act 2023.',
            ),
            SizedBox(height: 16),
            Text(
              '5. B2B Indemnification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'The hospital agrees to fully indemnify Softkrest Infotech and Mr. Sarthak Srivastava against any medical malpractice claims, patient disputes, or hospital data breaches.',
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
