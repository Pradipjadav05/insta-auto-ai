import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import 'glass_card.dart';

// Navigation State Provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class SidebarLayout extends ConsumerWidget {
  final List<Widget> screens;
  final VoidCallback onLogout;

  const SidebarLayout({
    super.key,
    required this.screens,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final navItems = [
      _NavigationItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
      _NavigationItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'Content Gen'),
      _NavigationItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendar'),
      _NavigationItem(icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Scheduler'),
      _NavigationItem(icon: Icons.link_outlined, activeIcon: Icons.link, label: 'Instagram'),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Premium Glassmorphic Sidebar
            _buildSidebar(context, ref, currentIndex, navItems),
            // Screen Content
            Expanded(
              child: Container(
                color: AppTheme.bgDark,
                child: screens[currentIndex],
              ),
            ),
          ],
        ),
      );
    }

    // Tablet/Mobile layout: Top App Bar with Drawer + Bottom Nav
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'InstaAuto AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = AppTheme.purpleCyanGradient.createShader(
                const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
              ),
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      drawer: _buildDrawer(context, ref, currentIndex, navItems),
      body: Container(
        color: AppTheme.bgDark,
        child: screens[currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.panelBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => ref.read(navigationIndexProvider.notifier).state = index,
          backgroundColor: const Color(0xFF0F0F16),
          selectedItemColor: AppTheme.neonCyan,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: navItems
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.activeIcon),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    List<_NavigationItem> items,
  ) {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F16),
        border: Border(
          right: BorderSide(color: AppTheme.panelBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleCyanGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'InstaAuto AI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = AppTheme.purpleCyanGradient.createShader(
                      const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                    ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Nav Links
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == currentIndex;
                return _SidebarButton(
                  icon: isSelected ? item.activeIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => ref.read(navigationIndexProvider.notifier).state = index,
                );
              },
            ),
          ),

          // User Profile Status & Logout
          const Divider(height: 30),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.neonPurple.withOpacity(0.2),
                child: const Icon(Icons.person, color: AppTheme.neonPurple),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Console',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: AppTheme.neonGreen),
                        SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: AppTheme.neonPink),
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    List<_NavigationItem> items,
  ) {
    return Drawer(
      backgroundColor: const Color(0xFF0F0F16),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleCyanGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'InstaAuto AI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return ListTile(
                    leading: Icon(isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? AppTheme.neonCyan : AppTheme.textSecondary),
                    title: Text(
                      item.label,
                      style: TextStyle(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: isSelected,
                    onTap: () {
                      ref.read(navigationIndexProvider.notifier).state = index;
                      Navigator.pop(context); // close drawer
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.neonPink),
              title: const Text('Logout', style: TextStyle(color: AppTheme.neonPink)),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _SidebarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.isSelected
                ? AppTheme.purpleCyanGradient
                : _isHovered
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ],
                      )
                    : null,
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : _isHovered
                      ? AppTheme.panelBorder
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected ? Colors.black : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected ? Colors.black : AppTheme.textPrimary,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
