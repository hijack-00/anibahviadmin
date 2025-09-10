
import 'package:anibhaviadmin/screens/all_orders_page.dart';
import 'package:anibhaviadmin/screens/order_details_page.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';
import 'package:anibhaviadmin/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'dashboard_widgets.dart';
import 'users_page.dart';

class UniversalScaffold extends StatefulWidget {
  final int selectedIndex;
  final Widget body;
  UniversalScaffold({required this.selectedIndex, required this.body});

  @override
  State<UniversalScaffold> createState() => _UniversalScaffoldState();
}

class _UniversalScaffoldState extends State<UniversalScaffold> {
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/orders');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/users');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/invoices');
        break;
      
      
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
      body: widget.body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: widget.selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Challan'),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<Map<String, dynamic>> _ordersFuture;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final routeObserver = ModalRoute.of(context)?.navigator?.widget.observers.whereType<RouteObserver<PageRoute>>().firstOrNull;
    routeObserver?.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final routeObserver = ModalRoute.of(context)?.navigator?.widget.observers.whereType<RouteObserver<PageRoute>>().firstOrNull;
    routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this page
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final salesStats = [
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

    // Dummy user overview data (replace with API if available)
    final userOverview = {
      'active': 12,
      'inactive': 3,
    };

    // Quick actions for dashboard
    final quickActions = [
      {'label': 'Add Customer', 'icon': Icons.person_add, 'action': 'add_customer'},
      {'label': 'View Orders', 'icon': Icons.shopping_cart, 'route': '/orders'},
      {'label': 'View Catalogue', 'icon': Icons.collections, 'route': '/catalogue'},
      {'label': 'View Invoices', 'icon': Icons.receipt_long, 'route': '/invoices'},
      {'label': 'Sales Report', 'icon': Icons.currency_rupee, 'route': '/reports'},

    
    ];

    // Order status colors
    final statusColors = {
      'pending': Colors.yellow.shade700,
      'shipped': Colors.blue,
      'confirmed': Colors.indigo,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };


    // Sample data for pending job slips and sales orders
    // Recent orders data with more details

    return UniversalScaffold(
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
            // Dashboard Title & Refresh
            SizedBox(height: 4),
            Text(
              "Welcome back! Here's what's happening with your store today.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            // Sales Stats
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: salesStats.map((stat) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: KpiCard(
                    title: stat['label'] as String,
                    value: stat['value'] as String,
                    icon: stat['icon'] as IconData,
                  ),
                )).toList(),
              ),
            ),
            SizedBox(height: 20),
            // Orders at a Glance (dynamic from API)
            Text('Orders at a Glance', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
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
    );
  }
}
