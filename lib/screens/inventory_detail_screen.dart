import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class InventoryDetailScreen extends StatelessWidget {
  final String locationId;
  const InventoryDetailScreen({Key? key, required this.locationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final location = {
      'id': locationId,
      'name': locationId == 'A' ? 'Warehouse A' : 'Warehouse B',
      'stock': locationId == 'A' ? 120 : 80,
      'products': [
        {'name': 'Kurta', 'qty': 40},
        {'name': 'Jeans', 'qty': 30},
      ],
    };
      return UniversalScaffold(
        selectedIndex: 0,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location ID: ${location['id']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Name: ${location['name']}'),
            Text('Total Stock: ${location['stock']}'),
            SizedBox(height: 16),
            Text('Products:', style: Theme.of(context).textTheme.titleMedium),
            ...List.generate((location['products'] as List).length, (i) {
              final product = (location['products'] as List)[i];
              return ListTile(
                title: Text(product['name'].toString()),
                subtitle: Text('Qty: ${product['qty']}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
