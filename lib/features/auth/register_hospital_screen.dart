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
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
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
      
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location fetched successfully!')),
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
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
                      const SizedBox(height: 32),
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
