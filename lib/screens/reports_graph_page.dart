import 'package:flutter/material.dart';

class ReportsGraphPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Reports & Graphs'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.bar_chart, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Graph View (Dummy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.indigo.shade100, blurRadius: 6)],
              ),
              child: Center(child: Text('Graph Placeholder', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Franchisee-wise Sales Return Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: 'Franchisee A',
              items: ['Franchisee A', 'Franchisee B', 'Franchisee C'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (_) {},
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: ListTile(
                leading: Icon(Icons.store, color: Colors.indigo),
                title: Text('Franchisee A', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Sales: ₹1,00,000 | Returns: ₹5,000 | Net: ₹95,000', style: TextStyle(color: Colors.indigo)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
