import 'package:anibhaviadmin/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_data_repo.dart';
import 'order_details_page.dart';
import 'universal_navbar.dart';
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
      final data = await AppDataRepo().fetchAllOrders();
      if (data['success'] == true && data['orders'] != null) {
        _orders = List<Map<String, dynamic>>.from(data['orders']);
      } else {
        _error = 'Failed to load orders';
      }
    } catch (e) {
      _error = 'Error loading orders';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('All Orders')),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _loading
            ? ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, idx) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                  );
                },
              )
            : _error != null
            ? Center(child: Text(_error!))
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final order = _orders[idx];
                  final shipping = order['shippingAddress'] ?? {};
                  String statusRaw = (order['orderStatus'] ?? '')
                      .toString()
                      .trim();
                  String status = statusRaw.toLowerCase() == 'order confirmed'
                      ? 'Confirmed'
                      : statusRaw;
                  String paymentStatus = (order['paymentStatus'] ?? '')
                      .toString()
                      .trim();
                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailsPage(orderId: order['_id']),
                          ),
                        );
                        if (result == true) {
                          _fetchOrders();
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
                                  child: Text(
                                    order['orderUniqueId'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                                        statusColors[status.toLowerCase()] ??
                                        Colors.grey.shade200,
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
                                padding: const EdgeInsets.only(top: 2.0),
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
                                          paymentStatus.toLowerCase().contains(
                                            'fail',
                                          )
                                          ? Colors.red
                                          : paymentStatus
                                                .toLowerCase()
                                                .contains('complete')
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
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Create Order', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
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

  // ...inside _CreateOrderSheetState...

  void _printSelectedData() {
    print('Selected Customer:');
    print(_selectedCustomer);
    print('Selected Products:');
    for (var p in _selectedProducts) {
      print(p);
    }
  }

  // Add this helper function:
  String getProductId(dynamic p) {
    final id = p['productId'];
    if (id is String) return id;
    if (id is Map && id['_id'] != null) return id['_id'].toString();
    return id?.toString() ?? '';
  }

  // Update _addProduct:
  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      final pid = getProductId(product);
      final idx = _selectedProducts.indexWhere((p) => getProductId(p) == pid);
      if (idx >= 0) {
        _selectedProducts[idx]['quantity'] += 1;
      } else {
        _selectedProducts.add({...product, 'quantity': 1});
      }
      _recalculatePrice();
    });
  }

  // Update _removeProduct:
  void _removeProduct(String productId) {
    setState(() {
      _selectedProducts.removeWhere((p) => getProductId(p) == productId);
      _recalculatePrice();
    });
  }

  // Update _updateProductQuantity:
  void _updateProductQuantity(String productId, int delta) {
    setState(() {
      final idx = _selectedProducts.indexWhere(
        (p) => getProductId(p) == productId,
      );
      if (idx >= 0) {
        _selectedProducts[idx]['quantity'] += delta;
        if (_selectedProducts[idx]['quantity'] < 1)
          _selectedProducts[idx]['quantity'] = 1;
      }
      _recalculatePrice();
    });
  }

  // Future<void> _scanAndAddProduct() async {
  //   try {
  //     final result = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => const SimpleBarcodeScannerPage(),
  //       ),
  //     );

  //     print('Scanned barcode: $result');
  //     print(
  //       'All product barcodes: ${_allProducts.map((p) => p['barcode']).toList()}',
  //     );

  //     if (result != null && result is String && result.isNotEmpty) {
  //       final found = _allProducts.firstWhere(
  //         (p) => (p['barcode']?.toString() ?? '') == result,
  //         orElse: () => <String, dynamic>{},
  //       );
  //       if (found.isNotEmpty) {
  //         print(
  //           'Barcode matched! Adding product: ${found['productName'] ?? found['name']}',
  //         );
  //         _addProduct(found);
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text('Product added!')));
  //       } else {
  //         print('No product found for this barcode.');
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('No product found for this barcode.')),
  //         );
  //       }
  //     } else {
  //       print('No barcode scanned or scan cancelled.');
  //     }
  //   } catch (e) {
  //     print('Barcode scan failed: $e');
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Barcode scan failed: $e')));
  //   }
  // }

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
    // TODO: Fetch user points if needed
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

  // void _addProduct(Map<String, dynamic> product) {
  //   setState(() {
  //     // If already added, increase quantity
  //     final idx = _selectedProducts.indexWhere(
  //       (p) => p['productId'] == product['productId'],
  //     );
  //     if (idx >= 0) {
  //       _selectedProducts[idx]['quantity'] += 1;
  //     } else {
  //       _selectedProducts.add({...product, 'quantity': 1});
  //     }
  //     _recalculatePrice();
  //   });
  // }

  // void _removeProduct(String productId) {
  //   setState(() {
  //     _selectedProducts.removeWhere((p) => p['productId'] == productId);
  //     _recalculatePrice();
  //   });
  // }

  // void _updateProductQuantity(String productId, int delta) {
  //   setState(() {
  //     final idx = _selectedProducts.indexWhere(
  //       (p) => p['productId'] == productId,
  //     );
  //     if (idx >= 0) {
  //       _selectedProducts[idx]['quantity'] += delta;
  //       if (_selectedProducts[idx]['quantity'] < 1)
  //         _selectedProducts[idx]['quantity'] = 1;
  //     }
  //     _recalculatePrice();
  //   });
  // }

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
    if (amt > 0) {
      setState(() {
        payments.add({'method': paymentMethod, 'amount': amt});
        paymentAmountController.clear();
        _recalculatePrice();
      });
    }
  }

  Future<void> _submitOrder() async {
    final url = "${ApiService.baseUrl}/order/create-order-by-admin";

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

    print('--- Create Order Request ---');
    print('URL: $url');
    print('Body: ${orderData}');
    print('----------------------------');

    try {
      final resp = await AppDataRepo().createOrderByAdmin(orderData);
      // Accept 200 or 201 as success
      if (resp['success'] == true || resp['status'] == 201) {
        Navigator.of(context).pop(true); // Close sheet and refresh parent

        print('--- Create Order Response ---');
        print('Status: ${resp['success']}');
        print('Response Body: ${resp['data']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Order creation failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));

      print('--- Create Order Error ---');
      print(e);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _showProductSelectionSheet() async {
    // Prepare initial counts: already selected products keep their quantity, others start at 0
    final Map<String, int> tempCounts = {};
    for (final p in _allProducts) {
      final pid = p['productId']?.toString() ?? '';
      final selected = _selectedProducts.firstWhere(
        (sp) => sp['productId']?.toString() == pid,
        orElse: () => <String, dynamic>{},
      );
      tempCounts[pid] = selected.isNotEmpty
          ? (selected['quantity'] is int
                ? selected['quantity']
                : int.tryParse(selected['quantity']?.toString() ?? '1') ?? 1)
          : 0;
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

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Text(
                    'Select Product Sets',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText:
                          'Search by product name, parent product, or price...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setModalState(() => search = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.64,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final p = filtered[idx];
                        final pid = p['productId']?.toString() ?? '';
                        final count = tempCounts[pid] ?? 0;

                        // safe image
                        String? imageUrl;
                        final imgs = p['images'];
                        if (imgs is List &&
                            imgs.isNotEmpty &&
                            imgs.first is String &&
                            (imgs.first as String).isNotEmpty) {
                          imageUrl = imgs.first as String;
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: count > 0
                                ? Colors.green.shade50
                                : Colors.white,
                            border: Border.all(
                              color: count > 0
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: count > 0 ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl ?? '',
                                    height: 60,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  p['productName'] ?? p['name'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '₹${p['price'] ?? p['singlePicPrice'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove, size: 15),
                                      onPressed: count > 0
                                          ? () => setModalState(
                                              () => tempCounts[pid] = count - 1,
                                            )
                                          : null,
                                    ),
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add, size: 15),
                                      onPressed: () => setModalState(
                                        () => tempCounts[pid] = count + 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.done),
                    label: Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44),
                    ),
                    onPressed: () {
                      // Update _selectedProducts in parent
                      setState(() {
                        // Remove products with 0 count
                        _selectedProducts.removeWhere(
                          (sp) =>
                              tempCounts[sp['productId']?.toString() ?? ''] ==
                                  null ||
                              tempCounts[sp['productId']?.toString() ?? ''] ==
                                  0,
                        );

                        tempCounts.forEach((pid, qty) {
                          if (qty > 0) {
                            final prod = _allProducts.firstWhere(
                              (p) => p['productId']?.toString() == pid,
                              orElse: () => <String, dynamic>{},
                            );
                            if (prod != null &&
                                prod is Map<String, dynamic> &&
                                prod.isNotEmpty) {
                              final idx = _selectedProducts.indexWhere(
                                (sp) => sp['productId']?.toString() == pid,
                              );
                              if (idx >= 0) {
                                _selectedProducts[idx]['quantity'] = qty;
                              } else {
                                _selectedProducts.add({
                                  ...prod,
                                  'quantity': qty,
                                });
                              }
                            }
                          }
                        });
                        _recalculatePrice();
                      });
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
                    // Customer Section

                    // Replace the Customer Section DropdownButton with this enhanced card-style dropdown:
                    Text(
                      'Customer Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
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
                                return SafeArea(
                                  child: Padding(
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
                                        ..._allCustomers.map(
                                          (c) => Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: _selectedCustomer == c
                                                    ? Colors.indigo
                                                    : Colors.grey.shade200,
                                                width: _selectedCustomer == c
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
                                                    ? NetworkImage(c['photo'])
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
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                              trailing: _selectedCustomer == c
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
                            vertical: 16,
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
                                            ),
                                          ),
                                          if ((_selectedCustomer!['email'] ??
                                                  '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              _selectedCustomer!['email'],
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          if ((_selectedCustomer!['phone'] ??
                                                  '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              _selectedCustomer!['phone'],
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          if ((_selectedCustomer!['address']?['street'] ??
                                                  '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(
                                              _selectedCustomer!['address']['street'],
                                              style: TextStyle(fontSize: 12),
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
                    // if (_selectedCustomer != null) ...[
                    //   TextFormField(
                    //     initialValue: _selectedCustomer!['email'] ?? '',
                    //     decoration: InputDecoration(labelText: 'Email'),
                    //     enabled: false,
                    //   ),
                    //   TextFormField(
                    //     initialValue: _selectedCustomer!['phone'] ?? '',
                    //     decoration: InputDecoration(labelText: 'Phone'),
                    //     enabled: false,
                    //   ),
                    //   TextFormField(
                    //     initialValue:
                    //         _selectedCustomer!['address']?['street'] ?? '',
                    //     decoration: InputDecoration(
                    //       labelText: 'Delivery Address',
                    //     ),
                    //     enabled: false,
                    //   ),
                    // ],

                    // Text(
                    //   'Customer Information',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // DropdownButton<Map<String, dynamic>>(
                    //   isExpanded: true,
                    //   value: _selectedCustomer,
                    //   hint: Text('Select Customer'),
                    //   items: _allCustomers.map((c) {
                    //     return DropdownMenuItem(
                    //       value: c,
                    //       child: Text('${c['name']} (${c['email'] ?? ''})'),
                    //     );
                    //   }).toList(),
                    //   onChanged: (val) {
                    //     if (val != null) _onSelectCustomer(val);
                    //   },
                    // ),
                    // if (_selectedCustomer != null) ...[
                    //   TextFormField(
                    //     initialValue: _selectedCustomer!['email'] ?? '',
                    //     decoration: InputDecoration(labelText: 'Email'),
                    //     enabled: false,
                    //   ),
                    //   TextFormField(
                    //     initialValue: _selectedCustomer!['phone'] ?? '',
                    //     decoration: InputDecoration(labelText: 'Phone'),
                    //     enabled: false,
                    //   ),
                    //   TextFormField(
                    //     initialValue:
                    //         _selectedCustomer!['address']?['street'] ?? '',
                    //     decoration: InputDecoration(
                    //       labelText: 'Delivery Address',
                    //     ),
                    //     enabled: false,
                    //   ),
                    // ],
                    SizedBox(height: 16),

                    // Order Info
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.indigo,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Order Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                isWide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                                  isExpanded: true,
                                                  value: orderType,
                                                  decoration: InputDecoration(
                                                    labelText: 'Order Type',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    prefixIcon: Icon(
                                                      Icons.shopping_bag,
                                                    ),
                                                  ),
                                                  items: ['Offline', 'Online']
                                                      .map(
                                                        (o) => DropdownMenuItem(
                                                          value: o,
                                                          child: Text(o),
                                                        ),
                                                      )
                                                      .toList(),
                                                  onChanged: (val) => setState(
                                                    () => orderType = val!,
                                                  ),
                                                ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: orderNoteController,
                                              decoration: InputDecoration(
                                                labelText: 'Order Note',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.note_alt_outlined,
                                                ),
                                              ),
                                              minLines: 1,
                                              maxLines: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  transportNameController,
                                              decoration: InputDecoration(
                                                labelText: 'Transport Name',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.local_shipping_outlined,
                                                ),
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
                                            decoration: InputDecoration(
                                              labelText: 'Order Type',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.shopping_bag,
                                              ),
                                            ),
                                            items: ['Offline', 'Online']
                                                .map(
                                                  (o) => DropdownMenuItem(
                                                    value: o,
                                                    child: Text(o),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (val) => setState(
                                              () => orderType = val!,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          TextField(
                                            controller: orderNoteController,
                                            decoration: InputDecoration(
                                              labelText: 'Order Note',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.note_alt_outlined,
                                              ),
                                            ),
                                            minLines: 1,
                                            maxLines: 2,
                                          ),
                                          SizedBox(height: 12),
                                          TextField(
                                            controller: transportNameController,
                                            decoration: InputDecoration(
                                              labelText: 'Transport Name',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.local_shipping_outlined,
                                              ),
                                            ),
                                            minLines: 1,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // Add Product Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.add_box_outlined,
                                  color: Colors.indigo,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add Product Sets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Enter Barcode',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.qr_code),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => barcodeInput = v,
                                  ),
                                ),
                                SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.check),
                                  label: Text('Submit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(100, 48),
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
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.list_alt),
                                  label: Text(
                                    'Manual Selection',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(80, 45),
                                    maximumSize: Size(130, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _showProductSelectionSheet,
                                ),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.qr_code_scanner),
                                  label: Text(
                                    'Scan Barcode',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(100, 45),
                                    maximumSize: Size(130, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {},
                                  // _scanAndAddProduct,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // // Product Section
                    // Text(
                    //   'Add Product Sets',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: TextField(
                    //         decoration: InputDecoration(
                    //           labelText: 'Enter Barcode',
                    //         ),
                    //         inputFormatters: [
                    //           FilteringTextInputFormatter.digitsOnly,
                    //         ],
                    //         keyboardType: TextInputType.number,
                    //         onChanged: (v) => barcodeInput = v,
                    //       ),
                    //     ),
                    //     SizedBox(
                    //       width: 150,
                    //       height: 50,
                    //       child: ElevatedButton(
                    //         child: Text('Submit'),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Colors.indigo,
                    //           foregroundColor: Colors.white,
                    //         ),
                    //         onPressed: () {
                    //           final found = _allProducts.firstWhere(
                    //             (p) => p['barcode'] == barcodeInput,
                    //             orElse: () => <String, dynamic>{},
                    //           );
                    //           if (found.isNotEmpty) _addProduct(found);
                    //         },
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(height: 8),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //   children: [
                    //     ElevatedButton(
                    //       child: Text('Manual Selection'),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: Colors.indigo,
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       onPressed: _showProductSelectionSheet,
                    //     ),
                    //     ElevatedButton(
                    //       child: Row(
                    //         children: [
                    //           Icon(Icons.qr_code_scanner),
                    //           Text('Scan Barcode'),
                    //         ],
                    //       ),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: Colors.indigo,
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       onPressed: _showProductSelectionSheet,
                    //     ),
                    //   ],
                    // ),
                    Text(
                      'Selected Products',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._selectedProducts.map((p) {
                      final int quantity = (p['quantity'] ?? 1) is int
                          ? (p['quantity'] ?? 1)
                          : int.tryParse(p['quantity'].toString()) ?? 1;
                      final int pcsInSet =
                          int.tryParse(p['pcsInSet']?.toString() ?? '1') ?? 1;
                      final String? imageUrl =
                          (p['images'] != null && p['images'].isNotEmpty)
                          ? (p['images'][0] as String?)
                          : null;
                      final String pid = getProductId(p); // <-- Use helper here
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade200,
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade100,
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 32,
                                        ),
                                      ),
                              ),
                              SizedBox(width: 12),
                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p['productName'] ?? p['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
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
                                                pid,
                                              ); // <-- Use helper here
                                            });
                                          },
                                          tooltip: 'Remove',
                                        ),
                                      ],
                                    ),

                                    if (p['availableSizes'] != null)
                                      Wrap(
                                        spacing: 6,
                                        children: (p['availableSizes'] as List)
                                            .map<Widget>(
                                              (s) => Chip(
                                                label: Text(
                                                  s,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.blue.shade50,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total: $quantity set${quantity > 1 ? 's' : ''} × $pcsInSet pcs = ${quantity * pcsInSet} pieces',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${((p['price'] ?? p['singlePicPrice'] ?? 0) * quantity * pcsInSet).toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'per set',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Quantity and pcs/set controls
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // Pcs per set selector
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text('Pcs/set:'),
                                                ElevatedButton(
                                                  style: ButtonStyle(
                                                    shape:
                                                        MaterialStateProperty.all(
                                                          CircleBorder(),
                                                        ),
                                                    backgroundColor:
                                                        MaterialStateProperty.all(
                                                          Colors.indigo,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.remove,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
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
                                                Text('$pcsInSet'),
                                                ElevatedButton(
                                                  style: ButtonStyle(
                                                    shape:
                                                        MaterialStateProperty.all(
                                                          CircleBorder(),
                                                        ),
                                                    backgroundColor:
                                                        MaterialStateProperty.all(
                                                          Colors.indigo,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      p['pcsInSet'] =
                                                          (pcsInSet + 1)
                                                              .toString();
                                                      _recalculatePrice();
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text('Qty:'),
                                                    ElevatedButton(
                                                      style: ButtonStyle(
                                                        shape:
                                                            MaterialStateProperty.all(
                                                              CircleBorder(),
                                                            ),
                                                        backgroundColor:
                                                            MaterialStateProperty.all(
                                                              Colors.indigo,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.remove,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      onPressed: quantity > 1
                                                          ? () {
                                                              setState(() {
                                                                _updateProductQuantity(
                                                                  pid,
                                                                  -1,
                                                                ); // <-- Use helper here
                                                              });
                                                            }
                                                          : null,
                                                    ),
                                                    Text('$quantity'),
                                                    ElevatedButton(
                                                      style: ButtonStyle(
                                                        shape:
                                                            MaterialStateProperty.all(
                                                              CircleBorder(),
                                                            ),
                                                        backgroundColor:
                                                            MaterialStateProperty.all(
                                                              Colors.indigo,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _updateProductQuantity(
                                                            pid,
                                                            1,
                                                          ); // <-- Use helper here
                                                        });
                                                      },
                                                    ),
                                                  ],
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
                            ],
                          ),
                        ),
                      );
                    }),

                    // Text(
                    //   'Selected Products',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // ..._selectedProducts.map((p) {
                    //   final int quantity = (p['quantity'] ?? 1) is int
                    //       ? (p['quantity'] ?? 1)
                    //       : int.tryParse(p['quantity'].toString()) ?? 1;
                    //   final int pcsInSet =
                    //       int.tryParse(p['pcsInSet']?.toString() ?? '1') ?? 1;
                    //   final String? imageUrl =
                    //       (p['images'] != null && p['images'].isNotEmpty)
                    //       ? (p['images'][0] as String?)
                    //       : null;
                    //   return Card(
                    //     margin: EdgeInsets.symmetric(vertical: 8),
                    //     elevation: 2,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(12.0),
                    //       child: Row(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           // Product Image with placeholder
                    //           ClipRRect(
                    //             borderRadius: BorderRadius.circular(8),
                    //             child: imageUrl != null && imageUrl.isNotEmpty
                    //                 ? Image.network(
                    //                     imageUrl,
                    //                     width: 70,
                    //                     height: 70,
                    //                     fit: BoxFit.cover,
                    //                     errorBuilder: (c, e, s) => Container(
                    //                       width: 70,
                    //                       height: 70,
                    //                       color: Colors.grey.shade200,
                    //                       child: Icon(
                    //                         Icons.image,
                    //                         color: Colors.grey,
                    //                         size: 32,
                    //                       ),
                    //                     ),
                    //                   )
                    //                 : Container(
                    //                     width: 70,
                    //                     height: 70,
                    //                     color: Colors.grey.shade100,
                    //                     child: Icon(
                    //                       Icons.image,
                    //                       color: Colors.grey,
                    //                       size: 32,
                    //                     ),
                    //                   ),
                    //           ),
                    //           SizedBox(width: 12),
                    //           // Product Details
                    //           Expanded(
                    //             child: Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 Row(
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.spaceBetween,
                    //                   children: [
                    //                     Text(
                    //                       p['productName'] ?? p['name'] ?? '',
                    //                       style: TextStyle(
                    //                         fontWeight: FontWeight.bold,
                    //                         fontSize: 15,
                    //                       ),
                    //                     ),

                    //                     IconButton(
                    //                       icon: Icon(
                    //                         Icons.delete,
                    //                         color: Colors.red,
                    //                       ),
                    //                       onPressed: () =>
                    //                           _removeProduct(p['productId']),
                    //                       tooltip: 'Remove',
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 // SizedBox(height: 2),
                    //                 if (p['availableSizes'] != null)
                    //                   Wrap(
                    //                     spacing: 6,
                    //                     children: (p['availableSizes'] as List)
                    //                         .map<Widget>(
                    //                           (s) => Chip(
                    //                             label: Text(
                    //                               s,
                    //                               style: TextStyle(
                    //                                 fontSize: 12,
                    //                               ),
                    //                             ),
                    //                             backgroundColor:
                    //                                 Colors.blue.shade50,
                    //                           ),
                    //                         )
                    //                         .toList(),
                    //                   ),
                    //                 // SizedBox(height: 8),
                    //                 Column(
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.spaceBetween,
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   children: [
                    //                     Text(
                    //                       'Total: $quantity set${quantity > 1 ? 's' : ''} × $pcsInSet pcs = ${quantity * pcsInSet} pieces',
                    //                       style: TextStyle(fontSize: 12),
                    //                     ),

                    //                     // Price
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           '₹${((p['price'] ?? p['singlePicPrice'] ?? 0) * quantity * pcsInSet).toStringAsFixed(0)}',
                    //                           style: TextStyle(
                    //                             fontWeight: FontWeight.bold,
                    //                             fontSize: 16,
                    //                             color: Colors.indigo,
                    //                           ),
                    //                         ),
                    //                         SizedBox(width: 4),
                    //                         Text(
                    //                           'per set',
                    //                           style: TextStyle(
                    //                             fontSize: 12,
                    //                             color: Colors.grey,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),

                    //                     // IconButton(
                    //                     //   icon: Icon(
                    //                     //     Icons.delete,
                    //                     //     color: Colors.red,
                    //                     //   ),
                    //                     //   onPressed: () =>
                    //                     //       _removeProduct(p['productId']),
                    //                     //   tooltip: 'Remove',
                    //                     // ),
                    //                   ],
                    //                 ),
                    //                 // SizedBox(height: 8),
                    //                 // Row for Pcs per set (left), Price (center), Quantity (right)
                    //                 Row(
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.spaceBetween,
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.end,
                    //                   children: [
                    //                     // Pcs per set selector
                    //                     Column(
                    //                       crossAxisAlignment:
                    //                           CrossAxisAlignment.start,
                    //                       children: [
                    //                         Row(
                    //                           children: [
                    //                             Text('Pcs/set:'),
                    //                             ElevatedButton(
                    //                               style: ButtonStyle(
                    //                                 shape:
                    //                                     MaterialStateProperty.all(
                    //                                       CircleBorder(),
                    //                                     ),
                    //                                 backgroundColor:
                    //                                     MaterialStateProperty.all(
                    //                                       Colors.indigo,
                    //                                     ),
                    //                               ),
                    //                               child: Icon(
                    //                                 Icons.remove,
                    //                                 color: Colors.white,
                    //                                 size: 18,
                    //                               ),
                    //                               onPressed: () {
                    //                                 setState(() {
                    //                                   if (pcsInSet > 1) {
                    //                                     p['pcsInSet'] =
                    //                                         (pcsInSet - 1)
                    //                                             .toString();
                    //                                     _recalculatePrice();
                    //                                   }
                    //                                 });
                    //                               },
                    //                             ),
                    //                             Text('$pcsInSet'),
                    //                             ElevatedButton(
                    //                               style: ButtonStyle(
                    //                                 shape:
                    //                                     MaterialStateProperty.all(
                    //                                       CircleBorder(),
                    //                                     ),
                    //                                 backgroundColor:
                    //                                     MaterialStateProperty.all(
                    //                                       Colors.indigo,
                    //                                     ),
                    //                               ),
                    //                               child: Icon(
                    //                                 Icons.add,
                    //                                 color: Colors.white,
                    //                                 size: 18,
                    //                               ),
                    //                               onPressed: () {
                    //                                 setState(() {
                    //                                   p['pcsInSet'] =
                    //                                       (pcsInSet + 1)
                    //                                           .toString();
                    //                                   _recalculatePrice();
                    //                                 });
                    //                               },
                    //                             ),
                    //                           ],
                    //                         ),

                    //                         SizedBox(width: 12),

                    //                         Row(
                    //                           mainAxisAlignment:
                    //                               MainAxisAlignment
                    //                                   .spaceBetween,
                    //                           children: [
                    //                             Row(
                    //                               children: [
                    //                                 Text('Qty:'),
                    //                                 ElevatedButton(
                    //                                   style: ButtonStyle(
                    //                                     shape:
                    //                                         MaterialStateProperty.all(
                    //                                           CircleBorder(),
                    //                                         ),
                    //                                     backgroundColor:
                    //                                         MaterialStateProperty.all(
                    //                                           Colors.indigo,
                    //                                         ),
                    //                                   ),
                    //                                   child: Icon(
                    //                                     Icons.remove,
                    //                                     color: Colors.white,
                    //                                     size: 18,
                    //                                   ),
                    //                                   onPressed: () =>
                    //                                       _updateProductQuantity(
                    //                                         p['productId'],
                    //                                         -1,
                    //                                       ),
                    //                                 ),
                    //                                 Text('$quantity'),
                    //                                 ElevatedButton(
                    //                                   style: ButtonStyle(
                    //                                     shape:
                    //                                         MaterialStateProperty.all(
                    //                                           CircleBorder(),
                    //                                         ),
                    //                                     backgroundColor:
                    //                                         MaterialStateProperty.all(
                    //                                           Colors.indigo,
                    //                                         ),
                    //                                   ),
                    //                                   child: Icon(
                    //                                     Icons.add,
                    //                                     color: Colors.white,
                    //                                     size: 18,
                    //                                   ),
                    //                                   onPressed: () =>
                    //                                       _updateProductQuantity(
                    //                                         p['productId'],
                    //                                         1,
                    //                                       ),
                    //                                 ),
                    //                               ],
                    //                             ),
                    //                           ],
                    //                         ),
                    //                       ],
                    //                     ),

                    //                     // Quantity selector
                    //                   ],
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   );
                    // }),

                    // Selected Products List
                    // Text(
                    //   'Selected Products',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // ..._selectedProducts.map((p) {
                    //   final int quantity = (p['quantity'] ?? 1) is int
                    //       ? (p['quantity'] ?? 1)
                    //       : int.tryParse(p['quantity'].toString()) ?? 1;
                    //   final int pcsInSet =
                    //       int.tryParse(p['pcsInSet']?.toString() ?? '1') ?? 1;
                    //   return Card(
                    //     margin: EdgeInsets.symmetric(vertical: 8),
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(12.0),
                    //       child: Row(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           // Product Image
                    //           if (p['images'] != null && p['images'].isNotEmpty)
                    //             ClipRRect(
                    //               borderRadius: BorderRadius.circular(8),
                    //               child: Image.network(
                    //                 p['images'][0],
                    //                 width: 60,
                    //                 height: 60,
                    //                 fit: BoxFit.cover,
                    //                 errorBuilder: (c, e, s) => Container(
                    //                   width: 60,
                    //                   height: 60,
                    //                   color: Colors.grey.shade200,
                    //                   child: Icon(
                    //                     Icons.image,
                    //                     color: Colors.grey,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           SizedBox(width: 12),
                    //           // Product Details
                    //           Expanded(
                    //             child: Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 Text(
                    //                   p['productName'] ?? p['name'] ?? '',
                    //                   style: TextStyle(
                    //                     fontWeight: FontWeight.bold,
                    //                   ),
                    //                 ),
                    //                 SizedBox(height: 2),
                    //                 if (p['availableSizes'] != null)
                    //                   Wrap(
                    //                     spacing: 6,
                    //                     children: (p['availableSizes'] as List)
                    //                         .map<Widget>(
                    //                           (s) => Chip(
                    //                             label: Text(
                    //                               s,
                    //                               style: TextStyle(
                    //                                 fontSize: 12,
                    //                               ),
                    //                             ),
                    //                             backgroundColor:
                    //                                 Colors.blue.shade50,
                    //                           ),
                    //                         )
                    //                         .toList(),
                    //                   ),
                    //                 SizedBox(height: 8),
                    //                 // Row for Total and Delete Button
                    //                 Row(
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.spaceBetween,
                    //                   children: [
                    //                     Text(
                    //                       'Total: $quantity set${quantity > 1 ? 's' : ''} × $pcsInSet pcs = ${quantity * pcsInSet} pieces',
                    //                       style: TextStyle(fontSize: 12),
                    //                     ),
                    //                     IconButton(
                    //                       icon: Icon(
                    //                         Icons.delete,
                    //                         color: Colors.red,
                    //                       ),
                    //                       onPressed: () =>
                    //                           _removeProduct(p['productId']),
                    //                       tooltip: 'Remove',
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 SizedBox(height: 8),
                    //                 // Row for Pcs per set (left), Price (center), Quantity (right)
                    //                 SingleChildScrollView(
                    //                   scrollDirection: Axis.horizontal,
                    //                   child: Row(
                    //                     children: [
                    //                       // Pcs per set selector (bottom left)
                    //                       Row(
                    //                         children: [
                    //                           Text('Pcs/set:'),
                    //                           IconButton(
                    //                             icon: Icon(
                    //                               Icons.remove,
                    //                               size: 18,
                    //                             ),
                    //                             onPressed: () {
                    //                               setState(() {
                    //                                 if (pcsInSet > 1) {
                    //                                   p['pcsInSet'] =
                    //                                       (pcsInSet - 1)
                    //                                           .toString();
                    //                                   _recalculatePrice();
                    //                                 }
                    //                               });
                    //                             },
                    //                           ),
                    //                           Text('$pcsInSet'),
                    //                           IconButton(
                    //                             icon: Icon(Icons.add, size: 18),
                    //                             onPressed: () {
                    //                               setState(() {
                    //                                 p['pcsInSet'] =
                    //                                     (pcsInSet + 1)
                    //                                         .toString();
                    //                                 _recalculatePrice();
                    //                               });
                    //                             },
                    //                           ),
                    //                         ],
                    //                       ),
                    //                       SizedBox(width: 12),
                    //                       // Price (center right)
                    //                       Column(
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.end,
                    //                         children: [
                    //                           Text(
                    //                             '₹${((p['price'] ?? p['singlePicPrice'] ?? 0) * quantity * pcsInSet).toStringAsFixed(0)}',
                    //                             style: TextStyle(
                    //                               fontWeight: FontWeight.bold,
                    //                               fontSize: 16,
                    //                               color: Colors.indigo,
                    //                             ),
                    //                           ),
                    //                           Text(
                    //                             'per set',
                    //                             style: TextStyle(
                    //                               fontSize: 11,
                    //                               color: Colors.grey,
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                       SizedBox(width: 12),
                    //                       // Quantity selector (bottom right)
                    //                       Row(
                    //                         children: [
                    //                           Text('Qty:'),
                    //                           IconButton(
                    //                             icon: Icon(
                    //                               Icons.remove,
                    //                               size: 18,
                    //                             ),
                    //                             onPressed: () =>
                    //                                 _updateProductQuantity(
                    //                                   p['productId'],
                    //                                   -1,
                    //                                 ),
                    //                           ),
                    //                           Text('$quantity'),
                    //                           IconButton(
                    //                             icon: Icon(Icons.add, size: 18),
                    //                             onPressed: () =>
                    //                                 _updateProductQuantity(
                    //                                   p['productId'],
                    //                                   1,
                    //                                 ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   );
                    // }),
                    SizedBox(height: 16),

                    // Points Redemption

                    // Redeem Points Section
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.stars, color: Colors.amber[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Redeem Points',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                isWide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Available: ${formatK(availablePoints)} pts',
                                                ),
                                                Text(
                                                  'Value: ₹${formatK(availablePoints * pointValue)}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Discount: ₹${formatK(discountValue)}',
                                                ),
                                                Text(
                                                  'Max Redeemable: $maxRedeemable pts',
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove),
                                                onPressed: redeemNow > 0
                                                    ? () => setState(() {
                                                        redeemNow--;
                                                        discountValue =
                                                            redeemNow *
                                                            pointValue;
                                                        _recalculatePrice();
                                                      })
                                                    : null,
                                              ),
                                              Text(
                                                '$redeemNow',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed:
                                                    redeemNow < maxRedeemable
                                                    ? () => setState(() {
                                                        redeemNow++;
                                                        discountValue =
                                                            redeemNow *
                                                            pointValue;
                                                        _recalculatePrice();
                                                      })
                                                    : null,
                                              ),
                                              SizedBox(width: 8),
                                              ElevatedButton(
                                                child: Text('Redeem'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.indigo,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: maxRedeemable > 0
                                                    ? () {
                                                        setState(() {
                                                          redeemNow =
                                                              maxRedeemable;
                                                          discountValue =
                                                              redeemNow *
                                                              pointValue;
                                                          _recalculatePrice();
                                                        });
                                                      }
                                                    : null,
                                              ),
                                              SizedBox(width: 8),
                                              ElevatedButton(
                                                child: Text('Clear'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: redeemNow > 0
                                                    ? () {
                                                        setState(() {
                                                          redeemNow = 0;
                                                          discountValue = 0.0;
                                                          _recalculatePrice();
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Available: ${formatK(availablePoints)} pts',
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Value: ₹${formatK(availablePoints * pointValue)}',
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Discount: ₹${formatK(discountValue)}',
                                                ),
                                              ),
                                              // Expanded(
                                              //   child:

                                              // ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                style: ButtonStyle(
                                                  shape:
                                                      MaterialStateProperty.all(
                                                        CircleBorder(),
                                                      ),
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                        Colors.indigo,
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  color: Colors.white,
                                                ),
                                                onPressed: redeemNow > 0
                                                    ? () => setState(() {
                                                        redeemNow--;
                                                        discountValue =
                                                            redeemNow *
                                                            pointValue;
                                                        _recalculatePrice();
                                                      })
                                                    : null,
                                              ),
                                              Text(
                                                '$redeemNow',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ButtonStyle(
                                                  shape:
                                                      MaterialStateProperty.all(
                                                        CircleBorder(),
                                                      ),
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                        Colors.indigo,
                                                      ),
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                ),
                                                onPressed:
                                                    redeemNow < maxRedeemable
                                                    ? () => setState(() {
                                                        redeemNow++;
                                                        discountValue =
                                                            redeemNow *
                                                            pointValue;
                                                        _recalculatePrice();
                                                      })
                                                    : null,
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ElevatedButton(
                                                child: Text('Redeem'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.indigo,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: maxRedeemable > 0
                                                    ? () {
                                                        setState(() {
                                                          redeemNow =
                                                              maxRedeemable;
                                                          discountValue =
                                                              redeemNow *
                                                              pointValue;
                                                          _recalculatePrice();
                                                        });
                                                      }
                                                    : null,
                                              ),
                                              // SizedBox(width: 8),
                                              ElevatedButton(
                                                child: Text('Clear'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: redeemNow > 0
                                                    ? () {
                                                        setState(() {
                                                          redeemNow = 0;
                                                          discountValue = 0.0;
                                                          _recalculatePrice();
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Max Redeemable: $maxRedeemable pts',
                                          ),
                                        ],
                                      ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // Text(
                    //   'Redeem Points',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // Row(
                    //   children: [
                    //     Text('Available: ${formatK(availablePoints)} pts'),

                    //     Spacer(),
                    //     Column(
                    //       crossAxisAlignment: CrossAxisAlignment.end,
                    //       children: [
                    //         Text(
                    //           'Value: ₹${formatK(availablePoints * pointValue)}',
                    //         ),

                    //         Text('Discount: ₹${formatK(discountValue)}'),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                    // Row(
                    //   children: [
                    //     IconButton(
                    //       icon: Icon(Icons.remove),
                    //       onPressed: redeemNow > 0
                    //           ? () => setState(() {
                    //               redeemNow--;
                    //               discountValue = redeemNow * pointValue;
                    //               _recalculatePrice();
                    //             })
                    //           : null,
                    //     ),
                    //     Text('$redeemNow'),
                    //     IconButton(
                    //       icon: Icon(Icons.add),
                    //       onPressed: redeemNow < maxRedeemable
                    //           ? () => setState(() {
                    //               redeemNow++;
                    //               discountValue = redeemNow * pointValue;
                    //               _recalculatePrice();
                    //             })
                    //           : null,
                    //     ),
                    //     SizedBox(width: 12),
                    //     ElevatedButton(
                    //       child: Text('Redeem'),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: Colors.indigo,
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       onPressed: maxRedeemable > 0
                    //           ? () {
                    //               setState(() {
                    //                 redeemNow = maxRedeemable;
                    //                 discountValue = redeemNow * pointValue;
                    //                 _recalculatePrice();
                    //               });
                    //             }
                    //           : null,
                    //     ),
                    //     SizedBox(width: 8),
                    //     ElevatedButton(
                    //       child: Text('Clear'),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: Colors.red,
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       onPressed: redeemNow > 0
                    //           ? () {
                    //               setState(() {
                    //                 redeemNow = 0;
                    //                 discountValue = 0.0;
                    //                 _recalculatePrice();
                    //               });
                    //             }
                    //           : null,
                    //     ),
                    //   ],
                    // ),
                    // Text('Max Redeemable: $maxRedeemable pts'),
                    SizedBox(height: 16),

                    // Payment Information
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      color: Colors.indigo,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Payment Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                isWide
                                    ? Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: DropdownButtonFormField<String>(
                                              value: paymentMethod,
                                              decoration: InputDecoration(
                                                labelText: 'Method',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                prefixIcon: Icon(
                                                  Icons
                                                      .account_balance_wallet_outlined,
                                                ),
                                              ),
                                              items:
                                                  [
                                                        'Cash',
                                                        'UPI',
                                                        'Bank Transfer',
                                                        'Card',
                                                        'Net Banking',
                                                      ]
                                                      .map(
                                                        (m) => DropdownMenuItem(
                                                          value: m,
                                                          child: Text(m),
                                                        ),
                                                      )
                                                      .toList(),
                                              onChanged: (val) => setState(
                                                () => paymentMethod = val!,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller:
                                                  paymentAmountController,
                                              decoration: InputDecoration(
                                                labelText: 'Amount',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.currency_rupee,
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.add),
                                            label: Text('Add'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              foregroundColor: Colors.white,
                                              minimumSize: Size(60, 48),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: _addPayment,
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          DropdownButtonFormField<String>(
                                            value: paymentMethod,
                                            decoration: InputDecoration(
                                              labelText: 'Method',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                              ),
                                            ),
                                            items:
                                                [
                                                      'Cash',
                                                      'UPI',
                                                      'Bank Transfer',
                                                      'Card',
                                                      'Net Banking',
                                                    ]
                                                    .map(
                                                      (m) => DropdownMenuItem(
                                                        value: m,
                                                        child: Text(m),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged: (val) => setState(
                                              () => paymentMethod = val!,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          TextField(
                                            controller: paymentAmountController,
                                            decoration: InputDecoration(
                                              labelText: 'Amount',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              prefixIcon: Icon(
                                                Icons.currency_rupee,
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                          SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.add),
                                            label: Text('Add'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              foregroundColor: Colors.white,
                                              minimumSize: Size(60, 48),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: _addPayment,
                                          ),
                                        ],
                                      ),
                                SizedBox(height: 12),
                                ...payments.map(
                                  (p) => ListTile(
                                    leading: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: Text('${p['method']}'),
                                    trailing: Text(
                                      '₹${p['amount']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // Row(
                    //   children: [
                    //     DropdownButton<String>(
                    //       value: paymentMethod,
                    //       items:
                    //           [
                    //                 'Cash',
                    //                 'UPI',
                    //                 'Bank Transfer',
                    //                 'Card',
                    //                 'Net Banking',
                    //               ]
                    //               .map(
                    //                 (m) => DropdownMenuItem(
                    //                   value: m,
                    //                   child: Text(m),
                    //                 ),
                    //               )
                    //               .toList(),
                    //       onChanged: (val) =>
                    //           setState(() => paymentMethod = val!),
                    //     ),
                    //     SizedBox(width: 8),
                    //     Expanded(
                    //       child: TextField(
                    //         controller: paymentAmountController,
                    //         decoration: InputDecoration(labelText: 'Amount'),
                    //         keyboardType: TextInputType.number,
                    //       ),
                    //     ),
                    //     ElevatedButton(
                    //       child: Text('Add Payment'),
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor: Colors.indigo,
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       onPressed: _addPayment,
                    //     ),
                    //   ],
                    // ),
                    // // Payment List
                    // ...payments.map(
                    //   (p) => ListTile(
                    //     title: Text('${p['method']}'),
                    //     trailing: Text('₹${p['amount']}'),
                    //   ),
                    // ),
                    // SizedBox(height: 16),

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
                        Text('Total Paid:'),
                        Text('₹${totalPaid.toStringAsFixed(2)}'),
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
