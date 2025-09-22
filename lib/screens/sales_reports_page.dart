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
    // Elegant card background for main content
    final cardBg = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 4))],
    );

    switch (_selectedReport) {
      case 'Section Wise':
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    color: Colors.indigo,
                  ),
                  _KpiCard(
                    label: 'Total Pieces',
                    value: sectionData['totalPieces'].toString(),
                    icon: Icons.check_circle,
                    color: Colors.indigo,
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text('Top Performing Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: sectionData['products'].length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final prod = sectionData['products'][idx];
                    return Card(
                      color: Colors.indigo.shade50,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
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
        );
        break;
      case 'Daily Sales':
        final daily = dummyData['Daily Sales']!;
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${daily['date']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 8),
              Text('Total Sales: ${daily['totalSales']}', style: TextStyle(color: Colors.indigo)),
              Text('Total Revenue: ₹${daily['totalRevenue']}', style: TextStyle(color: Colors.indigo)),
              SizedBox(height: 16),
              Text('Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ...List.generate((daily['details'] as List).length, (i) {
                final d = daily['details'][i];
                return Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  child: ListTile(
                    title: Text(d['product'], style: TextStyle(color: Colors.indigo)),
                    subtitle: Text('Qty: ${d['qty']}', style: TextStyle(color: Colors.indigo.shade400)),
                    trailing: Text('₹${d['revenue']}', style: TextStyle(color: Colors.green)),
                  ),
                );
              }),
            ],
          ),
        );
        break;
      case 'Delivery Challan':
        final challan = dummyData['Delivery Challan']!;
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Challan Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 8),
              ...List.generate((challan['challans'] as List).length, (i) {
                final c = challan['challans'][i];
                return Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  child: ListTile(
                    title: Text('ID: ${c['id']}', style: TextStyle(color: Colors.indigo)),
                    subtitle: Text('Date: ${c['date']} | Items: ${c['items']}', style: TextStyle(color: Colors.indigo.shade400)),
                    trailing: Text(c['status'], style: TextStyle(color: c['status'] == 'Delivered' ? Colors.green : Colors.orange)),
                  ),
                );
              }),
            ],
          ),
        );
        break;
      case 'Stock Report':
        final stock = dummyData['Stock Report']!;
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Low Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ...List.generate((stock['lowStock'] as List).length, (i) {
                final s = stock['lowStock'][i];
                return Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  child: ListTile(
                    title: Text(s['product'], style: TextStyle(color: Colors.indigo)),
                    trailing: Text('Qty: ${s['qty']}', style: TextStyle(color: Colors.red)),
                  ),
                );
              }),
              SizedBox(height: 8),
              Text('Total Stock: ${stock['totalStock']}', style: TextStyle(color: Colors.indigo)),
              SizedBox(height: 8),
              Text('Range Wise Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ...List.generate((stock['rangeStock'] as List).length, (i) {
                final s = stock['rangeStock'][i];
                return Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  child: ListTile(
                    title: Text(s['product'], style: TextStyle(color: Colors.indigo)),
                    trailing: Text('Qty: ${s['qty']}', style: TextStyle(color: Colors.indigo)),
                  ),
                );
              }),
            ],
          ),
        );
        break;
      case 'Stock Rotation':
        final rotation = dummyData['Stock Rotation']!;
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock Rotation Cycle', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ...List.generate((rotation['cycles'] as List).length, (i) {
                final r = rotation['cycles'][i];
                return Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  child: ListTile(
                    title: Text(r['product'], style: TextStyle(color: Colors.indigo)),
                    trailing: Text('${r['days']} days', style: TextStyle(color: Colors.indigo)),
                  ),
                );
              }),
            ],
          ),
        );
        break;
      case 'Net Sales':
        final net = dummyData['Net Sales']!;
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sales: ₹${net['sales']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('Sales Return: ₹${net['salesReturn']}', style: TextStyle(color: Colors.red)),
              Divider(),
              Text('Net Sales: ₹${net['netSales']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
        );
        break;
      case 'Franchisee-wise Sales':
        final fr = dummyData['Franchisee-wise Sales']!;
        reportWidget = Container(
          decoration: cardBg,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Franchisee-wise Sales', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ...List.generate((fr['franchisees'] as List).length, (i) {
                final f = fr['franchisees'][i];
                return Card(
                  color: Colors.indigo.shade50,
                  elevation: 0,
                  child: ListTile(
                    title: Text(f['name'], style: TextStyle(color: Colors.indigo)),
                    trailing: Text('₹${f['sales']}', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ],
          ),
        );
        break;
      default:
        reportWidget = SizedBox();
    }

    return UniversalScaffold(
      selectedIndex: -1,
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Elegant header
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                child: Text('Sales & Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.indigo)),
              ),
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
                    borderColor: Colors.indigo.shade200,
                    selectedBorderColor: Colors.indigo,
                    children: filters.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(f, style: TextStyle(fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  DropdownButton<String>(
                    value: _selectedSection,
                    dropdownColor: Colors.indigo.shade50,
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                    items: sections.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: _selectedReport == r ? Colors.white : Colors.indigo),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.indigo.shade100)),
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
      width: 110,
      height: 110,
      child: Card(
        color: Colors.indigo.shade100,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.indigo.shade700, size: 24),
              SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo.shade700)),
              SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.indigo.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

