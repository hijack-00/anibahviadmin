import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class CatalogueDetailScreen extends StatelessWidget {
  final String designId;
  const CatalogueDetailScreen({Key? key, required this.designId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for demonstration
    final design = {
      'id': designId,
      'name': 'Saree Design 1',
      'category': 'Saree',
      'tags': ['Indigo', 'Cotton'],
      'price': '₹1499',
      'images': [],
      'description': 'Beautiful indigo saree design.',
    };
      return UniversalScaffold(
        selectedIndex: 2,
        body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design ID: ${design['id']}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('Name: ${design['name']}'),
            Text('Category: ${design['category']}'),
            Text('Tags: ${(design['tags'] as List?)?.join(', ') ?? ''}'),
            Text('Price: ${design['price']}'),
            SizedBox(height: 16),
            Text('Description: ${design['description']}'),
            // Images and actions can be added here
          ],
        ),
      ),
    );
  }
}
