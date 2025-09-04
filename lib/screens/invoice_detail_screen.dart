import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailScreen({Key? key, required this.invoiceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final invoice = {
      'id': invoiceId,
      'orderId': '1003',
      'status': 'Paid',
      'total': '₹2999',
      'gstAmount': '₹299',
      'pdfUrl': '',
    };
      return UniversalScaffold(
        selectedIndex: 3,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice ID: ${invoice['id']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Order ID: ${invoice['orderId']}'),
            Text('Status: ${invoice['status']}'),
            Text('Total: ${invoice['total']}'),
            Text('GST Amount: ${invoice['gstAmount']}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Dummy PDF view
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('PDF Export'),
                    content: Text('PDF export/download (dummy).'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              child: Text('View/Download PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
