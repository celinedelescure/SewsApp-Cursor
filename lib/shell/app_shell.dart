import 'package:flutter/material.dart';

import '../core/roles/user_role.dart';
import '../features/auth/data/user_profile.dart';
import '../features/fabric_merchant/presentation/fabric_merchant_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/patterns/presentation/patterns_marketplace_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/stock_screen.dart';

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Shell navigable selon le rôle (placeholders métier + auth réelle).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    this.profile,
    this.profileNotice,
    this.onLogout,
  });

  final UserRole role;
  final UserProfile? profile;
  final String? profileNotice;
  final Future<void> Function()? onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<_ShellDestination> get _destinations {
    final role = widget.role;
    switch (role) {
      case UserRole.couturiere:
        return [
          _ShellDestination(
            label: 'Feed',
            icon: Icons.dynamic_feed_outlined,
            selectedIcon: Icons.dynamic_feed,
            builder: (_) => FeedScreen(role: role),
          ),
          _ShellDestination(
            label: 'Patrons',
            icon: Icons.picture_as_pdf_outlined,
            selectedIcon: Icons.picture_as_pdf,
            builder: (_) => PatternsMarketplaceScreen(role: role),
          ),
          _ShellDestination(
            label: 'Tissus',
            icon: Icons.texture_outlined,
            selectedIcon: Icons.texture,
            builder: (_) => FabricMerchantScreen(role: role),
          ),
          _ShellDestination(
            label: 'Stock',
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            builder: (_) => const StockScreen(),
          ),
          _ShellDestination(
            label: 'Profil',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            builder: (_) => ProfileScreen(
              role: role,
              profile: widget.profile,
              profileNotice: widget.profileNotice,
              onLogout: widget.onLogout,
            ),
          ),
        ];
      case UserRole.designer:
        return [
          _ShellDestination(
            label: 'Feed',
            icon: Icons.dynamic_feed_outlined,
            selectedIcon: Icons.dynamic_feed,
            builder: (_) => FeedScreen(role: role),
          ),
          _ShellDestination(
            label: 'Mes patrons',
            icon: Icons.design_services_outlined,
            selectedIcon: Icons.design_services,
            builder: (_) => PatternsMarketplaceScreen(role: role),
          ),
          _ShellDestination(
            label: 'Profil',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            builder: (_) => ProfileScreen(
              role: role,
              profile: widget.profile,
              profileNotice: widget.profileNotice,
              onLogout: widget.onLogout,
            ),
          ),
        ];
      case UserRole.marchandTissus:
        return [
          _ShellDestination(
            label: 'Catalogue',
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            builder: (_) => FabricMerchantScreen(role: role),
          ),
          _ShellDestination(
            label: 'Feed',
            icon: Icons.dynamic_feed_outlined,
            selectedIcon: Icons.dynamic_feed,
            builder: (_) => FeedScreen(role: role),
          ),
          _ShellDestination(
            label: 'Profil',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            builder: (_) => ProfileScreen(
              role: role,
              profile: widget.profile,
              profileNotice: widget.profileNotice,
              onLogout: widget.onLogout,
            ),
          ),
        ];
    }
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final safeIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: [
          for (final d in destinations) d.builder(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
