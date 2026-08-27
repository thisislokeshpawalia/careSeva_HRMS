import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/providers/auth_provider.dart';

class DoctorDashboardShell extends ConsumerWidget {
  final Widget child;

  const DoctorDashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('CareQueue HMS - Doctor'),
            ),
      drawer: isDesktop ? null : const _DoctorSidebar(),
      body: Row(
        children: [
          if (isDesktop) const _DoctorSidebar(),
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

class _DoctorSidebar extends ConsumerWidget {
  const _DoctorSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const Icon(Icons.medical_services, color: Color(0xFF1565C0)),
                const SizedBox(width: 12),
                Text(
                  'Doctor Portal',
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
                  title: 'Overview',
                  isSelected: GoRouterState.of(context).uri.path == '/doctor-dashboard',
                  onTap: () => context.go('/doctor-dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'My Patients',
                  isSelected: GoRouterState.of(context).uri.path == '/doctor-dashboard/patients',
                  onTap: () => context.go('/doctor-dashboard/patients'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'My Schedule',
                  isSelected: GoRouterState.of(context).uri.path == '/doctor-dashboard/schedule',
                  onTap: () => context.go('/doctor-dashboard/schedule'),
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
