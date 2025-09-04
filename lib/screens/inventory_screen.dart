import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Map<String, dynamic>> locations = [
    {
      'id': 'A',
      'name': 'Warehouse A',
      'stock': 120,
    },
    {
      'id': 'B',
      'name': 'Warehouse B',
      'stock': 80,
    },
  ];

  String searchText = '';

  List<Map<String, dynamic>> get filteredLocations {
    return locations.where((l) {
      return l['name'].toLowerCase().contains(searchText.toLowerCase()) || l['id'].toString().contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalScaffold(
      selectedIndex: 0,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search location',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredLocations.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final location = filteredLocations[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.store, color: Colors.indigo),
                          ),
                          title: Text(location['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Stock: ${location['stock']} items'),
                          onTap: () {
                            Navigator.pushNamed(context, '/inventory_detail', arguments: location['id']);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Stock Action'),
                    content: Text('Add/Edit stock (dummy action).'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text('Stock'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
}
}