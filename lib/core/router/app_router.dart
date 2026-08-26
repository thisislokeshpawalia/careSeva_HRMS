import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_hospital_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/hospital/hospital_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/doctors/doctors_screen.dart';
import '../../features/patients/patients_screen.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/doctor_dashboard/doctor_dashboard_shell.dart';
import '../../features/doctor_dashboard/doctor_dashboard_screen.dart';
import '../../features/doctor_dashboard/doctor_patients_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterHospitalScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/patients',
            builder: (context, state) => const PatientsScreen(),
          ),
          GoRoute(
            path: '/doctors',
            builder: (context, state) => const DoctorsScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const HospitalSettingsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => DoctorDashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/doctor-dashboard',
            builder: (context, state) => const DoctorDashboardScreen(),
          ),
          GoRoute(
            path: '/doctor-dashboard/patients',
            builder: (context, state) => const DoctorPatientsHistoryScreen(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthenticated = authState.isAuthenticated;
      final UserRole role = authState.role;
      final bool isLoginRoute = state.uri.path == '/login';
      final bool isRegisterRoute = state.uri.path == '/register';

      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        if (role == UserRole.admin) return '/dashboard';
        if (role == UserRole.doctor) return '/doctor-dashboard';
      }
      
      // Prevent role mixing
      if (isAuthenticated) {
        final path = state.uri.path;
        if (role == UserRole.admin && path.startsWith('/doctor-dashboard')) {
          return '/dashboard';
        }
        if (role == UserRole.doctor && !path.startsWith('/doctor-dashboard')) {
          return '/doctor-dashboard';
        }
      }
      return null;
    },
  );
});

class AppRouter {
  static final GoRouter router = GoRouter(initialLocation: '/login', routes: []); // Legacy, to be removed
}
