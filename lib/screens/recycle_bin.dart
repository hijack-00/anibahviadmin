import 'package:flutter/material.dart';
import 'package:anibhaviadmin/widgets/universal_scaffold.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({Key? key}) : super(key: key);

  @override
  _RecycleBinPageState createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _deletedOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDeletedOrders();
    _searchController.addListener(_filterOrders);
  }

  Future<void> _fetchDeletedOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await AppDataRepo()
          .fetchAllRecycledOrdersByAdminWithPagination(page: 1, limit: 100);

      if (resp['success'] == true && resp['orders'] is List) {
        final list = List<Map<String, dynamic>>.from(resp['orders']);
        setState(() {
          _deletedOrders = list;
          _filteredOrders = list;
        });
      } else {
        setState(() {
          _deletedOrders = [];
          _filteredOrders = [];
          _error = resp['message'] ?? 'Failed to load recycled orders';
        });
      }
    } catch (e) {
      setState(() {
        _deletedOrders = [];
        _filteredOrders = [];
        _error = 'Error loading deleted orders: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _deletedOrders.where((order) {
        final customer = order['customer'] ?? {};
        final orderNumber = (order['orderNumber'] ?? '')
            .toString()
            .toLowerCase();
        final customerName = (customer['name'] ?? '').toString().toLowerCase();
        final customerPhone = (customer['phone'] ?? '')
            .toString()
            .toLowerCase();
        final email = (customer['email'] ?? '').toString().toLowerCase();
        return orderNumber.contains(query) ||
            customerName.contains(query) ||
            customerPhone.contains(query) ||
            email.contains(query);
      }).toList();
    });
  }

  // Future<void> _restoreOrder(Map<String, dynamic> order) async {
  //   final orderId = (order['_id'] ?? order['id'] ?? '').toString();
  //   if (orderId.isEmpty) return;

  //   // show loading dialog
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => const Center(child: CircularProgressIndicator()),
  //   );

  //   try {
  //     final resp = await AppDataRepo().moveOrderToOrder(orderId);
  //     Navigator.of(context, rootNavigator: true).pop(); // close loader

  //     final msg = (resp['message'] ?? resp['data']?['message'] ?? 'Done')
  //         .toString();
  //     final ok =
  //         (resp['success'] == true ||
  //         resp['status'] == 200 ||
  //         resp['status'] == 201);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(msg),
  //         backgroundColor: ok ? Colors.green : Colors.redAccent,
  //       ),
  //     );

  //     if (ok) {
  //       await _fetchDeletedOrders();
  //     }
  //   } catch (e) {
  //     Navigator.of(context, rootNavigator: true).pop();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
  //     );
  //   }
  // }

  Future<void> _restoreOrder(Map<String, dynamic> order) async {
    final orderId = (order['_id'] ?? order['id'] ?? '').toString();
    if (orderId.isEmpty) return;

    // Confirm restore
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore order'),
        content: const Text('Are You Sure want to Restore this Order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await AppDataRepo().moveOrderToOrder(orderId);
      Navigator.of(context, rootNavigator: true).pop(); // close loader

      final msg = (resp['message'] ?? resp['data']?['message'] ?? 'Done')
          .toString();
      final ok =
          (resp['success'] == true ||
          resp['status'] == true ||
          resp['status'] == 200 ||
          resp['status'] == 201 ||
          resp['statusCode'] == 200);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? Colors.green : Colors.redAccent,
        ),
      );

      if (ok) {
        await _fetchDeletedOrders(); // refresh list after restore
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deletePermanently(Map<String, dynamic> order) async {
    final orderId = (order['_id'] ?? order['id'] ?? '').toString();
    if (orderId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently'),
        content: const Text(
          'This will permanently delete the order. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // final resp = await AppDataRepo().deleteOrderById(orderId);
      final resp = await AppDataRepo().deleteOrderById(orderId);

      Navigator.of(context, rootNavigator: true).pop(); // close loader

      final msg = (resp['message'] ?? 'Deleted').toString();
      // final ok = (resp['success'] == true || resp['status'] == 200);
      final ok =
          (resp['success'] == true ||
          resp['status'] == true ||
          resp['status'] == 200 ||
          resp['statusCode'] == 200);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok ? Colors.green : Colors.redAccent,
        ),
      );

      if (ok) {
        await _fetchDeletedOrders();
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UniversalScaffold(
      selectedIndex: 0,
      appIcon: Icons.delete_forever_rounded,
      title: 'Recycle Bin',
      body: RefreshIndicator(
        onRefresh: _fetchDeletedOrders,
        color: Colors.indigo,
        child: Container(
          color: const Color(0xFFF3F6FF),
          child: Column(
            children: [
              /// SEARCH BAR
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search deleted orders...",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.indigo.shade100),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.indigo),
                      )
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : _filteredOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'No deleted orders found.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredOrders.length,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                          bottom: 20,
                        ),
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final customer = order['customer'] ?? {};
                          final user = customer['userId'] ?? {};
                          final items = order['items'] as List? ?? [];
                          final total = order['total'] ?? 0.0;
                          final orderNumber = order['orderNumber'] ?? '';
                          final orderDate = order['orderDate'] ?? '';
                          final status = order['status'] ?? '';

                          String customerName =
                              user['name'] ?? customer['name'] ?? "Unknown";
                          String customerPhone =
                              user['phone'] ?? customer['phone'] ?? "N/A";
                          String customerEmail =
                              user['email'] ?? customer['email'] ?? "N/A";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.06),
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.indigo.shade400,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// HEADER - Order ID + Date
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        14,
                                        16,
                                        0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            orderNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          Text(
                                            orderDate.toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    /// CUSTOMER DETAILS
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _infoRow(
                                            Icons.person,
                                            "Customer",
                                            customerName,
                                          ),
                                          _infoRow(
                                            Icons.phone,
                                            "Phone",
                                            customerPhone,
                                          ),
                                          _infoRow(
                                            Icons.mail,
                                            "Email",
                                            customerEmail,
                                          ),
                                          _infoRow(
                                            Icons.shopping_bag,
                                            "Items",
                                            "${items.length} items",
                                          ),
                                          _infoRow(
                                            Icons.currency_rupee,
                                            "Total",
                                            total is num
                                                ? total.toStringAsFixed(2)
                                                : total,
                                          ),
                                          _infoRow(
                                            Icons.info,
                                            "Status",
                                            status,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Colors.grey.shade200,
                                    ),

                                    /// BUTTONS ROW (Restore + Delete)
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                side: BorderSide(
                                                  color: Colors.indigo.shade300,
                                                ),
                                                foregroundColor: Colors.indigo,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _restoreOrder(order),
                                              icon: const Icon(Icons.restore),
                                              label: const Text("Restore"),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                side: BorderSide(
                                                  color: Colors.red.shade300,
                                                ),
                                                foregroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _deletePermanently(order),
                                              icon: const Icon(
                                                Icons.delete_forever,
                                              ),
                                              label: const Text("Delete"),
                                            ),
                                          ),
                                        ],
                                      ),
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
      ),
    );
  }

  /// Small helper widget for displaying data rows
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.indigo.shade400),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
