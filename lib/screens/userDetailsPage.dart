
import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';
import 'package:shimmer/shimmer.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  const UserDetailsPage({required this.userId, Key? key}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
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
        final repo = AppDataRepo();
        final resp = await repo.deleteUserById(widget.userId);
        if (resp['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'User deleted successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'Failed to delete user', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
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
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: AppDataRepo().fetchOrdersByUserId(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null || snapshot.data!['success'] != true) {
                  final msg = snapshot.data != null && snapshot.data!['message'] != null
                      ? snapshot.data!['message'].toString()
                      : 'User has no orders';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        msg,
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final orders = List<Map<String, dynamic>>.from(snapshot.data!['orders'] ?? []);
                return Padding(
                  padding: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text('Order Details', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 8),
                      if (orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            "This user has no orders",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...orders.map((order) {
                        final shipping = order['shippingAddress'] ?? {};
                        final products = List<Map<String, dynamic>>.from(order['products'] ?? []);
                        String status = (order['orderStatus'] ?? '').toString();
                        String paymentStatus = (order['paymentStatus'] ?? '').toString();
                        Color statusColor = status.toLowerCase().contains('pending') ? Colors.yellow.shade700
                          : status.toLowerCase().contains('cancel') ? Colors.red
                          : status.toLowerCase().contains('deliver') ? Colors.green
                          : status.toLowerCase().contains('ship') ? Colors.blue
                          : Colors.indigo;
                        Color paymentColor = paymentStatus.toLowerCase().contains('fail') ? Colors.red
                          : paymentStatus.toLowerCase().contains('complete') ? Colors.indigo
                          : paymentStatus.toLowerCase().contains('partial') ? Colors.green
                          : Colors.black;
                        final recAmount = order['recivedAmount'] ?? 0;
                        final pendAmount = order['pendingAmount'] ?? 0;
                        final paymentMethod = order['paymentMethod'] ?? '';
                        final coupon = order['cupanCode'] ?? '';
                        final discountCupan = order['discountCupan'] ?? '';
                        final rewardPoints = order['reworPoins'] ?? '';
                        final shippingCost = order['shippingCost'] ?? '';
                        final orderDate = order['orderDate'] ?? '';
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(order['orderUniqueId'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(status, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                      Text(paymentStatus, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: paymentColor)),
                                    if (paymentStatus.isNotEmpty)
                                      Text(' • ', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                    Text('₹${order['totalAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Received: ₹$recAmount', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                                    ),
                                    SizedBox(width: 8),
                                    if (pendAmount != 0)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Pending: ₹$pendAmount', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                                      ),
                                    if (pendAmount == 0)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Fully Paid', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text('Payment Method: $paymentMethod', style: TextStyle(fontWeight: FontWeight.w500)),
                                if (coupon.toString().isNotEmpty)
                                  Text('Coupon: $coupon', style: TextStyle(fontWeight: FontWeight.w500)),
                                if (discountCupan.toString().isNotEmpty)
                                  Text('Discount Coupon: ₹$discountCupan', style: TextStyle(fontWeight: FontWeight.w500)),
                                if (rewardPoints.toString().isNotEmpty)
                                  Text('Reward Points: $rewardPoints', style: TextStyle(fontWeight: FontWeight.w500)),
                                if (shippingCost.toString().isNotEmpty)
                                  Text('Shipping Cost: ₹$shippingCost', style: TextStyle(fontWeight: FontWeight.w500)),
                                if (orderDate.toString().isNotEmpty)
                                  Text('Order Date: $orderDate', style: TextStyle(fontWeight: FontWeight.w500)),
                                SizedBox(height: 8),
                                Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...products.map((prod) {
                                  final subProducts = List<Map<String, dynamic>>.from(prod['subProduct'] ?? []);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: subProducts.map((sub) {
                                      final productId = sub['productId'] ?? {};
                                      final images = List<String>.from(sub['subProductImages'] ?? []);
                                      return Card(
                                        margin: EdgeInsets.symmetric(vertical: 4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              images.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(images[0], width: 48, height: 48, fit: BoxFit.cover),
                                                    )
                                                  : Container(width: 48, height: 48, color: Colors.grey[300], child: Icon(Icons.image)),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(productId['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    Text('Set: ${sub['set'] ?? ''}'),
                                                    Text('Price: ₹${sub['price'] ?? ''}'),
                                                    Text('Final Price: ₹${sub['finalPrice'] ?? ''}'),
                                                    Text('Color: ${sub['color'] ?? ''}'),
                                                    Text('Status: ${sub['status'] ?? ''}'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
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
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: AppDataRepo().fetchCartByUserId(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null || snapshot.data!['success'] != true) {
                  final msg = snapshot.data != null && snapshot.data!['message'] != null
                      ? snapshot.data!['message'].toString()
                      : "User's cart is empty";
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        msg,
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final cart = snapshot.data!['card'];
                final user = cart['user'] ?? {};
                final items = List<Map<String, dynamic>>.from(cart['items'] ?? []);
                return Padding(
                  padding: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text('Cart Details', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text(user['name'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? ''),
                              Text(user['phone'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Items in Cart', style: Theme.of(context).textTheme.titleMedium),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            "User's cart is empty",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...items.map((item) {
                        final subProduct = item['subProduct'] ?? {};
                        final productId = subProduct['productId'] ?? {};
                        final images = List<String>.from(subProduct['subProductImages'] ?? []);
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(images[0], width: 64, height: 64, fit: BoxFit.cover),
                                      )
                                    : Container(width: 64, height: 64, color: Colors.grey[300], child: Icon(Icons.image)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(productId['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Set: ${subProduct['set'] ?? ''}'),
                                      Text('Price: ₹${subProduct['price'] ?? ''}'),
                                      Text('Final Price: ₹${subProduct['finalPrice'] ?? ''}'),
                                      Text('Quantity: ${item['quantity'] ?? ''}'),
                                      Text('Status: ${item['status'] ?? ''}'),
                                      if (images.length > 1)
                                        SizedBox(height: 6),
                                      if (images.length > 1)
                                        SizedBox(
                                          height: 40,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: images.skip(1).map((img) => Padding(
                                              padding: const EdgeInsets.only(right: 6.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(img, width: 40, height: 40, fit: BoxFit.cover),
                                              ),
                                            )).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 12),
                      Text('Total Amount: ₹${cart['totalAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Total Quantity: ${snapshot.data!['Totalquantity'] ?? ''}'),
                      Text('Total Pcs: ${snapshot.data!['TotlePsc'] ?? ''}'),
                      SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _toggleLoading = false;
  String? _error;

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
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _getUserDetailsApi(widget.userId);
      if (response['success'] == true && response['user'] != null) {
        setState(() { _user = response['user']; _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load user'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<Map<String, dynamic>> _getUserDetailsApi(String userId) async {
    final repo = AppDataRepo();
    return await repo.fetchUserDetailsById(userId);
  }

  Future<void> _toggleUserStatus() async {
    if (_user == null) return;
    setState(() { _toggleLoading = true; });
    try {
      final repo = AppDataRepo();
      final result = await repo.toggleUserStatus(_user!['_id']);
      if (result['success'] == true) {
        setState(() { _user!['isActive'] = !_user!['isActive']; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Status updated')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to update status')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _toggleLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Details')),
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
                            radius: 32,
                            backgroundImage: _user!['photo'] != null && _user!['photo'].toString().isNotEmpty
                                ? NetworkImage(_user!['photo'])
                                : null,
                            child: _user!['photo'] == null || _user!['photo'].toString().isEmpty
                                ? Icon(Icons.person, size: 32)
                                : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User ID: ${_user!['uniqueUserId'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                                SizedBox(height: 4),
                                Text(_user!['name'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(_user!['email'] ?? '', style: TextStyle(fontSize: 16)),
                                Text(_user!['phone'] ?? '', style: TextStyle(fontSize: 16)),
                                Text('Shop Name: ${_user!['shopname'] ?? ''}', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        title: Text('Active'),
                        trailing: Switch(
                          value: _user!['isActive'] ?? false,
                          onChanged: _toggleLoading ? null : (val) => _toggleUserStatus(),
                        ),
                        subtitle: _toggleLoading ? Text('Updating...') : null,
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Address'),
                        subtitle: Text(
                          '${_user!['address']?['street'] ?? ''}, ${_user!['address']?['city'] ?? ''}, ${_user!['address']?['state'] ?? ''}, ${_user!['address']?['zipCode'] ?? ''}, ${_user!['address']?['country'] ?? ''}',
                        ),
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Created At'),
                        subtitle: Text(_formatDate(_user!['createdAt'])),
                      ),
                      ListTile(
                        title: Text('Updated At'),
                        subtitle: Text(_formatDate(_user!['updatedAt'])),
                      ),

                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.indigo)
                        ),
                        onPressed: _showCartBottomSheet,
                        child: Text('Check Cart', style: TextStyle(color: Colors.white),),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.indigo)
                        ),
                        onPressed: _showOrdersBottomSheet,
                        child: Text('Order Details', style: TextStyle(color: Colors.white),),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.red)
                        ),
                        onPressed: _deleteUser,
                        child: Text('Delete User', style: TextStyle(color: Colors.white)),
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 18, width: 120, color: Colors.white),
                      SizedBox(height: 8),
                      Container(height: 16, width: 180, color: Colors.white),
                      SizedBox(height: 8),
                      Container(height: 14, width: 120, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(height: 18, width: 100, color: Colors.white),
            SizedBox(height: 16),
            Container(height: 18, width: 200, color: Colors.white),
            SizedBox(height: 16),
            Container(height: 18, width: 150, color: Colors.white),
            SizedBox(height: 16),
            Container(height: 18, width: 150, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

