import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class DispatchDetailScreen extends StatelessWidget {
  final String dispatchId;
  const DispatchDetailScreen({Key? key, required this.dispatchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final dispatch = {
      'id': dispatchId,
      'orderId': '1003',
      'status': 'Shipped',
      'challanNo': 'DC203',
      'qrCodeUrl': '',
      'date': '2025-09-01',
    };
      return UniversalScaffold(
        selectedIndex: 0,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dispatch ID: ${dispatch['id']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Order ID: ${dispatch['orderId']}'),
            Text('Status: ${dispatch['status']}'),
            Text('Challan No: ${dispatch['challanNo']}'),
            Text('Date: ${dispatch['date']}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/order_detail', arguments: dispatch['orderId']);
              },
              child: Text('View Order Details'),
            ),
            // QR code and other actions can be added here
          ],
        ),
      ),
    );
  }
}
