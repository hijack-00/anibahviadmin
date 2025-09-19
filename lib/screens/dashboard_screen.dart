import 'package:anibhaviadmin/screens/all_orders_page.dart';
import 'package:anibhaviadmin/screens/order_details_page.dart';
import 'package:anibhaviadmin/screens/sales_reports_page.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';
import 'package:anibhaviadmin/screens/login_screen.dart';
import 'package:anibhaviadmin/widgets/add_product_form.dart';
import 'package:flutter/material.dart';
import 'dashboard_widgets.dart';
import '../dialogs/create_order_bottom_sheet.dart';
import '../dialogs/create_challan_dialog.dart';
import '../dialogs/create_return_dialog.dart';
import 'users_page.dart';
import 'universal_navbar.dart';

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
        // MediaQuery.of(context).size.width / 3 - 20,
        height: 120,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 11)),
            SizedBox(height: 8),
            Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => r.settings.name == '/dashboard');
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
              Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
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
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _drawerButton('Sales Order', '/sales-order'),
          Divider(),
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
          _drawerButton('WhatsApp Notifications', '/whatsapp-notifications'),
          Divider(),
          _drawerButton('Backend User Data', '/user-data'),
          Divider(),
          _drawerButton('Push Notifications', '/push-notifications'),
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

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
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
                Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.microtask(() => showCreateOrderBottomSheet(context));
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_box),
                      label: Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                       showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.microtask(() => showCreateChallanDialog(context));
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.assignment_return),
                      label: Text('Return Challan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Dashboard variables
  final List<Map<String, dynamic>> salesStats = [
    {
      'label': "Today's Sales",
      'value': '₹12,450',
      'change': '+8.2%',
      'changeColor': Colors.green,
      'icon': Icons.today,
      'bg': Colors.indigo.shade50
    },
    {
      'label': "Weekly Sales",
      'value': '₹89,420',
      'change': '+12.5%',
      'changeColor': Colors.green,
      'icon': Icons.calendar_view_week,
      'bg': Colors.blue.shade50
    },
    {
      'label': "Monthly Sales",
      'value': '₹3,24,680',
      'change': '+15.3%',
      'changeColor': Colors.green,
      'icon': Icons.calendar_month,
      'bg': Colors.purple.shade50
    },
  ];

  final Map<String, int> userOverview = {
    'active': 12,
    'inactive': 3,
  };

  final List<Map<String, dynamic>> quickActions = [
    {'label': 'Add Customer', 'icon': Icons.person_add, 'action': 'add_customer'},
    {'label': 'View Orders', 'icon': Icons.shopping_cart, 'route': '/orders'},
    // {'label': 'View Catalogue', 'icon': Icons.collections, 'route': '/catalogue'},
    {'label': 'View Challan', 'icon': Icons.local_shipping, 'route': '/challan'},
    {'label': 'Sales Report', 'icon': Icons.currency_rupee, 'route': '/reports'},
  ];

  final Map<String, Color> statusColors = {
    'pending': Colors.yellow.shade700,
    'shipped': Colors.blue,
    'confirmed': Colors.indigo,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
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
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo,
                  ),
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
                    // SALES SUMMARY BLOCK (dummy data)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SalesSummaryCard(
                          title: "Yearly Sales",
                          value: "₹12,00,000",
                          subtitle: "Revenue",
                          color: Colors.indigo.shade700,
                           onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalesReportsPage()),
        );
      },
                        ),
                        _SalesSummaryCard(
                          title: "Monthly Sales",
                          value: "₹1,00,000",
                          subtitle: "Revenue",
                          color: Colors.indigo.shade400,
                           onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalesReportsPage()),
        );
      },
                        ),
                        _SalesSummaryCard(
                          title: "Weekly Sales",
                          value: "₹25,000",
                          subtitle: "Revenue",
                          color: Colors.indigo.shade200,
                          onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalesReportsPage()),
        );
      },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Order stats
                    FutureBuilder<Map<String, dynamic>>(
                      future: _ordersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Skeleton loader for order stats
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(4, (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: Container(
                                  width: 100,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                ),
                              )),
                            ),
                          );
                        }
                        if (snapshot.hasError || snapshot.data == null || snapshot.data!['orders'] == null) {
                          return Center(child: Text('Error loading order stats'));
                        }
                        final orders = List<Map<String, dynamic>>.from(snapshot.data!['orders']);
                        final statusCounts = {
                          'pending': 0,
                          'shipped': 0,
                          'delivered': 0,
                          'cancelled': 0,
                        };
                        for (var order in orders) {
                          final statusRaw = order['orderStatus'] ?? '';
                          final status = statusRaw.toString().trim().toLowerCase();
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
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: statusCounts.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: OrderStatCard(
                                label: entry.key[0].toUpperCase() + entry.key.substring(1),
                                count: entry.value,
                                color: statusColors[entry.key]!,
                                icon: statusIcons[entry.key]!,
                              ),
                            )).toList(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Users', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    // User & Cart Overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UsersPage(showActive: true)),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UsersPage(showActive: false)),
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
                      ],
                    ),
                    SizedBox(height: 20),
                    // Quick Actions
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickActions.map((action) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: action['action'] == 'add_customer'
                              ? ElevatedButton.icon(
                                  icon: Icon(action['icon'] as IconData),
                                  label: Text(action['label'] as String),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Future.microtask(() => showUserCreationDialog(context));
                                    // Optionally refresh users or show a message
                                  },
                                )
                              : QuickActionButton(
                                  label: action['label'] as String,
                                  icon: action['icon'] as IconData,

                                  route: action['route'] as String,
                                ),
                        )).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Recent Orders from API
                    Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _ordersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Skeleton loader for recent orders
                          return Column(
                            children: List.generate(3, (i) => Card(
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: 120, height: 16, color: Colors.grey.shade200, margin: EdgeInsets.only(bottom: 8)),
                                    Container(width: 80, height: 12, color: Colors.grey.shade200, margin: EdgeInsets.only(bottom: 8)),
                                    Container(width: 180, height: 12, color: Colors.grey.shade200, margin: EdgeInsets.only(bottom: 8)),
                                    Container(width: 60, height: 12, color: Colors.grey.shade200),
                                  ],
                                ),
                              ),
                            )),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading orders'));
                        }
                        final data = snapshot.data;
                        final orders = (data != null && data['success'] == true && data['orders'] != null)
        // SALES SUMMARY CARD WIDGET
                          ? List<Map<String, dynamic>>.from(data['orders'])
                          : [];
                        if (orders.isEmpty) {
                          return Center(child: Text('No recent orders found'));
                        }
                        return Column(
                          children: [
                            ...orders.take(6).map((order) {
                              final shipping = order['shippingAddress'] ?? {};
                              String statusRaw = (order['orderStatus'] ?? '').toString().trim();
                              String status = statusRaw.toLowerCase() == 'order confirmed' ? 'Confirmed' : statusRaw;
                              String paymentStatus = (order['paymentStatus'] ?? '').toString().trim();
                              return Card(
                                color: Colors.white,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(orderId: order['_id']),
                                      ),
                                    );
                                    if (result == true) {
                                      _refreshData();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                child: Text(
                                                  order['orderUniqueId'] ?? '',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColors[status.toLowerCase()] ?? Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(12),
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
                                        if ((shipping['name'] ?? '').toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(shipping['name'] ?? '', style: TextStyle(fontSize: 14)),
                                          ),
                                        Row(
                                          children: [
                                            if ((shipping['phone'] ?? '').toString().isNotEmpty)
                                              Text(shipping['phone'] ?? '', style: TextStyle(fontSize: 13)),
                                            if ((shipping['phone'] ?? '').toString().isNotEmpty)
                                              Text(' • ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                            if ((shipping['email'] ?? '').toString().isNotEmpty)
                                              Text(shipping['email'] ?? '', style: TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                        if ((shipping['address'] ?? '').toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              '${shipping['address'] ?? ''}${shipping['city'] != null ? ', ' + shipping['city'] : ''}${shipping['state'] != null ? ', ' + shipping['state'] : ''}${shipping['country'] != null ? ', ' + shipping['country'] : ''}${shipping['postalCode'] != null ? ' - ' + shipping['postalCode'] : ''}',
                                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                                                    paymentStatus.toLowerCase().contains('fail') ? Colors.red :
                                                    paymentStatus.toLowerCase().contains('complete') ? Colors.indigo :
                                                    paymentStatus.toLowerCase().contains('partial') ? Colors.green : Colors.black,
                                                ),
                                              ),
                                            if (paymentStatus.isNotEmpty)
                                              Text(' • ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                            Text('₹${order['totalAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AllOrdersPage()),
                                    );
                                  },
                                  child: Text('View All'),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating button above bottom nav bar, using MediaQuery for correct spacing
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 72, // 56 for nav bar + 16 extra
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
