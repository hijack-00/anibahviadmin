import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  const OrderDetailsPage({required this.orderId, Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
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
        setState(() { _order = response['order']; _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load order'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
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
                          Text('Status: ${_order!['orderStatus'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Text('Amount: ₹${_order!['totalAmount'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Divider(),
                          Text('Customer: ${_order!['shippingAddress']?['name'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Text('Phone: ${_order!['shippingAddress']?['phone'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Text('Address: ${_order!['shippingAddress']?['address'] ?? ''}, ${_order!['shippingAddress']?['city'] ?? ''}, ${_order!['shippingAddress']?['state'] ?? ''}, ${_order!['shippingAddress']?['country'] ?? ''}', style: TextStyle(fontSize: 16)),
                          Divider(),
                          Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...?_order!['products']?.map<Widget>((prod) {
                            final subProd = prod['subProduct']?[0];
                            return ListTile(
                              title: Text(subProd?['productId']?['productName'] ?? 'Product'),
                              subtitle: Text('Qty: ${prod['quantity']?[0] ?? ''} | Price: ₹${prod['price']?[0] ?? ''}'),
                            );
                          })?.toList(),
                        ],
                      ),
                    ),
    );
  }
}
