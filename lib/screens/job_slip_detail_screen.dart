import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class JobSlipDetailScreen extends StatelessWidget {
  final String jobSlipId;
  const JobSlipDetailScreen({Key? key, required this.jobSlipId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final jobSlip = {
      'id': jobSlipId,
      'karigar': 'Karigar 3',
      'status': 'Assigned',
      'startedAt': '2025-09-01',
      'completedAt': '',
      'orderId': '1003',
    };
      return UniversalScaffold(
        selectedIndex: 0,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Slip ID: ${jobSlip['id']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Karigar: ${jobSlip['karigar']}'),
            Text('Status: ${jobSlip['status']}'),
            Text('Started At: ${jobSlip['startedAt']}'),
            Text('Completed At: ${(jobSlip['completedAt'] != null && (jobSlip['completedAt'] as String).isNotEmpty) ? jobSlip['completedAt'] : 'N/A'}'),
            SizedBox(height: 16),
            Text('Order ID: ${jobSlip['orderId']}'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/order_detail', arguments: jobSlip['orderId']);
              },
              child: Text('View Order Details'),
            ),
          ],
        ),
      ),
    );
  }
}
