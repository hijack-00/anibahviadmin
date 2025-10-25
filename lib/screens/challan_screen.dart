import 'dart:convert';
import 'package:flutter/services.dart';
import 'universal_navbar.dart';
import 'package:flutter/material.dart';
import '../widgets/searchable_dropdown.dart';
import 'package:fl_chart/fl_chart.dart'; // For graph view
import '../services/app_data_repo.dart';
import 'package:anibhaviadmin/widgets/searchable_dropdown.dart';
import 'package:shimmer/shimmer.dart';

class ChallanScreen extends StatefulWidget {
  const ChallanScreen({super.key});

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String searchText = '';
  String selectedStatus = 'All';
  DateTime? fromDate;
  DateTime? toDate;
  String selectedReport = 'Daily';
  bool showGraph = false;

  // API data
  int challanPage = 1;
  int challanTotalPages = 1;
  List<Map<String, dynamic>> challans = [];
  bool challanLoading = false;

  int returnPage = 1;
  int returnTotalPages = 1;
  List<Map<String, dynamic>> returns = [];
  bool returnLoading = false;

  List<String> statuses = [
    'All',
    'Pending',
    'Approved',
    'Completed',
    'Dispatched',
    'Rejected',
  ];

  List<String> reportTypes = ['Daily', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    fetchChallans();
    fetchReturns();
  }

  Future<void> fetchChallans() async {
    setState(() => challanLoading = true);
    final res = await AppDataRepo().fetchChallansWithPagination(
      page: challanPage,
      limit: 10,
    );
    challans = List<Map<String, dynamic>>.from(res['challans'] ?? []);
    challanTotalPages = res['totalPages'] ?? 1;
    setState(() => challanLoading = false);
  }

  Future<T?> _showFullHeightSelection<T>(
    BuildContext ctx, {
    required String title,
    required List<T> items,
    required String? currentLabel,
    required String Function(T) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bc) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.95, // open almost to top
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final it = items[idx];
                        final label = labelBuilder(it);
                        return ListTile(
                          title: Text(label),
                          selected: label == currentLabel,
                          onTap: () => Navigator.of(context).pop(it),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchReturns() async {
    setState(() => returnLoading = true);
    final res = await AppDataRepo().fetchReturnsWithPagination(
      page: returnPage,
      limit: 10,
    );
    returns = List<Map<String, dynamic>>.from(res['returns'] ?? []);
    returnTotalPages = res['totalPages'] ?? 1;
    setState(() => returnLoading = false);
  }

  List<Map<String, dynamic>> get filteredChallans {
    return challans.where((c) {
      final matchesSearch =
          (c['challanNumber'] ?? '').toString().toLowerCase().contains(
            searchText.toLowerCase(),
          ) ||
          (c['customer'] ?? '').toString().toLowerCase().contains(
            searchText.toLowerCase(),
          ) ||
          (c['orderNumber'] ?? '').toString().toLowerCase().contains(
            searchText.toLowerCase(),
          );
      final matchesStatus =
          selectedStatus == 'All' || (c['status'] ?? '') == selectedStatus;
      final date = c['date'] != null
          ? DateTime.tryParse(c['date'].toString())
          : null;
      final matchesFrom =
          fromDate == null ||
          (date != null && date.isAfter(fromDate!.subtract(Duration(days: 1))));
      final matchesTo =
          toDate == null ||
          (date != null && date.isBefore(toDate!.add(Duration(days: 1))));
      return matchesSearch && matchesStatus && matchesFrom && matchesTo;
    }).toList();
  }

  List<Map<String, dynamic>> get filteredReturns {
    return returns.where((r) {
      final matchesSearch =
          (r['returnNumber'] ?? '').toString().toLowerCase().contains(
            searchText.toLowerCase(),
          ) ||
          (r['customer'] ?? '').toString().toLowerCase().contains(
            searchText.toLowerCase(),
          );
      final matchesStatus =
          selectedStatus == 'All' || (r['status'] ?? '') == selectedStatus;
      final date = r['date'] != null
          ? DateTime.tryParse(r['date'].toString())
          : null;
      final matchesFrom =
          fromDate == null ||
          (date != null && date.isAfter(fromDate!.subtract(Duration(days: 1))));
      final matchesTo =
          toDate == null ||
          (date != null && date.isBefore(toDate!.add(Duration(days: 1))));
      return matchesSearch && matchesStatus && matchesFrom && matchesTo;
    }).toList();
  }

  void _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  void _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  Future<void> _showCreateChallanDialog() async {
    Map<String, dynamic>? selectedCustomer;
    Map<String, dynamic>? selectedOrder;
    String selectedVendor = 'BlueDart';
    String notes = '';
    List<Map<String, dynamic>> userOrders = [];
    List<Map<String, dynamic>> existingChallans = [];
    final vendors = ['BlueDart', 'Delhivery', 'DTDC', 'Other'];

    // map of order item idx -> new dispatch int
    final Map<int, int> newDispatchMap = {};
    // controllers for each item input so UI updates when value changes
    final Map<int, TextEditingController> dispatchControllers = {};

    // ensure users loaded
    await AppDataRepo().loadAllUsers();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        final height = MediaQuery.of(sheetCtx).size.height;
        return SafeArea(
          child: SizedBox(
            height: height * 0.98, // almost full screen
            child: StatefulBuilder(
              builder: (ctx2, setStateModal) {
                // helper to fetch orders for selected customer
                Future<void> _loadOrdersForCustomer(String userId) async {
                  try {
                    final resp = await AppDataRepo().fetchOrdersByUser(userId);
                    if (resp['success'] == true && resp['orders'] is List) {
                      final allOrders = List<Map<String, dynamic>>.from(
                        resp['orders'] as List,
                      );

                      // compute already dispatched sets for each order item
                      for (var order in allOrders) {
                        final orderId = order['_id']?.toString();
                        if (orderId == null) continue;

                        // fetch challans for this order
                        final challanResp = await AppDataRepo()
                            .getChallansByCustomerAndOrder(
                              customerId: userId,
                              orderId: orderId,
                            );

                        final challans = challanResp['data'] is List
                            ? List<Map<String, dynamic>>.from(
                                challanResp['data'],
                              )
                            : [];

                        final items = List<Map<String, dynamic>>.from(
                          order['items'] ?? [],
                        );
                        for (var item in items) {
                          final name = (item['name'] ?? '').toString();
                          int alreadyDispatchedSets = 0;

                          for (var ch in challans) {
                            final chItems = ch['items'] as List<dynamic>? ?? [];
                            for (var it in chItems) {
                              if ((it['name'] ?? '').toString() == name) {
                                alreadyDispatchedSets +=
                                    int.tryParse(
                                      it['dispatchedQty']?.toString() ?? '0',
                                    ) ??
                                    0;
                              }
                            }
                          }

                          item['alreadyDispatched'] = alreadyDispatchedSets;
                        }
                        order['items'] = items;
                      }

                      // filter orders with pending items
                      userOrders = allOrders.where((o) {
                        final status = (o['status'] ?? '')
                            .toString()
                            .toLowerCase();
                        if (status == 'cancelled' ||
                            status == 'returned' ||
                            status == 'dispatched') {
                          return false;
                        }
                        final items = List<Map<String, dynamic>>.from(
                          o['items'] ?? [],
                        );
                        for (final item in items) {
                          final orderedSets =
                              int.tryParse(
                                item['quantity']?.toString() ?? '0',
                              ) ??
                              0;
                          final alreadyDispatchedSets =
                              int.tryParse(
                                item['alreadyDispatched']?.toString() ?? '0',
                              ) ??
                              0;
                          if (alreadyDispatchedSets < orderedSets) return true;
                        }
                        return false;
                      }).toList();
                    } else {
                      userOrders = [];
                    }
                  } catch (e) {
                    userOrders = [];
                  }

                  // reset selection
                  selectedOrder = null;
                  existingChallans = [];
                  newDispatchMap.clear();
                  dispatchControllers.clear();
                  setStateModal(() {});
                }

                Future<void> _loadExistingChallans(
                  String custId,
                  String orderId,
                ) async {
                  try {
                    final resp = await AppDataRepo()
                        .getChallansByCustomerAndOrder(
                          customerId: custId,
                          orderId: orderId,
                        );
                    if ((resp['status'] == true || resp['success'] == true) &&
                        resp['data'] is List) {
                      existingChallans = List<Map<String, dynamic>>.from(
                        resp['data'] as List,
                      );
                    } else {
                      existingChallans = [];
                    }
                  } catch (e) {
                    existingChallans = [];
                  }

                  // prepopulate newDispatchMap to 0 and clear controllers
                  newDispatchMap.clear();
                  dispatchControllers.clear();
                  setStateModal(() {});
                }

                // compute already dispatched for an order item by matching name
                int _alreadyDispatchedForItem(Map<String, dynamic> item) {
                  final name = (item['name'] ?? '').toString();
                  int sum = 0;
                  for (var ch in existingChallans) {
                    final items = ch['items'] as List<dynamic>? ?? [];
                    for (var it in items) {
                      if ((it['name'] ?? '').toString() == name) {
                        final int dq =
                            int.tryParse(
                              it['dispatchedQty']?.toString() ?? '0',
                            ) ??
                            0;
                        sum += dq;
                      }
                    }
                  }
                  return sum;
                }

                final orderItems = selectedOrder != null
                    ? (List<Map<String, dynamic>>.from(
                        selectedOrder!['items'] ?? [],
                      ).where((it) {
                        final status = (it['status'] ?? '')
                            .toString()
                            .toLowerCase();
                        return !(status == 'cancelled' ||
                            status == 'returned' ||
                            status == 'dispatched');
                      }).toList())
                    : [];

                int _computeTotalValue() {
                  double total = 0.0;
                  for (int i = 0; i < orderItems.length; i++) {
                    final item = orderItems[i];
                    final int dispatchSets = newDispatchMap[i] ?? 0;
                    final prod = item['productId'] as Map<String, dynamic>?;
                    final filnalRaw =
                        item['filnalLotPrice'] ?? prod?['filnalLotPrice'];
                    final bool hasFilnal =
                        filnalRaw != null &&
                        filnalRaw.toString().trim().isNotEmpty;

                    if (hasFilnal) {
                      final double pricePerSet =
                          double.tryParse(filnalRaw.toString()) ?? 0.0;
                      total += pricePerSet * dispatchSets;
                    } else {
                      final double pricePerPiece =
                          double.tryParse(
                            (item['singlePicPrice'] ?? item['price'] ?? 0)
                                .toString(),
                          ) ??
                          0.0;
                      final int pcsInSet =
                          int.tryParse(item['pcsInSet']?.toString() ?? '1') ??
                          1;
                      total += pricePerPiece * pcsInSet * dispatchSets;
                    }
                  }
                  return total.round();
                }

                return Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 12,
                  ),
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 11, color: Colors.black),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Create Delivery Challan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(sheetCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          const Text('Select Customer'),
                          const SizedBox(height: 6),

                          InkWell(
                            onTap: () async {
                              final picked = await showModalBottomSheet<Map<String, dynamic>>(
                                context: sheetCtx,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(sheetCtx).size.height *
                                      0.95,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (pickerCtx) {
                                  String q = '';
                                  final users = AppDataRepo.users;
                                  return StatefulBuilder(
                                    builder: (pc, pcSet) {
                                      final filtered = users.where((u) {
                                        final label =
                                            '${u['name'] ?? ''} ${u['phone'] ?? ''}'
                                                .toLowerCase();
                                        return label.contains(q.toLowerCase());
                                      }).toList();

                                      return SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Select Customer',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          pickerCtx,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      prefixIcon: Icon(
                                                        Icons.search,
                                                      ),
                                                      hintText:
                                                          'Search customer...',
                                                      isDense: true,
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                onChanged: (v) =>
                                                    pcSet(() => q = v),
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: ListView.separated(
                                                  itemCount: filtered.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(height: 1),
                                                  itemBuilder: (context, i) {
                                                    final u = filtered[i];
                                                    final label =
                                                        '${u['name'] ?? ''} • ${u['phone'] ?? ''}';
                                                    return ListTile(
                                                      title: Text(label),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                            pickerCtx,
                                                            u,
                                                          ),
                                                    );
                                                  },
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

                              if (picked != null) {
                                selectedCustomer = picked;
                                setStateModal(() {});
                                if (picked['_id'] != null) {
                                  await _loadOrdersForCustomer(
                                    picked['_id'].toString(),
                                  );
                                }
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              child: Text(
                                selectedCustomer != null
                                    ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
                                    : 'Select Customer',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),

                          // InkWell(
                          //   onTap: () async {
                          //     final picked =
                          //         await showModalBottomSheet<
                          //           Map<String, dynamic>
                          //         >(
                          //           context: sheetCtx,
                          //           isScrollControlled: true,
                          //           backgroundColor: Colors.white,
                          //           constraints: BoxConstraints(
                          //             maxHeight:
                          //                 MediaQuery.of(sheetCtx).size.height *
                          //                 0.95,
                          //           ),
                          //           shape: const RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.vertical(
                          //               top: Radius.circular(16),
                          //             ),
                          //           ),
                          //           builder: (ctx) {
                          //             return SafeArea(
                          //               child: Padding(
                          //                 padding: const EdgeInsets.all(12.0),
                          //                 child: Column(
                          //                   children: [
                          //                     Row(
                          //                       children: [
                          //                         const Expanded(
                          //                           child: Text(
                          //                             'Select Customer',
                          //                             style: TextStyle(
                          //                               fontWeight:
                          //                                   FontWeight.bold,
                          //                               fontSize: 16,
                          //                             ),
                          //                           ),
                          //                         ),
                          //                         IconButton(
                          //                           icon: const Icon(
                          //                             Icons.close,
                          //                           ),
                          //                           onPressed: () =>
                          //                               Navigator.pop(ctx),
                          //                         ),
                          //                       ],
                          //                     ),
                          //                     const SizedBox(height: 8),
                          //                     Expanded(
                          //                       child: ListView.builder(
                          //                         itemCount:
                          //                             AppDataRepo.users.length,
                          //                         itemBuilder: (context, i) {
                          //                           final u =
                          //                               AppDataRepo.users[i];
                          //                           final label =
                          //                               '${u['name'] ?? ''} • ${u['phone'] ?? ''}';
                          //                           return ListTile(
                          //                             title: Text(label),
                          //                             onTap: () =>
                          //                                 Navigator.pop(ctx, u),
                          //                           );
                          //                         },
                          //                       ),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             );
                          //           },
                          //         );

                          //     if (picked != null) {
                          //       selectedCustomer = picked;
                          //       setStateModal(() {});
                          //       if (picked['_id'] != null) {
                          //         await _loadOrdersForCustomer(
                          //           picked['_id'].toString(),
                          //         );
                          //       }
                          //     }
                          //   },
                          //   child: InputDecorator(
                          //     decoration: const InputDecoration(
                          //       labelText: 'Customer',
                          //       border: OutlineInputBorder(),
                          //       isDense: true,
                          //     ),
                          //     child: Text(
                          //       selectedCustomer != null
                          //           ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
                          //           : 'Select Customer',
                          //       style: const TextStyle(fontSize: 13),
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 12),
                          const Text('Select Order'),
                          const SizedBox(height: 6),

                          InkWell(
                            onTap: () async {
                              if (userOrders.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No orders found for this customer',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final picked = await showModalBottomSheet<Map<String, dynamic>>(
                                context: sheetCtx,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(sheetCtx).size.height *
                                      0.95,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (pickerCtx) {
                                  String q = '';
                                  final orders = userOrders;
                                  return StatefulBuilder(
                                    builder: (pc, pcSet) {
                                      final delivered = orders
                                          .where((o) {
                                            return true; // userOrders already filtered in loader
                                          })
                                          .where((o) {
                                            final label =
                                                '${o['orderNumber'] ?? ''} ${o['total'] ?? o['subtotal'] ?? ''}'
                                                    .toLowerCase();
                                            return label.contains(
                                              q.toLowerCase(),
                                            );
                                          })
                                          .toList();

                                      return SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Select Order',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          pickerCtx,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      prefixIcon: Icon(
                                                        Icons.search,
                                                      ),
                                                      hintText:
                                                          'Search order...',
                                                      isDense: true,
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                onChanged: (v) =>
                                                    pcSet(() => q = v),
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: ListView.separated(
                                                  itemCount: delivered.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(height: 1),
                                                  itemBuilder: (context, i) {
                                                    final o = delivered[i];
                                                    final label =
                                                        '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})';
                                                    return ListTile(
                                                      title: Text(label),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                            pickerCtx,
                                                            o,
                                                          ),
                                                    );
                                                  },
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

                              if (picked != null) {
                                selectedOrder = picked;
                                setStateModal(() {});
                                if (selectedCustomer != null &&
                                    selectedCustomer!['_id'] != null &&
                                    selectedOrder!['_id'] != null) {
                                  await _loadExistingChallans(
                                    selectedCustomer!['_id'].toString(),
                                    selectedOrder!['_id'].toString(),
                                  );
                                }
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Order',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              child: Text(
                                selectedOrder != null
                                    ? '${selectedOrder!['orderNumber'] ?? ''} • ₹${selectedOrder!['total'] ?? selectedOrder!['subtotal'] ?? ''}'
                                    : 'Select Order',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (selectedOrder != null) ...[
                            const Text(
                              'Dispatch Quantities per Item',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            for (int i = 0; i < orderItems.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: Colors.grey.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orderItems[i]['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if ((orderItems[i]['availableSizes'] ??
                                                [])
                                            .isNotEmpty)
                                          Text(
                                            'Sizes: ${(orderItems[i]['availableSizes'] as List).join(", ")}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Ordered Qty',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${orderItems[i]['quantity'] ?? ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Already Dispatched',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${_alreadyDispatchedForItem(orderItems[i])}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                final orderedSets =
                                                    int.tryParse(
                                                      orderItems[i]['quantity']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;
                                                final already =
                                                    _alreadyDispatchedForItem(
                                                      orderItems[i],
                                                    );
                                                final remaining =
                                                    (orderedSets - already) > 0
                                                    ? (orderedSets - already)
                                                    : 0;
                                                int cur =
                                                    (newDispatchMap[i] ?? 0) -
                                                    1;
                                                if (cur < 0) cur = 0;
                                                newDispatchMap[i] = cur;
                                                dispatchControllers
                                                    .putIfAbsent(
                                                      i,
                                                      () =>
                                                          TextEditingController(),
                                                    )
                                                    .text = newDispatchMap[i]
                                                    .toString();
                                                setStateModal(() {});
                                              },
                                            ),
                                            Expanded(
                                              child: Builder(
                                                builder: (_) {
                                                  final orderedSets =
                                                      int.tryParse(
                                                        orderItems[i]['quantity']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0;
                                                  final already =
                                                      _alreadyDispatchedForItem(
                                                        orderItems[i],
                                                      );
                                                  final remaining =
                                                      (orderedSets - already) >
                                                          0
                                                      ? (orderedSets - already)
                                                      : 0;
                                                  final controller =
                                                      dispatchControllers.putIfAbsent(
                                                        i,
                                                        () => TextEditingController(
                                                          text:
                                                              (newDispatchMap[i] ??
                                                                      0)
                                                                  .toString(),
                                                        ),
                                                      );
                                                  return TextFormField(
                                                    controller: controller,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration:
                                                        const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                vertical: 6,
                                                              ),
                                                        ),
                                                    onChanged: (v) {
                                                      int val =
                                                          int.tryParse(v) ?? 0;
                                                      if (val < 0) val = 0;
                                                      if (val > remaining)
                                                        val = remaining;
                                                      newDispatchMap[i] = val;
                                                      if (controller.text !=
                                                          val.toString())
                                                        controller.text = val
                                                            .toString();
                                                      controller.selection =
                                                          TextSelection.collapsed(
                                                            offset: controller
                                                                .text
                                                                .length,
                                                          );
                                                      setStateModal(() {});
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                final orderedSets =
                                                    int.tryParse(
                                                      orderItems[i]['quantity']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;
                                                final already =
                                                    _alreadyDispatchedForItem(
                                                      orderItems[i],
                                                    );
                                                final remaining =
                                                    (orderedSets - already) > 0
                                                    ? (orderedSets - already)
                                                    : 0;
                                                int cur =
                                                    (newDispatchMap[i] ?? 0) +
                                                    1;
                                                if (cur > remaining)
                                                  cur = remaining;
                                                newDispatchMap[i] = cur;
                                                dispatchControllers
                                                    .putIfAbsent(
                                                      i,
                                                      () =>
                                                          TextEditingController(),
                                                    )
                                                    .text = newDispatchMap[i]
                                                    .toString();
                                                setStateModal(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Value: ₹${(() {
                                            final item = orderItems[i];
                                            final prod = item['productId'] as Map<String, dynamic>?;
                                            final filnal = item['filnalLotPrice'] ?? prod?['filnalLotPrice'];
                                            final hasFilnal = filnal != null && filnal.toString().trim().isNotEmpty;
                                            final int sets = newDispatchMap[i] ?? 0;
                                            if (hasFilnal) {
                                              final double pricePerSet = double.tryParse(filnal.toString()) ?? 0.0;
                                              return (pricePerSet * sets).round();
                                            } else {
                                              final double pricePerPiece = double.tryParse((item['singlePicPrice'] ?? item['price'] ?? 0).toString()) ?? 0.0;
                                              final int pcs = int.tryParse(item['pcsInSet']?.toString() ?? '1') ?? 1;
                                              return (pricePerPiece * pcs * sets).round();
                                            }
                                          }())}',
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Card(
                              color: Colors.indigo.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Total Dispatch Value:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${_computeTotalValue()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedVendor,
                                  items: vendors
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setStateModal(
                                    () => selectedVendor = v ?? selectedVendor,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery Vendor',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Notes / Tracking ID',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (v) => notes = v,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(sheetCtx).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  if (selectedCustomer == null ||
                                      selectedOrder == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Select customer and order',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final itemsPayload = <Map<String, dynamic>>[];
                                  for (int i = 0; i < orderItems.length; i++) {
                                    final item = orderItems[i];
                                    final int newDispatchSets =
                                        newDispatchMap[i] ?? 0;
                                    if (newDispatchSets <= 0) continue;
                                    final already = _alreadyDispatchedForItem(
                                      item,
                                    );
                                    final prod =
                                        item['productId']
                                            as Map<String, dynamic>?;
                                    final filnalRaw =
                                        item['filnalLotPrice'] ??
                                        prod?['filnalLotPrice'];
                                    final bool hasFilnal =
                                        filnalRaw != null &&
                                        filnalRaw.toString().trim().isNotEmpty;
                                    double priceValue = 0.0;
                                    String priceUnit = 'piece';
                                    if (hasFilnal) {
                                      priceValue =
                                          double.tryParse(
                                            filnalRaw.toString(),
                                          ) ??
                                          0.0;
                                      priceUnit = 'set';
                                    } else {
                                      priceValue =
                                          double.tryParse(
                                            (item['singlePicPrice'] ??
                                                    item['price'] ??
                                                    0)
                                                .toString(),
                                          ) ??
                                          0.0;
                                      priceUnit = 'piece';
                                    }
                                    final pcsInSet =
                                        int.tryParse(
                                          item['pcsInSet']?.toString() ?? '1',
                                        ) ??
                                        1;
                                    itemsPayload.add({
                                      'name': item['name'] ?? '',
                                      'availableSizes':
                                          item['availableSizes'] ?? [],
                                      'dispatchedQty': newDispatchSets,
                                      'price': priceValue,
                                      'priceUnit': priceUnit,
                                      'pcsInSet': pcsInSet,
                                      'selectedSizes':
                                          item['selectedSizes'] ?? [],
                                      'alreadyDispatched': already,
                                    });
                                  }

                                  if (itemsPayload.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter dispatch qty for at least one item',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final totalValue = itemsPayload.fold<int>(0, (
                                    sum,
                                    it,
                                  ) {
                                    final p =
                                        double.tryParse(
                                          (it['price'] ?? 0).toString(),
                                        ) ??
                                        0.0;
                                    final pcs =
                                        int.tryParse(
                                          (it['pcsInSet'] ?? 1).toString(),
                                        ) ??
                                        1;
                                    final sets =
                                        int.tryParse(
                                          (it['dispatchedQty'] ?? 0).toString(),
                                        ) ??
                                        0;
                                    final unit = (it['priceUnit'] ?? 'piece')
                                        .toString();
                                    if (unit == 'set') {
                                      return sum + (p * sets).round();
                                    } else {
                                      return sum + (p * pcs * sets).round();
                                    }
                                  });

                                  final body = {
                                    "customerId": selectedCustomer!['_id']
                                        ?.toString(),
                                    "customer": selectedCustomer!['name'] ?? '',
                                    "orderId": selectedOrder!['_id']
                                        ?.toString(),
                                    "orderNumber":
                                        selectedOrder!['orderNumber'] ?? '',
                                    "items": itemsPayload,
                                    "totalValue": totalValue,
                                    "date": DateTime.now()
                                        .toIso8601String()
                                        .substring(0, 10),
                                    "status": "Dispatched",
                                    "vendor": selectedVendor,
                                    "notes": notes,
                                  };

                                  try {
                                    final resp = await AppDataRepo()
                                        .createChallan(body);
                                    if (resp['success'] == true ||
                                        resp['status'] == true ||
                                        resp['challan'] != null) {
                                      Navigator.of(sheetCtx).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Challan created'),
                                        ),
                                      );
                                      await fetchChallans();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            resp['message']?.toString() ??
                                                'Failed to create challan',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'Create Challan',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateReturnDialog() async {
    Map<String, dynamic>? selectedCustomer;
    Map<String, dynamic>? selectedOrder;
    bool withOrder = true;
    List<Map<String, dynamic>> userOrders = [];
    List<Map<String, dynamic>> existingReturns = [];
    final Map<int, TextEditingController> returnQtyControllers = {};
    final Map<int, TextEditingController> reasonControllers = {};
    final Map<int, TextEditingController> refundControllers = {};
    final Map<int, TextEditingController> nameControllers = {};
    final Map<int, TextEditingController> deliveredControllers = {};
    String selectedRefundMethod = 'Bank Transfer';
    final refundMethods = ['Bank Transfer', 'Cash', 'Original Payment Method'];
    final List<Map<String, dynamic>> freeFormItems = [];
    int freeFormNextIdx = 0;

    await AppDataRepo().loadAllUsers();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModal) {
              Future<void> _loadOrdersForCustomer(String userId) async {
                try {
                  final resp = await AppDataRepo().fetchOrdersByUser(userId);
                  if (resp['success'] == true && resp['orders'] is List) {
                    userOrders = List<Map<String, dynamic>>.from(
                      resp['orders'],
                    );
                  } else {
                    userOrders = [];
                  }
                } catch (e) {
                  userOrders = [];
                }
                selectedOrder = null;
                existingReturns = [];
                returnQtyControllers.clear();
                reasonControllers.clear();
                refundControllers.clear();
                setModal(() {});
              }

              Future<void> _loadReturnsForSelection() async {
                existingReturns = [];
                returnQtyControllers.clear();
                reasonControllers.clear();
                refundControllers.clear();

                if (selectedCustomer != null && selectedOrder != null) {
                  final resp = await AppDataRepo().getReturnsByCustomerAndOrder(
                    customerId: selectedCustomer!['_id'].toString(),
                    orderId: selectedOrder!['_id'].toString(),
                  );
                  if (resp['status'] == true && resp['data'] is List) {
                    existingReturns = List<Map<String, dynamic>>.from(
                      resp['data'],
                    );
                  } else {
                    existingReturns = [];
                  }
                }
                setModal(() {});
              }

              int _alreadyReturnedForItem(Map<String, dynamic> orderItem) {
                final orderPid = (() {
                  final p = orderItem['productId'];
                  if (p is Map && p['_id'] != null) return p['_id'].toString();
                  return (p ?? '').toString();
                }());
                final orderName = (orderItem['name'] ?? '').toString();
                int sum = 0;
                for (var r in existingReturns) {
                  final items = r['items'] as List<dynamic>? ?? [];
                  for (var it in items) {
                    final rp = it['productId'];
                    final rid = rp is Map && rp['_id'] != null
                        ? rp['_id'].toString()
                        : (rp ?? '').toString();
                    final riname = (it['name'] ?? '').toString();
                    if ((orderPid.isNotEmpty && rid == orderPid) ||
                        (orderPid.isEmpty && riname == orderName)) {
                      sum +=
                          int.tryParse(it['returnPcs']?.toString() ?? '0') ?? 0;
                    }
                  }
                }
                return sum;
              }

              int _deliveredPcsForItem(Map<String, dynamic> it) {
                if (it['deliveredPcs'] != null) {
                  return int.tryParse(it['deliveredPcs'].toString()) ?? 0;
                }
                final qty =
                    int.tryParse(it['quantity']?.toString() ?? '0') ?? 0;
                final pcs =
                    int.tryParse(it['pcsInSet']?.toString() ?? '1') ?? 1;
                return qty * pcs;
              }

              double _computeTotalRefund() {
                double total = 0;
                if (withOrder) {
                  for (var k in refundControllers.keys) {
                    total +=
                        double.tryParse(refundControllers[k]?.text ?? '0') ?? 0;
                  }
                } else {
                  for (var k in refundControllers.keys) {
                    total +=
                        double.tryParse(refundControllers[k]?.text ?? '0') ?? 0;
                  }
                }
                return total;
              }

              List<Map<String, dynamic>> orderItems = selectedOrder != null
                  ? List<Map<String, dynamic>>.from(
                      selectedOrder!['items'] ?? [],
                    )
                  : [];

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (contextScroll, scrollController) {
                  return Material(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Create Return',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // With/Without Orders toggle
                          DropdownButtonFormField<String>(
                            value: withOrder ? 'With Orders' : 'Without Orders',
                            items: ['With Orders', 'Without Orders']
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              withOrder = (v == 'With Orders');
                              selectedOrder = null;
                              existingReturns = [];
                              returnQtyControllers.clear();
                              reasonControllers.clear();
                              refundControllers.clear();
                              setModal(() {});
                            },
                            decoration: const InputDecoration(isDense: true),
                          ),

                          const SizedBox(height: 12),
                          const Text('Select Customer'),
                          // const SizedBox(height: 6),

                          // const Text('Select Customer'),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showModalBottomSheet<Map<String, dynamic>>(
                                context: ctx,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(ctx).size.height * 0.95,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (pickerCtx) {
                                  // return SafeArea(
                                  //   child: Padding(
                                  //     padding: const EdgeInsets.all(12.0),
                                  //     child: Column(
                                  //       children: [
                                  //         Row(
                                  //           children: [
                                  //             const Expanded(
                                  //               child: Text(
                                  //                 'Select Customer',
                                  //                 style: TextStyle(
                                  //                   fontWeight:
                                  //                       FontWeight.bold,
                                  //                   fontSize: 16,
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //             IconButton(
                                  //               icon: const Icon(
                                  //                 Icons.close,
                                  //               ),
                                  //               onPressed: () =>
                                  //                   Navigator.pop(
                                  //                     pickerCtx,
                                  //                   ),
                                  //             ),
                                  //           ],
                                  //         ),
                                  //         const SizedBox(height: 8),
                                  //         Expanded(
                                  //           child: ListView.builder(
                                  //             itemCount:
                                  //                 AppDataRepo.users.length,
                                  //             itemBuilder: (context, i) {
                                  //               final u =
                                  //                   AppDataRepo.users[i];
                                  //               final label =
                                  //                   '${u['name'] ?? ''} • ${u['phone'] ?? ''}';
                                  //               return ListTile(
                                  //                 title: Text(label),
                                  //                 onTap: () =>
                                  //                     Navigator.pop(
                                  //                       pickerCtx,
                                  //                       u,
                                  //                     ),
                                  //               );
                                  //             },
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // );

                                  // add local search state so user can filter customers
                                  String q = '';
                                  final users = AppDataRepo.users;
                                  return StatefulBuilder(
                                    builder: (pickerCtx, pickerSet) {
                                      final filtered = users.where((u) {
                                        final label =
                                            '${u['name'] ?? ''} ${u['phone'] ?? ''}'
                                                .toLowerCase();
                                        return label.contains(q.toLowerCase());
                                      }).toList();

                                      return SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Select Customer',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          pickerCtx,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Search field
                                              TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      prefixIcon: Icon(
                                                        Icons.search,
                                                      ),
                                                      hintText:
                                                          'Search customer...',
                                                      isDense: true,
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                onChanged: (v) =>
                                                    pickerSet(() => q = v),
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: ListView.separated(
                                                  itemCount: filtered.length,
                                                  separatorBuilder: (_, __) =>
                                                      const Divider(height: 1),
                                                  itemBuilder: (context, i) {
                                                    final u = filtered[i];
                                                    final label =
                                                        '${u['name'] ?? ''} • ${u['phone'] ?? ''}';
                                                    return ListTile(
                                                      title: Text(label),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                            pickerCtx,
                                                            u,
                                                          ),
                                                    );
                                                  },
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

                              if (picked != null) {
                                selectedCustomer = picked;
                                setModal(() {});
                                if (picked['_id'] != null) {
                                  await _loadOrdersForCustomer(
                                    picked['_id'].toString(),
                                  );
                                }
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              child: Text(
                                selectedCustomer != null
                                    ? '${selectedCustomer!['name']} • ${selectedCustomer!['phone']}'
                                    : 'Select Customer',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),

                          if (withOrder) ...[
                            const SizedBox(height: 12),
                            const Text('Select Order'),
                            const SizedBox(height: 6),

                            InkWell(
                              onTap: () async {
                                if (userOrders.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No orders found for this customer',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final picked = await showModalBottomSheet<Map<String, dynamic>>(
                                  context: ctx,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(ctx).size.height * 0.95,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (pickerCtx) {
                                    final deliveredOrders = userOrders
                                        .where(
                                          (o) =>
                                              (o['status'] ?? '')
                                                  .toString()
                                                  .toLowerCase() ==
                                              'delivered',
                                        )
                                        .toList();

                                    String q = '';
                                    final orders = userOrders;
                                    return StatefulBuilder(
                                      builder: (pickerCtx, pickerSet) {
                                        final deliveredOrders = orders
                                            .where(
                                              (o) =>
                                                  (o['status'] ?? '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'delivered',
                                            )
                                            .where((o) {
                                              final label =
                                                  '${o['orderNumber'] ?? ''} ${o['total'] ?? o['subtotal'] ?? ''}'
                                                      .toLowerCase();
                                              return label.contains(
                                                q.toLowerCase(),
                                              );
                                            })
                                            .toList();

                                        return SafeArea(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Expanded(
                                                      child: Text(
                                                        'Select Order',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            pickerCtx,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                TextField(
                                                  decoration:
                                                      const InputDecoration(
                                                        prefixIcon: Icon(
                                                          Icons.search,
                                                        ),
                                                        hintText:
                                                            'Search order...',
                                                        isDense: true,
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  onChanged: (v) =>
                                                      pickerSet(() => q = v),
                                                ),
                                                const SizedBox(height: 8),
                                                Expanded(
                                                  child: ListView.separated(
                                                    itemCount:
                                                        deliveredOrders.length,
                                                    separatorBuilder: (_, __) =>
                                                        const Divider(
                                                          height: 1,
                                                        ),
                                                    itemBuilder: (context, i) {
                                                      final o =
                                                          deliveredOrders[i];
                                                      final label =
                                                          '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})';
                                                      return ListTile(
                                                        title: Text(label),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                              pickerCtx,
                                                              o,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    // return SafeArea(
                                    //   child: Padding(
                                    //     padding: const EdgeInsets.all(12.0),
                                    //     child: Column(
                                    //       children: [
                                    //         Row(
                                    //           children: [
                                    //             const Expanded(
                                    //               child: Text(
                                    //                 'Select Order',
                                    //                 style: TextStyle(
                                    //                   fontWeight:
                                    //                       FontWeight.bold,
                                    //                   fontSize: 16,
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //             IconButton(
                                    //               icon: const Icon(
                                    //                 Icons.close,
                                    //               ),
                                    //               onPressed: () =>
                                    //                   Navigator.pop(
                                    //                     pickerCtx,
                                    //                   ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         const SizedBox(height: 8),
                                    //         Expanded(
                                    //           child: ListView.builder(
                                    //             itemCount:
                                    //                 deliveredOrders.length,
                                    //             itemBuilder: (context, i) {
                                    //               final o =
                                    //                   deliveredOrders[i];
                                    //               final label =
                                    //                   '${o['orderNumber']} • ₹${o['total'] ?? o['subtotal']} (${o['status']})';
                                    //               return ListTile(
                                    //                 title: Text(label),
                                    //                 onTap: () =>
                                    //                     Navigator.pop(
                                    //                       pickerCtx,
                                    //                       o,
                                    //                     ),
                                    //               );
                                    //             },
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ),
                                    // );
                                  },
                                );

                                if (picked != null) {
                                  selectedOrder = picked;
                                  await _loadReturnsForSelection();
                                  final items = List<Map<String, dynamic>>.from(
                                    selectedOrder!['items'] ?? [],
                                  );
                                  for (int i = 0; i < items.length; i++) {
                                    returnQtyControllers.putIfAbsent(
                                      i,
                                      () => TextEditingController(text: '0'),
                                    );
                                    reasonControllers.putIfAbsent(
                                      i,
                                      () => TextEditingController(),
                                    );
                                    refundControllers.putIfAbsent(
                                      i,
                                      () => TextEditingController(text: '0'),
                                    );
                                  }
                                  setModal(() {});
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Order',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                child: Text(
                                  selectedOrder != null
                                      ? '${selectedOrder!['orderNumber']} • ₹${selectedOrder!['total'] ?? selectedOrder!['subtotal']} (${selectedOrder!['status']})'
                                      : 'Select Order',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Return Items
                          if (withOrder && selectedOrder != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Return Items',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                for (int i = 0; i < orderItems.length; i++) ...[
                                  Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            orderItems[i]['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Dispatched: ${_deliveredPcsForItem(orderItems[i])}',
                                          ),
                                          Text(
                                            'Already Returned: ${_alreadyReturnedForItem(orderItems[i])}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              //     Expanded(
                                              //       child: TextFormField(
                                              //         controller:
                                              //             returnQtyControllers[i],
                                              //         keyboardType:
                                              //             TextInputType.number,
                                              //         decoration:
                                              //             const InputDecoration(
                                              //               labelText: 'Return Qty',
                                              //               isDense: true,
                                              //             ),
                                              //       ),
                                              //     ),
                                              Expanded(
                                                child: Builder(
                                                  builder: (_) {
                                                    final ctrl =
                                                        returnQtyControllers
                                                            .putIfAbsent(
                                                              i,
                                                              () =>
                                                                  TextEditingController(
                                                                    text: '0',
                                                                  ),
                                                            );
                                                    // ensure refund controller exists
                                                    refundControllers.putIfAbsent(
                                                      i,
                                                      () =>
                                                          TextEditingController(
                                                            text: '0',
                                                          ),
                                                    );

                                                    return TextFormField(
                                                      controller: ctrl,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                      ],
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Return Qty',
                                                            isDense: true,
                                                          ),
                                                      onChanged: (val) {
                                                        int parsed =
                                                            int.tryParse(val) ??
                                                            0;
                                                        final delivered =
                                                            _deliveredPcsForItem(
                                                              orderItems[i],
                                                            );
                                                        final already =
                                                            _alreadyReturnedForItem(
                                                              orderItems[i],
                                                            );
                                                        final remaining =
                                                            (delivered -
                                                                    already) >
                                                                0
                                                            ? (delivered -
                                                                  already)
                                                            : 0;
                                                        if (parsed < 0)
                                                          parsed = 0;
                                                        if (parsed > remaining)
                                                          parsed = remaining;

                                                        final newText = parsed
                                                            .toString();
                                                        if (ctrl.text !=
                                                            newText) {
                                                          // preserve cursor at end
                                                          ctrl.value = TextEditingValue(
                                                            text: newText,
                                                            selection:
                                                                TextSelection.collapsed(
                                                                  offset: newText
                                                                      .length,
                                                                ),
                                                          );
                                                        }

                                                        // compute refund: singlePicPrice * pcsInSet * qty
                                                        final price =
                                                            double.tryParse(
                                                              (orderItems[i]['singlePicPrice'] ??
                                                                      orderItems[i]['price'] ??
                                                                      0)
                                                                  .toString(),
                                                            ) ??
                                                            0.0;
                                                        final pcs =
                                                            int.tryParse(
                                                              orderItems[i]['pcsInSet']
                                                                      ?.toString() ??
                                                                  '1',
                                                            ) ??
                                                            1;
                                                        final refundValue =
                                                            (price *
                                                                    pcs *
                                                                    parsed)
                                                                .round();

                                                        refundControllers[i]!
                                                            .text = refundValue
                                                            .toString();
                                                        setModal(() {});
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),

                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller:
                                                      reasonControllers[i],
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Reason',
                                                        isDense: true,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Refund: ₹${refundControllers[i]?.text ?? '0'}',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                Card(
                                  color: Colors.orange.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Refund:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '₹${_computeTotalRefund()}',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // WITHOUT ORDER: allow adding free-form return items
                          if (!withOrder) ...[
                            const Text(
                              'Return Items',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text(
                                  'Add Item',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  final idx = freeFormNextIdx++;
                                  freeFormItems.add({
                                    'idx': idx,
                                    'name': '',
                                    'returnPcs': 0,
                                    'reason': '',
                                    'refundAmount': 0,
                                    'deliveredPcs': 0,
                                  });
                                  // create controllers
                                  nameControllers.putIfAbsent(
                                    idx,
                                    () => TextEditingController(),
                                  );
                                  deliveredControllers.putIfAbsent(
                                    idx,
                                    () => TextEditingController(text: '0'),
                                  );
                                  returnQtyControllers.putIfAbsent(
                                    idx,
                                    () => TextEditingController(text: '0'),
                                  );
                                  reasonControllers.putIfAbsent(
                                    idx,
                                    () => TextEditingController(),
                                  );
                                  refundControllers.putIfAbsent(
                                    idx,
                                    () => TextEditingController(text: '0'),
                                  );
                                  setModal(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(110, 36),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            for (var fi in freeFormItems) ...[
                              Builder(
                                builder: (_) {
                                  final idx = fi['idx'] as int;
                                  final ctrlName = nameControllers.putIfAbsent(
                                    idx,
                                    () => TextEditingController(
                                      text: fi['name']?.toString() ?? '',
                                    ),
                                  );
                                  final ctrlDelivered = deliveredControllers
                                      .putIfAbsent(
                                        idx,
                                        () => TextEditingController(
                                          text: (fi['deliveredPcs'] ?? 0)
                                              .toString(),
                                        ),
                                      );
                                  final ctrlQty = returnQtyControllers
                                      .putIfAbsent(
                                        idx,
                                        () => TextEditingController(
                                          text:
                                              fi['returnPcs']?.toString() ??
                                              '0',
                                        ),
                                      );
                                  final ctrlReason = reasonControllers
                                      .putIfAbsent(
                                        idx,
                                        () => TextEditingController(
                                          text: fi['reason']?.toString() ?? '',
                                        ),
                                      );
                                  final ctrlRefund = refundControllers
                                      .putIfAbsent(
                                        idx,
                                        () => TextEditingController(
                                          text:
                                              fi['refundAmount']?.toString() ??
                                              '0',
                                        ),
                                      );

                                  return Card(
                                    color: Colors.grey.shade50,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: TextFormField(
                                                  controller: ctrlName,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Item Name',
                                                        isDense: true,
                                                      ),
                                                  onChanged: (v) =>
                                                      fi['name'] = v,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: ctrlDelivered,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Delivered PCS',
                                                        isDense: true,
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  onChanged: (v) =>
                                                      fi['deliveredPcs'] =
                                                          int.tryParse(v) ?? 0,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: ctrlQty,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Return Qty',
                                                        isDense: true,
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  onChanged: (v) =>
                                                      fi['returnPcs'] =
                                                          int.tryParse(v) ?? 0,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: TextFormField(
                                                  controller: ctrlReason,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Reason',
                                                        isDense: true,
                                                      ),
                                                  onChanged: (v) =>
                                                      fi['reason'] = v,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: ctrlRefund,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Refund (₹)',
                                                        isDense: true,
                                                      ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  onChanged: (v) {
                                                    // update model and refresh modal so totals update immediately
                                                    fi['refundAmount'] =
                                                        double.tryParse(v) ??
                                                        0.0;
                                                    setModal(() {});
                                                  },
                                                  // controller: ctrlRefund,
                                                  // keyboardType:
                                                  //     TextInputType.number,
                                                  // decoration:
                                                  //     const InputDecoration(
                                                  //       labelText: 'Refund (₹)',
                                                  //       isDense: true,
                                                  //     ),
                                                  // inputFormatters: [
                                                  //   FilteringTextInputFormatter
                                                  //       .digitsOnly,
                                                  // ],
                                                  // onChanged: (v) =>
                                                  //     fi['refundAmount'] =
                                                  //         double.tryParse(v) ??
                                                  //         0.0,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.redAccent,
                                                ),
                                                tooltip: 'Remove item',
                                                onPressed: () {
                                                  // dispose controllers and remove item
                                                  nameControllers
                                                      .remove(idx)
                                                      ?.dispose();
                                                  deliveredControllers
                                                      .remove(idx)
                                                      ?.dispose();
                                                  returnQtyControllers
                                                      .remove(idx)
                                                      ?.dispose();
                                                  reasonControllers
                                                      .remove(idx)
                                                      ?.dispose();
                                                  refundControllers
                                                      .remove(idx)
                                                      ?.dispose();
                                                  freeFormItems.removeWhere(
                                                    (e) => e['idx'] == idx,
                                                  );
                                                  setModal(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],

                            const SizedBox(height: 8),
                            Card(
                              color: Colors.orange.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Total Refund:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${(() {
                                        double t = 0;
                                        for (var it in freeFormItems) {
                                          t += double.tryParse((it['refundAmount'] ?? 0).toString()) ?? 0;
                                        }
                                        return t.round();
                                      }())}',

                                      // '₹${(() {
                                      //   double t = 0;
                                      //   for (var it in freeFormItems) {
                                      //     final idx = it['idx'] as int;
                                      //     t += double.tryParse(refundControllers[idx]?.text ?? '0') ?? 0;
                                      //   }
                                      //   return t.round();
                                      // }())}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const Text('Refund Method'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedRefundMethod,
                            items: refundMethods
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setModal(
                              () => selectedRefundMethod =
                                  v ?? selectedRefundMethod,
                            ),
                            decoration: const InputDecoration(isDense: true),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  // keep your existing submit logic here
                                  // (same as your original AlertDialog version)
                                  print('🔔 Create Return button pressed');
                                  print(
                                    'selectedOrder: ${selectedOrder ?? 'null'}',
                                  );
                                  print(
                                    'selectedCustomer: ${selectedCustomer ?? 'null'}',
                                  );
                                  print('withOrder: $withOrder');
                                  try {
                                    // Build itemsPayload (same logic you have)
                                    final itemsPayload =
                                        <Map<String, dynamic>>[];
                                    if (withOrder && selectedOrder != null) {
                                      for (
                                        int i = 0;
                                        i < orderItems.length;
                                        i++
                                      ) {
                                        final name =
                                            orderItems[i]['name'] ?? '';
                                        final returnPcs =
                                            int.tryParse(
                                              returnQtyControllers[i]?.text ??
                                                  '0',
                                            ) ??
                                            0;
                                        if (returnPcs <= 0) continue;
                                        final reason =
                                            reasonControllers[i]?.text ?? '';
                                        final refundAmount =
                                            double.tryParse(
                                              refundControllers[i]?.text ?? '0',
                                            ) ??
                                            0.0;
                                        final alreadyReturned =
                                            _alreadyReturnedForItem(
                                              orderItems[i],
                                            );
                                        itemsPayload.add({
                                          'name': name,
                                          'returnPcs': returnPcs,
                                          'reason': reason,
                                          'refundAmount': refundAmount,
                                          'alreadyReturned': alreadyReturned,
                                          'pcsInSet':
                                              int.tryParse(
                                                orderItems[i]['pcsInSet']
                                                        ?.toString() ??
                                                    '1',
                                              ) ??
                                              1,
                                          'singlePicPrice':
                                              double.tryParse(
                                                (orderItems[i]['singlePicPrice'] ??
                                                        orderItems[i]['price'] ??
                                                        0)
                                                    .toString(),
                                              ) ??
                                              0.0,
                                          'productId': (() {
                                            final p =
                                                orderItems[i]['productId'];
                                            if (p is Map && p['_id'] != null)
                                              return p['_id'].toString();
                                            return (p ?? '').toString();
                                          }()),
                                        });
                                      }
                                    } else {
                                      for (var fi in freeFormItems) {
                                        final idx = fi['idx'] as int;
                                        final name = (fi['name'] ?? '')
                                            .toString();
                                        final returnPcs =
                                            int.tryParse(
                                              returnQtyControllers[idx]?.text ??
                                                  '0',
                                            ) ??
                                            0;
                                        if (name.trim().isEmpty ||
                                            returnPcs <= 0)
                                          continue;
                                        final reason =
                                            reasonControllers[idx]?.text ?? '';
                                        final refundAmount =
                                            double.tryParse(
                                              refundControllers[idx]?.text ??
                                                  '0',
                                            ) ??
                                            0.0;
                                        itemsPayload.add({
                                          'name': name,
                                          'returnPcs': returnPcs,
                                          'reason': reason,
                                          'refundAmount': refundAmount,
                                          'alreadyReturned': 0,
                                          'pcsInSet': 1,
                                          'singlePicPrice': refundAmount,
                                          'productId': null,
                                        });
                                      }
                                    }

                                    print(
                                      'itemsPayload.length = ${itemsPayload.length}',
                                    );

                                    if (itemsPayload.isEmpty) {
                                      print(
                                        '⚠️ No return items — aborting createReturn',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Enter at least one return item',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final totalRefund = itemsPayload
                                        .fold<double>(
                                          0.0,
                                          (s, it) =>
                                              s +
                                              (double.tryParse(
                                                    (it['refundAmount'] ?? 0)
                                                        .toString(),
                                                  ) ??
                                                  0.0),
                                        );
                                    final bodyData = {
                                      'customer':
                                          selectedCustomer!['name'] ?? '',
                                      'customerId':
                                          selectedCustomer!['_id']
                                              ?.toString() ??
                                          '',
                                      'orderId': withOrder
                                          ? (selectedOrder?['_id']
                                                    ?.toString() ??
                                                '')
                                          : '',
                                      'items': itemsPayload
                                          .map(
                                            (it) => {
                                              'productId': it['productId'],
                                              'name': it['name'],
                                              'availableSizes':
                                                  it['availableSizes'] ?? [],
                                              'returnPcs': it['returnPcs'],
                                              'reason': it['reason'],
                                              'refundAmount':
                                                  it['refundAmount'],
                                              'pcsInSet': it['pcsInSet'],
                                              'singlePicPrice':
                                                  it['singlePicPrice'],
                                              'alreadyReturned':
                                                  it['alreadyReturned'],
                                            },
                                          )
                                          .toList(),
                                      'totalRefund': totalRefund.round(),
                                      'date': DateTime.now()
                                          .toIso8601String()
                                          .substring(0, 10),
                                      'status': 'Pending',
                                      'refundMethod': selectedRefundMethod,
                                    };

                                    print(
                                      '➡️ createReturn bodyData: ${jsonEncode(bodyData)}',
                                    );

                                    try {
                                      final resp = await AppDataRepo()
                                          .createReturn(data: bodyData);
                                      print(
                                        '✅ createReturn response object: $resp',
                                      );
                                      // Try to log success/status fields that are common
                                      print(
                                        'createReturn success: ${resp['success'] ?? resp['status']}',
                                      );
                                      if (resp['success'] == true ||
                                          resp['status'] == true) {
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Return created'),
                                          ),
                                        );
                                        await fetchReturns();
                                      } else {
                                        final msg =
                                            resp['message']?.toString() ??
                                            'Failed to create return';
                                        print(
                                          '❌ createReturn reported failure: $msg',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(msg)),
                                        );
                                      }
                                    } catch (e, st) {
                                      print(
                                        '🔥 createReturn thrown error: $e\n$st',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  } catch (err, st) {
                                    print(
                                      '⚠️ Error preparing create return payload: $err\n$st',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $err')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Create Return',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _editChallan(Map<String, dynamic> challan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit Challan #${challan['challanNumber']}')),
    );
  }

  void _editReturn(Map<String, dynamic> ret) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit Return #${ret['returnNumber']}')),
    );
  }

  void _showMismatchDialog(Map<String, dynamic> challan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Mismatch Detected', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          'Sales Order and Delivery Challan do not match for Challan #${challan['challanNumber']}.\nPlease review and correct.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper functions for filtering by date
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
  bool _isSameYear(DateTime a, DateTime b) => a.year == b.year;

  List<Map<String, dynamic>> get dailyChallans {
    final today = DateTime.now();
    return filteredChallans.where((c) {
      final date = c['date'] != null
          ? DateTime.tryParse(c['date'].toString())
          : null;
      return date != null && _isSameDay(date, today);
    }).toList();
  }

  List<Map<String, dynamic>> get monthlyChallans {
    final today = DateTime.now();
    return filteredChallans.where((c) {
      final date = c['date'] != null
          ? DateTime.tryParse(c['date'].toString())
          : null;
      return date != null && _isSameMonth(date, today);
    }).toList();
  }

  List<Map<String, dynamic>> get yearlyChallans {
    final today = DateTime.now();
    return filteredChallans.where((c) {
      final date = c['date'] != null
          ? DateTime.tryParse(c['date'].toString())
          : null;
      return date != null && _isSameYear(date, today);
    }).toList();
  }

  List<Map<String, dynamic>> get dailyReturns {
    final today = DateTime.now();
    return filteredReturns.where((r) {
      final date = r['date'] != null
          ? DateTime.tryParse(r['date'].toString())
          : null;
      return date != null && _isSameDay(date, today);
    }).toList();
  }

  List<Map<String, dynamic>> get monthlyReturns {
    final today = DateTime.now();
    return filteredReturns.where((r) {
      final date = r['date'] != null
          ? DateTime.tryParse(r['date'].toString())
          : null;
      return date != null && _isSameMonth(date, today);
    }).toList();
  }

  List<Map<String, dynamic>> get yearlyReturns {
    final today = DateTime.now();
    return filteredReturns.where((r) {
      final date = r['date'] != null
          ? DateTime.tryParse(r['date'].toString())
          : null;
      return date != null && _isSameYear(date, today);
    }).toList();
  }

  // Graph for Challan or Return (Horizontal Bar Chart)

  Widget _buildGraphSection({required bool isChallan}) {
    // Only show month-wise data
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    List<Map<String, dynamic>> data = isChallan
        ? monthlyChallans
        : monthlyReturns;
    Color barColor = isChallan ? Colors.indigo : Colors.orange;
    String title = isChallan ? 'Challan (This Month)' : 'Return (This Month)';

    // Group by day of month
    Map<String, int> counts = {};
    Map<String, double> values = {};
    for (var c in data) {
      final date = c['date'] != null
          ? DateTime.tryParse(c['date'].toString())
          : null;
      if (date != null && date.month == now.month && date.year == now.year) {
        final label =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        counts[label] = (counts[label] ?? 0) + 1;
        values[label] =
            (values[label] ?? 0) +
            (isChallan
                ? (c['totalValue'] ?? 0).toDouble()
                : (c['totalRefund'] ?? 0).toDouble());
      }
    }

    // Only show bars where value > 0
    final filteredLabels = values.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();

    // Find peak and lowest period
    String peakLabel = '';
    String lowestLabel = '';
    int peakValue = 0;
    int lowestValue = 999999;
    for (var label in filteredLabels) {
      if ((counts[label] ?? 0) > peakValue) {
        peakValue = counts[label] ?? 0;
        peakLabel = label;
      }
      if ((counts[label] ?? 0) < lowestValue) {
        lowestValue = counts[label] ?? 0;
        lowestLabel = label;
      }
    }

    double maxX = filteredLabels.isEmpty
        ? 1
        : filteredLabels
              .map((l) => counts[l] ?? 0)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();
    if (maxX < 1) maxX = 1;

    // Format date for display
    String formatLabel(String label) {
      final parts = label.split('-');
      if (parts.length == 3) {
        final month = DateTime(now.year, int.parse(parts[1]), 1);
        return "${month.month == now.month ? 'Oct' : 'Sep'} ${int.parse(parts[2])}";
      }
      return label;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo.shade50,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: barColor,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            filteredLabels.isEmpty
                ? Center(child: Text('No data available for this month'))
                : Column(
                    children: filteredLabels.map((label) {
                      final count = counts[label] ?? 0;
                      final value = values[label] ?? 0;
                      final percent = maxX > 0 ? count / maxX : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                formatLabel(label),
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor:
                                        200 *
                                        percent /
                                        MediaQuery.of(context).size.width,
                                    child: Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    child: Text(
                                      count > 0 ? count.toString() : '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '₹${value.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: barColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            Divider(height: 32),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Peak Period: ',
                          // style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${formatLabel(peakLabel)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Lowest Period: ',
                          // style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${formatLabel(lowestLabel)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSectionReturn() {
    final reportData = (() {
      if (selectedReport == 'Daily') {
        return dailyReturns;
      } else if (selectedReport == 'Monthly') {
        return monthlyReturns;
      } else {
        return yearlyReturns;
      }
    })();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Return Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: reportTypes
                    .map(
                      (type) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            type,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          selected: selectedReport == type,
                          selectedColor: Colors.orangeAccent,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedReport == type
                                ? Colors.white
                                : Colors.black,
                          ),
                          onSelected: (_) {
                            setState(() => selectedReport = type);
                            Navigator.of(context).pop();
                            Future.delayed(Duration(milliseconds: 200), () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                isScrollControlled: true,
                                builder: (context) =>
                                    _buildReportSectionReturn(),
                              );
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 16),
              Text(
                '$selectedReport Return Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              SizedBox(height: 8),
              reportData.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          "No data to show for this section",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      // children: reportData
                      //     .take(10)
                      //     .map(
                      //       (r) => ListTile(
                      //         leading: Icon(
                      //           Icons.undo,
                      //           color: Colors.orangeAccent,
                      //         ),
                      //         title: Text('Return #${r['returnNumber']}'),
                      //         subtitle: Text(
                      //           'Refund: ₹${r['totalRefund']} | Reason: ${r['reason'] ?? ''}',
                      //         ),
                      //         trailing: Text(
                      //           r['customer'] ?? '',
                      //           style: TextStyle(color: Colors.indigo),
                      //         ),
                      //       ),
                      //     )
                      //     .toList(),
                      children: reportData.take(10).map((c) {
                        // try parse date display
                        final dateStr = (c['date'] ?? '').toString();
                        final displayDate = dateStr.isNotEmpty
                            ? dateStr.substring(0, 10)
                            : '';
                        // compute total qty (sum dispatchedQty/quantity fields)
                        int totalQty = 0;
                        final items = (c['items'] as List<dynamic>?) ?? [];
                        for (var it in items) {
                          totalQty +=
                              int.tryParse(
                                (it['dispatchedQty'] ??
                                        it['quantity'] ??
                                        it['returnPcs'] ??
                                        0)
                                    .toString(),
                              ) ??
                              0;
                        }

                        return ListTile(
                          leading: const Icon(
                            Icons.receipt_long,
                            color: Colors.indigo,
                          ),
                          title: Text('Challan #${c['challanNumber']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: $displayDate'),
                              Text(
                                'Value: ₹${c['totalValue']} | Status: ${c['status']}',
                              ),
                              Text('Total Qty: $totalQty sets/pieces'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            c['customer'] ?? '',
                            style: const TextStyle(color: Colors.indigo),
                          ),
                          onTap: () => _showChallanDetails(c),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // show detailed challan in modal with full items and total qty
  void _showChallanDetails(Map<String, dynamic> challan) {
    final items = (challan['items'] as List<dynamic>?) ?? [];
    int totalQty = 0;
    for (var it in items) {
      totalQty +=
          int.tryParse(
            (it['dispatchedQty'] ?? it['quantity'] ?? 0).toString(),
          ) ??
          0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Challan #${challan['challanNumber']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${(challan['date'] ?? '').toString().substring(0, 10)}',
                ),
                Text('Customer: ${challan['customer'] ?? ''}'),
                Text('Order: ${challan['orderNumber'] ?? ''}'),
                Text('Vendor: ${challan['vendor'] ?? ''}'),
                const SizedBox(height: 8),
                Text(
                  'Total Value: ₹${challan['totalValue'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total Qty: $totalQty',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...items.map((it) {
                  final name = it['name'] ?? '';
                  final qty = (it['dispatchedQty'] ?? it['quantity'] ?? 0)
                      .toString();
                  final pcsInSet = it['pcsInSet']?.toString() ?? '';
                  final price = it['price']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '- $name',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty: $qty ${pcsInSet.isNotEmpty ? 'sets / pcsInSet:$pcsInSet' : ''} ${price.isNotEmpty ? '| Price: ₹$price' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // show detailed return in modal with full items and total qty
  void _showReturnDetails(Map<String, dynamic> ret) {
    final items = (ret['items'] as List<dynamic>?) ?? [];
    int totalQty = 0;
    for (var it in items) {
      totalQty +=
          int.tryParse((it['returnPcs'] ?? it['returnQty'] ?? 0).toString()) ??
          0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 12,
            right: 12,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Return #${ret['returnNumber']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${(ret['date'] ?? '').toString().substring(0, 10)}',
                ),
                Text('Customer: ${ret['customer'] ?? ''}'),
                Text('Refund Method: ${ret['refundMethod'] ?? ''}'),
                const SizedBox(height: 8),
                Text(
                  'Total Refund: ₹${ret['totalRefund'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total Qty: $totalQty',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...items.map((it) {
                  final name = it['name'] ?? '';
                  final qty = (it['returnPcs'] ?? it['returnQty'] ?? 0)
                      .toString();
                  final reason = it['reason'] ?? '';
                  final refund = it['refundAmount'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '- $name',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty: $qty | Reason: $reason | Refund: ₹$refund',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Challan & Return',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Search Bar ---
              Card(
                elevation: 2,
                shadowColor: Colors.indigo.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  child: TextField(
                    style: TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: _currentPage == 0
                          ? 'Search Challan'
                          : 'Search Return',
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.indigo.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.indigo.shade300,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => searchText = val),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- Status Chips ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statuses.map((status) {
                    final bool isSelected = selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.indigo.shade500,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.indigo.shade500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.indigo.shade400
                                : Colors.indigo.shade100,
                          ),
                        ),
                        onSelected: (_) =>
                            setState(() => selectedStatus = status),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // --- Date Range Selector ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'From:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: _pickFromDate,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: BorderSide(color: Colors.indigo.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        fromDate == null
                            ? 'Select'
                            : '${fromDate!.toLocal()}'.split(' ')[0],
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'To:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: _pickToDate,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: BorderSide(color: Colors.indigo.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        toDate == null
                            ? 'Select'
                            : '${toDate!.toLocal()}'.split(' ')[0],
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          fromDate = null;
                          toDate = null;
                        });
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // --- Action Buttons ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.bar_chart_rounded, size: 18),
                      label: Text(
                        showGraph ? 'Hide Graph' : 'Show Graph',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => setState(() => showGraph = !showGraph),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.receipt_long_rounded, size: 18),
                      label: Text(
                        'Show Reports',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          isScrollControlled: true,
                          builder: (context) => _currentPage == 0
                              ? _buildReportSectionChallan()
                              : _buildReportSectionReturn(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // --- Graph Section ---
              if (showGraph)
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _currentPage == 0
                      ? _buildGraphSection(isChallan: true)
                      : _buildGraphSection(isChallan: false),
                ),

              // --- PageView Section ---
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    // show skeleton while loading
                    challanLoading
                        ? const _ChallanSkeleton()
                        : ListView.separated(
                            itemCount: filteredChallans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _buildChallanCard(filteredChallans[i]),
                          ),
                    returnLoading
                        ? const _ChallanSkeleton()
                        : ListView.separated(
                            itemCount: filteredReturns.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _buildReturnCard(filteredReturns[i]),
                          ),
                  ],
                ),
              ),

              // --- Bottom Page Navigation ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      Icons.assignment_rounded,
                      color: _currentPage == 0
                          ? Colors.indigo
                          : Colors.grey.shade500,
                      size: 18,
                    ),
                    label: Text(
                      'Challan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _currentPage == 0
                            ? Colors.indigo
                            : Colors.grey.shade500,
                      ),
                    ),
                    onPressed: () => _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.undo_rounded,
                      color: _currentPage == 1
                          ? Colors.indigo
                          : Colors.grey.shade500,
                      size: 18,
                    ),
                    label: Text(
                      'Return',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _currentPage == 1
                            ? Colors.indigo
                            : Colors.grey.shade500,
                      ),
                    ),
                    onPressed: () => _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // --- Floating Action Button ---
      floatingActionButton: Padding(
        // raised higher so it doesn't overlap the bottom navigation
        padding: const EdgeInsets.only(bottom: 10.0),
        child: FloatingActionButton(
          backgroundColor: Colors.indigo.shade500,
          foregroundColor: Colors.white,
          elevation: 3,
          tooltip: 'Create Challan / Return',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // allow custom bottom padding
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) {
                final bottomPadding =
                    MediaQuery.of(context).viewInsets.bottom +
                    24 +
                    10; // extra space
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Create Challan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showCreateChallanDialog();
                            },
                          ),
                        ),
                        const SizedBox(width: 12), // horizontal gap
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.undo_rounded, size: 18),
                            label: const Text('Create Return'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.indigo.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showCreateReturnDialog();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),

      bottomNavigationBar: UniversalNavBar(
        selectedIndex: 4,
        onTap: (index) {
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
        },
      ),
    );
  }

  Widget _buildChallanCard(Map<String, dynamic> c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${c['challanNumber']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c['status'] == 'Pending'
                        ? Colors.yellow.shade100
                        : c['status'] == 'Approved'
                        ? Colors.green.shade100
                        : c['status'] == 'Rejected'
                        ? Colors.red.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c['status'],
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Date: ${c['date']?.toString().substring(0, 10) ?? ''}',
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
            ),
            Text('Customer: ${c['customer']}', style: TextStyle(fontSize: 11)),
            Text('Order: ${c['orderNumber']}', style: TextStyle(fontSize: 11)),
            Row(
              children: [
                Text('Value: ', style: TextStyle(fontSize: 11)),
                Text(
                  '₹${c['totalValue']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text('Vendor: ${c['vendor']}', style: TextStyle(fontSize: 11)),

            if (c['notes'] != null && c['notes'].toString().isNotEmpty)
              Text('Notes: ${c['notes']}', style: TextStyle(fontSize: 10)),

            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.indigo),
                  onPressed: () => _editChallan(c),
                  tooltip: 'Edit Challan',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> r) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Return #${r['returnNumber']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Date: ${r['date']?.toString().substring(0, 10) ?? ''}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  Text(
                    'Customer: ${r['customer']}',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Refund Method: ${r['refundMethod']}',
                    style: TextStyle(fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text('Refund: ', style: TextStyle(fontSize: 13)),
                      Text(
                        '₹${r['totalRefund']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: r['status'] == 'Pending'
                              ? Colors.yellow.shade100
                              : r['status'] == 'Approved'
                              ? Colors.green.shade100
                              : r['status'] == 'Rejected'
                              ? Colors.red.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r['status'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r['notes'] != null && r['notes'].toString().isNotEmpty)
                    Text(
                      'Notes: ${r['notes']}',
                      style: TextStyle(fontSize: 12),
                    ),
                  SizedBox(height: 8),
                  Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List<Widget>.from(
                    (r['items'] ?? []).map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '- ${item['name']} | Return Pcs: ${item['returnPcs'] ?? item['returnQty'] ?? ''} | Reason: ${item['reason'] ?? ''} | Refund: ₹${item['refundAmount'] ?? ''}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.redAccent),
                  onPressed: () => _editReturn(r),
                  tooltip: 'Edit Return',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // In _buildReportSectionChallan and _buildReportSectionReturn, update the report list rendering:

  Widget _buildReportSectionChallan() {
    final reportData = (() {
      if (selectedReport == 'Daily') {
        return dailyChallans;
      } else if (selectedReport == 'Monthly') {
        return monthlyChallans;
      } else {
        return yearlyChallans;
      }
    })();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challan Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: reportTypes
                    .map(
                      (type) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            type,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          selected: selectedReport == type,
                          selectedColor: Colors.indigo,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedReport == type
                                ? Colors.white
                                : Colors.indigo,
                          ),
                          onSelected: (_) {
                            setState(() => selectedReport = type);
                            Navigator.of(context).pop();
                            Future.delayed(Duration(milliseconds: 200), () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                isScrollControlled: true,
                                builder: (context) =>
                                    _buildReportSectionChallan(),
                              );
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 16),
              Text(
                '$selectedReport Challan Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 8),
              reportData.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          "No data to show for this section",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: reportData
                          .take(10)
                          .map(
                            (c) => ListTile(
                              leading: Icon(
                                Icons.receipt_long,
                                color: Colors.indigo,
                              ),
                              title: Text('Challan #${c['challanNumber']}'),
                              subtitle: Text(
                                'Value: ₹${c['totalValue']} | Status: ${c['status']}',
                              ),
                              trailing: Text(
                                c['customer'] ?? '',
                                style: TextStyle(color: Colors.indigo),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ...existing code...
// Add at the end of the file (before final closing brace)
// Simple shimmer skeleton for challan / return lists
class _ChallanSkeleton extends StatelessWidget {
  const _ChallanSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 160, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: Colors.white),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Container(height: 12, width: 80, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 220, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 140, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
