import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/hospital/hospital_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/doctors/doctors_screen.dart';
import '../../features/patients/patients_screen.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool isAuthenticated = authState;
      final bool isLoginRoute = state.uri.path == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        return '/dashboard';
      }
      return null;
    },
  );
});

class AppRouter {
  static final GoRouter router = GoRouter(initialLocation: '/login', routes: []); // Legacy, to be removed
}
