import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../core/api_config.dart';

class RegisterHospitalScreen extends StatefulWidget {
  const RegisterHospitalScreen({super.key});

  @override
  State<RegisterHospitalScreen> createState() => _RegisterHospitalScreenState();
}

class _RegisterHospitalScreenState extends State<RegisterHospitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _legalEntityController = TextEditingController();
  final _ceaNumberController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _msNameController = TextEditingController();
  final _msRegController = TextEditingController();
  final _bedsController = TextEditingController();
  String _nabhAccreditation = 'NONE';
  bool _slaAccepted = true;
  bool _isLoading = false;
  bool _fetchingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _legalEntityController.dispose();
    _ceaNumberController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _msNameController.dispose();
    _msRegController.dispose();
    _bedsController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_slaAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must accept the CareSeva Digital Master Service Agreement to register.')),
        );
        return;
      }
      setState(() => _isLoading = true);
      
      final payload = {
        "name": _nameController.text,
        "facility_type": "Hospital",
        "contact_person": _contactPersonController.text,
        "phone": _phoneController.text,
        "email": _emailController.text,
        "address": _addressController.text,
        "city": _cityController.text,
        "state": _stateController.text,
        "pincode": _pincodeController.text,
        "latitude": double.tryParse(_latController.text),
        "longitude": double.tryParse(_lngController.text),
        "legal_entity_name": _legalEntityController.text.isEmpty ? _nameController.text : _legalEntityController.text,
        "clinical_establishment_no": _ceaNumberController.text,
        "gstin": _gstinController.text,
        "pan_number": _panController.text,
        "nabh_accreditation": _nabhAccreditation,
        "medical_superintendent_name": _msNameController.text,
        "medical_superintendent_reg_no": _msRegController.text,
        "total_beds": int.tryParse(_bedsController.text) ?? 0,
        "sla_accepted": _slaAccepted,
        "specialties": [],
        "password": _passwordController.text
      };

      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.httpBaseUrl}/api/hospitals/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Registration Successful!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your facility has been registered and is pending approval.'),
                    const SizedBox(height: 16),
                    const Text('Please save your unique Hospital ID (HopID). You and your doctors will need it to login:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue.shade50,
                      child: SelectableText(
                        data['hop_id'] ?? 'UNKNOWN',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.go('/login');
                    },
                    child: const Text('Go to Login'),
                  )
                ],
              ),
            );
          }
        } else {
          final error = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration failed: ${error['detail'] ?? 'Unknown error'}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      } 

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      
      final lat = position.latitude.toString();
      final lng = position.longitude.toString();

      setState(() {
        _latController.text = lat;
        _lngController.text = lng;
      });

      // Auto-fill City, State, Pincode & Address via Reverse Geocoding
      String autoCity = '';
      String autoState = '';
      String autoPincode = '';
      String autoAddress = '';

      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.httpBaseUrl}/api/hospitals/reverse-geocode?lat=$lat&lng=$lng'),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          autoCity = data['city'] ?? '';
          autoState = data['state'] ?? '';
          autoPincode = data['pincode'] ?? '';
          autoAddress = data['address'] ?? '';
        }
      } catch (_) {
        // Direct client fallback to OpenStreetMap if backend reverse geocode is unreachable
        try {
          final clientRes = await http.get(
            Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
            headers: {'User-Agent': 'CareSeva-Hospital-Registry/1.0'},
          );
          if (clientRes.statusCode == 200) {
            final data = jsonDecode(clientRes.body);
            final addr = data['address'] ?? {};
            autoCity = addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['suburb'] ?? addr['state_district'] ?? '';
            autoState = addr['state'] ?? '';
            autoPincode = addr['postcode'] ?? '';
            autoAddress = addr['road'] ?? addr['suburb'] ?? '';
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          if (autoCity.isNotEmpty) _cityController.text = autoCity;
          if (autoState.isNotEmpty) _stateController.text = autoState;
          if (autoPincode.isNotEmpty) _pincodeController.text = autoPincode;
          if (autoAddress.isNotEmpty && _addressController.text.trim().isEmpty) {
            _addressController.text = autoAddress;
          }
        });

        String info = 'Location coordinates fetched!';
        if (autoCity.isNotEmpty || autoState.isNotEmpty || autoPincode.isNotEmpty) {
          info = 'Location fetched! Auto-filled $autoCity, $autoState ${autoPincode.isNotEmpty ? '($autoPincode)' : ''}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1565C0),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(info, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Register Hospital'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.local_hospital,
                        size: 48,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hospital Registration',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.business)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(labelText: 'Contact Person (Admin)', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Admin Password', prefixIcon: Icon(Icons.lock)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city)),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(labelText: 'State'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(labelText: 'Pincode'),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.explore)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.explore)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _fetchingLocation ? null : _fetchLocation,
                        icon: _fetchingLocation 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.my_location),
                        label: Text(_fetchingLocation ? 'Fetching...' : 'Fetch Current Location'),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF1565C0), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Statutory & Legal Em-panelment Credentials',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Required under the Clinical Establishments Act and CareSeva Aggregator Compliance.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ceaNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Establishment Act (CEA) Reg #',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                          hintText: 'e.g. CEA/UP/2026/0412',
                        ),
                        validator: (v) => v!.isEmpty ? 'CEA Registration # is required by law' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _legalEntityController,
                        decoration: const InputDecoration(
                          labelText: 'Registered Legal Entity Name',
                          prefixIcon: Icon(Icons.apartment_outlined),
                          hintText: 'e.g. Apollo Healthcare Ltd or Trust Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gstinController,
                              decoration: const InputDecoration(labelText: 'Hospital GSTIN', prefixIcon: Icon(Icons.receipt_long)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _panController,
                              decoration: const InputDecoration(labelText: 'Hospital PAN', prefixIcon: Icon(Icons.badge_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _msNameController,
                        decoration: const InputDecoration(labelText: 'Medical Superintendent / CMO Name', prefixIcon: Icon(Icons.medical_services_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _msRegController,
                        decoration: const InputDecoration(labelText: 'State Medical Council / NMC Reg #', prefixIcon: Icon(Icons.verified_outlined), hintText: 'e.g. MCI-2018-0921'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bedsController,
                        decoration: const InputDecoration(labelText: 'Total Monitored Inpatient Beds', prefixIcon: Icon(Icons.hotel_outlined), hintText: 'e.g. 50'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _nabhAccreditation,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'NABH / Quality Accreditation', prefixIcon: Icon(Icons.workspace_premium_outlined)),
                        items: const [
                          DropdownMenuItem(value: 'NONE', child: Text('None / Non-Accredited', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'ENTRY_LEVEL', child: Text('NABH Entry Level', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'FULL_NABH', child: Text('Full NABH Certified', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'NABL', child: Text('NABL Certified (Diagnostics)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) => setState(() => _nabhAccreditation = val ?? 'NONE'),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _slaAccepted,
                        onChanged: (val) => setState(() => _slaAccepted = val ?? false),
                        title: const Text(
                          'I declare that all submitted clinical details are true and accept the CareSeva Digital Master Service Agreement & Statutory Healthcare Indemnity Terms.',
                          style: TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Register Hospital'),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
