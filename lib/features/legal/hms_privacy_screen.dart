import 'package:flutter/material.dart';

class HmsPrivacyScreen extends StatelessWidget {
  const HmsPrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HMS Privacy & Data Notice'),
        backgroundColor: Colors.blueGrey.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'CareSeva™ HMS Privacy & Data Processing Notice',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            SizedBox(height: 8),
            Text(
              'Compliance: DPDP Act 2023 (India) | Version 1.0\n'
              'Data Processor: Softkrest Infotech (Proprietor: Mr. Sarthak Srivastava)\n'
              'MSME Udyam Reg: UDYAM-UP-75-0200308 | Trademark: CARESEVA™ Class 42\n'
              'Contact: softkrestinfotech@gmail.com | Helpline: +91 9369309644',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Divider(height: 24, thickness: 1),
            Text(
              '1. Legal Processing Roles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'The Hospital acts as the Data Fiduciary/Controller for patient clinical records created during hospital walk-in consultations. Softkrest Infotech acts as the SaaS Data Processor operating cloud infrastructure.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Multi-Tenant Database Isolation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'CareSeva HMS enforces strict row-level hospital data isolation. Hospital A staff have ZERO technical visibility into Hospital B patient records or queues.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Immutable Staff Audit Logging',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'HMS maintains server-side audit logs for all sensitive actions including login events, token status changes, patient registration, and prescription issuance.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Data Retention & Export',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Hospital operational data is retained during active subscription. Upon contract termination, data export in JSON/CSV format is provided prior to database purging.',
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
