import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          _buildMenuItems(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.store,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            'Supplier Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildMenuItem(
            context: context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/',
            isSelected: currentRoute == '/',
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.inventory,
            title: 'Products',
            route: '/products',
            isSelected: currentRoute.startsWith('/products'),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.people,
            title: 'Clients',
            route: '/clients',
            isSelected: currentRoute.startsWith('/clients'),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.shopping_cart,
            title: 'Orders',
            route: '/orders',
            isSelected: currentRoute.startsWith('/orders'),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.receipt,
            title: 'Invoices',
            route: '/invoices',
            isSelected: currentRoute.startsWith('/invoices'),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.bar_chart,
            title: 'Reports',
            route: '/reports',
            isSelected: currentRoute.startsWith('/reports'),
          ),
          const Divider(),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        // Close drawer
        Navigator.pop(context);
        
        // Navigate only if not already on the route
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Management App',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} All Rights Reserved',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
