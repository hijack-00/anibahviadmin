import 'package:flutter/material.dart';

class StockManagementPage extends StatelessWidget {
  final List<Map<String, dynamic>> stocks = [
    {'item': 'Lot A123', 'qty': 50, 'range': '28-36', 'store': 'Store 1'},
    {'item': 'Lot B456', 'qty': 20, 'range': '30-38', 'store': 'Store 2'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Stock Management'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.inventory, color: Colors.white)],
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
                  Icon(Icons.inventory, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Stock List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: stocks.isEmpty
                  ? Center(child: Text('No stocks yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: stocks.length,
                      itemBuilder: (context, i) {
                        final s = stocks[i];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.inventory_2, color: Colors.indigo),
                            title: Text(s['item'], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Qty: ${s['qty']}'),
                                Text('Range: ${s['range']}'),
                                Text('Store: ${s['store']}', style: TextStyle(color: Colors.indigo)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
