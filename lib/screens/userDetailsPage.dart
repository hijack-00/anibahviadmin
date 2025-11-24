import 'package:anibhaviadmin/permissions/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/app_data_repo.dart';
import 'order_details_page.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  const UserDetailsPage({required this.userId, Key? key}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with PermissionHelper {
  Map<String, dynamic>? _user;
  bool _loading = true;

  bool _toggleLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load permissions for /users (update/delete user)
    initPermissions('/users').then((_) {
      if (!mounted) return;
      debugPrint(
        'UserDetailsPage permissions: canUpdate=$canUpdate canDelete=$canDelete',
      );
    });

    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await AppDataRepo().fetchUserDetailsById(widget.userId);
      if (response['success'] == true && response['user'] != null) {
        setState(() {
          _user = response['user'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load user';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleUserStatus() async {
    if (_user == null) return;
    setState(() {
      _toggleLoading = true;
    });
    try {
      final result = await AppDataRepo().toggleUserStatus(_user!['_id']);
      if (result['success'] == true) {
        setState(() {
          _user!['isActive'] = !_user!['isActive'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Status updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update status'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _toggleLoading = false;
      });
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final resp = await AppDataRepo().deleteUserById(widget.userId);
        if (resp['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resp['message'] ?? 'User deleted successfully',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resp['message'] ?? 'Failed to delete user',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showOrdersBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: AppDataRepo().fetchOrdersByUserId(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // debug print
                if (snapshot.hasData) {
                  print('Get orders by user id response: ${snapshot.data}');
                } else if (snapshot.hasError) {
                  print('Get orders by user id error: ${snapshot.error}');
                }

                if (snapshot.hasError ||
                    snapshot.data == null ||
                    snapshot.data!['success'] != true) {
                  final msg =
                      snapshot.data != null && snapshot.data!['message'] != null
                      ? snapshot.data!['message'].toString()
                      : 'User has no orders';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final rawOrders = snapshot.data!['orders'] ?? [];
                final orders = List<Map<String, dynamic>>.from(rawOrders);
                print(
                  'Orders fetched for user ${widget.userId}: ${orders.length}',
                );

                return Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: ListView.separated(
                    controller: scrollController,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      // prefer orderNumber from API
                      final orderTitle =
                          (order['orderNumber'] ?? order['_id'] ?? '')
                              .toString();

                      // customer info (API uses customer.userId)
                      final customer = (order['customer'] is Map)
                          ? Map<String, dynamic>.from(order['customer'])
                          : <String, dynamic>{};
                      final userIdMap = (customer['userId'] is Map)
                          ? Map<String, dynamic>.from(customer['userId'])
                          : <String, dynamic>{};
                      final buyerName =
                          (userIdMap['name'] ?? customer['name'] ?? '')
                              .toString();
                      final buyerPhone =
                          (userIdMap['phone'] ?? customer['phone'] ?? '')
                              .toString();
                      final buyerEmail =
                          (userIdMap['email'] ?? customer['email'] ?? '')
                              .toString();
                      final deliveryAddr = (customer['deliveryAddress'] ?? '')
                          .toString();

                      final status =
                          (order['status'] ?? order['orderStatus'] ?? '')
                              .toString();
                      final paymentType =
                          (order['paymentType'] ?? order['paymentMethod'] ?? '')
                              .toString();
                      final total = (order['total'] ?? order['subtotal'] ?? 0)
                          .toString();
                      final paid = (order['paidAmount'] ?? order['paid'] ?? 0)
                          .toString();
                      final balance =
                          (order['balanceAmount'] ?? order['balance'] ?? 0)
                              .toString();
                      final orderDate =
                          (order['orderDate'] ?? order['createdAt'] ?? '')
                              .toString();

                      final items = (order['items'] is List)
                          ? List.from(order['items'])
                          : <dynamic>[];
                      final itemsSummary = items.isEmpty
                          ? ''
                          : '${items.length} item${items.length > 1 ? 's' : ''} • ${items.map((it) => (it['name'] ?? it['productId']?['name'] ?? '')).where((e) => e != '').take(3).join(', ')}';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            Navigator.of(context).pop();
                            final orderId = (order['_id'] ?? orderTitle)
                                .toString();
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailsPage(orderId: orderId),
                                settings: RouteSettings(arguments: [order]),
                              ),
                            );

                            // Navigator.of(context).pop();
                            // await Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (_) =>
                            //         OrderDetailsPage(orderId: order['_id']),
                            //   ),
                            // );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        orderTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            status.toLowerCase().contains(
                                              'pending',
                                            )
                                            ? Colors.orange
                                            : status.toLowerCase().contains(
                                                'cancel',
                                              )
                                            ? Colors.red
                                            : status.toLowerCase().contains(
                                                    'shipped',
                                                  ) ||
                                                  status.toLowerCase().contains(
                                                    'ship',
                                                  )
                                            ? Colors.blue
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (buyerName.isNotEmpty)
                                  const SizedBox(height: 6),
                                if (buyerName.isNotEmpty)
                                  Text(
                                    buyerName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                if (buyerPhone.isNotEmpty ||
                                    buyerEmail.isNotEmpty)
                                  Text(
                                    '${buyerPhone}${buyerPhone.isNotEmpty && buyerEmail.isNotEmpty ? ' • ' : ''}$buyerEmail',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                if (deliveryAddr.isNotEmpty)
                                  const SizedBox(height: 4),
                                if (deliveryAddr.isNotEmpty)
                                  Text(
                                    deliveryAddr,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                if (itemsSummary.isNotEmpty)
                                  const SizedBox(height: 6),
                                if (itemsSummary.isNotEmpty)
                                  Text(
                                    itemsSummary,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Type: $paymentType • Date: $orderDate',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    Text(
                                      '₹$total',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (paid != '0' && paid != '0.0')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Paid: ₹$paid',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    if (balance != '0' && balance != '0.0')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Balance: ₹$balance',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
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
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showCartBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: AppDataRepo().fetchCartByUserId(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    snapshot.data == null ||
                    snapshot.data!['success'] != true) {
                  return Center(
                    child: Text(
                      "User's cart is empty",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final cart = snapshot.data!['card'];
                final items = List<Map<String, dynamic>>.from(
                  cart['items'] ?? [],
                );
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      "User's cart is empty",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: ListView.separated(
                    controller: scrollController,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // final product = item['product'] ?? {};
                      // return Card(
                      //   elevation: 1,
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: ListTile(
                      //     leading:
                      //         (product['photo'] != null &&
                      //             product['photo'].toString().isNotEmpty)
                      //         ? ClipRRect(
                      //             borderRadius: BorderRadius.circular(6),
                      //             child: Image.network(
                      //               product['photo'],
                      //               width: 40,
                      //               height: 40,
                      //               fit: BoxFit.cover,
                      //             ),
                      //           )
                      //         : Icon(Icons.image),
                      //     title: Text(
                      //       product['productName'] ?? '',
                      //       style: TextStyle(
                      //         fontWeight: FontWeight.bold,
                      //         fontSize: 11,
                      //       ),
                      //     ),
                      //     subtitle: Text(
                      //       'Qty: ${item['quantity'] ?? 0}',
                      //       style: TextStyle(fontSize: 10),
                      //     ),
                      //   ),
                      // );
                      // Support both item['product'] and item['subProduct'] shapes
                      final Map<String, dynamic> subProduct =
                          (item['subProduct'] is Map)
                          ? Map<String, dynamic>.from(item['subProduct'])
                          : {};
                      final Map<String, dynamic> product =
                          (item['product'] is Map)
                          ? Map<String, dynamic>.from(item['product'])
                          : {};

                      final String title = subProduct.isNotEmpty
                          ? (subProduct['name'] ??
                                (subProduct['productId'] is Map
                                    ? subProduct['productId']['productName']
                                    : '') ??
                                '')
                          : (product['productName'] ?? product['name'] ?? '');

                      String imageUrl = '';
                      if (subProduct.isNotEmpty) {
                        if (subProduct['subProductImages'] is List &&
                            (subProduct['subProductImages'] as List)
                                .isNotEmpty) {
                          imageUrl = (subProduct['subProductImages'] as List)
                              .first
                              .toString();
                        } else if (subProduct['productId'] is Map &&
                            (subProduct['productId']['images'] is List &&
                                subProduct['productId']['images'].isNotEmpty)) {
                          imageUrl = subProduct['productId']['images'][0]
                              .toString();
                        }
                      } else {
                        if (product['photo'] != null &&
                            product['photo'].toString().isNotEmpty) {
                          imageUrl = product['photo'].toString();
                        } else if (product['images'] is List &&
                            product['images'].isNotEmpty) {
                          imageUrl = product['images'][0].toString();
                        }
                      }

                      final qty = (item['quantity'] ?? item['qty'] ?? 1)
                          .toString();
                      final price =
                          (subProduct['singlePicPrice'] ??
                                  subProduct['filnalLotPrice'] ??
                                  product['price'] ??
                                  '')
                              .toString();

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    imageUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image),
                                  ),
                                )
                              : const Icon(Icons.image),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            'Qty: $qty' +
                                (price.isNotEmpty ? ' • ₹$price' : ''),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            // optionally navigate to product/subproduct detail
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? UserDetailsSkeleton()
          : _user == null
          ? Center(child: Text(_error ?? 'No user found'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            _user!['photo'] != null &&
                                _user!['photo'].toString().isNotEmpty
                            ? NetworkImage(_user!['photo'])
                            : null,
                        child:
                            _user!['photo'] == null ||
                                _user!['photo'].toString().isEmpty
                            ? Icon(Icons.person, size: 28)
                            : null,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ID: ${_user!['uniqueUserId'] ?? ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.indigo,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _user!['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _user!['email'] ?? '',
                              style: TextStyle(fontSize: 10),
                            ),
                            Text(
                              _user!['phone'] ?? '',
                              style: TextStyle(fontSize: 10),
                            ),
                            Text(
                              'Shop: ${_user!['shopname'] ?? ''}',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (canUpdate)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Active', style: TextStyle(fontSize: 12)),
                      value: _user!['isActive'] ?? false,
                      onChanged: _toggleLoading
                          ? null
                          : (val) => _toggleUserStatus(),
                      subtitle: _toggleLoading
                          ? Text('Updating...', style: TextStyle(fontSize: 10))
                          : null,
                    ),
                  Divider(),
                  ListTile(
                    title: Text('Address', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${_user!['address']?['street'] ?? ''}, ${_user!['address']?['city'] ?? ''}, ${_user!['address']?['state'] ?? ''}, ${_user!['address']?['zipCode'] ?? ''}, ${_user!['address']?['country'] ?? ''}',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Created At', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      _formatDate(_user!['createdAt']),
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  ListTile(
                    title: Text('Updated At', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      _formatDate(_user!['updatedAt']),
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.indigo),
                    ),
                    onPressed: _showCartBottomSheet,
                    child: Text(
                      'Check Cart',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 6),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.indigo),
                    ),
                    onPressed: _showOrdersBottomSheet,
                    child: Text(
                      'Order Details',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 6),
                  if (canDelete)
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      onPressed: _deleteUser,
                      child: Text(
                        'Delete User',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class UserDetailsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.white),
                      SizedBox(height: 6),
                      Container(height: 12, width: 160, color: Colors.white),
                      SizedBox(height: 6),
                      Container(height: 10, width: 120, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(height: 12, width: 100, color: Colors.white),
            SizedBox(height: 16),
            Container(height: 12, width: 200, color: Colors.white),
            SizedBox(height: 16),
            Container(height: 12, width: 150, color: Colors.white),
            SizedBox(height: 16),
            Container(height: 12, width: 150, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
