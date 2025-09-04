import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final order = {
      'id': orderId,
      'customer': 'Priya',
      'status': 'Confirmed',
      'total': '₹2999',
      'items': [
        {'name': 'Kurta', 'qty': 2, 'price': 799},
        {'name': 'Jeans', 'qty': 1, 'price': 999},
      ],
    };
      return UniversalScaffold(
        selectedIndex: 1,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order['id']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Customer: ${order['customer']}'),
            Text('Status: ${order['status']}'),
            Text('Total: ${order['total']}'),
            SizedBox(height: 16),
            Text('Items:', style: Theme.of(context).textTheme.titleMedium),
            ...List.generate((order['items'] as List).length, (i) {
              final item = (order['items'] as List)[i];
              return ListTile(
                title: Text(item['name'].toString()),
                subtitle: Text('Qty: ${item['qty']}'),
                trailing: Text('₹${item['price']}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
