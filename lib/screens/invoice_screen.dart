import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class InvoiceScreen extends StatefulWidget {
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final List<Map<String, dynamic>> invoices = [
    {
      'id': 'INV301',
      'orderId': '1001',
      'status': 'Paid',
    },
    {
      'id': 'INV302',
      'orderId': '1002',
      'status': 'Pending',
    },
  ];

  String searchText = '';
  String selectedStatus = 'All';

  List<Map<String, dynamic>> get filteredInvoices {
    return invoices.where((inv) {
      final matchesSearch = inv['orderId'].toString().contains(searchText) || inv['id'].toString().contains(searchText);
      final matchesStatus = selectedStatus == 'All' || inv['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ['All', ...{for (var inv in invoices) inv['status']}];
    return UniversalScaffold(
      selectedIndex: 3,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search invoice',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
                SizedBox(height: 12),
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
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredInvoices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final invoice = filteredInvoices[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.receipt_long, color: Colors.indigo),
                          ),
                          title: Text('Invoice #${invoice['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Order: #${invoice['orderId']} | Status: ${invoice['status']}'),
                          trailing: Icon(Icons.picture_as_pdf),
                          onTap: () {
                            Navigator.pushNamed(context, '/invoice_detail', arguments: invoice['id']);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Create Invoice'),
                    content: Text('Create new invoice (dummy action).'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              icon: Icon(Icons.receipt_long),
              label: Text('Invoice'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
