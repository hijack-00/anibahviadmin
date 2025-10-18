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

      // Replace your appBar property in Scaffold (inside UniversalScaffold) with this:
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade500, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (widget.selectedIndex == 0)
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () async {
                        final repo = AppDataRepo();
                        await repo.clearUserData();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                ],
              ),
            ),
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
      _ordersFuture = AppDataRepo().fetchAllOrders().then(
        (ordersList) => {'orders': ordersList, 'success': true},
      );
    });
  }

  @override
  void didPopNext() {
    // Called when coming back to this page
    _refreshData();
  }

  // Add these helper functions and widgets to fix errors for _buildUserStatCard and _getStatusIcon

  // Helper for status icons
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'confirmed':
        return Icons.assignment_turned_in;
      default:
        return Icons.help_outline;
    }
  }

  // Helper for capitalizing status
  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  // Elegant user stat card
  Widget _buildUserStatCard(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.indigo.shade400,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Exit App',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to exit?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo.shade500,
                    textStyle: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('OK'),
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
              color: Colors.indigo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SALES SUMMARY ---
                    FutureBuilder<Map<String, dynamic>>(
                      future: salesDataFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox(
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.indigo.shade400,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data!['data'];
                        final jeans = data['jeans'];
                        final shirts = data['shirts'];
                        final allDaily = [
                          ...(jeans['dailyData'] ?? []),
                          ...(shirts['dailyData'] ?? []),
                        ];
                        int totalSales = 0;
                        Set<String> uniqueDays = {};
                        for (var d in allDaily) {
                          totalSales += (d['sales'] ?? 0) as int;
                          uniqueDays.add(d['date'] ?? '');
                        }
                        int numDays = uniqueDays.isNotEmpty
                            ? uniqueDays.length
                            : 1;
                        double avgDay = totalSales / numDays;
                        double avgYear = avgDay * 365;
                        double avgMonth = avgDay * 30;
                        double avgWeek = avgDay * 7;

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SalesSummaryCard(
                                title: "Yearly Sales",
                                value: formatCurrency(avgYear.round()),
                                subtitle: "Avg Revenue",
                                color: Colors.indigo.shade500,
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
                                color: Colors.teal.shade400,
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
                                color: Colors.purple.shade400,
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
                    const SizedBox(height: 20),

                    // --- Report Type Dropdown ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.shade100.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: _selectedReportType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.indigo.shade400,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                        items: _reportTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.indigo.shade600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedReportType = val!),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Graphs ---
                    if (_selectedReportType == 'Overview')
                      FutureBuilder<Map<String, dynamic>>(
                        future: salesDataFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return Center(child: CircularProgressIndicator());
                          final data = snapshot.data!['data'];
                          final jeans = data['jeans'];
                          final shirts = data['shirts'];
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
                                  final List<dynamic> jeansToday =
                                      (jeans['dailyData'] ?? [])
                                          .where((d) => d['date'] == todayStr)
                                          .toList();
                                  final List<dynamic> shirtsToday =
                                      (shirts['dailyData'] ?? [])
                                          .where((d) => d['date'] == todayStr)
                                          .toList();

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
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                rod.toY.toString(),
                                                TextStyle(
                                                  color: Colors.white,
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
                                                    fontSize: 11,
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
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                rod.toY.toString(),
                                                TextStyle(
                                                  color: Colors.white,
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
                                                    fontSize: 11,
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

                    const SizedBox(height: 24),

                    // --- Order Stats Section ---
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.shade100.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _ordersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Column(
                              children: List.generate(
                                4,
                                (i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError ||
                              snapshot.data == null ||
                              snapshot.data!['orders'] == null) {
                            print('Order stats error: ${snapshot.error}');
                            return Center(
                              child: Text(
                                'Error loading order stats',
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          final orders = List<Map<String, dynamic>>.from(
                            snapshot.data!['orders'],
                          );
                          // Print all statuses for debugging
                          print('Order statuses:');
                          for (var order in orders) {
                            print(order['status'] ?? order['orderStatus']);
                          }

                          // Map all statuses to your stats buckets
                          final statusCounts = {
                            'pending': 0,
                            'packed': 0,
                            'confirmed': 0,
                            'shipped': 0,
                            'delivered': 0,
                            'cancelled': 0,
                          };
                          for (var order in orders) {
                            final status =
                                ((order['status'] ?? order['orderStatus']) ??
                                        '')
                                    .toString()
                                    .trim()
                                    .toLowerCase();
                            if (statusCounts.containsKey(status)) {
                              statusCounts[status] = statusCounts[status]! + 1;
                            }
                          }
                          print('Order statusCounts: $statusCounts');

                          final statusColors = {
                            'pending': Colors.orange.shade400,
                            'packed': Colors.blue.shade300,
                            'confirmed': Colors.indigo,
                            'shipped': Colors.blue.shade400,
                            'delivered': Colors.green.shade400,
                            'cancelled': Colors.red.shade400,
                          };

                          // Only show statuses that have at least 1 order
                          final visibleStatuses = statusCounts.entries.where(
                            (e) => e.value > 0,
                          );

                          if (visibleStatuses.isEmpty) {
                            return Center(child: Text('No orders found'));
                          }

                          return Column(
                            children: visibleStatuses.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Material(
                                  color: statusColors[entry.key]!.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {},
                                    child: Container(
                                      height: 56,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getStatusIcon(entry.key),
                                            color: statusColors[entry.key],
                                            size: 24,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              _capitalize(entry.key),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: statusColors[entry.key],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${entry.value}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Orders',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
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

                    // Container(
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       colors: [Colors.indigo.shade50, Colors.white],
                    //       begin: Alignment.topLeft,
                    //       end: Alignment.bottomRight,
                    //     ),
                    //     borderRadius: BorderRadius.circular(20),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.indigo.shade100.withOpacity(0.3),
                    //         blurRadius: 6,
                    //         offset: Offset(0, 3),
                    //       ),
                    //     ],
                    //   ),
                    //   padding: const EdgeInsets.all(16),
                    //   child: FutureBuilder<Map<String, dynamic>>(
                    //     future: _ordersFuture,
                    //     builder: (context, snapshot) {
                    //       if (snapshot.connectionState ==
                    //           ConnectionState.waiting) {
                    //         return Column(
                    //           children: List.generate(
                    //             4,
                    //             (i) => Padding(
                    //               padding: const EdgeInsets.symmetric(
                    //                 vertical: 8.0,
                    //               ),
                    //               child: Container(
                    //                 height: 60,
                    //                 decoration: BoxDecoration(
                    //                   color: Colors.grey.shade200,
                    //                   borderRadius: BorderRadius.circular(12),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         );
                    //       }

                    //       if (snapshot.hasError ||
                    //           snapshot.data == null ||
                    //           snapshot.data!['orders'] == null) {
                    //         return Center(
                    //           child: Text(
                    //             'Error loading order stats',
                    //             style: TextStyle(
                    //               color: Colors.red.shade300,
                    //               fontSize: 13,
                    //             ),
                    //           ),
                    //         );
                    //       }

                    //       final orders = List<Map<String, dynamic>>.from(
                    //         snapshot.data!['orders'],
                    //       );
                    //       final statusCounts = {
                    //         'pending': 0,
                    //         'shipped': 0,
                    //         'delivered': 0,
                    //         'cancelled': 0,
                    //       };
                    //       for (var order in orders) {
                    //         final status = (order['orderStatus'] ?? '')
                    //             .toString()
                    //             .trim()
                    //             .toLowerCase();
                    //         if (statusCounts.containsKey(status)) {
                    //           statusCounts[status] = statusCounts[status]! + 1;
                    //         }
                    //       }

                    //       final statusColors = {
                    //         'pending': Colors.orange.shade400,
                    //         'shipped': Colors.blue.shade400,
                    //         'delivered': Colors.green.shade400,
                    //         'cancelled': Colors.red.shade400,
                    //       };

                    //       return Column(
                    //         children: statusCounts.entries.map((entry) {
                    //           return Padding(
                    //             padding: const EdgeInsets.symmetric(
                    //               vertical: 6.0,
                    //             ),
                    //             child: Material(
                    //               color: statusColors[entry.key]!.withOpacity(
                    //                 0.1,
                    //               ),
                    //               borderRadius: BorderRadius.circular(14),
                    //               child: InkWell(
                    //                 borderRadius: BorderRadius.circular(14),
                    //                 onTap: () {},
                    //                 child: Container(
                    //                   height: 56,
                    //                   padding: const EdgeInsets.symmetric(
                    //                     horizontal: 18,
                    //                   ),
                    //                   child: Row(
                    //                     children: [
                    //                       Icon(
                    //                         _getStatusIcon(entry.key),
                    //                         color: statusColors[entry.key],
                    //                         size: 24,
                    //                       ),
                    //                       const SizedBox(width: 16),
                    //                       Expanded(
                    //                         child: Text(
                    //                           _capitalize(
                    //                             entry.key,
                    //                           ), // Show status as text, not icon
                    //                           style: TextStyle(
                    //                             fontWeight: FontWeight.w600,
                    //                             fontSize: 14,
                    //                             color: statusColors[entry.key],
                    //                           ),
                    //                         ),
                    //                       ),
                    //                       Text(
                    //                         '${entry.value}',
                    //                         style: TextStyle(
                    //                           fontWeight: FontWeight.bold,
                    //                           fontSize: 18,
                    //                           color: Colors.black87,
                    //                         ),
                    //                       ),
                    //                       const SizedBox(width: 4),
                    //                       Text(
                    //                         'Orders',
                    //                         style: TextStyle(
                    //                           fontSize: 13,
                    //                           color: Colors.grey.shade700,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           );
                    //         }).toList(),
                    //       );
                    //     },
                    //   ),
                    // ),
                    const SizedBox(height: 24),

                    // --- User Stats ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildUserStatCard(
                            'Active Users',
                            userOverview['active'] as int,
                            Icons.person_rounded,
                            Colors.indigo.shade400,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildUserStatCard(
                            'Inactive Users',
                            userOverview['inactive'] as int,
                            Icons.person_off_rounded,
                            Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- Quick Actions ---
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.6,
                      children: quickActions.map((action) {
                        final Color btnColor =
                            action['color'] ?? Colors.indigo.shade50;
                        return ElevatedButton.icon(
                          icon: Icon(action['icon'] as IconData, size: 18),
                          label: Text(
                            action['label'] as String,
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnColor,
                            foregroundColor: Colors.indigo.shade600,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                          onPressed: () {
                            if (action['action'] == 'add_customer') {
                              Future.microtask(
                                () => showUserCreationDialog(context),
                              );
                            } else {
                              Navigator.pushNamed(context, action['route']);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // --- Recent Orders ---

                    // ...existing code...
                    Text(
                      'Recent Orders',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _ordersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Column(
                            children: List.generate(
                              3,
                              (i) => Card(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List.generate(
                                      4,
                                      (i) => Container(
                                        height: 14,
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError ||
                            snapshot.data == null ||
                            snapshot.data!['orders'] == null) {
                          print(
                            'Dashboard Recent Orders Error: ${snapshot.error}',
                          );
                          return Center(
                            child: Text('Error loading recent orders'),
                          );
                        }
                        final orders = List<Map<String, dynamic>>.from(
                          snapshot.data!['orders'],
                        );
                        print(
                          'Dashboard Recent Orders count: ${orders.length}',
                        );
                        if (orders.isNotEmpty)
                          print('First order: ${orders.first}');
                        if (orders.isEmpty) {
                          print('No recent orders found');
                          return Center(child: Text('No recent orders found'));
                        }
                        return Column(
                          children: List.generate(orders.length > 4 ? 4 : orders.length, (
                            idx,
                          ) {
                            final order = orders[idx];
                            print('Recent Order[$idx]: $order');
                            final customer = order['customer'] ?? {};
                            final user = customer['userId'] ?? {};
                            final address = user['address'] ?? {};
                            final items = order['items'] ?? [];
                            final payments = order['payments'] ?? [];
                            final paidAmount = order['paidAmount'] ?? 0;
                            final balanceAmount = order['balanceAmount'] ?? 0;
                            final paymentType = order['paymentType'] ?? '';
                            final paymentMethod = order['paymentMethod'] ?? '';
                            final orderNote = order['orderNote'] ?? '';
                            final transportName = order['transportName'] ?? '';
                            final orderType = order['orderType'] ?? '';
                            final orderDate = order['orderDate'] ?? '';
                            final status = order['status'] ?? '';
                            final total = order['total'] ?? 0;
                            final trackingId = order['trackingId'] ?? '';
                            final deliveryVendor =
                                order['deliveryVendor'] ?? '';

                            final deliveredPcs = items.fold<int>(
                              0,
                              (int sum, dynamic item) =>
                                  sum + ((item['deliveredPcs'] ?? 0) as int),
                            );
                            final totalPcs = items.fold<int>(
                              0,
                              (int sum, dynamic item) =>
                                  sum +
                                  (((item['quantity'] ?? 1) as int) *
                                      ((item['pcsInSet'] ?? 1) as int)),
                            );
                            final setsCount = items.fold<int>(
                              0,
                              (int sum, dynamic item) =>
                                  sum + ((item['quantity'] ?? 1) as int),
                            );

                            Color statusColor(String status) {
                              switch (status.toLowerCase()) {
                                case 'pending':
                                  return Colors.yellow.shade700;
                                case 'packed':
                                  return Colors.blue;
                                case 'cancelled':
                                  return Colors.red;
                                case 'confirmed':
                                  return Colors.indigo;
                                case 'delivered':
                                  return Colors.green;
                                default:
                                  return Colors.grey;
                              }
                            }

                            return Card(
                              color: Colors.white,
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  final orderId =
                                      order['_id'] ?? order['id'] ?? '';
                                  if (orderId.toString().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Order ID not found!'),
                                      ),
                                    );
                                    return;
                                  }
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OrderDetailsPage(orderId: orderId),
                                      settings: RouteSettings(
                                        arguments: orders,
                                      ),
                                    ),
                                  );
                                  if (result == true) _refreshData();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Order Number, Date, Type, Status
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order['orderNumber'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.indigo.shade700,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor(status),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            orderDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            orderType,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      // Customer Info
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    size: 14,
                                                    color: Colors.indigo,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    customer['name'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                              if ((customer['phone'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    customer['phone'],
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              if ((customer['email'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Text(
                                                  customer['email'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              if ((customer['deliveryAddress'] ??
                                                      '')
                                                  .toString()
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    customer['deliveryAddress']
                                                                .toString()
                                                                .length >
                                                            30
                                                        ? customer['deliveryAddress']
                                                                  .toString()
                                                                  .substring(
                                                                    0,
                                                                    30,
                                                                  ) +
                                                              '...'
                                                        : customer['deliveryAddress']
                                                              .toString(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              if (transportName
                                                  .toString()
                                                  .isNotEmpty)
                                                Text(
                                                  'Transport: $transportName',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              Row(
                                                children: [
                                                  Text(
                                                    deliveryVendor.isNotEmpty
                                                        ? deliveryVendor
                                                        : '',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.indigo,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    deliveryVendor.isNotEmpty
                                                        ? ' • '
                                                        : ' ',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.indigo,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    trackingId.isNotEmpty
                                                        ? trackingId
                                                        : 'No tracking',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.indigo,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Paid: ₹${paidAmount is num ? paidAmount.toStringAsFixed(2) : paidAmount}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              if (balanceAmount is num &&
                                                      balanceAmount > 0 ||
                                                  balanceAmount < 0)
                                                Text(
                                                  'Balance: ₹${balanceAmount.toString()}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              SizedBox(width: 10),
                                              Text(
                                                paymentMethod,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              Text(
                                                '$setsCount set${setsCount > 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              Text(
                                                '$totalPcs pieces',
                                                style: TextStyle(
                                                  color: Colors.indigo,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                '$deliveredPcs delivered',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),

                                      if (orderNote.toString().isNotEmpty)
                                        Text(
                                          'Note: ${orderNote.length > 25 ? orderNote.substring(0, 25) + '...' : orderNote}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // --- Floating Action Button ---
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 72,
            child: FloatingActionButton(
              backgroundColor: Colors.indigo.shade500,
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Quick Actions',
              onPressed: _showDashboardActionsSheet,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

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
