import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Facility Type Selection: 'clinic' or 'hospital'
  String? _facilityType; 

  // Basic Controllers
  final _nameController = TextEditingController();
  final _legalEntityController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _yearEstablishedController = TextEditingController();

  // Clinic Specific Controllers & State
  String _clinicType = 'General Clinic';
  String _systemOfMedicine = 'Allopathy';
  final _ownerNameController = TextEditingController();
  final _ownerDesignationController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _udyamController = TextEditingController();

  // Hospital Specific Controllers & State
  String _ownershipType = 'Private';
  final _totalBedsController = TextEditingController(text: '0');
  final _operationalBedsController = TextEditingController(text: '0');
  final _icuBedsController = TextEditingController(text: '0');
  final _emergencyBedsController = TextEditingController(text: '0');
  final _hduBedsController = TextEditingController(text: '0');
  final _isolationBedsController = TextEditingController(text: '0');
  
  bool _hasNabhAccreditation = false;
  String _nabhLevel = 'NONE';
  final _nabhNumberController = TextEditingController();

  // Legal & Statutory Credentials
  final _ceaNumberController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _msNameController = TextEditingController();
  final _msRegController = TextEditingController();
  final _bmwAuthController = TextEditingController();
  final _pharmacyLicenseController = TextEditingController();
  final _fireNocController = TextEditingController();

  // Selected Services & Specialities
  final Set<String> _selectedSpecialities = {
    'General Medicine', 'Paediatrics', 'Gynaecology'
  };
  final Set<String> _selectedHospitalServices = {
    'OPD', 'IPD', 'Emergency', 'Laboratory', 'Pharmacy'
  };

  bool _slaAccepted = true;
  bool _isLoading = false;
  bool _fetchingLocation = false;

  final List<String> _availableClinicTypes = [
    'General Clinic', 'Specialist Clinic', 'Polyclinic', 
    'Dental Clinic', 'Ayurveda Clinic', 'Homeopathy Clinic', 'Other'
  ];

  final List<String> _availableSystemsOfMedicine = [
    'Allopathy', 'Ayurveda', 'Homeopathy', 'Dental', 'Unani', 'Siddha', 'Other'
  ];

  final List<String> _availableOwnershipTypes = [
    'Private', 'Corporate', 'Trust', 'Society', 'Government', 'Other'
  ];

  final List<String> _availableSpecialities = [
    'General Medicine', 'Dentistry', 'Dermatology', 'ENT', 'Orthopaedics',
    'Gynaecology', 'Paediatrics', 'Physiotherapy', 'Ayurveda', 'Homeopathy',
    'Cardiology', 'Neurology', 'Ophthalmology', 'Psychiatry', 'Urology'
  ];

  final List<String> _availableHospitalServices = [
    'OPD', 'IPD', 'Emergency', 'ICU', 'Operation Theatre', 'Laboratory',
    'Radiology', 'Pharmacy', 'Blood Bank', 'Ambulance', 'Dialysis', 
    'Maternity', 'NICU', 'PICU'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _legalEntityController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _yearEstablishedController.dispose();

    _ownerNameController.dispose();
    _ownerDesignationController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _udyamController.dispose();

    _totalBedsController.dispose();
    _operationalBedsController.dispose();
    _icuBedsController.dispose();
    _emergencyBedsController.dispose();
    _hduBedsController.dispose();
    _isolationBedsController.dispose();
    _nabhNumberController.dispose();

    _ceaNumberController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _msNameController.dispose();
    _msRegController.dispose();
    _bmwAuthController.dispose();
    _pharmacyLicenseController.dispose();
    _fireNocController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_facilityType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please select a facility type: CLINIC or HOSPITAL before submitting.'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (!_slaAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must accept the CareSeva Digital Master Service Agreement to register.')),
        );
        return;
      }
      setState(() => _isLoading = true);
      
      final Map<String, dynamic> payload = {
        "name": _nameController.text.trim(),
        "facility_type": _facilityType, // 'clinic' or 'hospital'
        "contact_person": _contactPersonController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "latitude": double.tryParse(_latController.text),
        "longitude": double.tryParse(_lngController.text),
        "legal_entity_name": _legalEntityController.text.isEmpty ? _nameController.text.trim() : _legalEntityController.text.trim(),
        "clinical_establishment_no": _ceaNumberController.text.trim(),
        "gstin": _gstinController.text.trim(),
        "pan_number": _panController.text.trim(),
        "specialties": _selectedSpecialities.toList(),
        "password": _passwordController.text,
        "sla_accepted": _slaAccepted,
        "system_of_medicine": _systemOfMedicine,
      };

      if (_facilityType == 'clinic') {
        payload.addAll({
          "clinic_type": _clinicType,
          "owner_name": _ownerNameController.text.trim(),
          "owner_designation": _ownerDesignationController.text.trim(),
          "owner_phone": _ownerPhoneController.text.trim(),
          "owner_email": _ownerEmailController.text.trim(),
          "udyam_number": _udyamController.text.trim(),
        });
      } else {
        payload.addAll({
          "ownership_type": _ownershipType,
          "total_beds": int.tryParse(_totalBedsController.text) ?? 0,
          "operational_beds": int.tryParse(_operationalBedsController.text) ?? 0,
          "icu_beds": int.tryParse(_icuBedsController.text) ?? 0,
          "emergency_beds": int.tryParse(_emergencyBedsController.text) ?? 0,
          "hdu_beds": int.tryParse(_hduBedsController.text) ?? 0,
          "isolation_beds": int.tryParse(_isolationBedsController.text) ?? 0,
          "services": _selectedHospitalServices.toList(),
          "has_nabh": _hasNabhAccreditation,
          "nabh_accreditation": _hasNabhAccreditation ? _nabhLevel : "NONE",
          "medical_superintendent_name": _msNameController.text.trim(),
          "medical_superintendent_reg_no": _msRegController.text.trim(),
          "bmw_auth_number": _bmwAuthController.text.trim(),
          "pharmacy_license_no": _pharmacyLicenseController.text.trim(),
          "fire_noc_number": _fireNocController.text.trim(),
        });
      }

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
                title: Text('${_facilityType == 'clinic' ? 'Clinic' : 'Hospital'} Registration Successful!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your ${_facilityType == 'clinic' ? 'clinic' : 'hospital'} has been onboarded to CareSeva and is pending verification.'),
                    const SizedBox(height: 16),
                    const Text('Please save your unique Facility ID (HopID). You and your doctors will need it to login:', style: TextStyle(fontWeight: FontWeight.bold)),
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
        try {
          final clientRes = await http.get(
            Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
            headers: {'User-Agent': 'CareSeva-Facility-Registry/1.0'},
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1565C0),
            behavior: SnackBarBehavior.floating,
            content: Text('Location coordinates fetched: Lat $lat, Lng $lng'),
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
        title: const Text('Register Healthcare Facility'),
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
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Logo
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 52,
                              color: Color(0xFF1565C0),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'CareSeva',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Healthcare Facility Registration & Onboarding',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // MANDATORY FACILITY TYPE TOGGLE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withAlpha(120),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'What type of healthcare facility are you registering?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0D47A1),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _facilityType = 'clinic'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _facilityType == 'clinic' 
                                            ? Colors.teal.shade700 
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _facilityType == 'clinic'
                                            ? [BoxShadow(color: Colors.teal.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))]
                                            : [],
                                        border: Border.all(
                                          color: _facilityType == 'clinic' ? Colors.teal.shade700 : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.medical_services_outlined,
                                            color: _facilityType == 'clinic' ? Colors.white : Colors.teal.shade800,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'CLINIC',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: _facilityType == 'clinic' ? Colors.white : Colors.teal.shade900,
                                            ),
                                          ),
                                          Text(
                                            'CareSeva CMS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _facilityType == 'clinic' ? Colors.white70 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _facilityType = 'hospital'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _facilityType == 'hospital' 
                                            ? const Color(0xFF1565C0) 
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _facilityType == 'hospital'
                                            ? [BoxShadow(color: Colors.blue.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))]
                                            : [],
                                        border: Border.all(
                                          color: _facilityType == 'hospital' ? const Color(0xFF1565C0) : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.local_hospital,
                                            color: _facilityType == 'hospital' ? Colors.white : const Color(0xFF1565C0),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'HOSPITAL',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: _facilityType == 'hospital' ? Colors.white : const Color(0xFF0D47A1),
                                            ),
                                          ),
                                          Text(
                                            'CareSeva HMS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _facilityType == 'hospital' ? Colors.white70 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_facilityType == null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: const Text(
                            'Please tap CLINIC or HOSPITAL above to start the onboarding form.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ] else ...[
                        // BASIC FACILITY INFORMATION
                        _buildSectionHeader(
                          title: _facilityType == 'clinic' ? '1. Clinic Basic Information' : '1. Hospital Basic Information',
                          icon: Icons.info_outline,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: _facilityType == 'clinic' ? 'Clinic Name *' : 'Hospital Name *',
                            prefixIcon: const Icon(Icons.business),
                          ),
                          validator: (v) => v!.isEmpty ? 'Facility name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _legalEntityController,
                          decoration: const InputDecoration(
                            labelText: 'Registered Legal Entity Name',
                            prefixIcon: Icon(Icons.apartment),
                            hintText: 'e.g. Apex Health Pvt Ltd or Owner/Trust Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_facilityType == 'clinic') ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _clinicType,
                                  decoration: const InputDecoration(labelText: 'Clinic Type', prefixIcon: Icon(Icons.category)),
                                  items: _availableClinicTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (v) => setState(() => _clinicType = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _systemOfMedicine,
                                  decoration: const InputDecoration(labelText: 'System of Medicine', prefixIcon: Icon(Icons.healing)),
                                  items: _availableSystemsOfMedicine.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (v) => setState(() => _systemOfMedicine = v!),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _ownershipType,
                                  decoration: const InputDecoration(labelText: 'Ownership Type', prefixIcon: Icon(Icons.account_balance)),
                                  items: _availableOwnershipTypes.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                  onChanged: (v) => setState(() => _ownershipType = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _systemOfMedicine,
                                  decoration: const InputDecoration(labelText: 'System of Medicine', prefixIcon: Icon(Icons.healing)),
                                  items: _availableSystemsOfMedicine.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (v) => setState(() => _systemOfMedicine = v!),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _contactPersonController,
                                decoration: const InputDecoration(labelText: 'Admin / Contact Person *', prefixIcon: Icon(Icons.person)),
                                validator: (v) => v!.isEmpty ? 'Contact person required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(labelText: 'Official Phone *', prefixIcon: Icon(Icons.phone)),
                                keyboardType: TextInputType.phone,
                                validator: (v) => v!.isEmpty ? 'Phone number required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(labelText: 'Official Email *', prefixIcon: Icon(Icons.email)),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => v!.isEmpty ? 'Email required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Admin Password *', prefixIcon: Icon(Icons.lock)),
                                validator: (v) => v!.isEmpty ? 'Password required' : null,
                              ),
                            ),
                          ],
                        ),

                        // CLINIC OWNER / AUTHORIZED REPRESENTATIVE (Only for Clinic)
                        if (_facilityType == 'clinic') ...[
                          const SizedBox(height: 20),
                          _buildSectionHeader(title: '2. Clinic Owner / Proprietor Details', icon: Icons.person_pin),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ownerNameController,
                                  decoration: const InputDecoration(labelText: 'Owner / Proprietor Name', prefixIcon: Icon(Icons.badge)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _ownerDesignationController,
                                  decoration: const InputDecoration(
                                    labelText: 'Designation', 
                                    prefixIcon: Icon(Icons.work),
                                    hintText: 'e.g. Proprietor, Director',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ownerPhoneController,
                                  decoration: const InputDecoration(labelText: 'Owner Phone', prefixIcon: Icon(Icons.phone_android)),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _udyamController,
                                  decoration: const InputDecoration(labelText: 'Udyam Registration # (Optional)', prefixIcon: Icon(Icons.verified)),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // HOSPITAL CAPACITY DETAILS (Only for Hospital)
                        if (_facilityType == 'hospital') ...[
                          const SizedBox(height: 20),
                          _buildSectionHeader(title: '2. Hospital Capacity & Beds', icon: Icons.hotel),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _totalBedsController,
                                  decoration: const InputDecoration(labelText: 'Sanctioned Beds', prefixIcon: Icon(Icons.bed)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _operationalBedsController,
                                  decoration: const InputDecoration(labelText: 'Operational Beds', prefixIcon: Icon(Icons.bed_outlined)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _icuBedsController,
                                  decoration: const InputDecoration(labelText: 'ICU Beds', prefixIcon: Icon(Icons.monitor_heart)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emergencyBedsController,
                                  decoration: const InputDecoration(labelText: 'Emergency Beds', prefixIcon: Icon(Icons.emergency)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _hduBedsController,
                                  decoration: const InputDecoration(labelText: 'HDU Beds', prefixIcon: Icon(Icons.hotel_class)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _isolationBedsController,
                                  decoration: const InputDecoration(labelText: 'Isolation Beds', prefixIcon: Icon(Icons.masks)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // LOCATION DETAILS
                        const SizedBox(height: 20),
                        _buildSectionHeader(title: '3. Location Details', icon: Icons.location_on),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(labelText: 'Full Address *', prefixIcon: Icon(Icons.home)),
                                validator: (v) => v!.isEmpty ? 'Address is required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _pincodeController,
                                decoration: const InputDecoration(labelText: 'Pincode *', prefixIcon: Icon(Icons.pin_drop)),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty ? 'Pincode required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(labelText: 'City *', prefixIcon: Icon(Icons.location_city)),
                                validator: (v) => v!.isEmpty ? 'City required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(labelText: 'State *', prefixIcon: Icon(Icons.map)),
                                validator: (v) => v!.isEmpty ? 'State required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.explore)),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.explore)),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _fetchingLocation ? null : _fetchLocation,
                              icon: _fetchingLocation 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                                : const Icon(Icons.my_location),
                              label: Text(_fetchingLocation ? 'Fetching...' : 'GPS Location'),
                            ),
                          ],
                        ),

                        // SPECIALITIES & SERVICES
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          title: '4. Specialities & Services Offered', 
                          icon: Icons.medical_information,
                        ),
                        const SizedBox(height: 8),
                        const Text('Select specialities offered (integrated with patient app search):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _availableSpecialities.map((s) {
                            final isSel = _selectedSpecialities.contains(s);
                            return FilterChip(
                              label: Text(s),
                              selected: isSel,
                              selectedColor: Colors.teal.shade100,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedSpecialities.add(s);
                                  } else {
                                    _selectedSpecialities.remove(s);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        if (_facilityType == 'hospital') ...[
                          const SizedBox(height: 14),
                          const Text('Select Hospital Services:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _availableHospitalServices.map((hs) {
                              final isSel = _selectedHospitalServices.contains(hs);
                              return FilterChip(
                                label: Text(hs),
                                selected: isSel,
                                selectedColor: Colors.blue.shade100,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedHospitalServices.add(hs);
                                    } else {
                                      _selectedHospitalServices.remove(hs);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        // STATUTORY LEGAL CREDENTIALS
                        const SizedBox(height: 20),
                        _buildSectionHeader(title: '5. Statutory Credentials & Legal Compliance', icon: Icons.gavel),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ceaNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Clinical Establishment Reg # (CEA) *',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                            hintText: 'e.g. CEA/UP/2026/0412',
                          ),
                          validator: (v) => v!.isEmpty ? 'CEA Reg # is required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _gstinController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 15,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                  LengthLimitingTextInputFormatter(15),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'GSTIN (15 Digits - Optional)',
                                  prefixIcon: Icon(Icons.receipt_long),
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _panController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'PAN Number (10 Chars - Optional)',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_facilityType == 'hospital') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _msNameController,
                                  decoration: const InputDecoration(labelText: 'Medical Superintendent / CMO', prefixIcon: Icon(Icons.medical_services)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _msRegController,
                                  decoration: const InputDecoration(labelText: 'Medical Council / NMC Reg #', prefixIcon: Icon(Icons.verified)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // NABH ACCREDITATION TOGGLE (OPTIONAL)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.workspace_premium, color: Colors.amber),
                                        SizedBox(width: 8),
                                        Text('Does the hospital have NABH accreditation?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Switch(
                                      value: _hasNabhAccreditation,
                                      onChanged: (val) => setState(() => _hasNabhAccreditation = val),
                                    ),
                                  ],
                                ),
                                if (_hasNabhAccreditation) ...[
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: _nabhLevel == 'NONE' ? 'ENTRY_LEVEL' : _nabhLevel,
                                    decoration: const InputDecoration(labelText: 'Accreditation Level'),
                                    items: const [
                                      DropdownMenuItem(value: 'ENTRY_LEVEL', child: Text('NABH Entry Level')),
                                      DropdownMenuItem(value: 'FULL_NABH', child: Text('Full NABH Certified')),
                                      DropdownMenuItem(value: 'NABL', child: Text('NABL Certified (Lab)')),
                                      DropdownMenuItem(value: 'JCI', child: Text('JCI International Accredited')),
                                    ],
                                    onChanged: (v) => setState(() => _nabhLevel = v ?? 'ENTRY_LEVEL'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // SLA TERMS ACCEPTANCE
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          value: _slaAccepted,
                          onChanged: (val) => setState(() => _slaAccepted = val ?? false),
                          title: Text(
                            'I declare that all submitted information for this ${_facilityType == 'clinic' ? 'Clinic' : 'Hospital'} is true and accurate, and accept the CareSeva Master Service Agreement & Statutory Terms.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),
                        
                        _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _facilityType == 'clinic' ? Colors.teal.shade700 : const Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _register,
                              child: Text(
                                'Register ${_facilityType == 'clinic' ? 'Clinic (CareSeva CMS)' : 'Hospital (CareSeva HMS)'}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                      ],
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

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D47A1)),
        ),
      ],
    );
  }
}
