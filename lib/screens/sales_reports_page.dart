import 'package:flutter/material.dart';

class SalesReportsPage extends StatefulWidget {
  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  String _selectedFilter = 'Monthly';
  String _selectedSection = 'Overview';

  final List<String> filters = ['Weekly', 'Monthly', 'Yearly'];
  final List<String> sections = ['Overview', 'Jeans', 'Shirts'];

  // Dummy data for demonstration
  final Map<String, Map<String, dynamic>> dummyData = {
    'Overview': {
      'totalSales': 1200,
      'totalRevenue': 450000,
      'totalPieces': 1800,
      'products': [
        {
          'name': 'Jeans Classic',
          'revenue': 120000,
          'pieces': 400,
          'growth': 12.5,
          'unit': 'pcs',
        },
        {
          'name': 'Shirt Slim',
          'revenue': 95000,
          'pieces': 300,
          'growth': 10.2,
          'unit': 'pcs',
        },
        {
          'name': 'Jeans Stretch',
          'revenue': 80000,
          'pieces': 250,
          'growth': 8.7,
          'unit': 'pcs',
        },
        {
          'name': 'Shirt Classic',
          'revenue': 75000,
          'pieces': 200,
          'growth': 7.1,
          'unit': 'pcs',
        },
      ],
    },
    'Jeans': {
      'totalSales': 650,
      'totalRevenue': 200000,
      'totalPieces': 650,
      'products': [
        {
          'name': 'Jeans Classic',
          'revenue': 120000,
          'pieces': 400,
          'growth': 12.5,
          'unit': 'pcs',
        },
        {
          'name': 'Jeans Stretch',
          'revenue': 80000,
          'pieces': 250,
          'growth': 8.7,
          'unit': 'pcs',
        },
      ],
    },
    'Shirts': {
      'totalSales': 550,
      'totalRevenue': 250000,
      'totalPieces': 1150,
      'products': [
        {
          'name': 'Shirt Slim',
          'revenue': 95000,
          'pieces': 300,
          'growth': 10.2,
          'unit': 'pcs',
        },
        {
          'name': 'Shirt Classic',
          'revenue': 75000,
          'pieces': 200,
          'growth': 7.1,
          'unit': 'pcs',
        },
        {
          'name': 'Shirt Premium',
          'revenue': 80000,
          'pieces': 650,
          'growth': 15.0,
          'unit': 'pcs',
        },
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final sectionData = dummyData[_selectedSection]!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales & Reports'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter & Section Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToggleButtons(
                  isSelected: filters.map((f) => f == _selectedFilter).toList(),
                  onPressed: (i) {
                    setState(() {
                      _selectedFilter = filters[i];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Colors.indigo,
                  color: Colors.indigo,
                  children: filters.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(f, style: TextStyle(fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                DropdownButton<String>(
                  value: _selectedSection,
                  items: sections.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: TextStyle(fontWeight: FontWeight.bold)),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSection = val!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            // KPIs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _KpiCard(
                  label: 'Total Sales',
                  value: sectionData['totalSales'].toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.indigo,
                ),
                _KpiCard(
                  label: 'Total Revenue',
                  value: '₹${sectionData['totalRevenue']}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                _KpiCard(
                  label: 'Total Pieces',
                  value: sectionData['totalPieces'].toString(),
                  icon: Icons.check_circle,
                  color: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text('Top Performing Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: sectionData['products'].length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final prod = sectionData['products'][idx];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prod['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Revenue: ₹${prod['revenue']}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                Text('Units Sold: ${prod['pieces']} ${prod['unit']}', style: TextStyle(color: Colors.indigo)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${prod['growth']}%', style: TextStyle(
                                color: prod['growth'] > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                              Text('Growth', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
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
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}

