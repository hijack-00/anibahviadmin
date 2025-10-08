import 'package:flutter/material.dart';

Future<void> showCreateOrderBottomSheet(BuildContext context) async {
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
}

class _CreateOrderSheet extends StatefulWidget {
  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  String? selectedCustomer;
  String customerName = '';
  String customerEmail = '';
  String customerPhone = '';
  String deliveryAddress = '';
  String orderType = 'Online';
  String paymentType = 'UPI';
  String paymentAmount = '';
  String barcodeInput = '';
  List<Map<String, dynamic>> selectedProducts = [];

  // Dummy customers and products
  final List<String> customers = ['Client X', 'Client Y', 'Client Z'];
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Jeans Classic',
      'barcode': '1234567890123',
      'sets': 2,
      'pcs': 24,
      'price': 1200,
    },
    {
      'name': 'Shirt Slim',
      'barcode': '2345678901234',
      'sets': 1,
      'pcs': 12,
      'price': 950,
    },
    {
      'name': 'Jeans Stretch',
      'barcode': '3456789012345',
      'sets': 3,
      'pcs': 36,
      'price': 800,
    },
    {
      'name': 'Shirt Classic',
      'barcode': '4567890123456',
      'sets': 2,
      'pcs': 24,
      'price': 750,
    },
  ];
  final List<String> orderTypes = ['Online', 'Offline'];
  final List<String> paymentTypes = ['UPI', 'Cash', 'Card', 'Net Banking'];

  // Summary
  int get totalSets =>
      selectedProducts.fold(0, (sum, p) => sum + (p['sets'] as int));
  int get totalPcs =>
      selectedProducts.fold(0, (sum, p) => sum + (p['pcs'] as int));
  double get subtotal => selectedProducts.fold(
    0.0,
    (sum, p) =>
        sum +
        ((p['price'] is int)
            ? (p['price'] as int).toDouble()
            : (p['price'] as double)),
  );
  double get totalPaid =>
      double.tryParse(paymentAmount.isEmpty ? '0' : paymentAmount) ?? 0.0;
  double get balance => subtotal - totalPaid;

  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      selectedProducts.add(product);
    });
  }

  void _scanBarcode() async {
    final found = products.firstWhere(
      (p) => p['barcode'] == barcodeInput,
      orElse: () => {},
    );
    if (found.isNotEmpty) {
      _addProduct(found);
      setState(() {
        barcodeInput = '';
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product not found for barcode')));
    }
  }

  void _showProductSelection() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Products',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, idx) {
                    final prod = products[idx];
                    return ListTile(
                      title: Text(prod['name']),
                      subtitle: Text('Barcode: ${prod['barcode']}'),
                      trailing: ElevatedButton(
                        child: Text('Add'),
                        onPressed: () {
                          _addProduct(prod);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedCustomer,
                hint: Text('Select Customer'),
                items: customers
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCustomer = val;
                  });
                },
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(labelText: 'Customer Name'),
                onChanged: (v) => setState(() => customerName = v),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (v) => setState(() => customerEmail = v),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(labelText: 'Phone'),
                onChanged: (v) => setState(() => customerPhone = v),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(labelText: 'Delivery Address'),
                onChanged: (v) => setState(() => deliveryAddress = v),
              ),
              SizedBox(height: 8),
              Text('Order Type', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                value: orderType,
                items: orderTypes
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    orderType = val!;
                  });
                },
              ),
              Divider(height: 24),
              Text(
                'Product Sets',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Enter 13-digit Barcode',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 13,
                onChanged: (v) => setState(() => barcodeInput = v),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _showProductSelection,
                child: Text('Manual Selection'),
              ),
              SizedBox(height: 8),
              if (selectedProducts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedProducts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    return ListTile(
                      title: Text(p['name']),
                      subtitle: Text(
                        'Sets: ${p['sets']}, Pcs: ${p['pcs']}, Price: \u20b9${p['price']}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedProducts.removeAt(idx);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              Divider(height: 24),
              Text(
                'Payment Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: paymentType,
                items: paymentTypes
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    paymentType = val!;
                  });
                },
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => paymentAmount = v),
              ),
              Divider(height: 24),
              Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Sets: $totalSets'),
                  Text('Total Pcs: $totalPcs'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal: \u20b9${subtotal.toStringAsFixed(2)}'),
                  Text('Total Paid: \u20b9${totalPaid.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Balance: \u20b9${balance.toStringAsFixed(2)}'),
                  Text('Final Amount: \u20b9${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Implement create order logic
                      Navigator.of(context).pop();
                    },
                    child: Text('Create Order'),
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
