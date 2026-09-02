import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.admin;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      bool success = false;
      if (_selectedRole == UserRole.admin) {
        success = await ref.read(authProvider.notifier).login(
              _emailController.text,
              _passwordController.text,
              _selectedRole,
            );
      } else {
        // Normalize HopID and DocID
        String rawHop = _emailController.text.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
        if (rawHop.startsWith('CARE') && rawHop.length > 4) {
          rawHop = 'CARE-${rawHop.substring(4)}';
        }
        
        String rawDoc = _passwordController.text.toUpperCase().replaceAll(' ', '').replaceAll('-', '');

        success = await ref.read(authProvider.notifier).doctorLogin(
              rawHop,
              rawDoc,
            );
      }
      
      if (success && mounted) {
        // Routing is handled by GoRouter redirect based on auth state
      } else if (mounted) {
        final authState = ref.read(authProvider);
        final err = authState.errorMessage ?? 'Login failed. Check your credentials.';

        if (err.contains('REGISTRATION_REJECTED')) {
          final cleanReason = err.replaceAll('REGISTRATION_REJECTED:', '').trim();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent)),
              title: const Row(
                children: [
                  Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 10),
                  Text('Application Rejected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your hospital em-panelment application was reviewed and rejected by the CareSeva Regulatory Directorate.',
                    style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(cleanReason, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To re-apply or appeal, contact compliance@careseva.com.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
        } else if (err.contains('REGISTRATION_PENDING')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              content: Text('Hospital registration is currently undergoing verification by CareSeva Superadmin.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                        size: 64,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'CareQueue HMS',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment<UserRole>(
                            value: UserRole.admin,
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                          ButtonSegment<UserRole>(
                            value: UserRole.doctor,
                            label: Text('Doctor'),
                            icon: Icon(Icons.medical_services),
                          ),
                        ],
                        selected: <UserRole>{_selectedRole},
                        onSelectionChanged: (Set<UserRole> newSelection) {
                          setState(() {
                            _selectedRole = newSelection.first;
                            _emailController.clear();
                            _passwordController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_selectedRole == UserRole.admin) ...[
                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Hospital ID (HopID)',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your HopID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Doctor ID (DocID)',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your DocID';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedRole == UserRole.admin)
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Register new Hospital/Clinic'),
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

