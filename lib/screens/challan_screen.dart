import 'universal_navbar.dart';
import 'package:flutter/material.dart';
import '../widgets/searchable_dropdown.dart';

class ChallanScreen extends StatefulWidget {
  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  Future<void> _showCreateChallanDialog() async {
    String? selectedCustomer;
    String? selectedOrder;
    String? selectedVendor;
    String notes = '';
    List<String> customers = ['Client X', 'Client Y', 'Client Z'];
    List<String> orders = ['Order 101', 'Order 102', 'Order 103'];
    List<String> vendors = ['DP Express', 'DP Fast', 'DP Quick'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Create Challan', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdown(
                  label: 'Select Customer',
                  items: customers,
                  value: selectedCustomer,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedCustomer = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Select Order',
                  items: orders,
                  value: selectedOrder,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedOrder = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Delivery Vendor',
                  items: vendors,
                  value: selectedVendor,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedVendor = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                Text('Notes (optional)', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                TextField(
                  decoration: InputDecoration(hintText: 'Add notes'),
                  onChanged: (val) {
                    notes = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement create challan logic
                Navigator.of(context).pop();
              },
              child: Text('Create Challan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateReturnDialog() async {
    String? selectedCustomer;
    String? selectedOrder;
    String? selectedRefund;
    List<String> customers = ['Client X', 'Client Y', 'Client Z'];
    List<String> orders = ['Order 101', 'Order 102', 'Order 103'];
    List<String> refundMethods = ['Bank Transfer', 'UPI', 'Cash'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Create Return', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdown(
                  label: 'Select Customer',
                  items: customers,
                  value: selectedCustomer,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedCustomer = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Select Order',
                  items: orders,
                  value: selectedOrder,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedOrder = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Refund Method',
                  items: refundMethods,
                  value: selectedRefund,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedRefund = val;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement create return logic
                Navigator.of(context).pop();
              },
              child: Text('Create Return'),
            ),
          ],
        );
      },
    );
  }
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
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.indigo,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showCreateChallanDialog,
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.undo),
                  label: Text('Create Return'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showCreateReturnDialog,
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
                    label: Text(status, style: TextStyle(fontWeight: FontWeight.w500)),
                    selected: selectedStatus == status,
                    selectedColor: Colors.indigo.shade50,
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => selectedStatus = status),
                  ),
                )).toList(),
              ),
            ),
            SizedBox(height: 12),
            // Sort by Date
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (fromDate == null)
                    Text('From:', style: TextStyle(fontWeight: FontWeight.w500)),
                  if (fromDate == null)
                    SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _pickFromDate,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(fromDate == null ? 'Select' : '${fromDate!.toLocal()}'.split(' ')[0]),
                  ),
                  SizedBox(width: 16),
                    Text(':', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(width: 16),

                  if (toDate == null)
                    Text('To:', style: TextStyle(fontWeight: FontWeight.w500)),
                  
                  if (toDate == null)
                    SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _pickToDate,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(toDate == null ? 'Select' : '${toDate!.toLocal()}'.split(' ')[0]),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.clear, size: 20, color: Colors.red),
                    tooltip: 'Clear date range',
                    onPressed: () {
                      setState(() {
                        fromDate = null;
                        toDate = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Challan Data Table
            Expanded(
              child: ListView.separated(
                itemCount: filteredChallans.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = filteredChallans[i];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Challan #${c['number']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Date: ${c['date'].toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                Text('Shop: ${c['shop']}', style: TextStyle(fontSize: 13)),
                                Text('Client: ${c['client']}', style: TextStyle(fontSize: 13)),
                                Row(
                                  children: [
                                    Text('Amount: ', style: TextStyle(fontSize: 13)),
                                    Text('₹${c['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
                                    SizedBox(width: 8),
                                    Text('Pieces: ${c['pieces']}', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                                Text('Items: ${c['items']}', style: TextStyle(fontSize: 13)),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: c['status'] == 'Pending' ? Colors.yellow.shade100 :
                                               c['status'] == 'Approved' ? Colors.green.shade100 :
                                               c['status'] == 'Rejected' ? Colors.red.shade100 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(c['status'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Delivery: ${c['deliveryPartner']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.indigo),
                            onPressed: () => _editChallan(c),
                          ),
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
      bottomNavigationBar: UniversalNavBar(
        selectedIndex: 4,
        onTap: (index) {
          if (index == 4) return; // Already on Challan
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
            case 3:
              Navigator.pushReplacementNamed(context, '/reports');
              break;
          }
        },
      ),
    );
  }
}