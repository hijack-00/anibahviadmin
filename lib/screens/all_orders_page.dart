import 'dart:convert';

import 'package:anibhaviadmin/services/api_service.dart';
import 'package:anibhaviadmin/widgets/barcode_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_data_repo.dart';
import 'order_details_page.dart';
import 'universal_navbar.dart';
import 'package:intl/intl.dart';

// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> with RouteAware {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

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
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch from new endpoint and response structure
      final response = await ApiService().fetchAllOrdersByAdminWithPagination(
        page: 1,
        limit: 1000,
      );
      if (response['success'] == true && response['orders'] is List) {
        _orders = List<Map<String, dynamic>>.from(response['orders']);
      } else {
        _orders = [];
        _error = response['message'] ?? 'Error loading orders';
      }
    } catch (e) {
      _error = 'Error loading orders';
      _orders = [];
    }
    setState(() {
      _loading = false;
    });
  }

  void _onNavTap(int index) {
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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    return _orders.where((order) {
      final shipping = order['shippingAddress'] ?? {};
      final name = (shipping['name'] ?? '').toString().toLowerCase();
      final phone = (shipping['phone'] ?? '').toString().toLowerCase();
      final id = (order['orderUniqueId'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          id.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // Replace your appBar property in Scaffold with this:
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
                children: [
                  const Icon(Icons.list_alt, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'All Orders',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: Colors.indigo,
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shadowColor: Colors.indigo.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query.toLowerCase();
                      });
                    },
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name, order number, or phone',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.indigo.shade400,
                      ),
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // 📦 MAIN CONTENT
            Expanded(
              child: _loading
                  ? ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, idx) {
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredOrders.length,
                      separatorBuilder: (_, __) => SizedBox(height: 6),

                      itemBuilder: (context, idx) {
                        final order = _filteredOrders[idx];
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
                        final deliveryVendor = order['deliveryVendor'] ?? '';

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
                              // Some orders may not have '_id', try 'order['_id']' or fallback to 'order['id']'
                              final orderId = order['_id'] ?? order['id'] ?? '';
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
                                    arguments: _orders,
                                  ), // Pass all orders here
                                ),
                              );
                              if (result == true) _fetchOrders();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          if ((customer['phone'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
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
                                              padding: const EdgeInsets.only(
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
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),

                                              Text(
                                                deliveryVendor.isNotEmpty
                                                    ? ' • '
                                                    : ' ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.indigo,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                trackingId.isNotEmpty
                                                    ? trackingId
                                                    : 'No tracking',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.indigo,
                                                  fontWeight: FontWeight.w500,
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _OrderActionButton(
                                        icon: Icons.note_alt_outlined,
                                        label: 'Note',
                                        color: Colors.orange.shade600,
                                        onPressed: () async {
                                          final orderId =
                                              order['_id'] ?? order['id'] ?? '';
                                          String currentNote =
                                              order['orderNote'] ?? '';
                                          final TextEditingController
                                          noteController =
                                              TextEditingController(
                                                text: currentNote,
                                              );

                                          final result = await showDialog<String>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                'Edit Order Note',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              content: TextField(
                                                controller: noteController,
                                                maxLines: 3,
                                                style: TextStyle(fontSize: 13),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Enter order note...',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                ),
                                                ElevatedButton(
                                                  child: Text(
                                                    'Submit',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.indigo,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: () async {
                                                    final newNote =
                                                        noteController.text
                                                            .trim();
                                                    if (newNote.isEmpty) return;
                                                    Navigator.of(
                                                      ctx,
                                                    ).pop(newNote);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );

                                          if (result != null &&
                                              result != currentNote) {
                                            // Call update note API
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (ctx) => Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                            try {
                                              final resp = await AppDataRepo()
                                                  .updateOrderNoteByAdmin(
                                                    orderId,
                                                    result,
                                                  );
                                              Navigator.of(
                                                context,
                                              ).pop(); // Remove loading dialog
                                              if (resp['success'] == true) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Order note updated successfully.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                await _fetchOrders();
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      resp['message'] ??
                                                          'Failed to update note',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),

                                      SizedBox(width: 6),
                                      if (!(status.toString().toLowerCase() ==
                                              'cancelled' ||
                                          status.toString().toLowerCase() ==
                                              'delivered' ||
                                          status.toString().toLowerCase() ==
                                              'returned'))
                                        _OrderActionButton(
                                          icon: Icons.info_outline,
                                          label: 'Status',
                                          color: Colors.indigo.shade600,
                                          // ...inside your Status button onPressed...
                                          onPressed: () async {
                                            final orderId =
                                                order['_id'] ??
                                                order['id'] ??
                                                '';
                                            final currentStatus =
                                                (order['status'] ?? '')
                                                    .toString()
                                                    .toLowerCase();
                                            final orderNumber =
                                                order['orderNumber'] ?? '';

                                            if (currentStatus == 'packed') {
                                              await showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    'Status Update',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    'Please Create Delivery Challan!',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      child: Text(
                                                        'OK',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }

                                            List<String> statusOptions = [];
                                            if (currentStatus == 'pending') {
                                              statusOptions = [
                                                'Packed',
                                                'Cancelled',
                                              ];
                                            } else if (currentStatus ==
                                                'shipped') {
                                              statusOptions = [
                                                'Delivered',
                                                'Cancelled',
                                              ];
                                            }

                                            String selectedStatus =
                                                statusOptions.isNotEmpty
                                                ? statusOptions.first
                                                : '';
                                            String trackingId = '';
                                            String deliveryVendor = '';

                                            if (statusOptions.isNotEmpty) {
                                              final result = await showDialog<Map<String, dynamic>>(
                                                context: context,
                                                builder: (ctx) => Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          20.0,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'Update Order Status',
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.close,
                                                                size: 18,
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop(),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Order: $orderNumber',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              'Current Status: ',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 2,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .yellow
                                                                    .shade100,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                (order['status'] ??
                                                                        '')
                                                                    .toString(),
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .orange
                                                                      .shade800,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 16),
                                                        Text(
                                                          'New Status',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        DropdownButtonFormField<
                                                          String
                                                        >(
                                                          value: selectedStatus,
                                                          items: statusOptions
                                                              .map(
                                                                (
                                                                  s,
                                                                ) => DropdownMenuItem(
                                                                  value: s,
                                                                  child: Text(
                                                                    s,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                          onChanged: (val) {
                                                            if (val != null)
                                                              selectedStatus =
                                                                  val;
                                                          },
                                                          decoration: InputDecoration(
                                                            border:
                                                                OutlineInputBorder(),
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            isDense: true,
                                                          ),
                                                        ),
                                                        SizedBox(height: 18),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .black,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  minimumSize:
                                                                      Size(
                                                                        0,
                                                                        38,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  textStyle:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Cancel',
                                                                ),
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                      ctx,
                                                                    ).pop(),
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue
                                                                          .shade700,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  minimumSize:
                                                                      Size(
                                                                        0,
                                                                        38,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  textStyle:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Update Status',
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop({
                                                                    'newStatus':
                                                                        selectedStatus,
                                                                    'trackingId':
                                                                        trackingId,
                                                                    'deliveryVendor':
                                                                        deliveryVendor,
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );

                                              if (result != null &&
                                                  result['newStatus'] != null) {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (ctx) => Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                                try {
                                                  final resp = await AppDataRepo()
                                                      .changeOrderStatusByAdmin(
                                                        orderId: orderId,
                                                        newStatus:
                                                            result['newStatus'],
                                                        trackingId:
                                                            result['trackingId'] ??
                                                            '',
                                                        deliveryVendor:
                                                            result['deliveryVendor'] ??
                                                            '',
                                                      );
                                                  Navigator.of(
                                                    context,
                                                  ).pop(); // Remove loading
                                                  if (resp['success'] == true) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          resp['message'] ??
                                                              'Order status updated.',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                    await _fetchOrders();
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          resp['message'] ??
                                                              'Failed to update status',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: $e',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      SizedBox(width: 6),
                                      if (balanceAmount is num &&
                                          balanceAmount != 0)
                                        _OrderActionButton(
                                          icon: Icons.payments_outlined,
                                          label: 'Payment',
                                          color: Colors.green.shade600,
                                          onPressed: () async {
                                            final orderId =
                                                order['_id'] ??
                                                order['id'] ??
                                                '';
                                            final orderNumber =
                                                order['orderNumber'] ?? '';
                                            final totalAmount =
                                                order['total'] ?? 0;
                                            final alreadyPaid =
                                                order['paidAmount'] ?? 0;
                                            final balanceDue =
                                                order['balanceAmount'] ?? 0;

                                            String paymentMethod = 'Cash';
                                            final paymentMethods = [
                                              'Cash',
                                              'UPI',
                                              'Credit Card',
                                              'Bank Transfer',
                                            ];
                                            final paymentNotesController =
                                                TextEditingController();
                                            final paymentAmountController =
                                                TextEditingController();

                                            final result = await showDialog<Map<String, dynamic>>(
                                              context: context,
                                              builder: (ctx) => Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    20.0,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'Update Payment',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.close,
                                                                size: 18,
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop(),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Order: $orderNumber',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        SizedBox(height: 10),
                                                        Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Total Amount:',
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  '₹${totalAmount.toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Already Paid:',
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  '₹${alreadyPaid.toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .green,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Balance Due:',
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                ),
                                                                Text(
                                                                  '₹${balanceDue.toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .red,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 16),
                                                        Text(
                                                          'Additional Payment Amount (₹)',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        TextField(
                                                          controller:
                                                              paymentAmountController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration: InputDecoration(
                                                            hintText:
                                                                'Enter payment amount',
                                                            border:
                                                                OutlineInputBorder(),
                                                            isDense: true,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        SizedBox(height: 12),
                                                        Text(
                                                          'Payment Method',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        DropdownButtonFormField<
                                                          String
                                                        >(
                                                          value: paymentMethod,
                                                          items: paymentMethods
                                                              .map(
                                                                (
                                                                  m,
                                                                ) => DropdownMenuItem(
                                                                  value: m,
                                                                  child: Text(
                                                                    m,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                          onChanged: (val) {
                                                            if (val != null)
                                                              paymentMethod =
                                                                  val;
                                                          },
                                                          decoration:
                                                              InputDecoration(
                                                                border:
                                                                    OutlineInputBorder(),
                                                                isDense: true,
                                                              ),
                                                        ),
                                                        SizedBox(height: 12),
                                                        Text(
                                                          'Notes (Optional)',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        SizedBox(height: 6),
                                                        TextField(
                                                          controller:
                                                              paymentNotesController,
                                                          decoration: InputDecoration(
                                                            hintText:
                                                                'Payment notes...',
                                                            border:
                                                                OutlineInputBorder(),
                                                            isDense: true,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 2,
                                                        ),
                                                        SizedBox(height: 18),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .black,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  minimumSize:
                                                                      Size(
                                                                        0,
                                                                        38,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  textStyle:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Cancel',
                                                                ),
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                      ctx,
                                                                    ).pop(),
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green
                                                                          .shade700,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  minimumSize:
                                                                      Size(
                                                                        0,
                                                                        38,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  textStyle:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Update Payment',
                                                                ),
                                                                onPressed: () {
                                                                  final amt =
                                                                      double.tryParse(
                                                                        paymentAmountController
                                                                            .text,
                                                                      ) ??
                                                                      0.0;
                                                                  if (amt <=
                                                                      0) {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                              'Enter a valid payment amount',
                                                                            ),
                                                                      ),
                                                                    );
                                                                    return;
                                                                  }
                                                                  Navigator.of(
                                                                    ctx,
                                                                  ).pop({
                                                                    'additionalPayment':
                                                                        amt,
                                                                    'paymentMethod':
                                                                        paymentMethod,
                                                                    'notes': paymentNotesController
                                                                        .text
                                                                        .trim(),
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );

                                            if (result != null &&
                                                result['additionalPayment'] !=
                                                    null) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (ctx) => Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                              try {
                                                final resp = await AppDataRepo()
                                                    .updateOrderPaymentByAdmin(
                                                      orderId: orderId,
                                                      additionalPayment:
                                                          result['additionalPayment'],
                                                      paymentMethod:
                                                          result['paymentMethod'],
                                                      notes: result['notes'],
                                                    );
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Remove loading
                                                if (resp['success'] == true) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        resp['message'] ??
                                                            'Payment updated.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                  await _fetchOrders();
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        resp['message'] ??
                                                            'Failed to update payment',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                Navigator.of(context).pop();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                    ],
                                  ),

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
                      },
                    ),
            ),
          ],
        ),
      ),

      // ➕ Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Create Order',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: _CreateOrderSheet(),
            ),
          );
        },
      ),

      bottomNavigationBar: UniversalNavBar(selectedIndex: 1, onTap: _onNavTap),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _OrderActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(90, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      onPressed: onPressed,
    );
  }
}

class _ProductRateController {
  final TextEditingController controller;
  _ProductRateController(double value)
    : controller = TextEditingController(text: value.toStringAsFixed(2));
}

// --- Create Order Bottom Sheet ---
class _CreateOrderSheet extends StatefulWidget {
  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  // Customer
  List<Map<String, dynamic>> _allCustomers = [];
  Map<String, dynamic>? _selectedCustomer;
  String customerSearch = '';
  late TextEditingController redeemNowController;

  final Map<String, _ProductRateController> _rateControllers = {};

  Map<String, dynamic> deepCopyProduct(Map<String, dynamic> product) {
    return jsonDecode(jsonEncode(product)) as Map<String, dynamic>;
  }

  // Products
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  String barcodeInput = '';

  // Order Info
  String orderType = 'Offline';
  TextEditingController orderNoteController = TextEditingController();
  TextEditingController transportNameController = TextEditingController();

  // Points
  int availablePoints = 0;
  double pointValue = 0.5;
  int maxRedeemablePoints = 0;
  int redeemNow = 0;
  double discountValue = 0.0;

  // Payments
  List<Map<String, dynamic>> payments = [];
  String paymentMethod = 'Cash';
  TextEditingController paymentAmountController = TextEditingController();

  // Price
  double subtotal = 0.0;
  double totalPaid = 0.0;
  double balanceDue = 0.0;

  bool loading = false;

  String getProductKey(Map<String, dynamic> p) {
    if (p.containsKey('_id')) return p['_id'].toString();
    if (p.containsKey('productId')) {
      final id = p['productId'];
      if (id is Map && id['_id'] != null) return id['_id'].toString();
      return id.toString();
    }
    return '';
  }

  // ...inside _CreateOrderSheetState...

  void _printSelectedData() {
    print('Selected Customer:');
    print(_selectedCustomer);
    print('Selected Products:');
    for (var p in _selectedProducts) {
      print(p);
    }
  }

  void debugSelectedProducts() {
    print('--- Selected Products ---');
    for (var p in _selectedProducts) {
      print('ID: ${getProductId(p)}, Qty: ${p['quantity']}');
    }
    print('------------------------');
  }

  // Add this helper function:
  String getProductId(dynamic p) {
    final id = p['productId'];
    if (id is String) return id;
    if (id is Map && id['_id'] != null) return id['_id'].toString();
    return id?.toString() ?? '';
  }

  // Update _addProduct:
  // void _addProduct(Map<String, dynamic> product) {
  //   setState(() {
  //     final pid = getProductId(product);
  //     final idx = _selectedProducts.indexWhere((p) => getProductId(p) == pid);
  //     if (idx >= 0) {
  //       _selectedProducts[idx]['quantity'] += 1;
  //     } else {
  //       _selectedProducts.add({...product, 'quantity': 1});
  //     }

  //     _recalculatePrice();
  //   });
  // }
  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      final pid = getProductKey(product);
      final idx = _selectedProducts.indexWhere((p) => getProductKey(p) == pid);

      if (idx >= 0) {
        _selectedProducts[idx]['quantity'] =
            (_selectedProducts[idx]['quantity'] ?? 1) + 1;
      } else {
        final prodCopy = deepCopyProduct(product);
        prodCopy['quantity'] = 1;
        _selectedProducts.add(prodCopy);
      }

      _recalculatePrice();
    });
  }

  // Update _removeProduct:
  void _removeProduct(String pid) {
    setState(() {
      _selectedProducts.removeWhere((p) => getProductKey(p) == pid);
      _recalculatePrice();
      print(
        'After removal: ${_selectedProducts.map((p) => getProductKey(p)).toList()}',
      );
    });
  }

  // Update _updateProductQuantity:
  // void _updateProductQuantity(String pid, int delta) {
  //   final idx = _selectedProducts.indexWhere((p) => getProductKey(p) == pid);
  //   if (idx >= 0) {
  //     final newQty = (_selectedProducts[idx]['quantity'] ?? 1) + delta;
  //     print('Trying to set qty for $pid: $newQty');
  //     _selectedProducts[idx]['quantity'] = newQty.clamp(1, 999);
  //   }
  //   _recalculatePrice();
  // }

  void _updateProductQuantity(String pid, int delta) {
    final idx = _selectedProducts.indexWhere((p) => getProductKey(p) == pid);
    if (idx >= 0) {
      final product = _selectedProducts[idx];
      final int lotStock =
          int.tryParse(product['lotStock']?.toString() ?? '0') ?? 0;
      final int currentQty = (product['quantity'] ?? 1) is int
          ? (product['quantity'] ?? 1)
          : int.tryParse(product['quantity'].toString()) ?? 1;
      final int newQty = currentQty + delta;

      // Enforce lotStock limit
      if (newQty > lotStock) {
        print('Blocked increment: qty=$currentQty, lotStock=$lotStock');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot select more than available stock ($lotStock sets).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Enforce minimum quantity of 1
      product['quantity'] = newQty.clamp(1, lotStock > 0 ? lotStock : 999);
      print('Trying to set qty for $pid: ${product['quantity']}');
    }
    _recalculatePrice();
  }

  //Redeem Discount Points Calculation
  int calculateRedeemDiscountPoints(double billAmount, int totalPoints) {
    const double pointValue = 0.5;
    const double maxDiscountPercent = 2.5;

    double maxDiscount = (maxDiscountPercent / 100) * billAmount;
    double totalPointsValue = totalPoints * pointValue;

    double discountToApply = totalPointsValue >= maxDiscount
        ? maxDiscount
        : totalPointsValue;

    int pointsRedeemed = (discountToApply / pointValue).floor();

    return pointsRedeemed;
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchProducts();
    redeemNowController = TextEditingController(text: redeemNow.toString());

    // TODO: Fetch user points if needed
  }

  @override
  void dispose() {
    redeemNowController.dispose();
    for (final c in _rateControllers.values) {
      c.controller.dispose();
    }
    super.dispose();
  }

  void _setRedeemNow(int value, int maxRedeemable) {
    setState(() {
      redeemNow = value.clamp(0, maxRedeemable);
      redeemNowController.text = redeemNow.toString();
      discountValue = redeemNow * pointValue;
      _recalculatePrice();
    });
  }

  Future<void> _fetchCustomers() async {
    setState(() => loading = true);
    await AppDataRepo().loadAllUsers();
    setState(() {
      _allCustomers = AppDataRepo.users;
      loading = false;
    });
  }

  String formatK(num value) {
    if (value.abs() >= 10000) {
      double v = value / 1000;
      return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1) + 'k';
    }
    return value.toStringAsFixed(0);
  }

  Future<void> _fetchProducts() async {
    setState(() => loading = true);
    _allProducts = await AppDataRepo().fetchCatalogueProducts();
    setState(() => loading = false);
  }

  void _onSelectCustomer(Map<String, dynamic> customer) async {
    setState(() {
      _selectedCustomer = customer;
      availablePoints = 0;
      redeemNow = 0;
      discountValue = 0.0;
    });
    if (customer['_id'] != null) {
      final points = await AppDataRepo().fetchUserRewardPoints(customer['_id']);
      setState(() {
        availablePoints = points;
        // Optionally, set maxRedeemablePoints = points;
      });
    }
  }

  void _recalculatePrice() {
    subtotal = _selectedProducts.fold(0.0, (sum, p) {
      final price = (p['singlePicPrice'] ?? p['price'] ?? 0).toDouble();
      final pcs = int.tryParse(p['pcsInSet']?.toString() ?? '1') ?? 1;
      return sum + price * pcs * (p['quantity'] ?? 1);
    });
    discountValue = redeemNow * pointValue;
    totalPaid = payments.fold(
      0.0,
      (sum, p) => sum + (double.tryParse(p['amount'].toString()) ?? 0.0),
    );
    balanceDue = subtotal - discountValue - totalPaid;
  }

  void _addPayment() {
    final amt = double.tryParse(paymentAmountController.text) ?? 0.0;
    if (amt <= 0) return;

    final remaining = balanceDue;
    double addAmount = amt;

    if (amt > remaining) {
      addAmount = remaining;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment amount exceeds balance due. Only ₹${addAmount.toStringAsFixed(2)} will be added.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (addAmount > 0) {
      setState(() {
        payments.add({'method': paymentMethod, 'amount': addAmount});
        paymentAmountController.clear();
        _recalculatePrice();
      });
    }
  }

  void _submitOrder() async {
    if (_selectedCustomer == null || _selectedProducts.isEmpty) return;
    setState(() => loading = true);

    final orderData = {
      "customer": {
        "userId": _selectedCustomer!['_id'],
        "name": _selectedCustomer!['name'],
        "email": _selectedCustomer!['email'],
        "phone": _selectedCustomer!['phone'],
        "deliveryAddress": _selectedCustomer!['address']?['street'] ?? '',
      },
      "items": _selectedProducts
          .map(
            (p) => {
              "productId": p['productId'] is Map
                  ? p['productId']['_id']?.toString()
                  : p['productId']?.toString(),
              "name": p['productName'] ?? p['name'],
              "quantity": p['quantity'] is int
                  ? p['quantity']
                  : int.tryParse(p['quantity']?.toString() ?? '1') ?? 1,
              "singlePicPrice": p['singlePicPrice'] ?? p['price'],
              "pcsInSet": p['pcsInSet'] is int
                  ? p['pcsInSet']
                  : int.tryParse(p['pcsInSet']?.toString() ?? '1') ?? 1,
              "availableSizes": p['availableSizes'] ?? [],
              "images": p['images'] ?? [],
              "selectedSizes": p['selectedSizes'] ?? [],
            },
          )
          .toList(),
      "subtotal": subtotal,
      "pointsRedeemed": redeemNow,
      "pointsRedemptionValue": discountValue,
      "total": subtotal - discountValue,
      "status": "Pending",
      "paymentType": payments.length > 1
          ? "Partial Payment"
          : "Complete Payment",
      "paidAmount": totalPaid,
      "balanceAmount": balanceDue,
      "payments": payments
          .map(
            (p) => {
              "method": p['method'],
              "amount": p['amount'] is num
                  ? p['amount']
                  : double.tryParse(p['amount'].toString()) ?? 0.0,
            },
          )
          .toList(),
      "paymentMethod": payments.isNotEmpty ? payments[0]['method'] : '',
      "orderType": orderType,
      "orderDate": DateTime.now().toIso8601String().substring(0, 10),
      "trackingId": "",
      "deliveryVendor": "",
      "pointsEarned": 0,
      "pointsEarnedValue": 0,
      "orderNote": orderNoteController.text,
      "transportName": transportNameController.text,
    };
    try {
      final String bodyJson = jsonEncode(orderData);
      print('--- CREATE ORDER REQUEST START ---');
      print('Repository method: AppDataRepo.createOrderByAdmin');
      print('Request body JSON: $bodyJson');
      print('--- CREATE ORDER REQUEST END ---');
    } catch (e) {
      // fallback safe print
      print('Could not JSON encode orderData: $e');
      print('orderData (raw): $orderData');
    }

    try {
      final resp = await AppDataRepo().createOrderByAdmin(orderData);

      // Print response details
      print('--- CREATE ORDER RESPONSE START ---');
      print('Response object (AppDataRepo): $resp');
      try {
        print('Response JSON: ${jsonEncode(resp)}');
      } catch (_) {
        // ignore json encode errors for response
      }
      print('--- CREATE ORDER RESPONSE END ---');

      if (resp['success'] == true || resp['status'] == 201) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Order creation failed')),
        );
      }
    } catch (e, st) {
      print('Error while creating order: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }

    // try {

    //   final resp = await AppDataRepo().createOrderByAdmin(orderData);
    //   if (resp['success'] == true || resp['status'] == 201) {
    //     Navigator.of(context).pop(true);
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(resp['message'] ?? 'Order creation failed')),
    //     );
    //   }

    // } catch (e) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(SnackBar(content: Text('Error: $e')));
    // } finally {
    //   setState(() => loading = false);
    // }
  }

  Future<void> _showProductSelectionSheet() async {
    final Map<String, int> tempCounts = {};
    for (final p in _allProducts) {
      final pid = getProductKey(p);
      final selected = _selectedProducts.firstWhere(
        (sp) => getProductKey(sp) == pid,
        orElse: () => <String, dynamic>{},
      );
      tempCounts[pid] = selected.isNotEmpty ? (selected['quantity'] ?? 0) : 0;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = search.toLowerCase();
            final filtered = _allProducts.where((p) {
              String s(String? v) => (v ?? '').toLowerCase();
              return s(p['productName']).contains(q) ||
                  s(p['name']).contains(q) ||
                  s(p['parentProduct']).contains(q) ||
                  (p['price']?.toString() ?? '').toLowerCase().contains(q);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(height: 10),
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Product Sets',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText:
                            'Search by product name, parent product, or price...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      style: TextStyle(fontSize: 12),
                      onChanged: (v) => setModalState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth < 500
                              ? 1
                              : 2;
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 2.7,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final p = filtered[idx];
                              // final pid = p['productId']?.toString() ?? '';
                              // final count = tempCounts[pid] ?? 0;
                              final pid = getProductKey(p);

                              // Image
                              String? imageUrl;
                              final imgs = p['subProductImages'];
                              if (imgs is List &&
                                  imgs.isNotEmpty &&
                                  imgs.first is String &&
                                  (imgs.first as String).isNotEmpty) {
                                imageUrl = imgs.first as String;
                              }

                              // Sizes
                              final List sizes =
                                  (p['availableSizes'] ?? []) as List;

                              // Stock
                              final int stock = p['lotStock'] is int
                                  ? p['lotStock']
                                  : int.tryParse(
                                          p['lotStock']?.toString() ?? '0',
                                        ) ??
                                        0;
                              final int pcsInSet =
                                  int.tryParse(
                                    p['pcsInSet']?.toString() ?? '1',
                                  ) ??
                                  1;
                              final int setsAvailable = pcsInSet > 0
                                  ? (stock * pcsInSet)
                                  : 0;

                              return SizedBox(
                                height: 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (tempCounts[pid] ?? 0) > 0
                                        ? Colors.green.shade50
                                        : Colors.white,
                                    border: Border.all(
                                      color: (tempCounts[pid] ?? 0) > 0
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: (tempCounts[pid] ?? 0) > 0 ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image with 1:1 aspect ratio
                                        SizedBox(
                                          width:
                                              120, // Adjust for grid, but image will be 300x300 if space allows
                                          height: 120,
                                          child: Center(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  imageUrl != null &&
                                                      imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      width: 300,
                                                      height: 300,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) =>
                                                          Container(
                                                            width: 300,
                                                            height: 300,
                                                            color: Colors
                                                                .grey
                                                                .shade200,
                                                            child: Icon(
                                                              Icons.image,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                    )
                                                  : Container(
                                                      width: 300,
                                                      height: 300,
                                                      color:
                                                          Colors.grey.shade100,
                                                      child: Icon(
                                                        Icons.image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        // Product Info
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['productName'] ??
                                                  p['name'] ??
                                                  '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if ((p['parentProduct'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                'Parent: ${p['parentProduct']}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[700],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if ((p['lotNo'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                'Lot No. ${p['lotNo']}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            Text(
                                              '₹${p['price'] ?? p['singlePicPrice'] ?? ''} per piece',
                                              style: TextStyle(
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (pcsInSet > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '$pcsInSet pcs per set',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.blue[900],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (sizes.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                ),
                                                child: Wrap(
                                                  spacing: 4,
                                                  runSpacing: 2,
                                                  children: sizes
                                                      .map<Widget>(
                                                        (s) => Chip(
                                                          label: Text(
                                                            s.toString(),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              Colors
                                                                  .indigo
                                                                  .shade50,
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                              ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2.0,
                                              ),
                                              child: Text(
                                                'Stock: $setsAvailable pcs (${stock > 0 ? '$stock sets available' : '0 sets available'})',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),

                                            // Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    color: Colors.grey.shade100,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.remove,
                                                          size: 16,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            BoxConstraints(),
                                                        onPressed:
                                                            (tempCounts[pid] ??
                                                                    0) >
                                                                0
                                                            ? () {
                                                                setModalState(() {
                                                                  tempCounts[pid] =
                                                                      (tempCounts[pid] ??
                                                                          1) -
                                                                      1;
                                                                  if (tempCounts[pid]! <
                                                                      0)
                                                                    tempCounts[pid] =
                                                                        0;
                                                                  print(
                                                                    'Decremented $pid to ${tempCounts[pid]}',
                                                                  );
                                                                });
                                                              }
                                                            : null,
                                                      ),
                                                      Container(
                                                        width: 22,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Text(
                                                          '${tempCounts[pid] ?? 0}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.add,
                                                          size: 16,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            BoxConstraints(),
                                                        // Limit increment to available sets
                                                        onPressed:
                                                            (tempCounts[pid] ??
                                                                    0) <
                                                                (stock > 0
                                                                    ? stock
                                                                    : 0)
                                                            ? () {
                                                                setModalState(() {
                                                                  tempCounts[pid] =
                                                                      (tempCounts[pid] ??
                                                                          0) +
                                                                      1;
                                                                  print(
                                                                    'Incremented $pid to ${tempCounts[pid]}',
                                                                  );
                                                                });
                                                              }
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.done),
                      label: Text('Done', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 44),
                      ),

                      onPressed: () {
                        setState(() {
                          print('TempCounts before merge: $tempCounts');

                          _selectedProducts.removeWhere(
                            (sp) =>
                                tempCounts[getProductKey(sp)] == null ||
                                tempCounts[getProductKey(sp)] == 0,
                          );
                          tempCounts.forEach((pid, qty) {
                            if (qty > 0) {
                              final prod = _allProducts.firstWhere(
                                (p) => getProductKey(p) == pid,
                                orElse: () => <String, dynamic>{},
                              );

                              if (prod.isNotEmpty) {
                                final idx = _selectedProducts.indexWhere(
                                  (sp) => getProductKey(sp) == pid,
                                );

                                if (idx >= 0) {
                                  _selectedProducts[idx]['quantity'] = qty;
                                } else {
                                  final prodCopy = deepCopyProduct(prod);
                                  prodCopy['quantity'] = qty;
                                  _selectedProducts.add(prodCopy);
                                }
                              }
                            }
                          });

                          _recalculatePrice();

                          print(
                            'Selected after merge: ${_selectedProducts.map((p) => getProductKey(p)).toList()}',
                          );
                        });

                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(28, 28),
        shape: const CircleBorder(),
        backgroundColor: Colors.indigo,
      ),
      onPressed: onTap,
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int maxRedeemable = calculateRedeemDiscountPoints(
      subtotal,
      availablePoints,
    );
    return SafeArea(
      child: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),

                    Text(
                      'Create New Order',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Customer Section
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        String search = '';
                        final selected =
                            await showModalBottomSheet<Map<String, dynamic>>(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (ctx) {
                                return StatefulBuilder(
                                  builder: (context, setModalState) {
                                    final filtered = search.isEmpty
                                        ? _allCustomers
                                        : _allCustomers.where((c) {
                                            final name = (c['name'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                            final phone = (c['phone'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                            final email = (c['email'] ?? '')
                                                .toString()
                                                .toLowerCase();
                                            final q = search.toLowerCase();
                                            return name.contains(q) ||
                                                phone.contains(q) ||
                                                email.contains(q);
                                          }).toList();
                                    return SafeArea(
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.8,
                                        padding: const EdgeInsets.all(16.0),
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            Text(
                                              'Select Customer',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            TextField(
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Search by name, phone, or email...',
                                                prefixIcon: Icon(Icons.search),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              onChanged: (v) => setModalState(
                                                () => search = v,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            ...filtered.map(
                                              (c) => Card(
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color:
                                                        _selectedCustomer == c
                                                        ? Colors.indigo
                                                        : Colors.grey.shade200,
                                                    width:
                                                        _selectedCustomer == c
                                                        ? 2
                                                        : 1,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    radius: 28,
                                                    backgroundImage:
                                                        c['photo'] != null &&
                                                            c['photo']
                                                                .toString()
                                                                .isNotEmpty
                                                        ? NetworkImage(
                                                            c['photo'],
                                                          )
                                                        : null,
                                                    child:
                                                        (c['photo'] == null ||
                                                            c['photo']
                                                                .toString()
                                                                .isEmpty)
                                                        ? Icon(
                                                            Icons.person,
                                                            size: 28,
                                                            color: Colors.grey,
                                                          )
                                                        : null,
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                  ),
                                                  title: Text(
                                                    c['name'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if ((c['email'] ?? '')
                                                          .toString()
                                                          .isNotEmpty)
                                                        Text(c['email']),
                                                      if ((c['phone'] ?? '')
                                                          .toString()
                                                          .isNotEmpty)
                                                        Text(c['phone']),
                                                      if ((c['address']?['street'] ??
                                                              '')
                                                          .toString()
                                                          .isNotEmpty)
                                                        Text(
                                                          c['address']['street'],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  trailing:
                                                      _selectedCustomer == c
                                                      ? Icon(
                                                          Icons.check_circle,
                                                          color: Colors.indigo,
                                                        )
                                                      : null,
                                                  onTap: () =>
                                                      Navigator.of(ctx).pop(c),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                        if (selected != null) _onSelectCustomer(selected);
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.indigo.shade50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              // ...inside the Row in the main customer card...
                              CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    _selectedCustomer != null &&
                                        _selectedCustomer!['photo'] != null &&
                                        _selectedCustomer!['photo']
                                            .toString()
                                            .isNotEmpty
                                    ? NetworkImage(_selectedCustomer!['photo'])
                                    : null,
                                child:
                                    (_selectedCustomer == null ||
                                        _selectedCustomer!['photo'] == null ||
                                        _selectedCustomer!['photo']
                                            .toString()
                                            .isEmpty)
                                    ? Icon(
                                        Icons.person,
                                        size: 28,
                                        color: Colors.grey,
                                      )
                                    : null,
                                backgroundColor: Colors.grey.shade200,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _selectedCustomer == null
                                    ? Text(
                                        'Select Customer',
                                        style: TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedCustomer!['name'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if ((_selectedCustomer!['email'] ??
                                                  '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              _selectedCustomer!['email'],
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          if ((_selectedCustomer!['phone'] ??
                                                  '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              _selectedCustomer!['phone'],
                                              style: TextStyle(fontSize: 11),
                                            ),
                                        ],
                                      ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.indigo),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    // Order Information
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 600;

                            return Theme(
                              data: Theme.of(context).copyWith(
                                textTheme: Theme.of(context).textTheme.copyWith(
                                  bodyMedium: const TextStyle(fontSize: 11),
                                  bodySmall: const TextStyle(fontSize: 10),
                                  labelLarge: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                inputDecorationTheme:
                                    const InputDecorationTheme(
                                      labelStyle: TextStyle(fontSize: 11),
                                      hintStyle: TextStyle(fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 8,
                                      ),
                                    ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.indigo,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Order Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  isWide
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                isExpanded: true,
                                                value: orderType,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Order Type',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.shopping_bag,
                                                        size: 16,
                                                      ),
                                                    ),
                                                items: ['Offline', 'Online']
                                                    .map(
                                                      (o) => DropdownMenuItem(
                                                        value: o,
                                                        child: Text(
                                                          o,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (val) => setState(
                                                  () => orderType = val!,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: orderNoteController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Order Note',
                                                      border:
                                                          OutlineInputBorder(),
                                                      prefixIcon: Icon(
                                                        Icons.note_alt_outlined,
                                                        size: 16,
                                                      ),
                                                    ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                                minLines: 1,
                                                maxLines: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    transportNameController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Transport Name',
                                                  border: OutlineInputBorder(),
                                                  prefixIcon: Icon(
                                                    Icons
                                                        .local_shipping_outlined,
                                                    size: 16,
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                                minLines: 1,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              value: orderType,
                                              decoration: const InputDecoration(
                                                labelText: 'Order Type',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.shopping_bag,
                                                  size: 16,
                                                ),
                                              ),
                                              items: ['Offline', 'Online']
                                                  .map(
                                                    (o) => DropdownMenuItem(
                                                      value: o,
                                                      child: Text(
                                                        o,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) => setState(
                                                () => orderType = val!,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: orderNoteController,
                                              decoration: const InputDecoration(
                                                labelText: 'Order Note',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.note_alt_outlined,
                                                  size: 16,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              minLines: 1,
                                              maxLines: 2,
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller:
                                                  transportNameController,
                                              decoration: const InputDecoration(
                                                labelText: 'Transport Name',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.local_shipping_outlined,
                                                  size: 16,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              minLines: 1,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                          bodyMedium: const TextStyle(fontSize: 11),
                          bodySmall: const TextStyle(fontSize: 10),
                          labelLarge: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        inputDecorationTheme: const InputDecorationTheme(
                          labelStyle: TextStyle(fontSize: 11),
                          hintStyle: TextStyle(fontSize: 11),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                        ),
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.add_box_outlined,
                                    color: Colors.indigo,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add Product Sets',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Enter Barcode',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.qr_code,
                                          size: 16,
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 11),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => barcodeInput = v,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 15),
                                    label: const Text(
                                      'Submit',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(80, 38),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      final found = _allProducts.firstWhere(
                                        (p) => p['barcode'] == barcodeInput,
                                        orElse: () => <String, dynamic>{},
                                      );
                                      if (found.isNotEmpty) _addProduct(found);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.list_alt,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Manual Selection',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(90, 40),
                                        maximumSize: const Size(130, 45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: _showProductSelectionSheet,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Builder(
                                      builder: (sheetContext) => ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.qr_code_scanner,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Scan Barcode',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(90, 40),
                                          maximumSize: const Size(130, 45),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final barcode =
                                              await showDialog<String>(
                                                context: context,
                                                builder: (ctx) =>
                                                    const BarcodeScannerPage(),
                                              );
                                          if (!mounted) return;
                                          if (barcode != null &&
                                              barcode.isNotEmpty) {
                                            final found = _allProducts
                                                .firstWhere(
                                                  (p) =>
                                                      p['barcode']
                                                          ?.toString() ==
                                                      barcode,
                                                  orElse: () =>
                                                      <String, dynamic>{},
                                                );
                                            if (found.isNotEmpty) {
                                              final pid = getProductId(found);
                                              final idx = _selectedProducts
                                                  .indexWhere(
                                                    (p) =>
                                                        getProductId(p) == pid,
                                                  );
                                              if (idx >= 0) {
                                                setState(() {
                                                  _selectedProducts[idx]['quantity'] =
                                                      (_selectedProducts[idx]['quantity'] ??
                                                          1) +
                                                      1;
                                                  _recalculatePrice();
                                                });
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Product already added. Quantity increased!',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                setState(() {
                                                  _addProduct(found);
                                                });
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Product added!',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No product found for this barcode.',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                          bodyMedium: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          bodySmall: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                          labelLarge: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        inputDecorationTheme: const InputDecorationTheme(
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Products',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          ..._selectedProducts.map((p) {
                            final double perPieceRate =
                                (p['singlePicPrice'] ?? p['price'] ?? 0)
                                    .toDouble();
                            final int quantity = (p['quantity'] ?? 1) is int
                                ? (p['quantity'] ?? 1)
                                : int.tryParse(p['quantity'].toString()) ?? 1;
                            final int pcsInSet =
                                int.tryParse(
                                  p['pcsInSet']?.toString() ?? '1',
                                ) ??
                                1;
                            final String? imageUrl =
                                (p['subProductImages'] != null &&
                                    p['subProductImages'].isNotEmpty)
                                ? (p['subProductImages'][0] as String?)
                                : null;
                            final String pid = getProductKey(p);
                            final int lotStock =
                                int.tryParse(
                                  p['lotStock']?.toString() ?? '0',
                                ) ??
                                0;

                            if (!_rateControllers.containsKey(pid)) {
                              _rateControllers[pid] = _ProductRateController(
                                perPieceRate,
                              );
                            } else {
                              final ctrl = _rateControllers[pid]!;
                              final currentText = ctrl.controller.text;
                              if (double.tryParse(currentText) !=
                                  perPieceRate) {
                                ctrl.controller.text = perPieceRate
                                    .toStringAsFixed(2);
                              }
                            }

                            final rateController =
                                _rateControllers[pid]!.controller;

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // --- Product Image ---
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child:
                                              imageUrl != null &&
                                                  imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      Container(
                                                        width: 60,
                                                        height: 60,
                                                        child: const Icon(
                                                          Icons.image,
                                                          size: 26,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 60,
                                                  height: 60,
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 26,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 10),

                                        // --- Product Details ---
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      p['productName'] ??
                                                          p['name'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _removeProduct(
                                                          getProductKey(p),
                                                        );
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                              if (p['availableSizes'] != null)
                                                Wrap(
                                                  spacing: 4,
                                                  children: (p['availableSizes'] as List)
                                                      .map<Widget>(
                                                        (s) => Chip(
                                                          label: Text(
                                                            s,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                          backgroundColor:
                                                              Colors
                                                                  .blue
                                                                  .shade50,
                                                          materialTapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              Text(
                                                'Sets Available: $lotStock',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                'Total: $quantity set${quantity > 1 ? 's' : ''} × $pcsInSet pcs = ${quantity * pcsInSet} pcs',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              // --- Price and rate section ---
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    '₹',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.indigo,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  SizedBox(
                                                    width: 70,
                                                    child: TextField(
                                                      controller:
                                                          rateController,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(
                                                            r'^\d*\.?\d{0,2}',
                                                          ),
                                                        ),
                                                      ],
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                      ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                        color: Colors.indigo,
                                                      ),
                                                      onChanged: (val) {
                                                        final newRate =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            perPieceRate;
                                                        setState(() {
                                                          p['singlePicPrice'] =
                                                              newRate;
                                                          _recalculatePrice();
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'per piece',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    '₹${(perPieceRate * pcsInSet).toStringAsFixed(2)} / set',
                                                    style: const TextStyle(
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
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // --- Bottom row: Pcs/set & Qty ---
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // --- Pcs/set ---
                                        Column(
                                          children: [
                                            const Text(
                                              'Pcs/set:',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            Row(
                                              children: [
                                                _qtyButton(
                                                  icon: Icons.remove,
                                                  onTap: () {
                                                    setState(() {
                                                      if (pcsInSet > 1) {
                                                        p['pcsInSet'] =
                                                            (pcsInSet - 1)
                                                                .toString();
                                                        _recalculatePrice();
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text(
                                                  '$pcsInSet',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                _qtyButton(
                                                  icon: Icons.add,
                                                  onTap: () {
                                                    print(
                                                      'Current qty: $quantity, lotStock: $lotStock',
                                                    );
                                                    if (quantity < lotStock) {
                                                      setState(
                                                        () =>
                                                            _updateProductQuantity(
                                                              pid,
                                                              1,
                                                            ),
                                                      );
                                                    } else {
                                                      print(
                                                        'Blocked increment: qty=$quantity, lotStock=$lotStock',
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Cannot select more than available stock ($lotStock sets).',
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // --- Quantity ---
                                        Column(
                                          children: [
                                            const Text(
                                              'Qty:',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            Row(
                                              children: [
                                                _qtyButton(
                                                  icon: Icons.remove,
                                                  onTap: quantity > 1
                                                      ? () => setState(
                                                          () =>
                                                              _updateProductQuantity(
                                                                pid,
                                                                -1,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                Text(
                                                  '$quantity',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                _qtyButton(
                                                  icon: Icons.add,
                                                  onTap: (quantity < lotStock)
                                                      ? () => setState(
                                                          () =>
                                                              _updateProductQuantity(
                                                                pid,
                                                                1,
                                                              ),
                                                        )
                                                      : null, // Disabled when at lotStock
                                                ),
                                              ],
                                            ),
                                            if (quantity >= lotStock &&
                                                lotStock > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                ),
                                                child: Text(
                                                  'No more stock available',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        // Column(
                                        //   children: [
                                        //     const Text(
                                        //       'Qty:',
                                        //       style: TextStyle(fontSize: 10),
                                        //     ),
                                        //     Row(
                                        //       children: [
                                        //         _qtyButton(
                                        //           icon: Icons.remove,
                                        //           onTap: quantity > 1
                                        //               ? () => setState(
                                        //                   () =>
                                        //                       _updateProductQuantity(
                                        //                         pid,
                                        //                         -1,
                                        //                       ),
                                        //                 )
                                        //               : null,
                                        //         ),
                                        //         Text(
                                        //           '$quantity',
                                        //           style: const TextStyle(
                                        //             fontSize: 11,
                                        //           ),
                                        //         ),
                                        //         _qtyButton(
                                        //           icon: Icons.add,
                                        //           onTap: () => setState(
                                        //             () =>
                                        //                 _updateProductQuantity(
                                        //                   pid,
                                        //                   1,
                                        //                 ),
                                        //           ),
                                        //         ),
                                        //       ],
                                        //     ),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Redeem Points Section
                    Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                          bodyMedium: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          bodySmall: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                          labelLarge: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        inputDecorationTheme: const InputDecorationTheme(
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 600;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.stars,
                                        color: Colors.amber[700],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Redeem Points',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // --- Points and input section ---
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // --- Points info ---
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Available: ${formatK(availablePoints)} pts',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                'Value: ₹${formatK(availablePoints * pointValue)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                'Discount: ₹${formatK(discountValue)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                'Max Redeemable: $maxRedeemable pts',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // --- Redeem input + buttons ---
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 90,
                                                child: TextField(
                                                  controller:
                                                      redeemNowController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                  ),
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onChanged: (val) {
                                                    final n =
                                                        int.tryParse(val) ?? 0;
                                                    _setRedeemNow(
                                                      n,
                                                      maxRedeemable,
                                                    );
                                                  },
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(
                                                        28,
                                                        28,
                                                      ),
                                                      shape:
                                                          const CircleBorder(),
                                                      backgroundColor:
                                                          Colors.indigo,
                                                    ),
                                                    onPressed: redeemNow > 0
                                                        ? () => _setRedeemNow(
                                                            redeemNow - 1,
                                                            maxRedeemable,
                                                          )
                                                        : null,
                                                    child: const Icon(
                                                      Icons.remove,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(
                                                        28,
                                                        28,
                                                      ),
                                                      shape:
                                                          const CircleBorder(),
                                                      backgroundColor:
                                                          Colors.indigo,
                                                    ),
                                                    onPressed:
                                                        redeemNow <
                                                            maxRedeemable
                                                        ? () => _setRedeemNow(
                                                            redeemNow + 1,
                                                            maxRedeemable,
                                                          )
                                                        : null,
                                                    child: const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // --- Clear / Redeem buttons ---
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                            ),
                                            onPressed: redeemNow > 0
                                                ? () => _setRedeemNow(
                                                    0,
                                                    maxRedeemable,
                                                  )
                                                : null,
                                            child: const Text(
                                              'Clear',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                            ),
                                            onPressed: maxRedeemable > 0
                                                ? () => _setRedeemNow(
                                                    maxRedeemable,
                                                    maxRedeemable,
                                                  )
                                                : null,
                                            child: const Text(
                                              'Redeem',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Payment Information
                    Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                          bodyMedium: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          bodySmall: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                          labelLarge: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        inputDecorationTheme: const InputDecorationTheme(
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              bool isWide = constraints.maxWidth > 600;

                              // Filter payment methods to exclude already added ones
                              final allMethods = [
                                'Cash',
                                'UPI',
                                'Bank Transfer',
                                'Card',
                                'Net Banking',
                              ];
                              final usedMethods = payments
                                  .map((p) => p['method'] as String)
                                  .toSet();
                              final availableMethods = allMethods
                                  .where((m) => !usedMethods.contains(m))
                                  .toList();

                              // If current paymentMethod is not in availableMethods, reset it
                              if (!availableMethods.contains(paymentMethod) &&
                                  availableMethods.isNotEmpty) {
                                paymentMethod = availableMethods.first;
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ---- Header ----
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.payments_outlined,
                                        color: Colors.indigo,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Payment Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  if (availableMethods.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: DropdownButtonFormField<String>(
                                            isExpanded: true, // <-- Important!
                                            value:
                                                paymentMethod.isNotEmpty &&
                                                    availableMethods.contains(
                                                      paymentMethod,
                                                    )
                                                ? paymentMethod
                                                : availableMethods.first,
                                            decoration: InputDecoration(
                                              labelText: 'Method',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: const Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                              ),
                                            ),
                                            items: availableMethods
                                                .map(
                                                  (m) => DropdownMenuItem(
                                                    value: m,
                                                    child: Text(
                                                      m,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (val) => setState(
                                              () => paymentMethod = val ?? '',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: paymentAmountController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Amount',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.currency_rupee,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.add, size: 13),
                                          label: const Text(
                                            'Add',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(60, 30),

                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed:
                                              (balanceDue <= 0 ||
                                                  availableMethods.isEmpty)
                                              ? null
                                              : () {
                                                  final amt =
                                                      double.tryParse(
                                                        paymentAmountController
                                                            .text,
                                                      ) ??
                                                      0.0;
                                                  if (amt <= 0) return;
                                                  setState(() {
                                                    payments.add({
                                                      'method': paymentMethod,
                                                      'amount': amt,
                                                      'editing': false,
                                                    });
                                                    paymentAmountController
                                                        .clear();
                                                    if (availableMethods
                                                            .length >
                                                        1) {
                                                      paymentMethod =
                                                          availableMethods
                                                              .firstWhere(
                                                                (m) =>
                                                                    m !=
                                                                    paymentMethod,
                                                                orElse: () =>
                                                                    '',
                                                              );
                                                    } else {
                                                      paymentMethod = '';
                                                    }
                                                    _recalculatePrice();
                                                  });
                                                },
                                        ),
                                      ],
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        'All payment methods added.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 10),

                                  // ---- Warning Message ----
                                  if (balanceDue < 0)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Total paid cannot exceed balance due.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),

                                  // ---- Payment List (editable) ----
                                  ...payments.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final p = entry.value;
                                    final isEditing = p['editing'] == true;
                                    final TextEditingController editController =
                                        TextEditingController(
                                          text: p['amount'].toString(),
                                        );
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      title: Text(
                                        '${p['method']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          isEditing
                                              ? SizedBox(
                                                  width: 70,
                                                  child: TextField(
                                                    controller: editController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 6,
                                                          ),
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    onSubmitted: (val) {
                                                      final newAmt =
                                                          double.tryParse(
                                                            val,
                                                          ) ??
                                                          p['amount'];
                                                      setState(() {
                                                        payments[idx]['amount'] =
                                                            newAmt;
                                                        payments[idx]['editing'] =
                                                            false;
                                                        _recalculatePrice();
                                                      });
                                                    },
                                                  ),
                                                )
                                              : Text(
                                                  '₹${p['amount']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                          IconButton(
                                            icon: Icon(
                                              isEditing
                                                  ? Icons.check
                                                  : Icons.edit,
                                              color: Colors.indigo,
                                              size: 18,
                                            ),
                                            tooltip: isEditing
                                                ? 'Save'
                                                : 'Edit',
                                            onPressed: () {
                                              if (isEditing) {
                                                final newAmt =
                                                    double.tryParse(
                                                      editController.text,
                                                    ) ??
                                                    p['amount'];
                                                setState(() {
                                                  payments[idx]['amount'] =
                                                      newAmt;
                                                  payments[idx]['editing'] =
                                                      false;
                                                  _recalculatePrice();
                                                });
                                              } else {
                                                setState(() {
                                                  payments[idx]['editing'] =
                                                      true;
                                                });
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            tooltip: 'Remove Payment',
                                            onPressed: () {
                                              setState(() {
                                                // After removing, make method available again
                                                final removedMethod =
                                                    payments[idx]['method'];
                                                payments.removeAt(idx);
                                                if (paymentMethod.isEmpty &&
                                                    availableMethods
                                                        .isNotEmpty) {
                                                  paymentMethod =
                                                      availableMethods.first;
                                                }
                                                _recalculatePrice();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      dense: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Price Breakdown
                    Text(
                      'Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal:'),
                        Text('₹${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount:'),
                        Text('- ₹${discountValue.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${totalPaid.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Balance Due:'),
                        Text('₹${balanceDue.toStringAsFixed(2)}'),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _printSelectedData();
                            _submitOrder();
                          },
                          child: Text('Create Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
