import 'package:anibhaviadmin/screens/all_orders_page.dart';
import 'package:anibhaviadmin/screens/order_details_page.dart';
import 'package:anibhaviadmin/screens/sales_reports_page.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';
import 'package:anibhaviadmin/screens/login_screen.dart';
import 'package:anibhaviadmin/widgets/add_product_form.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dashboard_widgets.dart';
import '../dialogs/create_order_bottom_sheet.dart';
import '../dialogs/create_challan_dialog.dart';
import '../dialogs/create_return_dialog.dart';
import 'users_page.dart';
import 'universal_navbar.dart';
import 'package:intl/intl.dart';

String formatCurrency(num amount) {
  if (amount >= 1000000) {
    return '₹${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(1)}K';
  } else {
    return '₹${amount.toStringAsFixed(0)}';
  }
}

// SALES SUMMARY CARD WIDGET
class _SalesSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _SalesSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(color: Colors.white, blurRadius: 8, offset: Offset(0, 2)),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                // fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            // SizedBox(height: 4),
            // Text(subtitle, style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class UniversalScaffold extends StatefulWidget {
  final int selectedIndex;
  final Widget body;
  UniversalScaffold({required this.selectedIndex, required this.body});

  @override
  State<UniversalScaffold> createState() => _UniversalScaffoldState();
}

class _UniversalScaffoldState extends State<UniversalScaffold> {
  // Drawer button with arrow icon at right
  Widget _drawerButton(String title, String route) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.indigo),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  void _onItemTapped(int index) {
    String? route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/orders';
        break;
      case 2:
        route = '/users';
        break;
      case 3:
        route = '/catalogue';
        break;
      case 4:
        route = '/challan';
        break;
    }
    if (route != null && ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (r) => r.settings.name == '/dashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        // elevation: 2,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (widget.selectedIndex == 0)
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Logout',
                  onPressed: () async {
                    final repo = AppDataRepo();
                    await repo.clearUserData();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // _drawerButton('Sales Order', '/sales-order'),
            // Divider(),
            // _drawerButton('Notes', '/notes'),
            // Divider(),
            // _drawerButton('LR Upload', '/lr-upload'),
            // Divider(),
            // _drawerButton('Transport Name Entry', '/transport-entry'),
            // Divider(),
            // _drawerButton('PDF Share', '/pdf-share'),
            // Divider(),
            // _drawerButton('Barcode Scan/Manual', '/barcode'),
            // Divider(),
            // _drawerButton('Franchisee Selection', '/franchisee-select'),
            // Divider(),
            _drawerButton('Sales Return', '/sales-return'),
            Divider(),
            _drawerButton('Stock Adjustment', '/stock-adjustment'),
            Divider(),
            // _drawerButton('Refund/Credit Note', '/refund-credit'),
            // Divider(),
            // _drawerButton('Return Challan', '/return-challan'),
            // Divider(),
            // _drawerButton('Reports Graph', '/reports-graph'),
            // Divider(),
            _drawerButton('Notifications', '/notifications'),
            Divider(),
            _drawerButton('Stock Management', '/stock-management'),
            Divider(),
            _drawerButton('Customer Ledger', '/customer-ledger'),
            Divider(),
            // _drawerButton('WhatsApp Notifications', '/whatsapp-notifications'),
            // Divider(),
            _drawerButton('Backend User Data', '/user-data'),
            // Divider(),
            // _drawerButton('Push Notifications', '/push-notifications'),
            Divider(),
            _drawerButton('Catalogue Upload', '/catalogue-upload'),
            Divider(),
          ],
        ),
      ),
      body: widget.body,
      bottomNavigationBar: UniversalNavBar(
        selectedIndex: widget.selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

String _selectedReportType = 'Overview';
final List<String> _reportTypes = ['Overview', 'Jeans', 'Shirts'];

class _DashboardScreenState extends State<DashboardScreen> {
  // Helper to get dummy or API data for the graph (replace with your actual data source)
  List<dynamic> getJeansDaily(Map<String, dynamic>? salesData) {
    return salesData?['jeans']?['dailyData'] ?? [];
  }

  List<dynamic> getShirtsDaily(Map<String, dynamic>? salesData) {
    return salesData?['shirts']?['dailyData'] ?? [];
  }

  void _showDashboardActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.person_add),
                      label: Text('Add Customer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.microtask(() => showUserCreationDialog(context));
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Create Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.microtask(
                          () => showCreateOrderBottomSheet(context),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_box),
                      label: Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: AddProductForm(),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.local_shipping),
                      label: Text('Create Challan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.microtask(
                          () => showCreateChallanDialog(context),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.assignment_return),
                      label: Text('Return Challan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.microtask(() => showCreateReturnDialog(context));
                      },
                    ),
                  ],
                ),
                // SALES SUMMARY BLOCK (dummy data)
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     _SalesSummaryCard(
                //       title: "Yearly Sales",
                //       value: "₹12,00,000",
                //       subtitle: "Revenue",
                //       color: Colors.indigo.shade700,
                //     ),
                //     _SalesSummaryCard(
                //       title: "Monthly Sales",
                //       value: "₹1,00,000",
                //       subtitle: "Revenue",
                //       color: Colors.indigo.shade400,
                //     ),
                //     _SalesSummaryCard(
                //       title: "Weekly Sales",
                //       value: "₹25,000",
                //       subtitle: "Revenue",
                //       color: Colors.indigo.shade200,
                //     ),
                //   ],
                // ),
                // SizedBox(height: 20),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  late Future<Map<String, dynamic>> _ordersFuture;

  final Map<String, int> userOverview = {'active': 12, 'inactive': 3};

  // final List<Map<String, dynamic>> quickActions = [
  //   {
  //     'label': 'Add Customer',
  //     'icon': Icons.person_add,
  //     'action': 'add_customer',
  //   },
  //   {
  //     'label': 'View Orders',
  //     'icon': Icons.shopping_cart,
  //     'route': '/orders',
  //
  //   },
  //   // {'label': 'View Catalogue', 'icon': Icons.collections, 'route': '/catalogue'},
  //   {
  //     'label': 'View Challan',
  //     'icon': Icons.local_shipping,
  //     'route': '/challan',
  //   },
  //   {
  //     'label': 'Sales Report',
  //     'icon': Icons.currency_rupee,
  //     'route': '/reports',
  //   },
  // ];
  final List<Map<String, dynamic>> quickActions = [
    {
      'label': 'Add Customer',
      'icon': Icons.person_add,
      'action': 'add_customer',
      // 'color': Colors.indigo.shade50,
    },
    {
      'label': 'View Orders',
      'icon': Icons.shopping_cart,
      'route': '/orders',
      // 'color': Colors.yellow.shade50,
    },
    {
      'label': 'View Challan',
      'icon': Icons.local_shipping,
      'route': '/challan',
      // 'color': Colors.blue.shade50,
    },
    {
      'label': 'Sales Report',
      'icon': Icons.currency_rupee,
      'route': '/reports',
      // 'color': Colors.green.shade50,
    },
  ];

  final Map<String, Color> statusColors = {
    'pending': Colors.yellow.shade700,
    'shipped': Colors.blue,
    'confirmed': Colors.indigo,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  late Future<Map<String, dynamic>> jeansShirtFuture;
  late Future<Map<String, dynamic>> salesDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
    jeansShirtFuture = AppDataRepo().getJeansShirtRevenueAndOrder();
    salesDataFuture = AppDataRepo().getSalesData();
  }

  void _refreshData() {
    setState(() {
      _ordersFuture = AppDataRepo().fetchAllOrders();
    });
  }

  @override
  void didPopNext() {
    // Called when coming back to this page
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Graphs Section
        FutureBuilder<Map<String, dynamic>>(
          future: salesDataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 120,
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            }
            final salesData = snapshot.data;

            String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

            final List<dynamic> jeansToday =
                (salesData?['jeans']?['dailyData'] ?? [])
                    .where((d) => d['date'] == todayStr)
                    .toList();
            final List<dynamic> shirtsToday =
                (salesData?['shirts']?['dailyData'] ?? [])
                    .where((d) => d['date'] == todayStr)
                    .toList();

            if (_selectedReportType == 'Overview') {
              return SalesBarChart(
                jeansDaily: jeansToday,
                shirtsDaily: shirtsToday,
                section: 'overview',
              );
            } else if (_selectedReportType == 'Jeans') {
              return SalesBarChart(
                jeansDaily: jeansToday,
                shirtsDaily: [],
                section: 'jeans',
              );
            } else if (_selectedReportType == 'Shirts') {
              return SalesBarChart(
                jeansDaily: [],
                shirtsDaily: shirtsToday,
                section: 'shirts',
              );
            }
            return SizedBox();
          },
        );

        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Exit App'),
              content: Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('OK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
        return result == true;
      },
      child: Stack(
        children: [
          UniversalScaffold(
            selectedIndex: 0,
            body: RefreshIndicator(
              onRefresh: () async {
                _refreshData();
                await _ordersFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SALES SUMMARY BLOCK (API-driven)
                    FutureBuilder<Map<String, dynamic>>(
                      future: salesDataFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          );
                        }
                        final data = snapshot.data!['data'];
                        final jeans = data['jeans'];
                        final shirts = data['shirts'];
                        final List<dynamic> jeansDaily =
                            jeans['dailyData'] ?? [];
                        final List<dynamic> shirtsDaily =
                            shirts['dailyData'] ?? [];
                        // Combine all daily sales
                        final allDaily = [...jeansDaily, ...shirtsDaily];
                        int totalSales = 0;
                        Set<String> uniqueDays = {};
                        for (var d in allDaily) {
                          totalSales += (d['sales'] ?? 0) as int;
                          uniqueDays.add(d['date'] ?? '');
                        }
                        int numDays = uniqueDays.length > 0
                            ? uniqueDays.length
                            : 1;
                        double avgDay = totalSales / numDays;
                        double avgYear = avgDay * 365;
                        double avgMonth = avgDay * 30;
                        double avgWeek = avgDay * 7;
                        String fmt(num n) {
                          double k = n / 1000;
                          if (k < 0.1 && n > 0) k = 0.1;
                          return '₹${k.toStringAsFixed(1)}K';
                        }

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SalesSummaryCard(
                                title: "Yearly Sales",
                                value: formatCurrency(avgYear.round()),
                                subtitle: "Avg Revenue",
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalesReportsPage(),
                                    ),
                                  );
                                },
                              ),
                              _SalesSummaryCard(
                                title: "Monthly Sales",
                                value: formatCurrency(avgMonth.round()),

                                subtitle: "Avg Revenue",
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalesReportsPage(),
                                    ),
                                  );
                                },
                              ),
                              _SalesSummaryCard(
                                title: "Weekly Sales",
                                value: formatCurrency(avgWeek.round()),
                                subtitle: "Avg Revenue",
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SalesReportsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),

                    // Dropdown for report type
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: _selectedReportType,
                        isExpanded: true,
                        underline: SizedBox(),
                        items: _reportTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedReportType = val!;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: 30),

                    // Graphs Section
                    if (_selectedReportType == 'Overview')
                      FutureBuilder<Map<String, dynamic>>(
                        future: salesDataFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return Center(child: CircularProgressIndicator());
                          final data = snapshot.data!['data'];
                          final jeans = data['jeans'];
                          final shirts = data['shirts'];
                          // Use API fields for total orders and revenue
                          final totalOrders =
                              (jeans['orders'] ?? 0) + (shirts['orders'] ?? 0);
                          final totalRevenue =
                              (jeans['total'] ?? 0) + (shirts['total'] ?? 0);
                          return Column(
                            children: [
                              Text(
                                'Revenue Distribution',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: (jeans['total'] ?? 0).toDouble(),
                                        color: Colors.indigo,
                                        title: 'Jeans',
                                        radius: 60,
                                        titleStyle: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: (shirts['total'] ?? 0)
                                            .toDouble(),
                                        color: Colors.green,
                                        title: 'Shirts',
                                        radius: 60,
                                        titleStyle: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendDot(
                                    color: Colors.indigo,
                                    label: 'Jeans',
                                  ),
                                  SizedBox(width: 16),
                                  _LegendDot(
                                    color: Colors.green,
                                    label: 'Shirts',
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Builder(
                                builder: (context) {
                                  String todayStr = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.now());
                                  // Filter for today's data
                                  final List<dynamic> jeansToday =
                                      (jeans['dailyData'] ?? [])
                                          .where((d) => d['date'] == todayStr)
                                          .toList();
                                  final List<dynamic> shirtsToday =
                                      (shirts['dailyData'] ?? [])
                                          .where((d) => d['date'] == todayStr)
                                          .toList();

                                  // Calculate today's total orders and revenue
                                  int todayOrders = 0;
                                  int todayRevenue = 0;
                                  for (var d in jeansToday) {
                                    todayOrders += (d['orders'] ?? 0) as int;
                                    todayRevenue += (d['sales'] ?? 0) as int;
                                  }
                                  for (var d in shirtsToday) {
                                    todayOrders += (d['orders'] ?? 0) as int;
                                    todayRevenue += (d['sales'] ?? 0) as int;
                                  }

                                  return Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              "Today's Orders",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '$todayOrders',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 1,
                                          height: 32,
                                          color: Colors.indigo.shade100,
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              "Today's Revenue",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '₹$todayRevenue',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      )
                    else if (_selectedReportType == 'Jeans')
                      FutureBuilder<Map<String, dynamic>>(
                        future: salesDataFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return Center(child: CircularProgressIndicator());
                          final jeans = snapshot.data!['data']['jeans'];
                          final dailyData = jeans['dailyData'];
                          if (dailyData == null || dailyData.isEmpty) {
                            return Center(
                              child: Text('No daily sales data available.'),
                            );
                          }
                          String todayStr = DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.now());
                          final List<dynamic> jeansToday = (dailyData ?? [])
                              .where((d) => d['date'] == todayStr)
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jeans Daily Sales',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barGroups: jeansToday
                                        .asMap()
                                        .entries
                                        .map<BarChartGroupData>((entry) {
                                          int idx = entry.key;
                                          var d = entry.value;
                                          return BarChartGroupData(
                                            x: idx,
                                            barRods: [
                                              BarChartRodData(
                                                toY: (d['sales'] as num)
                                                    .toDouble(),
                                                color: Colors.indigo,
                                                width: 18,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ],
                                            showingTooltipIndicators: [0],
                                          );
                                        })
                                        .toList(),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        // tooltipBgColor: Colors.indigo,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                rod.toY.toString(),
                                                TextStyle(
                                                  color: Colors
                                                      .white, // <-- This sets the label color to white
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                String formatted;
                                                if (value >= 1000) {
                                                  formatted =
                                                      '${(value ~/ 1000)}k';
                                                } else {
                                                  formatted = value
                                                      .toInt()
                                                      .toString();
                                                }
                                                return Text(
                                                  formatted,
                                                  style: TextStyle(
                                                    fontSize:
                                                        11, // Your desired text size
                                                    color: Colors.black,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                final idx = value.toInt();
                                                if (idx < jeansToday.length) {
                                                  // If time is available, show time, else show index+1
                                                  String label = '';
                                                  if (jeansToday[idx]['time'] !=
                                                      null) {
                                                    label =
                                                        jeansToday[idx]['time']
                                                            .toString();
                                                  } else {
                                                    label = '#${idx + 1}';
                                                  }
                                                  return Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                    ),
                                                  );
                                                }
                                                return Text('');
                                              },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else if (_selectedReportType == 'Shirts')
                      FutureBuilder<Map<String, dynamic>>(
                        future: salesDataFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return Center(child: CircularProgressIndicator());
                          final shirts = snapshot.data!['data']['shirts'];
                          final dailyData = shirts['dailyData'];
                          if (dailyData == null || dailyData.isEmpty) {
                            return Center(
                              child: Text('No daily sales data available.'),
                            );
                          }
                          String todayStr = DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.now());
                          final List<dynamic> shirtsToday = (dailyData ?? [])
                              .where((d) => d['date'] == todayStr)
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shirts Daily Sales',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barGroups: shirtsToday
                                        .asMap()
                                        .entries
                                        .map<BarChartGroupData>((entry) {
                                          int idx = entry.key;
                                          var d = entry.value;
                                          return BarChartGroupData(
                                            x: idx,
                                            barRods: [
                                              BarChartRodData(
                                                toY: (d['sales'] as num)
                                                    .toDouble(),
                                                color: Colors.green,
                                                width: 18,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ],
                                            showingTooltipIndicators: [0],
                                          );
                                        })
                                        .toList(),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        // tooltipBgColor: Colors.black87,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                rod.toY.toString(),
                                                TextStyle(
                                                  color: Colors
                                                      .white, // <-- This sets the label color to white
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                String formatted;
                                                if (value >= 1000) {
                                                  formatted =
                                                      '${(value ~/ 1000)}k';
                                                } else {
                                                  formatted = value
                                                      .toInt()
                                                      .toString();
                                                }
                                                return Text(
                                                  formatted,
                                                  style: TextStyle(
                                                    fontSize:
                                                        11, // Your desired text size
                                                    color: Colors.black,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                final idx = value.toInt();
                                                if (idx < shirtsToday.length) {
                                                  // If time is available, show time, else show index+1
                                                  String label = '';
                                                  if (shirtsToday[idx]['time'] !=
                                                      null) {
                                                    label =
                                                        shirtsToday[idx]['time']
                                                            .toString();
                                                  } else {
                                                    label = '#${idx + 1}';
                                                  }
                                                  return Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  );
                                                }
                                                return Text('');
                                              },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    SizedBox(height: 20),

                    // Order stats
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF6F8FA), // Elegant light background
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: EdgeInsets.all(16),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _ordersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Skeleton loader for big buttons
                            return Column(
                              children: List.generate(
                                4,
                                (i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError ||
                              snapshot.data == null ||
                              snapshot.data!['orders'] == null) {
                            return Center(
                              child: Text('Error loading order stats'),
                            );
                          }
                          final orders = List<Map<String, dynamic>>.from(
                            snapshot.data!['orders'],
                          );
                          final statusCounts = {
                            'pending': 0,
                            'shipped': 0,
                            'delivered': 0,
                            'cancelled': 0,
                          };
                          for (var order in orders) {
                            final statusRaw = order['orderStatus'] ?? '';
                            final status = statusRaw
                                .toString()
                                .trim()
                                .toLowerCase();
                            if (statusCounts.containsKey(status)) {
                              statusCounts[status] = statusCounts[status]! + 1;
                            }
                          }
                          final statusIcons = {
                            'pending': Icons.pending_actions,
                            'shipped': Icons.local_shipping,
                            'delivered': Icons.check_circle,
                            'cancelled': Icons.cancel,
                          };
                          final statusLabels = {
                            'pending': 'Pending',
                            'shipped': 'Shipped',
                            'delivered': 'Delivered',
                            'cancelled': 'Cancelled',
                          };
                          return Column(
                            children: statusCounts.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Material(
                                  color: statusColors[entry.key]!.withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      // TODO: Add navigation or action if needed
                                    },
                                    child: Container(
                                      height: 50,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            statusIcons[entry.key],
                                            color: statusColors[entry.key],
                                            size: 28,
                                          ),
                                          SizedBox(width: 18),
                                          Expanded(
                                            child: Text(
                                              statusLabels[entry.key]!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: statusColors[entry.key],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${entry.value} ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Orders',
                                            style: TextStyle(
                                              // fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    // Text(
                    //   'Users',
                    //   style: Theme.of(context).textTheme.titleMedium,
                    // ),
                    SizedBox(height: 8),

                    // User & Cart Overview
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    //       child: GestureDetector(
                    //         onTap: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //               builder: (context) =>
                    //                   UsersPage(showActive: true),
                    //             ),
                    //           );
                    //         },
                    //         child: UserStatCard(
                    //           label: 'Active Users',
                    //           count: userOverview['active'] as int,
                    //           icon: Icons.person,
                    //           color: Colors.indigo,
                    //         ),
                    //       ),
                    //     ),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    //       child: GestureDetector(
                    //         onTap: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //               builder: (context) =>
                    //                   UsersPage(showActive: false),
                    //             ),
                    //           );
                    //         },
                    //         child: UserStatCard(
                    //           label: 'Inactive Users',
                    //           count: userOverview['inactive'] as int,
                    //           icon: Icons.person_off,
                    //           color: Colors.grey,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UsersPage(showActive: true),
                                  ),
                                );
                              },
                              child: UserStatCard(
                                label: 'Active Users',
                                count: userOverview['active'] as int,
                                icon: Icons.person,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UsersPage(showActive: false),
                                  ),
                                );
                              },
                              child: UserStatCard(
                                label: 'Inactive Users',
                                count: userOverview['inactive'] as int,
                                icon: Icons.person_off,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Quick Actions
                    // Text(
                    //   'Quick Actions',
                    //   style: Theme.of(context).textTheme.titleMedium,
                    // ),
                    SizedBox(height: 8),
                    // SingleChildScrollView(
                    //   scrollDirection: Axis.horizontal,
                    //   child: Row(
                    //     children: quickActions
                    //         .map(
                    //           (action) => Padding(
                    //             padding: const EdgeInsets.symmetric(
                    //               horizontal: 6.0,
                    //             ),
                    //             child: action['action'] == 'add_customer'
                    //                 ? ElevatedButton.icon(
                    //                     icon: Icon(action['icon'] as IconData),
                    //                     label: Text(action['label'] as String),
                    //                     style: ElevatedButton.styleFrom(
                    //                       backgroundColor: Colors.indigo,
                    //                       foregroundColor: Colors.white,
                    //                       padding: EdgeInsets.symmetric(
                    //                         horizontal: 16,
                    //                         vertical: 10,
                    //                       ),
                    //                       shape: RoundedRectangleBorder(
                    //                         borderRadius: BorderRadius.circular(
                    //                           12,
                    //                         ),
                    //                       ),
                    //                     ),
                    //                     onPressed: () {
                    //                       Future.microtask(
                    //                         () =>
                    //                             showUserCreationDialog(context),
                    //                       );
                    //                       // Optionally refresh users or show a message
                    //                     },
                    //                   )
                    //                 : QuickActionButton(
                    //                     label: action['label'] as String,
                    //                     icon: action['icon'] as IconData,

                    //                     route: action['route'] as String,
                    //                   ),
                    //           ),
                    //         )
                    //         .toList(),
                    //   ),
                    // ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.6, // Adjust for button shape
                      children: quickActions.map((action) {
                        final Color btnColor =
                            action['color'] ?? Colors.grey.shade200;
                        return action['action'] == 'add_customer'
                            ? ElevatedButton.icon(
                                icon: Icon(action['icon'] as IconData),
                                label: Text(action['label'] as String),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: btnColor,
                                  // foregroundColor: Colors.indigo,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                                onPressed: () {
                                  Future.microtask(
                                    () => showUserCreationDialog(context),
                                  );
                                },
                              )
                            : QuickActionButton(
                                label: action['label'] as String,
                                icon: action['icon'] as IconData,
                                route: action['route'] as String,
                                bgcolor: btnColor, // Pass color to your widget
                                fgcolor: Colors
                                    .indigo, // Pass foreground color to your widget
                              );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    // Recent Orders from API
                    Text(
                      'Recent Orders',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _ordersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Skeleton loader for recent orders
                          return Column(
                            children: List.generate(
                              3,
                              (i) => Card(
                                color: Colors.white,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 16,
                                        color: Colors.grey.shade200,
                                        margin: EdgeInsets.only(bottom: 8),
                                      ),
                                      Container(
                                        width: 80,
                                        height: 12,
                                        color: Colors.grey.shade200,
                                        margin: EdgeInsets.only(bottom: 8),
                                      ),
                                      Container(
                                        width: 180,
                                        height: 12,
                                        color: Colors.grey.shade200,
                                        margin: EdgeInsets.only(bottom: 8),
                                      ),
                                      Container(
                                        width: 60,
                                        height: 12,
                                        color: Colors.grey.shade200,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading orders'));
                        }
                        final data = snapshot.data;
                        final orders =
                            (data != null &&
                                data['success'] == true &&
                                data['orders'] != null)
                            // SALES SUMMARY CARD WIDGET
                            ? List<Map<String, dynamic>>.from(data['orders'])
                            : [];
                        if (orders.isEmpty) {
                          return Center(child: Text('No recent orders found'));
                        }
                        return Column(
                          children: [
                            ...orders.take(3).map((order) {
                              final shipping = order['shippingAddress'] ?? {};
                              String statusRaw = (order['orderStatus'] ?? '')
                                  .toString()
                                  .trim();
                              String status =
                                  statusRaw.toLowerCase() == 'order confirmed'
                                  ? 'Confirmed'
                                  : statusRaw;
                              String paymentStatus =
                                  (order['paymentStatus'] ?? '')
                                      .toString()
                                      .trim();
                              return Card(
                                color: Colors.white,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(
                                          orderId: order['_id'],
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _refreshData();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                child: Text(
                                                  order['orderUniqueId'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    statusColors[status
                                                        .toLowerCase()] ??
                                                    Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if ((shipping['name'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              shipping['name'] ?? '',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            if ((shipping['phone'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                shipping['phone'] ?? '',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            if ((shipping['phone'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                ' • ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            if ((shipping['email'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                shipping['email'] ?? '',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                          ],
                                        ),
                                        if ((shipping['address'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              '${shipping['address'] ?? ''}${shipping['city'] != null ? ', ' + shipping['city'] : ''}${shipping['state'] != null ? ', ' + shipping['state'] : ''}${shipping['country'] != null ? ', ' + shipping['country'] : ''}${shipping['postalCode'] != null ? ' - ' + shipping['postalCode'] : ''}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            if (paymentStatus.isNotEmpty)
                                              Text(
                                                paymentStatus,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      paymentStatus
                                                          .toLowerCase()
                                                          .contains('fail')
                                                      ? Colors.red
                                                      : paymentStatus
                                                            .toLowerCase()
                                                            .contains(
                                                              'complete',
                                                            )
                                                      ? Colors.indigo
                                                      : paymentStatus
                                                            .toLowerCase()
                                                            .contains('partial')
                                                      ? Colors.green
                                                      : Colors.black,
                                                ),
                                              ),
                                            if (paymentStatus.isNotEmpty)
                                              Text(
                                                ' • ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            Text(
                                              '₹${order['totalAmount'] ?? ''}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (orders.length > 6)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AllOrdersPage(),
                                      ),
                                    );
                                  },
                                  child: Text('View All'),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Floating button above bottom nav bar, using MediaQuery for correct spacing
          Positioned(
            right: 24,
            bottom:
                MediaQuery.of(context).padding.bottom +
                72, // 56 for nav bar + 16 extra
            child: FloatingActionButton(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: Icon(Icons.add, size: 32),
              onPressed: _showDashboardActionsSheet,
              tooltip: 'Quick Actions',
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets
// Widget _StatColumn(String label, String value) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//       SizedBox(height: 4),
//       Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
//     ],
//   );
// }

// class _QuickCard extends StatelessWidget {
//   final Color color;
//   final IconData icon;
//   final String title;
//   final String subtitle;

//   const _QuickCard({
//     required this.color,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.black54, size: 28),
//           SizedBox(height: 12),
//           Text(
//             title,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//           ),
//           SizedBox(height: 6),
//           Text(
//             subtitle,
//             style: TextStyle(color: Colors.grey[700], fontSize: 12),
//           ),
//           Spacer(),
//           Align(
//             alignment: Alignment.bottomRight,
//             child: Icon(Icons.arrow_forward, color: Colors.black38, size: 18),
//           ),
//         ],
//       ),
//     );
//   }
// }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage('assets/avatar.png'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hello, Rownok!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Icon(Icons.search, color: Colors.grey[700]),
                SizedBox(width: 8),
                Icon(Icons.notifications_none, color: Colors.grey[700]),
              ],
            ),
            SizedBox(height: 18),

            // Combined Sales Summary Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFF8D7DA),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Sales Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.more_horiz, color: Colors.grey[700]),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SalesStatBig(title: 'Yearly', value: '₹12,00,000'),
                      _SalesStatBig(title: 'Monthly', value: '₹1,00,000'),
                      _SalesStatBig(title: 'Weekly', value: '₹25,000'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Updated Today',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      Spacer(),
                      Text(
                        'See Details',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Status Cards: 2 in a row, big cards
            Row(
              children: [
                Expanded(
                  child: _StatusCardBig(
                    color: Color(0xFFFFF3CD),
                    icon: Icons.hourglass_top,
                    title: 'Pending',
                    subtitle: '12 Orders',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _StatusCardBig(
                    color: Color(0xFFD1E7DD),
                    icon: Icons.local_shipping,
                    title: 'Shipped',
                    subtitle: '8 Orders',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusCardBig(
                    color: Color(0xFFD6EAF8),
                    icon: Icons.check_circle_outline,
                    title: 'Delivered',
                    subtitle: '20 Orders',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _StatusCardBig(
                    color: Color(0xFFF8D7DA),
                    icon: Icons.cancel_outlined,
                    title: 'Cancelled',
                    subtitle: '2 Orders',
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Today Recommendation
            Text(
              'Today Recommendation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            // Add your recommendation widgets here
          ],
        ),
      ),
    ),
    // Custom bottom navigation bar
    bottomNavigationBar: Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: Colors.indigo, size: 28),
            Icon(Icons.bar_chart, color: Colors.grey, size: 28),
            Icon(Icons.add_circle, color: Colors.indigo, size: 36),
            Icon(Icons.person, color: Colors.grey, size: 28),
            Icon(Icons.settings, color: Colors.grey, size: 28),
          ],
        ),
      ),
    ),
  );
}

// Helper widgets for sales stats
class _SalesStatBig extends StatelessWidget {
  final String title;
  final String value;
  const _SalesStatBig({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.redAccent,
          ),
        ),
        SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      ],
    );
  }
}

// Big status card widget
class _StatusCardBig extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  const _StatusCardBig({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54, size: 28),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
