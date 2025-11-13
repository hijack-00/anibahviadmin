import 'package:flutter/material.dart';

class UniversalNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  UniversalNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Catalogue'),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Challan'),
    ];

    return BottomNavigationBar(
      items: items,
      currentIndex: (selectedIndex >= 0 && selectedIndex < items.length) ? selectedIndex : 0,
      // Optionally, you can visually indicate "no tab selected" if selectedIndex == -1
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
    );
  }
}
