import 'dart:convert';

import 'package:flutter/services.dart';

import 'universal_navbar.dart';
import 'package:flutter/material.dart';
import '../widgets/searchable_dropdown.dart';
import 'package:fl_chart/fl_chart.dart'; // For graph view
import '../services/app_data_repo.dart';
import 'package:anibhaviadmin/widgets/searchable_dropdown.dart';

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
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateModal) {
            // helper to fetch orders for selected customer
            print('----- Debug Orders Before Filtering -----');
            for (var o in userOrders) {
              print('Order: ${o['orderNumber']} (${o['status']})');
              final items = List<Map<String, dynamic>>.from(o['items'] ?? []);
              for (var it in items) {
                final name = it['name'];
                final q = it['quantity'];
                final pcs = it['pcsInSet'];
                final ad = it['alreadyDispatched'];
                print(
                  '   Item: $name | qty: $q | pcsInSet: $pcs | alreadyDispatched: $ad',
                );
              }
            }
            print('-----------------------------------------');
            Future<void> _loadOrdersForCustomer(String userId) async {
              print('Fetching orders for user: $userId');
              try {
                final resp = await AppDataRepo().fetchOrdersByUser(userId);
                print('Fetch orders response: $resp');
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
                        ? List<Map<String, dynamic>>.from(challanResp['data'])
                        : [];

                    // loop through items in this order and compute dispatched qty
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

                  // ✅ Now filter orders based on pending items
                  userOrders = allOrders.where((o) {
                    final status = (o['status'] ?? '').toString().toLowerCase();
                    if (status == 'cancelled' ||
                        status == 'returned' ||
                        status == 'dispatched') {
                      return false;
                    }

                    final items = List<Map<String, dynamic>>.from(
                      o['items'] ?? [],
                    );
                    bool hasPendingItem = false;

                    for (final item in items) {
                      final orderedSets =
                          int.tryParse(item['quantity']?.toString() ?? '0') ??
                          0;
                      final alreadyDispatchedSets =
                          int.tryParse(
                            item['alreadyDispatched']?.toString() ?? '0',
                          ) ??
                          0;

                      print(
                        "🔍 Checking item: ${item['name']} | OrderedSets=$orderedSets | DispatchedSets=$alreadyDispatchedSets",
                      );

                      // ✅ Keep order if at least one item has pending sets
                      if (alreadyDispatchedSets < orderedSets) {
                        hasPendingItem = true;
                        break;
                      }
                    }

                    print(
                      "➡️ Order ${o['orderNumber']} kept? ${hasPendingItem ? 'YES (pending items)' : 'NO (fully dispatched)'}",
                    );

                    return hasPendingItem;
                  }).toList();
                } else {
                  userOrders = [];
                }
              } catch (e) {
                print('Error fetching orders: $e');
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
              print(
                'Fetching existing challans for customer:$custId order:$orderId',
              );
              try {
                final resp = await AppDataRepo().getChallansByCustomerAndOrder(
                  customerId: custId,
                  orderId: orderId,
                );
                print('getChallansByCustomerAndOrder response: $resp');
                if ((resp['status'] == true || resp['success'] == true) &&
                    resp['data'] is List) {
                  existingChallans = List<Map<String, dynamic>>.from(
                    resp['data'] as List,
                  );
                } else {
                  existingChallans = [];
                }
              } catch (e) {
                print('Error fetching existing challans: $e');
                existingChallans = [];
              }
              // prepopulate newDispatchMap to 0
              newDispatchMap.clear();
              dispatchControllers.clear();

              // Print detailed selectedOrder + per-product totals & delivered pieces
              try {
                print('--- Selected Order FULL DATA ---');
                print(jsonEncode(selectedOrder ?? {}));

                final itemsList = List<Map<String, dynamic>>.from(
                  selectedOrder?['items'] ?? [],
                );
                for (var item in itemsList) {
                  final name = (item['name'] ?? '').toString();
                  final status = (item['status'] ?? '').toString();
                  final orderedSets =
                      int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
                  final pcsInSet =
                      int.tryParse(item['pcsInSet']?.toString() ?? '1') ?? 1;

                  // compute already dispatched sets for this item from existingChallans
                  int alreadyDispatchedSets = 0;
                  for (var ch in existingChallans) {
                    final items = ch['items'] as List<dynamic>? ?? [];
                    for (var it in items) {
                      if ((it['name'] ?? '').toString() == name) {
                        alreadyDispatchedSets +=
                            int.tryParse(
                              it['dispatchedQty']?.toString() ?? '0',
                            ) ??
                            0;
                      }
                    }
                  }

                  final totalPcs = orderedSets * pcsInSet;
                  final deliveredPcs = alreadyDispatchedSets * pcsInSet;

                  print(
                    'Product: $name | Status: $status | Ordered sets: $orderedSets | pcsInSet: $pcsInSet | Total pcs: $totalPcs | Already dispatched sets: $alreadyDispatchedSets | Delivered pcs: $deliveredPcs',
                  );
                }
                print('--- END Selected Order DATA ---');
              } catch (e) {
                print('Error printing selectedOrder details: $e');
              }

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
                        int.tryParse(it['dispatchedQty']?.toString() ?? '0') ??
                        0;
                    sum += dq;
                  }
                }
              }
              return sum;
            }

            // build list of order items for UI (from selectedOrder)
            final orderItems = selectedOrder != null
                ? (List<Map<String, dynamic>>.from(
                    selectedOrder!['items'] ?? [],
                  ).where((it) {
                    final status = (it['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    // hide items that are cancelled, returned or already dispatched
                    return !(status == 'cancelled' ||
                        status == 'returned' ||
                        status == 'dispatched');
                  }).toList())
                : [];

            // compute totalValue for current newDispatchMap
            int _computeTotalValue() {
              double total = 0.0;
              for (int i = 0; i < orderItems.length; i++) {
                final item = orderItems[i];
                final int dispatchSets = newDispatchMap[i] ?? 0;

                // --- safe price resolution (use filnalLotPrice when present, support nested productId) ---
                final prod = item['productId'] as Map<String, dynamic>?;
                final filnalRaw =
                    item['filnalLotPrice'] ?? prod?['filnalLotPrice'];
                final bool hasFilnal =
                    filnalRaw != null && filnalRaw.toString().trim().isNotEmpty;

                if (hasFilnal) {
                  // filnalLotPrice represents price per set/lot — do not multiply by pcsInSet again
                  final double pricePerSet =
                      double.tryParse(filnalRaw.toString()) ?? 0.0;
                  total += pricePerSet * dispatchSets;
                } else {
                  // fallback to per-piece price * pcsInSet * sets
                  final double pricePerPiece =
                      double.tryParse(
                        (item['singlePicPrice'] ?? item['price'] ?? 0)
                            .toString(),
                      ) ??
                      0.0;
                  final int pcsInSet =
                      int.tryParse(item['pcsInSet']?.toString() ?? '1') ?? 1;
                  total += pricePerPiece * pcsInSet * dispatchSets;
                }
              }
              return total.round();
            }

            return AlertDialog(
              title: Text(
                'Create Delivery Challan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              content: SingleChildScrollView(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer selector (searchable)
                      Text('Select Customer'),
                      const SizedBox(height: 6),
                      SearchableDropdown(
                        label: 'Customer',
                        items: AppDataRepo.users
                            .map(
                              (u) => '${u['name'] ?? ''} • ${u['phone'] ?? ''}',
                            )
                            .toList(),
                        value: selectedCustomer != null
                            ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
                            : null,
                        labelColor: Colors.indigo,
                        onChanged: (label) {
                          final user = AppDataRepo.users.firstWhere(
                            (u) =>
                                '${u['name'] ?? ''} • ${u['phone'] ?? ''}' ==
                                label,
                            orElse: () => {},
                          );
                          if (user.isNotEmpty) {
                            selectedCustomer = user;
                            setStateModal(() {});
                            if (user['_id'] != null) {
                              _loadOrdersForCustomer(user['_id'].toString());
                            }
                          } else {
                            selectedCustomer = null;
                            userOrders = [];
                            setStateModal(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Orders selector (populated after customer selection)
                      Text('Select Order'),
                      const SizedBox(height: 6),
                      SearchableDropdown(
                        label: 'Order',
                        items: userOrders
                            .where((o) {
                              final status = (o['status'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              if (status == 'cancelled' ||
                                  status == 'returned' ||
                                  status == 'dispatched')
                                return false;
                              final items = List<Map<String, dynamic>>.from(
                                o['items'] ?? [],
                              );
                              bool allItemsDispatched = true;
                              for (var item in items) {
                                final orderedQty =
                                    int.tryParse(
                                      item['quantity']?.toString() ?? '0',
                                    ) ??
                                    0;
                                final pcsInSet =
                                    int.tryParse(
                                      item['pcsInSet']?.toString() ?? '1',
                                    ) ??
                                    1;
                                final totalOrdered = orderedQty * pcsInSet;
                                final alreadyDispatched =
                                    int.tryParse(
                                      item['alreadyDispatched']?.toString() ??
                                          '0',
                                    ) ??
                                    0;
                                if (totalOrdered > alreadyDispatched) {
                                  allItemsDispatched = false;
                                  break;
                                }
                              }
                              return !allItemsDispatched;
                            })
                            .map(
                              (o) =>
                                  '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})',
                            )
                            .toList(),
                        value: selectedOrder != null
                            ? '${selectedOrder!['orderNumber'] ?? ''} • ₹${selectedOrder!['total'] ?? selectedOrder!['subtotal'] ?? ''} (${selectedOrder!['status'] ?? ''})'
                            : null,
                        labelColor: Colors.indigo,
                        onChanged: (label) {
                          final found = userOrders.firstWhere(
                            (o) =>
                                '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})' ==
                                label,
                            orElse: () => {},
                          );
                          if (found.isNotEmpty) {
                            selectedOrder = found;
                            try {
                              print(
                                'Order selected (raw): ${jsonEncode(selectedOrder ?? {})}',
                              );
                            } catch (_) {
                              print('Order selected (raw): $selectedOrder');
                            }
                            if (selectedCustomer != null &&
                                selectedCustomer!['_id'] != null &&
                                selectedOrder != null &&
                                selectedOrder!['_id'] != null) {
                              _loadExistingChallans(
                                selectedCustomer!['_id'].toString(),
                                selectedOrder!['_id'].toString(),
                              );
                            } else {
                              existingChallans = [];
                              newDispatchMap.clear();
                              setStateModal(() {});
                            }
                          } else {
                            selectedOrder = null;
                            setStateModal(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Show products from selected order and allow new dispatch entry
                      if (selectedOrder != null) ...[
                        Text(
                          'Dispatch Quantities per Item',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < orderItems.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orderItems[i]['name'] ?? '',
                                          style: TextStyle(
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
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Ordered Qty',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          '${orderItems[i]['quantity'] ?? ''}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Already Dispatched',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          '${_alreadyDispatchedForItem(orderItems[i])}',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'New Dispatch',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.remove_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                // compute limits
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
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration: InputDecoration(
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
                                                      // keep controller text consistent (in case we clamped)
                                                      if (controller.text !=
                                                          val.toString())
                                                        controller.text = val
                                                            .toString();
                                                      // move cursor to end
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
                                              icon: Icon(
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
                                        const SizedBox(height: 4),
                                        Text(
                                          // 'Value: ₹${((double.tryParse(orderItems[i]['filnalLotPrice']?.toString() ?? (orderItems[i]['singlePicPrice'] ?? orderItems[i]['price'] ?? 0).toString()) ?? 0.0) * (int.tryParse(orderItems[i]['pcsInSet']?.toString() ?? '1') ?? 1) * (newDispatchMap[i] ?? 0)).round()}',
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
                                          style: TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 8),
                        Card(
                          color: Colors.indigo.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Total Dispatch Value:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${_computeTotalValue()}',
                                  style: TextStyle(
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

                      // Vendor selector + notes
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
                              decoration: InputDecoration(
                                labelText: 'Delivery Vendor',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Notes / Tracking ID',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => notes = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCustomer == null || selectedOrder == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Select customer and order')),
                      );
                      return;
                    }

                    // Build items array
                    final itemsPayload = <Map<String, dynamic>>[];
                    for (int i = 0; i < orderItems.length; i++) {
                      final item = orderItems[i];
                      final int newDispatchSets = newDispatchMap[i] ?? 0;
                      if (newDispatchSets <= 0) continue; // skip zero dispatch
                      final already = _alreadyDispatchedForItem(item);
                      final prod = item['productId'] as Map<String, dynamic>?;
                      final filnalRaw =
                          item['filnalLotPrice'] ?? prod?['filnalLotPrice'];
                      final bool hasFilnal =
                          filnalRaw != null &&
                          filnalRaw.toString().trim().isNotEmpty;
                      double priceValue = 0.0;
                      String priceUnit = 'piece'; // 'piece' or 'set'
                      if (hasFilnal) {
                        priceValue =
                            double.tryParse(filnalRaw.toString()) ?? 0.0;
                        priceUnit = 'set';
                      } else {
                        priceValue =
                            double.tryParse(
                              (item['singlePicPrice'] ?? item['price'] ?? 0)
                                  .toString(),
                            ) ??
                            0.0;
                        priceUnit = 'piece';
                      }
                      // final price =
                      //     (item['singlePicPrice'] ?? item['price'] ?? 0);
                      final pcsInSet =
                          int.tryParse(item['pcsInSet']?.toString() ?? '1') ??
                          1;
                      itemsPayload.add({
                        'name': item['name'] ?? '',
                        'availableSizes': item['availableSizes'] ?? [],
                        'dispatchedQty': newDispatchSets,
                        'price': priceValue,
                        'priceUnit': priceUnit,
                        'pcsInSet': pcsInSet,
                        'selectedSizes': item['selectedSizes'] ?? [],
                        'alreadyDispatched': already,
                      });
                    }

                    if (itemsPayload.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Enter dispatch qty for at least one item',
                          ),
                        ),
                      );
                      return;
                    }

                    final totalValue = itemsPayload.fold<int>(0, (sum, it) {
                      final p =
                          double.tryParse((it['price'] ?? 0).toString()) ?? 0.0;
                      final pcs =
                          int.tryParse((it['pcsInSet'] ?? 1).toString()) ?? 1;
                      final sets =
                          int.tryParse((it['dispatchedQty'] ?? 0).toString()) ??
                          0;
                      final unit = (it['priceUnit'] ?? 'piece').toString();
                      if (unit == 'set') {
                        return sum + (p * sets).round();
                      } else {
                        return sum + (p * pcs * sets).round();
                      }
                      // final p =
                      //     double.tryParse((it['price'] ?? 0).toString()) ?? 0.0;
                      // final pcs =
                      //     int.tryParse((it['pcsInSet'] ?? 1).toString()) ?? 1;
                      // final sets =
                      //     int.tryParse((it['dispatchedQty'] ?? 0).toString()) ??
                      //     0;
                      // return sum + (p * pcs * sets).round();
                    });

                    final body = {
                      "customerId": selectedCustomer!['_id']?.toString(),
                      "customer": selectedCustomer!['name'] ?? '',
                      "orderId": selectedOrder!['_id']?.toString(),
                      "orderNumber": selectedOrder!['orderNumber'] ?? '',
                      "items": itemsPayload,
                      "totalValue": totalValue,
                      "date": DateTime.now().toIso8601String().substring(0, 10),
                      "status": "Dispatched",
                      "vendor": selectedVendor,
                      "notes": notes,
                    };

                    print('Creating challan with body: $body');

                    try {
                      final resp = await AppDataRepo().createChallan(body);
                      print('createChallan response: $resp');
                      if (resp['success'] == true || resp['status'] == true) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Challan created successfully'),
                          ),
                        );
                        // refresh challans on screen
                        await fetchChallans();
                      } else if (resp['challan'] != null) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Challan created')),
                        );
                        await fetchChallans();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              resp['message']?.toString() ??
                                  'Failed to create challan',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error creating challan: $e');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text('Create Challan', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateReturnDialog() async {
    Map<String, dynamic>? selectedCustomer;
    Map<String, dynamic>? selectedOrder;
    bool withOrder = true; // toggle between with-order and without-order
    List<Map<String, dynamic>> userOrders = [];
    List<Map<String, dynamic>> existingReturns = [];
    final Map<int, TextEditingController> returnQtyControllers = {};
    final Map<int, TextEditingController> reasonControllers = {};
    final Map<int, TextEditingController> refundControllers = {};
    final Map<int, TextEditingController> nameControllers = {};
    final Map<int, TextEditingController> deliveredControllers = {};
    String selectedRefundMethod = 'Bank Transfer';
    final refundMethods = ['Bank Transfer', 'Cash', 'Original Payment Method'];

    // Free-form (without-order) items storage and id counter (persist across rebuilds)
    final List<Map<String, dynamic>> freeFormItems = [];
    int freeFormNextIdx = 0;

    await AppDataRepo().loadAllUsers();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModal) {
            Future<void> _loadOrdersForCustomer(String userId) async {
              try {
                final resp = await AppDataRepo().fetchOrdersByUser(userId);
                if (resp['success'] == true && resp['orders'] is List) {
                  userOrders = List<Map<String, dynamic>>.from(resp['orders']);
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

            // helper to compute alreadyReturned per item by matching productId or name
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
                  final riprod = rp is Map && rp['_id'] != null
                      ? rp['_id'].toString()
                      : (rp ?? '').toString();
                  final riname = (it['name'] ?? '').toString();
                  if ((orderPid.isNotEmpty && riprod == orderPid) ||
                      (orderPid.isEmpty && riname == orderName)) {
                    sum +=
                        int.tryParse(it['returnPcs']?.toString() ?? '0') ?? 0;
                  }
                }
              }
              return sum;
            }

            // Items to show in form when WITH ORDER
            List<Map<String, dynamic>> orderItems = selectedOrder != null
                ? List<Map<String, dynamic>>.from(selectedOrder!['items'] ?? [])
                : <Map<String, dynamic>>[];

            // compute dispatched/delivered pcs for an order item
            int _deliveredPcsForItem(Map<String, dynamic> it) {
              if (it['deliveredPcs'] != null) {
                return int.tryParse(it['deliveredPcs'].toString()) ?? 0;
              }
              final qty = int.tryParse(it['quantity']?.toString() ?? '0') ?? 0;
              final pcs = int.tryParse(it['pcsInSet']?.toString() ?? '1') ?? 1;
              return qty * pcs;
            }

            double _computeTotalRefund() {
              double total = 0;
              if (withOrder) {
                for (int i = 0; i < orderItems.length; i++) {
                  final rq =
                      int.tryParse(returnQtyControllers[i]?.text ?? '0') ?? 0;
                  final refund =
                      double.tryParse(refundControllers[i]?.text ?? '0') ?? 0.0;
                  total += refund;
                }
              } else {
                // without-order: controllers keyed by index in a dynamic list; use keys
                for (var k in refundControllers.keys) {
                  total +=
                      double.tryParse(refundControllers[k]?.text ?? '0') ?? 0.0;
                }
              }
              return total;
            }

            // dynamic list for without-order items
            // final List<Map<String, dynamic>> freeFormItems = [];

            return AlertDialog(
              title: const Text(
                'Create Return',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // mode toggle
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: withOrder
                                  ? 'With Orders'
                                  : 'Without Orders',
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
                                // reset selections
                                selectedOrder = null;
                                existingReturns = [];
                                returnQtyControllers.clear();
                                reasonControllers.clear();
                                refundControllers.clear();
                                setModal(() {});
                              },
                              decoration: const InputDecoration(isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Customer (searchable like challan)
                      const Text('Select Customer'),
                      const SizedBox(height: 6),
                      SearchableDropdown(
                        label: 'Customer',
                        items: AppDataRepo.users
                            .map(
                              (u) => '${u['name'] ?? ''} • ${u['phone'] ?? ''}',
                            )
                            .toList(),
                        value: selectedCustomer != null
                            ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
                            : null,
                        labelColor: Colors.indigo,
                        onChanged: (label) {
                          final user = AppDataRepo.users.firstWhere(
                            (u) =>
                                '${u['name'] ?? ''} • ${u['phone'] ?? ''}' ==
                                label,
                            orElse: () => {},
                          );
                          if (user.isNotEmpty) {
                            selectedCustomer = user;
                            setModal(() {});
                            if (user['_id'] != null)
                              _loadOrdersForCustomer(user['_id'].toString());
                          } else {
                            selectedCustomer = null;
                            userOrders = [];
                            setModal(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Order selector (only when withOrder)
                      if (withOrder) ...[
                        const Text('Select Order'),
                        const SizedBox(height: 6),
                        SearchableDropdown(
                          label: 'Order',
                          items: userOrders
                              .where(
                                (o) =>
                                    (o['status'] ?? '')
                                        .toString()
                                        .toLowerCase() ==
                                    'delivered',
                              )
                              .map(
                                (o) =>
                                    '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})',
                              )
                              .toList(),
                          value: selectedOrder != null
                              ? '${selectedOrder!['orderNumber'] ?? ''} • ₹${selectedOrder!['total'] ?? selectedOrder!['subtotal'] ?? ''} (${selectedOrder!['status'] ?? ''})'
                              : null,
                          labelColor: Colors.indigo,
                          onChanged: (label) async {
                            final found = userOrders.firstWhere(
                              (o) =>
                                  '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})' ==
                                  label,
                              orElse: () => {},
                            );
                            if (found.isNotEmpty) {
                              selectedOrder = found;
                              // load existing returns for selected customer+order
                              await _loadReturnsForSelection();

                              // init controllers for each order item
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
                                // compute initial refund for 0 qty
                                refundControllers[i]!.text = '0';
                              }
                              setModal(() {});
                            } else {
                              selectedOrder = null;
                              setModal(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Form items
                      if (withOrder && selectedOrder != null) ...[
                        const Text(
                          'Return Items',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < orderItems.length; i++) ...[
                          Card(
                            color: Colors.grey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    orderItems[i]['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Column(
                                    children: [
                                      Text(
                                        'Dispatched PCS: ${_deliveredPcsForItem(orderItems[i])}',
                                      ),
                                      Text(
                                        'Already Return Qty: ${_alreadyReturnedForItem(orderItems[i])}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // ...existing code...
                                      Expanded(
                                        flex: 2,
                                        child: Builder(
                                          builder: (_) {
                                            final ctrl = returnQtyControllers
                                                .putIfAbsent(
                                                  i,
                                                  () => TextEditingController(
                                                    text: '0',
                                                  ),
                                                );
                                            final delivered =
                                                _deliveredPcsForItem(
                                                  orderItems[i],
                                                );
                                            final already =
                                                _alreadyReturnedForItem(
                                                  orderItems[i],
                                                );
                                            final remaining =
                                                (delivered - already) > 0
                                                ? (delivered - already)
                                                : 0;
                                            return TextFormField(
                                              controller: ctrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Return Qty (max $remaining)',
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                int parsed =
                                                    int.tryParse(val) ?? 0;
                                                if (parsed < 0) parsed = 0;
                                                if (parsed > remaining)
                                                  parsed = remaining;

                                                final str = parsed.toString();
                                                if (ctrl.text != str) {
                                                  // update controller while preserving cursor at end
                                                  ctrl.value = TextEditingValue(
                                                    text: str,
                                                    selection:
                                                        TextSelection.collapsed(
                                                          offset: str.length,
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
                                                final refund =
                                                    (price * pcs * parsed)
                                                        .round();
                                                refundControllers
                                                    .putIfAbsent(
                                                      i,
                                                      () =>
                                                          TextEditingController(),
                                                    )
                                                    .text = refund
                                                    .toString();
                                                setModal(() {});
                                              },
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: reasonControllers
                                              .putIfAbsent(
                                                i,
                                                () => TextEditingController(),
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'Reason',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Refund (₹)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${refundControllers[i]?.text ?? '0'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
                                  '₹${_computeTotalRefund()}',
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

                      if (!withOrder) ...[
                        const SizedBox(height: 8),
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
                              final idx = freeFormNextIdx;
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
                              final ctrlQty = returnQtyControllers.putIfAbsent(
                                idx,
                                () => TextEditingController(
                                  text: fi['returnPcs']?.toString() ?? '0',
                                ),
                              );
                              final ctrlReason = reasonControllers.putIfAbsent(
                                idx,
                                () => TextEditingController(
                                  text: fi['reason']?.toString() ?? '',
                                ),
                              );
                              final ctrlRefund = refundControllers.putIfAbsent(
                                idx,
                                () => TextEditingController(
                                  text: fi['refundAmount']?.toString() ?? '0',
                                ),
                              );

                              return Card(
                                color: Colors.grey.shade50,
                                margin: const EdgeInsets.symmetric(vertical: 6),
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
                                              decoration: const InputDecoration(
                                                labelText: 'Item Name',
                                                isDense: true,
                                              ),
                                              onChanged: (v) => fi['name'] = v,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: ctrlDelivered,
                                              decoration: const InputDecoration(
                                                labelText: 'Delivered PCS',
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
                                              decoration: InputDecoration(
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
                                              decoration: const InputDecoration(
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
                                              decoration: const InputDecoration(
                                                labelText: 'Refund (₹)',
                                                isDense: true,
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              onChanged: (v) =>
                                                  fi['refundAmount'] =
                                                      double.tryParse(v) ?? 0.0,
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
                                    for (var it in freeFormItems) t += double.tryParse((it['refundAmount'] ?? 0).toString()) ?? 0;
                                    return t.round();
                                  }())}',
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

                      // if (!withOrder) ...[
                      //   const SizedBox(height: 8),
                      //   const Text(
                      //     'Return Items',
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      //   const SizedBox(height: 8),
                      //   // Add item button
                      //   Align(
                      //     alignment: Alignment.centerRight,
                      //     child: ElevatedButton.icon(
                      //       icon: const Icon(Icons.add, size: 14),
                      //       label: const Text(
                      //         'Add Item',
                      //         style: TextStyle(fontSize: 12),
                      //       ),
                      //       onPressed: () {
                      //         final idx = freeFormNextIdx++;
                      //         freeFormItems.add({
                      //           'idx': idx,
                      //           'name': '',
                      //           'returnPcs': 0,
                      //           'reason': '',
                      //           'refundAmount': 0,
                      //           'deliveredPcs':
                      //               0, // for display; user can edit if needed
                      //         });
                      //         // create controllers for this row
                      //         returnQtyControllers.putIfAbsent(
                      //           idx,
                      //           () => TextEditingController(text: '0'),
                      //         );
                      //         reasonControllers.putIfAbsent(
                      //           idx,
                      //           () => TextEditingController(),
                      //         );
                      //         refundControllers.putIfAbsent(
                      //           idx,
                      //           () => TextEditingController(text: '0'),
                      //         );
                      //         setModal(() {});
                      //       },
                      //       style: ElevatedButton.styleFrom(
                      //         minimumSize: const Size(110, 36),
                      //       ),
                      //     ),
                      //   ),
                      //   const SizedBox(height: 8),

                      //   // render freeFormItems rows (name / delivered / qty / reason / refund / remove)
                      //   for (var fi in freeFormItems) ...[
                      //     Builder(
                      //       builder: (_) {
                      //         final idx = fi['idx'] as int;
                      //         final name = fi['name'] as String? ?? '';
                      //         final delivered = fi['deliveredPcs'] as int? ?? 0;
                      //         final ctrlQty = returnQtyControllers.putIfAbsent(
                      //           idx,
                      //           () => TextEditingController(
                      //             text: fi['returnPcs']?.toString() ?? '0',
                      //           ),
                      //         );
                      //         final ctrlReason = reasonControllers.putIfAbsent(
                      //           idx,
                      //           () => TextEditingController(
                      //             text: fi['reason']?.toString() ?? '',
                      //           ),
                      //         );
                      //         final ctrlRefund = refundControllers.putIfAbsent(
                      //           idx,
                      //           () => TextEditingController(
                      //             text: fi['refundAmount']?.toString() ?? '0',
                      //           ),
                      //         );

                      //         return Card(
                      //           color: Colors.grey.shade50,
                      //           margin: const EdgeInsets.symmetric(vertical: 6),
                      //           child: Padding(
                      //             padding: const EdgeInsets.all(10.0),
                      //             child: Column(
                      //               children: [
                      //                 Row(
                      //                   children: [
                      //                     Expanded(
                      //                       flex: 4,
                      //                       child: TextFormField(
                      //                         initialValue: name,
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Item Name',
                      //                           isDense: true,
                      //                         ),
                      //                         onChanged: (v) => fi['name'] = v,
                      //                       ),
                      //                     ),
                      //                     const SizedBox(width: 8),
                      //                     Expanded(
                      //                       flex: 2,
                      //                       child: Column(
                      //                         crossAxisAlignment:
                      //                             CrossAxisAlignment.start,
                      //                         children: [
                      //                           const Text(
                      //                             'Delivered PCS',
                      //                             style: TextStyle(
                      //                               fontSize: 11,
                      //                               color: Colors.grey,
                      //                             ),
                      //                           ),
                      //                           const SizedBox(height: 4),
                      //                           Text(
                      //                             delivered.toString(),
                      //                             style: const TextStyle(
                      //                               fontWeight: FontWeight.bold,
                      //                             ),
                      //                           ),
                      //                         ],
                      //                       ),
                      //                     ),
                      //                     const SizedBox(width: 8),
                      //                     Expanded(
                      //                       flex: 2,
                      //                       child: TextFormField(
                      //                         controller: ctrlQty,
                      //                         keyboardType:
                      //                             TextInputType.number,
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Return Qty',
                      //                           isDense: true,
                      //                         ),
                      //                         inputFormatters: [
                      //                           FilteringTextInputFormatter
                      //                               .digitsOnly,
                      //                         ],
                      //                         onChanged: (v) {
                      //                           final parsed =
                      //                               int.tryParse(v) ?? 0;
                      //                           fi['returnPcs'] = parsed;
                      //                           // optionally clamp to delivered - alreadyReturned if you have that info
                      //                         },
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //                 const SizedBox(height: 8),
                      //                 Row(
                      //                   children: [
                      //                     Expanded(
                      //                       flex: 3,
                      //                       child: TextFormField(
                      //                         controller: ctrlReason,
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Reason',
                      //                           isDense: true,
                      //                         ),
                      //                         onChanged: (v) =>
                      //                             fi['reason'] = v,
                      //                       ),
                      //                     ),
                      //                     const SizedBox(width: 8),
                      //                     Expanded(
                      //                       child: TextFormField(
                      //                         controller: ctrlRefund,
                      //                         keyboardType:
                      //                             TextInputType.number,
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Refund (₹)',
                      //                           isDense: true,
                      //                         ),
                      //                         inputFormatters: [
                      //                           FilteringTextInputFormatter
                      //                               .digitsOnly,
                      //                         ],
                      //                         onChanged: (v) {
                      //                           final parsed =
                      //                               double.tryParse(v) ?? 0.0;
                      //                           fi['refundAmount'] = parsed;
                      //                         },
                      //                       ),
                      //                     ),
                      //                     const SizedBox(width: 8),
                      //                     IconButton(
                      //                       icon: const Icon(
                      //                         Icons.close,
                      //                         color: Colors.redAccent,
                      //                       ),
                      //                       tooltip: 'Remove item',
                      //                       onPressed: () {
                      //                         // dispose controllers and remove item
                      //                         returnQtyControllers
                      //                             .remove(idx)
                      //                             ?.dispose();
                      //                         reasonControllers
                      //                             .remove(idx)
                      //                             ?.dispose();
                      //                         refundControllers
                      //                             .remove(idx)
                      //                             ?.dispose();
                      //                         freeFormItems.removeWhere(
                      //                           (e) => e['idx'] == idx,
                      //                         );
                      //                         setModal(() {});
                      //                       },
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ],

                      //   const SizedBox(height: 8),
                      //   Card(
                      //     color: Colors.orange.shade50,
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(10.0),
                      //       child: Row(
                      //         children: [
                      //           const Expanded(
                      //             child: Text(
                      //               'Total Refund:',
                      //               style: TextStyle(
                      //                 fontWeight: FontWeight.bold,
                      //               ),
                      //             ),
                      //           ),
                      //           Text(
                      //             '₹${(() {
                      //               double t = 0;
                      //               for (var it in freeFormItems) t += double.tryParse((it['refundAmount'] ?? 0).toString()) ?? 0;
                      //               return t.round();
                      //             }())}',
                      //             style: const TextStyle(
                      //               fontWeight: FontWeight.bold,
                      //               color: Colors.orange,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ],

                      // Without-order form
                      // if (!withOrder) ...[
                      //   const SizedBox(height: 8),
                      //   const Text(
                      //     'Return Items',
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      //   const SizedBox(height: 8),
                      //   // dynamic area: user can add rows. We'll use controllers keyed by incremental index.
                      //   ElevatedButton.icon(
                      //     icon: const Icon(Icons.add, size: 14),
                      //     label: const Text(
                      //       'Add Item',
                      //       style: TextStyle(fontSize: 12),
                      //     ),
                      //     style: ElevatedButton.styleFrom(
                      //       minimumSize: const Size.fromHeight(36),
                      //     ),
                      //     onPressed: () {
                      //       final idx = refundControllers.length; // new key
                      //       returnQtyControllers.putIfAbsent(
                      //         idx,
                      //         () => TextEditingController(text: '0'),
                      //       );
                      //       reasonControllers.putIfAbsent(
                      //         idx,
                      //         () => TextEditingController(),
                      //       );
                      //       refundControllers.putIfAbsent(
                      //         idx,
                      //         () => TextEditingController(text: '0'),
                      //       );

                      //       // ✅ Add new item to the persistent list
                      //       freeFormItems.add({
                      //         'idx': idx,
                      //         'name': '',
                      //         'deliveredPcs': 0,
                      //       });

                      //       // ✅ Trigger rebuild
                      //       setModal(() {});
                      //     },
                      //   ),
                      //   const SizedBox(height: 8),
                      //   // render freeFormItems
                      //   for (var fi in freeFormItems) ...[
                      //     Builder(
                      //       builder: (_) {
                      //         final idx = fi['idx'] as int;
                      //         return Card(
                      //           color: Colors.grey.shade50,
                      //           child: Padding(
                      //             padding: const EdgeInsets.all(10.0),
                      //             child: Column(
                      //               children: [
                      //                 TextFormField(
                      //                   decoration: const InputDecoration(
                      //                     labelText: 'Item Name',
                      //                     isDense: true,
                      //                   ),
                      //                   onChanged: (v) => fi['name'] = v,
                      //                 ),
                      //                 const SizedBox(height: 8),
                      //                 Row(
                      //                   children: [
                      //                     Expanded(
                      //                       child: TextFormField(
                      //                         controller:
                      //                             returnQtyControllers[idx],
                      //                         keyboardType:
                      //                             TextInputType.number,
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Return Qty',
                      //                           isDense: true,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                     const SizedBox(width: 8),
                      //                     Expanded(
                      //                       child: TextFormField(
                      //                         controller:
                      //                             reasonControllers[idx],
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Reason',
                      //                           isDense: true,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                     const SizedBox(width: 8),
                      //                     Expanded(
                      //                       child: TextFormField(
                      //                         controller:
                      //                             refundControllers[idx],
                      //                         keyboardType:
                      //                             TextInputType.number,
                      //                         decoration: const InputDecoration(
                      //                           labelText: 'Refund (₹)',
                      //                           isDense: true,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ],
                      //   const SizedBox(height: 8),
                      //   Card(
                      //     color: Colors.orange.shade50,
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(10.0),
                      //       child: Row(
                      //         children: [
                      //           const Expanded(
                      //             child: Text(
                      //               'Total Refund:',
                      //               style: TextStyle(
                      //                 fontWeight: FontWeight.bold,
                      //               ),
                      //             ),
                      //           ),
                      //           Text(
                      //             '₹${_computeTotalRefund()}',
                      //             style: const TextStyle(
                      //               fontWeight: FontWeight.bold,
                      //               color: Colors.orange,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ],
                      const SizedBox(height: 12),

                      // Refund method
                      const Text('Refund Method'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedRefundMethod,
                        items: refundMethods
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (v) => setModal(
                          () =>
                              selectedRefundMethod = v ?? selectedRefundMethod,
                        ),
                        decoration: const InputDecoration(isDense: true),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCustomer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select customer')),
                      );
                      return;
                    }

                    final itemsPayload = <Map<String, dynamic>>[];

                    if (withOrder && selectedOrder != null) {
                      for (int i = 0; i < orderItems.length; i++) {
                        final name = orderItems[i]['name'] ?? '';
                        final returnPcs =
                            int.tryParse(
                              returnQtyControllers[i]?.text ?? '0',
                            ) ??
                            0;
                        if (returnPcs <= 0) continue;
                        final reason = reasonControllers[i]?.text ?? '';
                        final refundAmount =
                            double.tryParse(
                              refundControllers[i]?.text ?? '0',
                            ) ??
                            0.0;
                        final alreadyReturned = _alreadyReturnedForItem(
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
                                orderItems[i]['pcsInSet']?.toString() ?? '1',
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
                            final p = orderItems[i]['productId'];
                            if (p is Map && p['_id'] != null)
                              return p['_id'].toString();
                            return (p ?? '').toString();
                          }()),
                        });
                      }
                    } else {
                      // without order: use freeFormItems + controllers
                      for (var fi in freeFormItems) {
                        final idx = fi['idx'] as int;
                        final name = (fi['name'] ?? '').toString();
                        final returnPcs =
                            int.tryParse(
                              returnQtyControllers[idx]?.text ?? '0',
                            ) ??
                            0;
                        if (name.trim().isEmpty || returnPcs <= 0) continue;
                        final reason = reasonControllers[idx]?.text ?? '';
                        final refundAmount =
                            double.tryParse(
                              refundControllers[idx]?.text ?? '0',
                            ) ??
                            0.0;
                        itemsPayload.add({
                          'name': name,
                          'returnPcs': returnPcs,
                          'reason': reason,
                          'refundAmount': refundAmount,
                          'alreadyReturned': 0,
                          'pcsInSet': 1,
                          'singlePicPrice':
                              refundAmount, // user-provided full refund
                          'productId': null,
                        });
                      }

                      // without order: use freeFormItems + controllers
                      // for (var fi in freeFormItems) {
                      //   final idx = fi['idx'] as int;
                      //   final name = (fi['name'] ?? '').toString();
                      //   final returnPcs =
                      //       int.tryParse(
                      //         returnQtyControllers[idx]?.text ?? '0',
                      //       ) ??
                      //       0;
                      //   if (name.trim().isEmpty || returnPcs <= 0) continue;
                      //   final reason = reasonControllers[idx]?.text ?? '';
                      //   final refundAmount =
                      //       double.tryParse(
                      //         refundControllers[idx]?.text ?? '0',
                      //       ) ??
                      //       0.0;
                      //   itemsPayload.add({
                      //     'name': name,
                      //     'returnPcs': returnPcs,
                      //     'reason': reason,
                      //     'refundAmount': refundAmount,
                      //     'alreadyReturned': 0,
                      //     'pcsInSet': 1,
                      //     'singlePicPrice':
                      //         refundAmount, // user provided full refund
                      //     'productId': null,
                      //   });
                      // }
                    }

                    if (itemsPayload.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter at least one return item'),
                        ),
                      );
                      return;
                    }

                    final totalRefund = itemsPayload.fold<double>(
                      0.0,
                      (s, it) =>
                          s +
                          (double.tryParse(
                                (it['refundAmount'] ?? 0).toString(),
                              ) ??
                              0.0),
                    );
                    final bodyData = {
                      'customer': selectedCustomer!['name'] ?? '',
                      'customerId': selectedCustomer!['_id']?.toString() ?? '',
                      'orderId': withOrder
                          ? (selectedOrder?['_id']?.toString() ?? '')
                          : '',
                      'items': itemsPayload.map((it) {
                        // ensure keys match API expectation
                        return {
                          'productId': it['productId'],
                          'name': it['name'],
                          'availableSizes': it['availableSizes'] ?? [],
                          'returnPcs': it['returnPcs'],
                          'reason': it['reason'],
                          'refundAmount': it['refundAmount'],
                          'pcsInSet': it['pcsInSet'],
                          'singlePicPrice': it['singlePicPrice'],
                          'alreadyReturned': it['alreadyReturned'],
                        };
                      }).toList(),
                      'totalRefund': totalRefund.round(),
                      'date': DateTime.now().toIso8601String().substring(0, 10),
                      'status': 'Pending',
                      'refundMethod': selectedRefundMethod,
                    };

                    try {
                      final resp = await AppDataRepo().createReturn(
                        data: bodyData,
                      );
                      print('createReturn resp: $resp');
                      if (resp['success'] == true || resp['status'] == true) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Return created')),
                        );
                        await fetchReturns();
                      } else {
                        final msg =
                            resp['message']?.toString() ??
                            'Failed to create return';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } catch (e) {
                      print('Error creating return: $e');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text(
                    'Create Return',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Future<void> _showCreateReturnDialog() async {
  //   Map<String, dynamic>? selectedCustomer;
  //   Map<String, dynamic>? selectedOrder;
  //   String mode = 'With Orders';
  //   String? selectedRefundMethod = 'Bank Transfer';
  //   String notes = '';
  //   List<Map<String, dynamic>> userOrders = [];
  //   final List<Map<String, dynamic>> formItems = [];

  //   int _asInt(dynamic v) {
  //     if (v == null) return 0;
  //     if (v is int) return v;
  //     if (v is double) return v.toInt();
  //     if (v is String) return int.tryParse(v) ?? 0;
  //     return 0;
  //   }

  //   double _computeTotalRefund() {
  //     double total = 0;
  //     for (var it in formItems) {
  //       final price =
  //           double.tryParse((it['singlePicPrice'] ?? 0).toString()) ?? 0.0;
  //       final pcsInSet = int.tryParse(it['pcsInSet']?.toString() ?? '1') ?? 1;
  //       final returnQty = int.tryParse(it['returnPcs']?.toString() ?? '0') ?? 0;
  //       total += price * pcsInSet * returnQty;
  //     }
  //     return total;
  //   }

  //   await AppDataRepo().loadAllUsers();

  //   await showDialog(
  //     context: context,
  //     builder: (ctx) {
  //       return StatefulBuilder(
  //         builder: (ctx2, setStateModal) {
  //           Future<void> _loadOrdersForCustomer(String userId) async {
  //             print('🟢 Fetching orders for customerId: $userId');
  //             try {
  //               final resp = await AppDataRepo().fetchOrdersByUser(userId);
  //               if (resp['orders'] is List) {
  //                 userOrders = List<Map<String, dynamic>>.from(resp['orders']);
  //               } else if (resp['data'] is List) {
  //                 userOrders = List<Map<String, dynamic>>.from(resp['data']);
  //               } else {
  //                 userOrders = [];
  //               }
  //               print('✅ Orders fetched: ${userOrders.length}');
  //             } catch (e) {
  //               print('❌ Error loading orders: $e');
  //               userOrders = [];
  //             }
  //             selectedOrder = null;
  //             formItems.clear();
  //             setStateModal(() {});
  //           }

  //           void _populateItemsFromOrder(Map<String, dynamic> order) {
  //             formItems.clear();
  //             final items = List<Map<String, dynamic>>.from(
  //               order['items'] ?? [],
  //             );
  //             for (var item in items) {
  //               dynamic prod = item['productId'];
  //               String? productIdValue;
  //               if (prod is Map && prod['_id'] != null) {
  //                 productIdValue = prod['_id'].toString();
  //               } else if (prod != null) {
  //                 productIdValue = prod.toString();
  //               }

  //               final name =
  //                   (item['name'] ??
  //                           (prod is Map
  //                               ? (prod['name'] ?? prod['productName'])
  //                               : null) ??
  //                           '')
  //                       .toString();

  //               final deliveredPcs = item['deliveredPcs'] != null
  //                   ? int.tryParse(item['deliveredPcs'].toString()) ?? 0
  //                   : ((int.tryParse(item['quantity']?.toString() ?? '0') ??
  //                             0) *
  //                         (int.tryParse(item['pcsInSet']?.toString() ?? '1') ??
  //                             1));

  //               final pcsInSet =
  //                   int.tryParse(item['pcsInSet']?.toString() ?? '1') ?? 1;
  //               final singlePicPrice =
  //                   double.tryParse(
  //                     (item['singlePicPrice'] ??
  //                             (prod is Map
  //                                 ? prod['singlePicPrice'] ?? prod['price']
  //                                 : null) ??
  //                             0)
  //                         .toString(),
  //                   ) ??
  //                   0.0;

  //               formItems.add({
  //                 'productId': productIdValue,
  //                 'name': name,
  //                 'deliveredPcs': deliveredPcs,
  //                 'alreadyReturned': 0,
  //                 'returnPcs': 0,
  //                 'reason': '',
  //                 'pcsInSet': pcsInSet,
  //                 'singlePicPrice': singlePicPrice,
  //                 'refundAmount': 0,
  //               });
  //             }
  //             print('✅ Items populated: ${formItems.length}');
  //             setStateModal(() {});
  //           }

  //           Future<void> _onOrderSelected(Map<String, dynamic> order) async {
  //             selectedOrder = order;
  //             _populateItemsFromOrder(selectedOrder!);

  //             if (selectedCustomer == null || selectedOrder!['_id'] == null)
  //               return;

  //             print('🔵 Fetching returns for order ${selectedOrder!['_id']}');
  //             Map<String, dynamic> resp = {};
  //             try {
  //               resp = await AppDataRepo().fetchReturnsByCustomerAndOrder(
  //                 selectedCustomer!['_id'].toString(),
  //                 selectedOrder!['_id'].toString(),
  //               );
  //             } catch (e) {
  //               print('❌ Error fetching returns: $e');
  //               return;
  //             }

  //             if (resp['status'] == true && resp['data'] is List) {
  //               final List<dynamic> previousReturns = List.from(resp['data']);
  //               print('✅ Got ${previousReturns.length} return entries');

  //               final allPrevItems = previousReturns
  //                   .expand<Map<String, dynamic>>((r) {
  //                     final items = r['items'];
  //                     if (items is List) {
  //                       return items.whereType<Map<String, dynamic>>();
  //                     }
  //                     return <Map<String, dynamic>>[];
  //                   })
  //                   .toList();

  //               print('🧩 Flattened ${allPrevItems.length} total return items');
  //               for (var item in formItems) {
  //                 final orderPid = (item['productId'] ?? '').toString();
  //                 final orderName = (item['name'] ?? '').toString();

  //                 final matching = allPrevItems.where((ri) {
  //                   final riprod = ri['productId'];
  //                   final rid = (riprod is Map && riprod['_id'] != null)
  //                       ? riprod['_id'].toString()
  //                       : (riprod ?? '').toString();
  //                   final riname = (ri['name'] ?? '').toString();
  //                   return rid == orderPid || riname == orderName;
  //                 }).toList();

  //                 final totalReturned = matching.fold<int>(
  //                   0,
  //                   (sum, i) => sum + _asInt(i['returnPcs']),
  //                 );

  //                 item['alreadyReturned'] = totalReturned;

  //                 print(
  //                   '➡️ Item: $orderName (pid=$orderPid) -> Matches=${matching.length}, Returned=$totalReturned',
  //                 );
  //               }
  //             } else {
  //               print('⚠️ No return data found.');
  //             }

  //             setStateModal(() {});
  //           }

  //           return AlertDialog(
  //             title: const Text(
  //               'Create Return',
  //               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  //             ),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // Customer selection
  //                   DropdownButtonFormField<String>(
  //                     decoration: const InputDecoration(
  //                       labelText: 'Select Customer',
  //                     ),
  //                     value: selectedCustomer != null
  //                         ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
  //                         : null,
  //                     items: AppDataRepo.users
  //                         .map(
  //                           (u) => DropdownMenuItem<String>(
  //                             value: '${u['name'] ?? ''} • ${u['phone'] ?? ''}',
  //                             child: Text(
  //                               '${u['name'] ?? ''} • ${u['phone'] ?? ''}',
  //                             ),
  //                           ),
  //                         )
  //                         .toList(),
  //                     onChanged: (label) {
  //                       final user = AppDataRepo.users.firstWhere(
  //                         (u) =>
  //                             '${u['name'] ?? ''} • ${u['phone'] ?? ''}' ==
  //                             label,
  //                         orElse: () => {},
  //                       );
  //                       if (user.isNotEmpty) {
  //                         selectedCustomer = user;
  //                         print('👤 Selected customer: ${user['name']}');
  //                         _loadOrdersForCustomer(user['_id'].toString());
  //                       }
  //                     },
  //                   ),

  //                   const SizedBox(height: 10),

  //                   // Order selection
  //                   if (mode == 'With Orders')
  //                     DropdownButtonFormField<String>(
  //                       decoration: const InputDecoration(
  //                         labelText: 'Select Order',
  //                       ),
  //                       value: selectedOrder != null
  //                           ? '${selectedOrder!['orderNumber'] ?? ''} • ₹${selectedOrder!['total'] ?? ''}'
  //                           : null,
  //                       items: userOrders
  //                           .map(
  //                             (o) => DropdownMenuItem<String>(
  //                               value:
  //                                   '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? ''}',
  //                               child: Text(
  //                                 '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? ''}',
  //                               ),
  //                             ),
  //                           )
  //                           .toList(),
  //                       onChanged: (label) async {
  //                         final order = userOrders.firstWhere(
  //                           (o) =>
  //                               '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? ''}' ==
  //                               label,
  //                           orElse: () => {},
  //                         );
  //                         if (order.isNotEmpty) {
  //                           await _onOrderSelected(order);
  //                         }
  //                       },
  //                     ),

  //                   const SizedBox(height: 12),

  //                   // Return items
  //                   if (formItems.isNotEmpty)
  //                     ...formItems.map((item) {
  //                       return Card(
  //                         margin: const EdgeInsets.symmetric(vertical: 6),
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(10),
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 item['name'] ?? '',
  //                                 style: const TextStyle(
  //                                   fontWeight: FontWeight.bold,
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 6),
  //                               Row(
  //                                 children: [
  //                                   Expanded(
  //                                     child: Text(
  //                                       'Dispatched: ${item['deliveredPcs']}',
  //                                     ),
  //                                   ),
  //                                   Expanded(
  //                                     child: Text(
  //                                       'Already Returned: ${item['alreadyReturned']}',
  //                                       style: const TextStyle(
  //                                         color: Colors.redAccent,
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                               const SizedBox(height: 6),
  //                               TextField(
  //                                 decoration: const InputDecoration(
  //                                   labelText: 'Return Qty',
  //                                 ),
  //                                 keyboardType: TextInputType.number,
  //                                 onChanged: (v) {
  //                                   item['returnPcs'] = int.tryParse(v) ?? 0;
  //                                   setStateModal(() {});
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

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

  Widget _buildReportSection() {
    // Use SingleChildScrollView and padding to avoid overflow
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
                'Reports',
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
                                builder: (context) => _buildReportSection(),
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
                '$selectedReport Report',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Challan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              ...(() {
                    if (selectedReport == 'Daily') {
                      return dailyChallans;
                    } else if (selectedReport == 'Monthly') {
                      return monthlyChallans;
                    } else {
                      return yearlyChallans;
                    }
                  })()
                  .take(10)
                  .map(
                    (c) => ListTile(
                      leading: Icon(Icons.receipt_long, color: Colors.indigo),
                      title: Text('Challan #${c['challanNumber']}'),
                      subtitle: Text(
                        'Value: ₹${c['totalValue']} | Status: ${c['status']}',
                      ),
                      trailing: Text(
                        c['customer'] ?? '',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ),
              SizedBox(height: 8),
              Text(
                'Return',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              ...(() {
                    if (selectedReport == 'Daily') {
                      return dailyReturns;
                    } else if (selectedReport == 'Monthly') {
                      return monthlyReturns;
                    } else {
                      return yearlyReturns;
                    }
                  })()
                  .take(10)
                  .map(
                    (r) => ListTile(
                      leading: Icon(Icons.undo, color: Colors.redAccent),
                      title: Text('Return #${r['returnNumber']}'),
                      subtitle: Text(
                        'Refund: ₹${r['totalRefund']} | Reason: ${r['reason'] ?? ''}',
                      ),
                      trailing: Text(
                        r['customer'] ?? '',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
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
              // --- Header ---
              // Text(
              //   'Challan & Return',
              //   style: TextStyle(
              //     fontWeight: FontWeight.w600,
              //     fontSize: 20,
              //     color: Colors.indigo.shade700,
              //     letterSpacing: 0.3,
              //   ),
              // ),
              // const SizedBox(height: 8),

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
                    challanLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemCount: filteredChallans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _buildChallanCard(filteredChallans[i]),
                          ),
                    returnLoading
                        ? const Center(child: CircularProgressIndicator())
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

  // Widget _buildReturnCard(Map<String, dynamic> r) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     color: Colors.white,
  //     margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Row(
  //                   children: [
  //                     Text(
  //                       'Return #${r['returnNumber']}',
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 16,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(height: 4),
  //                 Text(
  //                   'Date: ${r['date']?.toString().substring(0, 10) ?? ''}',
  //                   style: TextStyle(color: Colors.grey[700], fontSize: 13),
  //                 ),
  //                 Text(
  //                   'Customer: ${r['customer']}',
  //                   style: TextStyle
  //                         'Peak Period: ',
  //                         // style: TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                       Text(
  //                         '${formatLabel(peakLabel)}',
  //                         style: TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   Row(
  //                     children: [
  //                       Text(
  //                         'Lowest Period: ',
  //                         // style: TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                       Text(
  //                         '${formatLabel(lowestLabel)}',
  //                         style: TextStyle(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildReportSection() {
  //   // Use SingleChildScrollView and padding to avoid overflow
  //   return SafeArea(
  //     child: Padding(
  //       padding: EdgeInsets.only(
  //         bottom: MediaQuery.of(context).viewInsets.bottom + 16,
  //         left: 16,
  //         right: 16,
  //         top: 16,
  //       ),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Reports',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.indigo,
  //               ),
  //             ),
  //             SizedBox(height: 12),
  //             Row(
  //               children: reportTypes
  //                   .map(
  //                     (type) => Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                       child: ChoiceChip(
  //                         label: Text(
  //                           type,
  //                           style: TextStyle(fontWeight: FontWeight.w500),
  //                         ),
  //                         selected: selectedReport == type,
  //                         selectedColor: Colors.indigo,
  //                         backgroundColor: Colors.white,
  //                         labelStyle: TextStyle(
  //                           color: selectedReport == type
  //                               ? Colors.white
  //                               : Colors.indigo,
  //                         ),
  //                         onSelected: (_) {
  //                           setState(() => selectedReport = type);
  //                           Navigator.of(context).pop();
  //                           Future.delayed(Duration(milliseconds: 200), () {
  //                             showModalBottomSheet(
  //                               context: context,
  //                               backgroundColor: Colors.white,
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.vertical(
  //                                   top: Radius.circular(24),
  //                                 ),
  //                               ),
  //                               isScrollControlled: true,
  //                               builder: (context) => _buildReportSection(),
  //                             );
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                   )
  //                   .toList(),
  //             ),
  //             SizedBox(height: 16),
  //             Text(
  //               '$selectedReport Report',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.indigo,
  //               ),
  //             ),
  //             SizedBox(height: 8),
  //             Text(
  //               'Challan',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.indigo,
  //               ),
  //             ),
  //             ...(() {
  //                   if (selectedReport == 'Daily') {
  //                     return dailyChallans;
  //                   } else if (selectedReport == 'Monthly') {
  //                     return monthlyChallans;
  //                   } else {
  //                     return yearlyChallans;
  //                   }
  //                 })()
  //                 .take(10)
  //                 .map(
  //                   (c) => ListTile(
  //                     leading: Icon(Icons.receipt_long, color: Colors.indigo),
  //                     title: Text('Challan #${c['challanNumber']}'),
  //                     subtitle: Text(
  //                       'Value: ₹${c['totalValue']} | Status: ${c['status']}',
  //                     ),
  //                     trailing: Text(
  //                       c['customer'] ?? '',
  //                       style: TextStyle(color: Colors.indigo),
  //                     ),
  //                   ),
  //                 ),
  //             SizedBox(height: 8),
  //             Text(
  //               'Return',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.redAccent,
  //               ),
  //             ),
  //             ...(() {
  //                   if (selectedReport == 'Daily') {
  //                     return dailyReturns;
  //                   } else if (selectedReport == 'Monthly') {
  //                     return monthlyReturns;
  //                   } else {
  //                     return yearlyReturns;
  //                   }
  //                 })()
  //                 .take(10)
  //                 .map(
  //                   (r) => ListTile(
  //                     leading: Icon(Icons.undo, color: Colors.redAccent),
  //                     title: Text('Return #${r['returnNumber']}'),
  //                     subtitle: Text(
  //                       'Refund: ₹${r['totalRefund']} | Reason: ${r['reason'] ?? ''}',
  //                     ),
  //                     trailing: Text(
  //                       r['customer'] ?? '',
  //                       style: TextStyle(color: Colors.indigo),
  //                     ),
  //                   ),
  //                 ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     // Replace your appBar property in Scaffold with this:
  //     appBar: PreferredSize(
  //       preferredSize: const Size.fromHeight(80),
  //       child: Container(
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             colors: [Colors.indigo.shade500, Colors.teal.shade400],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           ),
  //         ),
  //         child: SafeArea(
  //           child: Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //             child: Row(
  //               children: [
  //                 const Icon(
  //                   Icons.receipt_long_rounded,
  //                   color: Colors.white,
  //                   size: 22,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   'Challan & Return',
  //                   style: TextStyle(
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     body: SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // --- Header ---
  //             // Text(
  //             //   'Challan & Return',
  //             //   style: TextStyle(
  //             //     fontWeight: FontWeight.w600,
  //             //     fontSize: 20,
  //             //     color: Colors.indigo.shade700,
  //             //     letterSpacing: 0.3,
  //             //   ),
  //             // ),
  //             // const SizedBox(height: 8),

  //             // --- Search Bar ---
  //             Card(
  //               elevation: 2,
  //               shadowColor: Colors.indigo.shade100,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(14),
  //               ),
  //               child: Padding(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 8,
  //                   vertical: 1,
  //                 ),
  //                 child: TextField(
  //                   style: TextStyle(fontSize: 12),
  //                   decoration: InputDecoration(
  //                     labelText: _currentPage == 0
  //                         ? 'Search Challan'
  //                         : 'Search Return',
  //                     labelStyle: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.indigo.shade400,
  //                     ),
  //                     prefixIcon: Icon(
  //                       Icons.search,
  //                       color: Colors.indigo.shade300,
  //                     ),
  //                     border: InputBorder.none,
  //                   ),
  //                   onChanged: (val) => setState(() => searchText = val),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 8),

  //             // --- Status Chips ---
  //             SingleChildScrollView(
  //               scrollDirection: Axis.horizontal,
  //               child: Row(
  //                 children: statuses.map((status) {
  //                   final bool isSelected = selectedStatus == status;
  //                   return Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //                     child: ChoiceChip(
  //                       label: Text(
  //                         status,
  //                         style: TextStyle(
  //                           fontWeight: FontWeight.w500,
  //                           fontSize: 13,
  //                         ),
  //                       ),
  //                       selected: isSelected,
  //                       selectedColor: Colors.indigo.shade500,
  //                       backgroundColor: Colors.white,
  //                       labelStyle: TextStyle(
  //                         color: isSelected
  //                             ? Colors.white
  //                             : Colors.indigo.shade500,
  //                       ),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(20),
  //                         side: BorderSide(
  //                           color: isSelected
  //                               ? Colors.indigo.shade400
  //                               : Colors.indigo.shade100,
  //                         ),
  //                       ),
  //                       onSelected: (_) =>
  //                           setState(() => selectedStatus = status),
  //                     ),
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //             const SizedBox(height: 8),

  //             // --- Date Range Selector ---
  //             SingleChildScrollView(
  //               scrollDirection: Axis.horizontal,
  //               child: Row(
  //                 children: [
  //                   Text(
  //                     'From:',
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.w500,
  //                       fontSize: 13,
  //                       color: Colors.indigo.shade600,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 6),
  //                   OutlinedButton(
  //                     onPressed: _pickFromDate,
  //                     style: OutlinedButton.styleFrom(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 6,
  //                       ),
  //                       side: BorderSide(color: Colors.indigo.shade200),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     child: Text(
  //                       fromDate == null
  //                           ? 'Select'
  //                           : '${fromDate!.toLocal()}'.split(' ')[0],
  //                       style: TextStyle(fontSize: 13),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 16),
  //                   Text(
  //                     'To:',
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.w500,
  //                       fontSize: 13,
  //                       color: Colors.indigo.shade600,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 6),
  //                   OutlinedButton(
  //                     onPressed: _pickToDate,
  //                     style: OutlinedButton.styleFrom(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 6,
  //                       ),
  //                       side: BorderSide(color: Colors.indigo.shade200),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     child: Text(
  //                       toDate == null
  //                           ? 'Select'
  //                           : '${toDate!.toLocal()}'.split(' ')[0],
  //                       style: TextStyle(fontSize: 13),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   TextButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         fromDate = null;
  //                         toDate = null;
  //                       });
  //                     },
  //                     child: Text(
  //                       'Clear',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Colors.red.shade400,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 8),

  //             // --- Action Buttons ---
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: ElevatedButton.icon(
  //                     icon: Icon(Icons.bar_chart_rounded, size: 18),
  //                     label: Text(
  //                       showGraph ? 'Hide Graph' : 'Show Graph',
  //                       style: TextStyle(fontSize: 13),
  //                     ),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.indigo.shade500,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(vertical: 10),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                       ),
  //                       elevation: 2,
  //                     ),
  //                     onPressed: () => setState(() => showGraph = !showGraph),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: ElevatedButton.icon(
  //                     icon: Icon(Icons.receipt_long_rounded, size: 18),
  //                     label: Text(
  //                       'Show Reports',
  //                       style: TextStyle(fontSize: 13),
  //                     ),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.indigo.shade500,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(vertical: 10),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                       ),
  //                       elevation: 2,
  //                     ),
  //                     onPressed: () {
  //                       showModalBottomSheet(
  //                         context: context,
  //                         backgroundColor: Colors.white,
  //                         shape: const RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.vertical(
  //                             top: Radius.circular(24),
  //                           ),
  //                         ),
  //                         isScrollControlled: true,
  //                         builder: (context) => _currentPage == 0
  //                             ? _buildReportSectionChallan()
  //                             : _buildReportSectionReturn(),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 10),

  //             // --- Graph Section ---
  //             if (showGraph)
  //               AnimatedSwitcher(
  //                 duration: Duration(milliseconds: 300),
  //                 child: _currentPage == 0
  //                     ? _buildGraphSection(isChallan: true)
  //                     : _buildGraphSection(isChallan: false),
  //               ),

  //             // --- PageView Section ---
  //             Expanded(
  //               child: PageView(
  //                 controller: _pageController,
  //                 onPageChanged: (i) => setState(() => _currentPage = i),
  //                 children: [
  //                   challanLoading
  //                       ? const Center(child: CircularProgressIndicator())
  //                       : ListView.separated(
  //                           itemCount: filteredChallans.length,
  //                           separatorBuilder: (_, __) =>
  //                               const SizedBox(height: 12),
  //                           itemBuilder: (context, i) =>
  //                               _buildChallanCard(filteredChallans[i]),
  //                         ),
  //                   returnLoading
  //                       ? const Center(child: CircularProgressIndicator())
  //                       : ListView.separated(
  //                           itemCount: filteredReturns.length,
  //                           separatorBuilder: (_, __) =>
  //                               const SizedBox(height: 12),
  //                           itemBuilder: (context, i) =>
  //                               _buildReturnCard(filteredReturns[i]),
  //                         ),
  //                 ],
  //               ),
  //             ),

  //             // --- Bottom Page Navigation ---
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 TextButton.icon(
  //                   icon: Icon(
  //                     Icons.assignment_rounded,
  //                     color: _currentPage == 0
  //                         ? Colors.indigo
  //                         : Colors.grey.shade500,
  //                     size: 18,
  //                   ),
  //                   label: Text(
  //                     'Challan',
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w500,
  //                       color: _currentPage == 0
  //                           ? Colors.indigo
  //                           : Colors.grey.shade500,
  //                     ),
  //                   ),
  //                   onPressed: () => _pageController.animateToPage(
  //                     0,
  //                     duration: const Duration(milliseconds: 300),
  //                     curve: Curves.ease,
  //                   ),
  //                 ),
  //                 TextButton.icon(
  //                   icon: Icon(
  //                     Icons.undo_rounded,
  //                     color: _currentPage == 1
  //                         ? Colors.indigo
  //                         : Colors.grey.shade500,
  //                     size: 18,
  //                   ),
  //                   label: Text(
  //                     'Return',
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w500,
  //                       color: _currentPage == 1
  //                           ? Colors.indigo
  //                           : Colors.grey.shade500,
  //                     ),
  //                   ),
  //                   onPressed: () => _pageController.animateToPage(
  //                     1,
  //                     duration: const Duration(milliseconds: 300),
  //                     curve: Curves.ease,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     // --- Floating Action Button ---
  //     floatingActionButton: Padding(
  //       // raised higher so it doesn't overlap the bottom navigation
  //       padding: const EdgeInsets.only(bottom: 10.0),
  //       child: FloatingActionButton(
  //         backgroundColor: Colors.indigo.shade500,
  //         foregroundColor: Colors.white,
  //         elevation: 3,
  //         tooltip: 'Create Challan / Return',
  //         onPressed: () {
  //           showModalBottomSheet(
  //             context: context,
  //             isScrollControlled: true, // allow custom bottom padding
  //             backgroundColor: Colors.white,
  //             shape: const RoundedRectangleBorder(
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //             ),
  //             builder: (context) {
  //               final bottomPadding =
  //                   MediaQuery.of(context).viewInsets.bottom +
  //                   24 +
  //                   10; // extra space
  //               return SafeArea(
  //                 child: Padding(
  //                   padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.max,
  //                     children: [
  //                       Expanded(
  //                         child: ElevatedButton.icon(
  //                           icon: const Icon(Icons.add_rounded, size: 18),
  //                           label: const Text('Create Challan'),
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: Colors.indigo.shade500,
  //                             foregroundColor: Colors.white,
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(10),
  //                             ),
  //                             minimumSize: const Size(double.infinity, 44),
  //                           ),
  //                           onPressed: () {
  //                             Navigator.of(context).pop();
  //                             _showCreateChallanDialog();
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12), // horizontal gap
  //                       Expanded(
  //                         child: ElevatedButton.icon(
  //                           icon: const Icon(Icons.undo_rounded, size: 18),
  //                           label: const Text('Create Return'),
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: Colors.grey.shade100,
  //                             foregroundColor: Colors.indigo.shade600,
  //                             shape: RoundedRectangleBorder(
  //                               borderRadius: BorderRadius.circular(10),
  //                             ),
  //                             minimumSize: const Size(double.infinity, 44),
  //                           ),
  //                           onPressed: () {
  //                             Navigator.of(context).pop();
  //                             _showCreateReturnDialog();
  //                           },
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         },
  //         child: const Icon(Icons.add_rounded, size: 28),
  //       ),
  //     ),

  //     bottomNavigationBar: UniversalNavBar(
  //       selectedIndex: 4,
  //       onTap: (index) {
  //         String? route;
  //         switch (index) {
  //           case 0:
  //             route = '/dashboard';
  //             break;
  //           case 1:
  //             route = '/orders';
  //             break;
  //           case 2:
  //             route = '/users';
  //             break;
  //           case 3:
  //             route = '/catalogue';
  //             break;
  //           case 4:
  //             route = '/challan';
  //             break;
  //         }
  //         if (route != null && ModalRoute.of(context)?.settings.name != route) {
  //           Navigator.pushNamedAndRemoveUntil(
  //             context,
  //             route,
  //             (r) => r.settings.name == '/dashboard',
  //           );
  //         }
  //       },
  //     ),

  //   );

  // }

  // Widget _buildChallanCard(Map<String, dynamic> c) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     color: Colors.white,
  //     margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 '#${c['challanNumber']}',
  //                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  //               ),

  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                 decoration: BoxDecoration(
  //                   color: c['status'] == 'Pending'
  //                       ? Colors.yellow.shade100
  //                       : c['status'] == 'Approved'
  //                       ? Colors.green.shade100
  //                       : c['status'] == 'Rejected'
  //                       ? Colors.red.shade100
  //                       : Colors.grey.shade200,
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Text(
  //                   c['status'],
  //                   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 4),
  //           Text(
  //             'Date: ${c['date']?.toString().substring(0, 10) ?? ''}',
  //             style: TextStyle(color: Colors.grey[700], fontSize: 11),
  //           ),
  //           Text('Customer: ${c['customer']}', style: TextStyle(fontSize: 11)),
  //           Text('Order: ${c['orderNumber']}', style: TextStyle(fontSize: 11)),
  //           Row(
  //             children: [
  //               Text('Value: ', style: TextStyle(fontSize: 11)),
  //               Text(
  //                 '₹${c['totalValue']}',
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.indigo,
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           Text('Vendor: ${c['vendor']}', style: TextStyle(fontSize: 11)),

  //           if (c['notes'] != null && c['notes'].toString().isNotEmpty)
  //             Text('Notes: ${c['notes']}', style: TextStyle(fontSize: 10)),

  //           Row(
  //             children: [
  //               IconButton(
  //                 icon: Icon(Icons.edit, color: Colors.indigo),
  //                 onPressed: () => _editChallan(c),
  //                 tooltip: 'Edit Challan',
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
                      children: reportData
                          .take(10)
                          .map(
                            (r) => ListTile(
                              leading: Icon(
                                Icons.undo,
                                color: Colors.orangeAccent,
                              ),
                              title: Text('Return #${r['returnNumber']}'),
                              subtitle: Text(
                                'Refund: ₹${r['totalRefund']} | Reason: ${r['reason'] ?? ''}',
                              ),
                              trailing: Text(
                                r['customer'] ?? '',
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
