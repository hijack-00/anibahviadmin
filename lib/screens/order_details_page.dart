import 'package:anibhaviadmin/services/api_service.dart';
import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  const OrderDetailsPage({required this.orderId, Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final Map<String, String> orderStatusOptionsMap = {
    'Order Pending': 'pending',
    'Order Confirmed': 'order Confirmed',
    'Processing': 'processing',
    'Shipped': 'shipped',
    'Delivered': 'delivered',
    'Cancelled': 'cancelled',
  };
  List<String> get orderStatusOptions => orderStatusOptionsMap.keys.toList();
  final List<String> paymentStatusOptions = [
    'Pending',
    'Complete Payment',
    'Failed',
    'Partial Payment',
  ];
  String? _selectedOrderStatus;
  String? _selectedPaymentStatus;

  Future<void> _changeOrderStatus() async {
    if (_selectedOrderStatus == null && _selectedPaymentStatus == null) return;
    try {
      final repo = AppDataRepo();
      final resp = await repo.changeOrderStatus(
        widget.orderId,
        orderStatus: _selectedOrderStatus != null ? orderStatusOptionsMap[_selectedOrderStatus!] : null,
        paymentStatus: _selectedPaymentStatus,
      );
      if (resp['success'] == true) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Status updated successfully'), backgroundColor: Colors.green),
        );
        await _fetchOrderDetails();
      } else {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Failed to update status'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
  Future<void> _deleteOrder() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Delete Order'),
      content: Text('Are you sure you want to delete this order?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: Text('Confirm', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      final repo = AppDataRepo();
      final resp = await repo.deleteOrderById(widget.orderId);

      print("API response: $resp");

      // 🔑 Check `status` instead of `success`
      if (resp['status'] == true) {
        if (!mounted) return;

        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              resp['message'] ?? 'Order deleted successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );

        // ✅ Pop OrderDetailsPage
        Navigator.of(context, rootNavigator: true).pop(true);
      } else {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              resp['message'] ?? 'Failed to delete order',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = AppDataRepo();
      final response = await repo.fetchOrderById(widget.orderId);
      if (response['success'] == true && response['order'] != null) {
        setState(() {
          _order = response['order'];
          _loading = false;
          _selectedOrderStatus = _order!['orderStatus'] != null ? _mapOrderStatus(_order!['orderStatus']) : null;
          _selectedPaymentStatus = _order!['paymentStatus'] != null ? _mapPaymentStatus(_order!['paymentStatus']) : null;
        });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load order'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String? _mapOrderStatus(dynamic status) {
    final s = status.toString().toLowerCase();
    if (s == 'pending') return 'Order Pending';
    if (s == 'order confirmed') return 'Order Confirmed';
    if (s == 'processing') return 'Processing';
    if (s == 'shipped') return 'Shipped';
    if (s == 'delivered') return 'Delivered';
    if (s == 'cancelled') return 'Cancelled';
    return null;
  }
  String? _mapPaymentStatus(dynamic status) {
    final s = status.toString().toLowerCase();
    if (s.contains('pending')) return 'Pending';
    if (s.contains('complete')) return 'Complete Payment';
    if (s.contains('fail')) return 'Failed';
    if (s.contains('partial')) return 'Partial Payment';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: _loading
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: List.generate(5, (i) => Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
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
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _order == null
                  ? Center(child: Text('No order found'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: [
                          Text('Order ID: ${_order!['orderUniqueId'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 8),
                          // Payment details UI with highlights
                          Text('Amount: ₹${_order!['totalAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Payment Method: ${_order!['paymentMethod'] ?? ''}', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Payment Status: ${_order!['paymentStatus'] ?? ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                (_order!['paymentStatus']?.toString().toLowerCase().contains('fail') ?? false)
                                  ? Colors.red
                                  : (_order!['paymentStatus']?.toString().toLowerCase().contains('complete') ?? false)
                                    ? Colors.indigo
                                    : (_order!['paymentStatus']?.toString().toLowerCase().contains('partial') ?? false)
                                      ? Colors.green
                                      : Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Received Amount: ₹${_order!['recivedAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Pending Amount: ₹${_order!['pendingAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                          Divider(),
                          Text('Customer: ${_order!['shippingAddress']?['name'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Text('Phone: ${_order!['shippingAddress']?['phone'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Text('Address: ${_order!['shippingAddress']?['address'] ?? ''}, ${_order!['shippingAddress']?['city'] ?? ''}, ${_order!['shippingAddress']?['state'] ?? ''}, ${_order!['shippingAddress']?['country'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Divider(),
                          Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...?_order!['products']?.map<Widget>((prod) {
                            final subProducts = prod['subProduct'] ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List<Widget>.from(subProducts.map<Widget>((subProd) {
                                final images = List<String>.from(subProd['subProductImages'] ?? []);
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: images.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(images[0], width: 48, height: 48, fit: BoxFit.cover),
                                          )
                                        : Container(width: 48, height: 48, color: Colors.grey[300], child: Icon(Icons.image)),
                                    title: Text(subProd['productId']?['productName'] ?? 'Product'),
                                    subtitle: Text('Qty: ${prod['quantity']?[0] ?? ''} | Price: ₹${prod['price']?[0] ?? ''}'),
                                  ),
                                );
                              })),
                            );
                          })?.toList(),
                          SizedBox(height: 16),
                          // Dropdowns above delete button (in Column)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(labelText: 'Order Status'),
                                value: _selectedOrderStatus,
                                items: orderStatusOptions.map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() { _selectedOrderStatus = val; });
                                  _changeOrderStatus();
                                },
                              ),
                              SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(labelText: 'Payment Status'),
                                value: _selectedPaymentStatus,
                                items: paymentStatusOptions.map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() { _selectedPaymentStatus = val; });
                                  _changeOrderStatus();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await _deleteOrder();
                              if (mounted) Navigator.of(context).pop(true); // Return true to previous page for refresh
                            },
                            child: Text('Delete Order', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
