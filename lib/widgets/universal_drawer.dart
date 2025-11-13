import 'package:flutter/material.dart';
import 'package:anibhaviadmin/screens/login_screen.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UniversalDrawer extends StatelessWidget {
  const UniversalDrawer({super.key});

  void _navigate(BuildContext context, String routeName) {
    Navigator.of(context).pop(); // close drawer first
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) return;

    // Keep dashboard as the "root" when navigating to it
    if (routeName == '/dashboard') {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (r) => false);
      return;
    }

    // For other pages, push normally
    Navigator.of(context).pushNamed(routeName);
  }

  /// Confirm logout, clear saved preferences and in-memory caches, then go to login.
  Future<void> _confirmLogout(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (res == true) {
      // Clear all saved preferences (user, token, role id, etc.)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}

      // Clear in-memory caches
      try {
        AppDataRepo.roles = [];
      } catch (_) {}

      // Replace navigation stack with login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (r) => false,
      );
    }
  }

  Widget _tile(BuildContext c, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      onTap: () => _navigate(c, route),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              // decoration: BoxDecoration(color: Colors.indigo.shade600),
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  // CircleAvatar(
                  //   radius: 28,
                  //   backgroundColor: Colors.white24,
                  //   child: Icon(
                  //     Icons.storefront_outlined,
                  //     color: Colors.white,
                  //     size: 32,
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Image.asset("assets/logowithText.png"),
                    // child: Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text('Anibhavi ERP', style: headerStyle),
                    //     const SizedBox(height: 6),
                    //     Text(
                    //       'Admin',
                    //       style: theme.textTheme.bodySmall?.copyWith(
                    //         color: Colors.white70,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _tile(
                    context,
                    Icons.dashboard_outlined,
                    'Dashboard',
                    '/dashboard',
                  ),
                  _tile(context, Icons.list_alt_outlined, 'Orders', '/orders'),
                  _tile(
                    context,
                    Icons.local_shipping_outlined,
                    'Challan',
                    '/challan',
                  ),
                  _tile(
                    context,
                    Icons.receipt_long_outlined,
                    'Sales Reports',
                    '/reports',
                  ),
                  _tile(
                    context,
                    Icons.inventory_2_outlined,
                    'Catalogue',
                    '/catalogue',
                  ),
                  _tile(context, Icons.people_outline, 'Users', '/users'),
                  _tile(
                    context,
                    Icons.delete_outline,
                    'Recycle Bin',
                    '/recycleBin',
                  ),
                  _tile(
                    context,
                    Icons.admin_panel_settings_outlined,
                    'Admin & Staffs',
                    '/admin-users',
                  ),
                  // _tile(
                  //   context,
                  //   Icons.swap_horiz_outlined,
                  //   'Sales Return',
                  //   '/sales-return',
                  // ),
                  // _tile(
                  //   context,
                  //   Icons.settings_suggest_outlined,
                  //   'Stock Adjustment',
                  //   '/stock-adjustment',
                  // ),
                  // _tile(
                  //   context,
                  //   Icons.notifications_outlined,
                  //   'Notifications',
                  //   '/notifications',
                  // ),
                  // _tile(
                  //   context,
                  //   Icons.upload_file_outlined,
                  //   'Catalogue Upload',
                  //   '/catalogue-upload',
                  // ),
                ],
              ),
            ),

            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.indigo),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.of(context).pop();
                showAboutDialog(
                  context: context,
                  applicationName: 'Anibhavi ERP',
                  applicationVersion: '1.0.0',
                  children: [
                    const Text('Contact support at support@anibhavi.com'),
                  ],
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
