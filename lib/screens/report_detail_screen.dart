import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportType;
  const ReportDetailScreen({Key? key, required this.reportType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final report = {
      'type': reportType,
      'summary': 'This is a summary for $reportType report.',
      'downloadable': true,
    };
      return UniversalScaffold(
        selectedIndex: 0,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Type: ${report['type']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Summary: ${report['summary']}'),
            SizedBox(height: 16),
            if (report['downloadable'] == true)
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Download'),
                      content: Text('Download Excel/PDF (dummy).'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                    ),
                  );
                },
                child: Text('Download Excel/PDF'),
              ),
          ],
        ),
      ),
    );
  }
}
