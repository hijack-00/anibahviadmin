import 'package:anibhaviadmin/screens/login_screen.dart';
import 'package:anibhaviadmin/widgets/universal_navbar.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';
import 'package:anibhaviadmin/widgets/universal_drawer.dart';
import 'package:flutter/material.dart';

class UniversalScaffold extends StatefulWidget {
  final int selectedIndex;
  final Widget body;
  final String title; // Add title parameter
  final IconData appIcon; // Add app icon parameter
  final bool showLogoutButton; // Add parameter to show/hide logout button
  final FloatingActionButton?
  floatingActionButton; // Add optional FAB parameter
  final Future<void> Function()? onRefresh; // Add onRefresh callback

  UniversalScaffold({
    required this.selectedIndex,
    required this.body,
    required this.title,
    required this.appIcon,
    this.showLogoutButton = false, // Default to false
    this.floatingActionButton, // Optional FAB
    this.onRefresh, // Optional onRefresh callback
  });

  @override
  State<UniversalScaffold> createState() => _UniversalScaffoldState();
}

class _UniversalScaffoldState extends State<UniversalScaffold> {
  void _onItemTapped(int index) {
    String? route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/orders';
        break;
      case 2:
        route = '/users';
        break;
      case 3:
        route = '/catalogue';
        break;
      case 4:
        route = '/challan';
        break;
    }
    if (route != null && ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (r) => r.settings.name == '/dashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade500, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Drawer button wrapped in Builder
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openDrawer(); // Open the drawer
                        },
                      );
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        widget.title, // Use the title parameter
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (widget
                      .showLogoutButton) // Conditionally show logout button
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () async {
                        final repo = AppDataRepo();
                        await repo.clearUserData();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: const UniversalDrawer(),
      body: RefreshIndicator(
        onRefresh:
            widget.onRefresh ?? () async {}, // Use the onRefresh callback
        child: widget.body,
      ),
      floatingActionButton: widget.floatingActionButton, // Use the optional FAB
      bottomNavigationBar: UniversalNavBar(
        selectedIndex: widget.selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
