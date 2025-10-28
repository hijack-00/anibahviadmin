import 'package:anibhaviadmin/services/api_service.dart';
import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({required this.orderId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allOrders =
        ModalRoute.of(context)?.settings.arguments
            as List<Map<String, dynamic>>?;
    final order = allOrders?.firstWhere(
      (o) => o['_id'] == orderId || o['id'] == orderId,
      orElse: () => {},
    );

    if (order == null || order.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(child: Text('Order not found')),
      );
    }

    final customer = order['customer'] ?? {};
    final user = customer['userId'] ?? {};
    final address = user['address'] ?? {};
    final items = order['items'] ?? [];
    final payments = order['payments'] ?? [];
    final statusHistory = order['statusHistory'] ?? [];
    final paidAmount = order['paidAmount'] ?? 0;
    final balanceAmount = order['balanceAmount'] ?? 0;
    final paymentType = order['paymentType'] ?? '';
    final paymentMethod = order['paymentMethod'] ?? '';
    final subtotal = order['subtotal'] ?? 0;
    final total = order['total'] ?? 0;
    final pointsRedeemed = order['pointsRedeemed'] ?? 0;
    final pointsRedemptionValue = order['pointsRedemptionValue'] ?? 0;
    final pointsEarned = order['pointsEarned'] ?? 0;
    final pointsEarnedValue = order['pointsEarnedValue'] ?? 0;
    final orderNote = order['orderNote'] ?? '';
    final transportName = order['transportName'] ?? '';
    final orderType = order['orderType'] ?? '';
    final orderDate = order['orderDate'] ?? '';
    final status = order['status'] ?? '';
    final deliveryAddress = customer['deliveryAddress'] ?? '';

    Color statusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'packed':
          return Colors.blue;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${order['orderNumber'] ?? ''}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 12.0),
        //     child: ElevatedButton.icon(
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.green,
        //         foregroundColor: Colors.white,
        //         elevation: 0,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(6),
        //         ),
        //       ),
        //       icon: Icon(Icons.print, size: 18),
        //       label: Text('Print Invoice'),
        //       onPressed: () {},
        //     ),
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Row: Customer Info, Order Info, Status History
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              // margin: EdgeInsets.only(right: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'User ID: ${user['uniqueUserId'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          'Shop Name: ${user['shopname'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Name: ${customer['name'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          'Phone: ${customer['phone'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),

                                    Text(
                                      'Email: ${customer['email'] ?? ''}',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Order Info
                      Card(
                        elevation: 0,
                        // margin: EdgeInsets.only(right: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date: $orderDate',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Type: $orderType',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Type: $paymentType',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Payment Method: $paymentMethod',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (transportName.toString().isNotEmpty)
                                        Text(
                                          'Transport: $transportName',
                                          style: TextStyle(fontSize: 11),
                                        ),

                                      if (orderNote.toString().isNotEmpty)
                                        Text(
                                          'Note: $orderNote',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                    ],
                                  ),

                                  Column(
                                    children: [
                                      Text(
                                        'Subtotal: ₹$subtotal',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        'Total: ₹$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
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

                      // Status History
                    ],
                  ),

                  // Delivery Address
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''}, ${address['country'] ?? ''} - ${address['zipCode'] ?? ''}',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          ...statusHistory.map<Widget>(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: statusColor(s['status'] ?? ''),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${s['status'] ?? ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${s['date'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'by ${s['updatedBy'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              // Payment Information
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Paid Amount: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$paidAmount',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  Text(
                                    'Redeemed:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,

                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "$pointsRedeemed Points",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  Text(
                                    'Balance Amount: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$balanceAmount',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    'Earned:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "$pointsEarned Points",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              // SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,

                                children: [
                                  Text(
                                    'Discount:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$pointsRedemptionValue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    'Earned Value:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$pointsEarnedValue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6),

                      // SizedBox(height: 12),
                      Text(
                        'Payments:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...payments.map<Widget>(
                        (pm) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${pm['method'] ?? 'Cash'}:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${pm['amount'] ?? ''}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              // Items
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      ...items.map<Widget>((item) {
                        // Calculate total pieces and total price
                        final sets = item['quantity'] ?? 1;
                        final pcsInSet = item['pcsInSet'] ?? 1;
                        final pricePerPiece = item['singlePicPrice'] ?? 0;
                        final totalPcs = sets * pcsInSet;
                        final totalPrice = pricePerPiece * totalPcs;

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              item['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity: $sets sets × $pcsInSet pcs = $totalPcs pieces',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Price: ₹$pricePerPiece per piece',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₹${totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '$totalPcs pieces',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              //   onPressed: () => Navigator.of(context).pop(true),
              //   child: Text(
              //     'Delete Order',
              //     style: TextStyle(color: Colors.white),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
