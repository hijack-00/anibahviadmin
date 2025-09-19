import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class SalesReportsPage extends StatefulWidget {
  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  String _selectedFilter = 'Monthly';
  String _selectedSection = 'Overview';
  String _selectedReport = 'Section Wise';

  final List<String> filters = ['Weekly', 'Monthly', 'Yearly'];
  final List<String> sections = ['Overview', 'Jeans', 'Shirts'];
  final List<String> reports = [
    'Section Wise',
    'Daily Sales',
    'Delivery Challan',
    'Stock Report',
    'Stock Rotation',
    'Net Sales',
    'Franchisee-wise Sales',
  ];

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
    // Daily Sales Report
    'Daily Sales': {
      'date': '2025-09-19',
      'totalSales': 45,
      'totalRevenue': 18000,
      'details': [
        {'product': 'Jeans Classic', 'qty': 10, 'revenue': 4000},
        {'product': 'Shirt Slim', 'qty': 8, 'revenue': 3200},
        {'product': 'Shirt Classic', 'qty': 5, 'revenue': 2000},
      ],
    },
    // Delivery Challan Report
    'Delivery Challan': {
      'challans': [
        {'id': 'DC001', 'date': '2025-09-18', 'items': 120, 'status': 'Delivered'},
        {'id': 'DC002', 'date': '2025-09-17', 'items': 80, 'status': 'Pending'},
      ],
    },
    // Stock Report
    'Stock Report': {
      'lowStock': [
        {'product': 'Jeans Classic', 'qty': 5},
        {'product': 'Shirt Slim', 'qty': 2},
      ],
      'totalStock': 1200,
      'rangeStock': [
        {'product': 'Jeans Classic', 'qty': 5},
        {'product': 'Jeans Stretch', 'qty': 20},
        {'product': 'Shirt Slim', 'qty': 2},
      ],
    },
    // Stock Rotation Cycle
    'Stock Rotation': {
      'cycles': [
        {'product': 'Jeans Classic', 'days': 30},
        {'product': 'Shirt Slim', 'days': 20},
      ],
    },
    // Net Sales (Sales + Sales Return)
    'Net Sales': {
      'sales': 450000,
      'salesReturn': 25000,
      'netSales': 425000,
    },
    // Franchisee-wise Sales
    'Franchisee-wise Sales': {
      'franchisees': [
        {'name': 'Franchisee A', 'sales': 120000},
        {'name': 'Franchisee B', 'sales': 95000},
        {'name': 'Franchisee C', 'sales': 80000},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    Widget reportWidget;
    final sectionData = dummyData[_selectedSection]!;
    switch (_selectedReport) {
      case 'Section Wise':
        reportWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        );
        break;
      case 'Daily Sales':
        final daily = dummyData['Daily Sales']!;
        reportWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${daily['date']}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Total Sales: ${daily['totalSales']}'),
            Text('Total Revenue: ₹${daily['totalRevenue']}'),
            SizedBox(height: 16),
            Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((daily['details'] as List).length, (i) {
              final d = daily['details'][i];
              return ListTile(
                title: Text(d['product']),
                subtitle: Text('Qty: ${d['qty']}'),
                trailing: Text('₹${d['revenue']}'),
              );
            }),
          ],
        );
        break;
      case 'Delivery Challan':
        final challan = dummyData['Delivery Challan']!;
        reportWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Challan Report', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...List.generate((challan['challans'] as List).length, (i) {
              final c = challan['challans'][i];
              return Card(
                child: ListTile(
                  title: Text('ID: ${c['id']}'),
                  subtitle: Text('Date: ${c['date']} | Items: ${c['items']}'),
                  trailing: Text(c['status'], style: TextStyle(color: c['status'] == 'Delivered' ? Colors.green : Colors.orange)),
                ),
              );
            }),
          ],
        );
        break;
      case 'Stock Report':
        final stock = dummyData['Stock Report']!;
        reportWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Low Stock', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((stock['lowStock'] as List).length, (i) {
              final s = stock['lowStock'][i];
              return ListTile(
                title: Text(s['product']),
                trailing: Text('Qty: ${s['qty']}', style: TextStyle(color: Colors.red)),
              );
            }),
            SizedBox(height: 8),
            Text('Total Stock: ${stock['totalStock']}'),
            SizedBox(height: 8),
            Text('Range Wise Stock', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((stock['rangeStock'] as List).length, (i) {
              final s = stock['rangeStock'][i];
              return ListTile(
                title: Text(s['product']),
                trailing: Text('Qty: ${s['qty']}'),
              );
            }),
          ],
        );
        break;
      case 'Stock Rotation':
        final rotation = dummyData['Stock Rotation']!;
        reportWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Rotation Cycle', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((rotation['cycles'] as List).length, (i) {
              final r = rotation['cycles'][i];
              return ListTile(
                title: Text(r['product']),
                trailing: Text('${r['days']} days'),
              );
            }),
          ],
        );
        break;
      case 'Net Sales':
        final net = dummyData['Net Sales']!;
        reportWidget = Card(
          margin: EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales: ₹${net['sales']}', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Sales Return: ₹${net['salesReturn']}', style: TextStyle(color: Colors.red)),
                Divider(),
                Text('Net Sales: ₹${net['netSales']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
          ),
        );
        break;
      case 'Franchisee-wise Sales':
        final fr = dummyData['Franchisee-wise Sales']!;
        reportWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Franchisee-wise Sales', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((fr['franchisees'] as List).length, (i) {
              final f = fr['franchisees'][i];
              return Card(
                child: ListTile(
                  title: Text(f['name']),
                  trailing: Text('₹${f['sales']}', style: TextStyle(color: Colors.indigo)),
                ),
              );
            }),
          ],
        );
        break;
      default:
        reportWidget = SizedBox();
    }

    return UniversalScaffold(
      selectedIndex: -1,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBar(
              title: Text('Sales & Reports'),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.indigo,
              automaticallyImplyLeading: false,
            ),
            SizedBox(height: 16),
            // Filter, Section, and Report Tabs
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
            SizedBox(height: 16),
            // Report Type Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: reports.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(r, style: TextStyle(fontWeight: FontWeight.bold)),
                    selected: _selectedReport == r,
                    selectedColor: Colors.indigo,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(color: _selectedReport == r ? Colors.white : Colors.indigo),
                    onSelected: (selected) {
                      setState(() {
                        _selectedReport = r;
                      });
                    },
                  ),
                )).toList(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(child: reportWidget),
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

