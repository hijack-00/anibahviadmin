import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productFuture;

  // Editable fields
  TextEditingController nameController = TextEditingController();
  String parentProduct = '';
  TextEditingController lotNumberController = TextEditingController();
  int pcsInSet = 1;
  int lotStock = 1;
  double singlePicPrice = 1;
  DateTime? dateOfOpening;
  TextEditingController descriptionController = TextEditingController();
  String status = 'In Stock';
  TextEditingController barcodeController = TextEditingController();
  List<String> selectedSizes = [];
  List<String> availableSizes = [];
  List<String> imageUrls = [];
  String finalPrice = '0';

  List<String> parentProductOptions = ['Denim Jeans', 'Cargo', 'Bootcut Jeans', 'Tapered Jeans', 'Slim Jeans'];
  List<String> statusOptions = ['In Stock', 'Low Stock', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfOpening ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateOfOpening = picked;
      });
    }
  }

  Widget _imageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (_, __) => SizedBox(width: 8),
            itemBuilder: (context, idx) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrls[idx],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        imageUrls.removeAt(idx);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            // Dummy: Add a placeholder image
            // setState(() {
            //   imageUrls.add('https://via.placeholder.com/100');
            // });
          },
          icon: Icon(Icons.upload),
          label: Text('Upload Image'),
        ),
      ],
    );
  }

  Widget _sizesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: availableSizes.map((size) {
            return ChoiceChip(
              label: Text(size),
              selected: false,
              onSelected: (_) {
                setState(() {
                  selectedSizes.add(size);
                });
              },
            );
          }).toList(),
        ),
        SizedBox(height: 8),
        Text('Selected Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: selectedSizes.map((size) {
            return Chip(
              label: Text(size),
              onDeleted: () {
                setState(() {
                  selectedSizes.remove(size);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _barcodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Dummy: Generate barcode number
                setState(() {
                  barcodeController.text = '1234567890123';
                });
              },
              child: Text('Generate Barcode'),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (barcodeController.text.isNotEmpty)
          Column(
            children: [
              Image.network(
                'https://barcode.tec-it.com/barcode.ashx?data=${barcodeController.text}&code=EAN13',
                height: 48,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 8),
              Text(barcodeController.text, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
      ],
    );
  }

  Widget numberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    TextEditingController controller = TextEditingController(text: value.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.only(left: 12, right: 12),
                ),
                onChanged: (val) {
                  final num = int.tryParse(val) ?? value;
                  onChanged(num);
                },
              ),
            ),
            SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_drop_up),
                    onPressed: () {
                      onChanged(value + 1);
                    },
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      if (value > 1) onChanged(value - 1);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget doubleNumberField({
    required String label,
    required double value,
    required void Function(double) onChanged,
  }) {
    TextEditingController controller = TextEditingController(text: value.toStringAsFixed(0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.only(left: 12, right: 12),
                ),
                onChanged: (val) {
                  final num = double.tryParse(val) ?? value;
                  onChanged(num);
                },
              ),
            ),
            SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_drop_up),
                    onPressed: () {
                      onChanged(value + 1);
                    },
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      if (value > 1) onChanged(value - 1);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading product details'));
          }
          final data = snapshot.data?['data'] ?? {};
          final productId = data['productId'] ?? {};
          final images = data['subProductImages'] ?? [];
          final sizesApi = data['sizes'] ?? [];
          final statusApi = data['status'] == true ? 'In Stock' : 'Out of Stock';

          // Fill fields with API data if not already set
          nameController.text = data['color']?.toString() ?? nameController.text;
          parentProduct = productId['productName']?.toString() ?? parentProduct;
          lotNumberController.text = data['lotNumber']?.toString() ?? lotNumberController.text;
          pcsInSet = int.tryParse(data['set']?.toString() ?? '') ?? pcsInSet;
          lotStock = int.tryParse(data['lotStock']?.toString() ?? '') ?? lotStock;
          singlePicPrice = double.tryParse(data['singlePicPrice']?.toString() ?? '') ?? singlePicPrice;
          finalPrice = data['finalPrice']?.toString() ?? data['price']?.toString() ?? finalPrice;
          descriptionController.text = ''; // Not from API
          status = statusApi;
          barcodeController.text = barcodeController.text;
          availableSizes = sizesApi.map<String>((sz) => sz['size'].toString()).toList();
          if (imageUrls.isEmpty && images.isNotEmpty) imageUrls = List<String>.from(images);

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _imageUploadSection(),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name (Color)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: parentProductOptions.contains(parentProduct) ? parentProduct : null,
                items: [
                  ...parentProductOptions.map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(opt),
                  )),
                  if (parentProduct.isNotEmpty && !parentProductOptions.contains(parentProduct))
                    DropdownMenuItem(
                      value: parentProduct,
                      child: Text(parentProduct),
                    ),
                ],
                decoration: InputDecoration(
                  labelText: 'Parent Product',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    parentProduct = val ?? '';
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: lotNumberController,
                decoration: InputDecoration(
                  labelText: 'Lot Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              numberField(
                label: 'Pcs in Set',
                value: pcsInSet,
                onChanged: (val) => setState(() => pcsInSet = val),
              ),
              SizedBox(height: 16),
              numberField(
                label: 'Lot Stock',
                value: lotStock,
                onChanged: (val) => setState(() => lotStock = val),
              ),
              SizedBox(height: 16),
              doubleNumberField(
                label: 'Single Pic Price',
                value: singlePicPrice,
                onChanged: (val) => setState(() => singlePicPrice = val),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Date of Opening', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(dateOfOpening != null
                      ? '${dateOfOpening!.day}/${dateOfOpening!.month}/${dateOfOpening!.year}'
                      : 'Select Date'),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                items: statusOptions.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                )).toList(),
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    status = val ?? 'In Stock';
                  });
                },
              ),
              SizedBox(height: 16),
              _barcodeSection(),
              SizedBox(height: 16),
              _sizesSection(),
              SizedBox(height: 24),
              Text('Final Price: ₹$finalPrice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Update'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text('Cancel'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
