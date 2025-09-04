import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class OrdersScreen extends StatefulWidget {
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<Map<String, dynamic>> orders = [
    {
      'id': '1001',
      'customer': 'Rajesh',
      'status': 'Confirmed',
      'total': '₹4999',
    },
    {
      'id': '1002',
      'customer': 'Priya',
      'status': 'Pending',
      'total': '₹2999',
    },
  ];

  String searchText = '';
  String selectedStatus = 'All';

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((o) {
      final matchesSearch = o['customer'].toLowerCase().contains(searchText.toLowerCase()) || o['id'].toString().contains(searchText);
      final matchesStatus = selectedStatus == 'All' || o['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ['All', ...{for (var o in orders) o['status']}];
    return UniversalScaffold(
      selectedIndex: 1,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search orders',
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
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final order = filteredOrders[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.shopping_cart, color: Colors.indigo),
                          ),
                          title: Text('Order #${order['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Customer: ${order['customer']}\nStatus: ${order['status']}'),
                          trailing: Text(order['total'], style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            Navigator.pushNamed(context, '/order_detail', arguments: order['id']);
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
                    title: Text('Add Order'),
                    content: Text('Add new order (dummy action).'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              icon: Icon(Icons.add_shopping_cart),
              label: Text('Add Order'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
