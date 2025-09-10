import 'universal_navbar.dart';
import 'package:flutter/material.dart';

class ChallanScreen extends StatefulWidget {
  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  String searchText = '';
  String selectedStatus = 'All';
  DateTime? fromDate;
  DateTime? toDate;

  List<Map<String, dynamic>> challans = [
    {
      'number': 'CH1001',
      'date': DateTime(2025, 9, 1),
      'shop': 'Shop A',
      'client': 'Client X',
      'amount': 12000,
      'pieces': 50,
      'items': 'Shirts, Trousers',
      'status': 'Pending',
      'deliveryPartner': 'DP Express',
    },
    {
      'number': 'CH1002',
      'date': DateTime(2025, 9, 2),
      'shop': 'Shop B',
      'client': 'Client Y',
      'amount': 8000,
      'pieces': 30,
      'items': 'Jeans',
      'status': 'Approved',
      'deliveryPartner': 'DP Fast',
    },
    // ...more dummy data
  ];

  List<String> statuses = [
    'All', 'Pending', 'Approved', 'Completed', 'Dispatched', 'Rejected'
  ];

  List<Map<String, dynamic>> get filteredChallans {
    return challans.where((c) {
      final matchesSearch = c['number'].toLowerCase().contains(searchText.toLowerCase()) ||
        c['shop'].toLowerCase().contains(searchText.toLowerCase()) ||
        c['client'].toLowerCase().contains(searchText.toLowerCase());
      final matchesStatus = selectedStatus == 'All' || c['status'] == selectedStatus;
      final matchesFrom = fromDate == null || c['date'].isAfter(fromDate!.subtract(Duration(days: 1)));
      final matchesTo = toDate == null || c['date'].isBefore(toDate!.add(Duration(days: 1)));
      return matchesSearch && matchesStatus && matchesFrom && matchesTo;
    }).toList();
  }

  void _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  void _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  void _createChallan() {
    // TODO: Implement create challan logic
  }

  void _createReturn() {
    // TODO: Implement create return logic
  }

  void _editChallan(Map<String, dynamic> challan) {
    // TODO: Implement edit challan logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Challan & Return'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Challan',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchText = val),
            ),
            SizedBox(height: 12),
            // Create Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Create Challan'),
                  onPressed: _createChallan,
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.undo),
                  label: Text('Create Return'),
                  onPressed: _createReturn,
                ),
              ],
            ),
            SizedBox(height: 12),
            // Filter Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: selectedStatus == status,
                    onSelected: (_) => setState(() => selectedStatus = status),
                  ),
                )).toList(),
              ),
            ),
            SizedBox(height: 12),
            // Sort by Date
            Row(
              children: [
                Text('From:'),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickFromDate,
                  child: Text(fromDate == null ? 'Select' : '${fromDate!.toLocal()}'.split(' ')[0]),
                ),
                SizedBox(width: 16),
                Text('To:'),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickToDate,
                  child: Text(toDate == null ? 'Select' : '${toDate!.toLocal()}'.split(' ')[0]),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Challan Data Table
            Expanded(
              child: ListView.separated(
                itemCount: filteredChallans.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = filteredChallans[i];
                  return Card(
                    child: ListTile(
                      title: Text('Challan #${c['number']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${c['date'].toLocal().toString().split(' ')[0]}'),
                          Text('Shop: ${c['shop']}'),
                          Text('Client: ${c['client']}'),
                          Text('Amount: ₹${c['amount']}'),
                          Text('Pieces: ${c['pieces']}'),
                          Text('Items: ${c['items']}'),
                          Text('Status: ${c['status']}'),
                          Text('Delivery Partner: ${c['deliveryPartner']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.indigo),
                        onPressed: () => _editChallan(c),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: UniversalNavBar(
        selectedIndex: 3,
        onTap: (index) {
          if (index == 3) return; // Already on Challan
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/orders');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/users');
              break;
          }
        },
      ),
    );
  }
}
