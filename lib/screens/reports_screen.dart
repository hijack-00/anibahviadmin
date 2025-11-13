import 'package:anibhaviadmin/widgets/universal_scaffold.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class ReportsScreen extends StatefulWidget {
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Map<String, dynamic>> reports = [
    {'type': 'Sales', 'desc': 'Sales Report'},
    {'type': 'Inventory', 'desc': 'Inventory Valuation'},
  ];

  String searchText = '';
  String selectedType = 'All';

  List<Map<String, dynamic>> get filteredReports {
    return reports.where((r) {
      final matchesSearch =
          r['desc'].toLowerCase().contains(searchText.toLowerCase()) ||
          r['type'].toString().contains(searchText);
      final matchesType = selectedType == 'All' || r['type'] == selectedType;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      'All',
      ...{for (var r in reports) r['type']},
    ];
    return UniversalScaffold(
      title: 'Reports',
      appIcon: Icons.bar_chart,
      selectedIndex: 0,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search reports',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: types
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: selectedType == type,
                              onSelected: (_) =>
                                  setState(() => selectedType = type),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredReports.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final report = filteredReports[i];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(Icons.bar_chart, color: Colors.indigo),
                          ),
                          title: Text(
                            report['desc'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Download as Excel/PDF'),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/report_detail',
                              arguments: report['type'],
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
                    title: Text('Download Report'),
                    content: Text('Download Excel/PDF (dummy action).'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.download),
              label: Text('Download'),
              backgroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
