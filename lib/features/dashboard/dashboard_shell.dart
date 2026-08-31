import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/providers/auth_provider.dart';

class DashboardShell extends ConsumerWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('CareQueue HMS'),
            ),
      drawer: isDesktop ? null : const _DashboardSidebar(),
      body: Row(
        children: [
          if (isDesktop) const _DashboardSidebar(),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        const CircleAvatar(
                          backgroundColor: Color(0xFF1565C0),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSidebar extends ConsumerWidget {
  const _DashboardSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 64,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital, color: Color(0xFF1565C0)),
                const SizedBox(width: 12),
                Text(
                  'CareQueue HMS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isSelected: location == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'Patients',
                  isSelected: location == '/patients',
                  onTap: () => context.go('/patients'),
                ),
                _SidebarItem(
                  icon: Icons.hotel_outlined,
                  title: 'Admissions',
                  isSelected: location == '/admissions',
                  onTap: () => context.go('/admissions'),
                ),
                _SidebarItem(
                  icon: Icons.medical_services_outlined,
                  title: 'Doctors',
                  isSelected: location == '/doctors',
                  onTap: () => context.go('/doctors'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Appointments',
                  isSelected: location == '/appointments',
                  onTap: () => context.go('/appointments'),
                ),
                _SidebarItem(
                  icon: Icons.folder_shared_outlined,
                  title: 'Patient Records',
                  isSelected: location == '/patient-records',
                  onTap: () => context.go('/patient-records'),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  isSelected: location == '/settings',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hoverColor: Colors.red.withAlpha(25),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF1565C0).withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }
}
