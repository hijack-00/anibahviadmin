import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';
import 'order_details_page.dart';

class AllOrdersPage extends StatefulWidget {
  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = AppDataRepo();
      final response = await repo.fetchAllOrders();
      if (response['success'] == true && response['orders'] != null) {
        setState(() { _orders = response['orders']; _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load orders'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  final statusColors = {
    'pending': Colors.yellow.shade700,
    'shipped': Colors.blue,
    'delivered': Colors.green,
    'cancelled': Colors.red,
    'confirmed': Colors.indigo,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('All Orders')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, idx) {
                    final order = _orders[idx];
                    final shipping = order['shippingAddress'] ?? {};
                    String statusRaw = (order['orderStatus'] ?? '').toString().trim();
                    String status = statusRaw.toLowerCase() == 'order confirmed' ? 'Confirmed' : statusRaw;
                    String paymentStatus = (order['paymentStatus'] ?? '').toString().trim();
                    return Card(
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(orderId: order['_id']),
                            ),
                          );
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
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  },
                ),
    );
  }
}
