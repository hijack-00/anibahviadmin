import 'package:anibhaviadmin/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class DispatchScreen extends StatefulWidget {
  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final List<Map<String, dynamic>> dispatches = [
    {
      'id': 'DC201',
      'status': 'Shipped',
    },
    {
      'id': 'DC202',
      'status': 'Pending',
    },
  ];

  String searchText = '';
  String selectedStatus = 'All';

  List<Map<String, dynamic>> get filteredDispatches {
    return dispatches.where((d) {
      final matchesSearch = d['id'].toString().contains(searchText);
      final matchesStatus = selectedStatus == 'All' || d['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ['All', ...{for (var d in dispatches) d['status']}];
    return UniversalScaffold(
      selectedIndex: 0,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search dispatch',
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
                    itemCount: filteredDispatches.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final dispatch = filteredDispatches[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.local_shipping, color: Colors.indigo),
                          ),
                          title: Text('Challan #${dispatch['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Status: ${dispatch['status']} | QR'),
                          onTap: () {
                            Navigator.pushNamed(context, '/dispatch_detail', arguments: dispatch['id']);
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
                    title: Text('Create Dispatch'),
                    content: Text('Create new dispatch (dummy action).'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              icon: Icon(Icons.local_shipping),
              label: Text('Dispatch'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
