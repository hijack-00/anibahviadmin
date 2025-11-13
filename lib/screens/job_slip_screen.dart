import 'package:anibhaviadmin/widgets/universal_scaffold.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class JobSlipScreen extends StatefulWidget {
  @override
  State<JobSlipScreen> createState() => _JobSlipScreenState();
}

class _JobSlipScreenState extends State<JobSlipScreen> {
  final List<Map<String, dynamic>> jobSlips = [
    {'id': 'JS101', 'karigar': 'Karigar 1', 'status': 'In Progress'},
    {'id': 'JS102', 'karigar': 'Karigar 2', 'status': 'Completed'},
  ];

  String searchText = '';
  String selectedStatus = 'All';

  List<Map<String, dynamic>> get filteredJobSlips {
    return jobSlips.where((s) {
      final matchesSearch =
          s['karigar'].toLowerCase().contains(searchText.toLowerCase()) ||
          s['id'].toString().contains(searchText);
      final matchesStatus =
          selectedStatus == 'All' || s['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'All',
      ...{for (var s in jobSlips) s['status']},
    ];
    return UniversalScaffold(
      title: 'Job Slips',
      appIcon: Icons.assignment,
      selectedIndex: 0,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search job slips',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: statuses
                        .map(
                          (status) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: selectedStatus == status,
                              onSelected: (_) =>
                                  setState(() => selectedStatus = status),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredJobSlips.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final slip = filteredJobSlips[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.assignment, color: Colors.indigo),
                          ),
                          title: Text(
                            'Job Slip #${slip['id']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Assigned to: ${slip['karigar']}\nStatus: ${slip['status']}',
                          ),
                          trailing: Icon(Icons.qr_code),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/job_slip_detail',
                              arguments: slip['id'],
                            );
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
                    title: Text('Add Job Slip'),
                    content: Text('Create new job slip (dummy action).'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.assignment_add),
              label: Text('Add Job Slip'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
