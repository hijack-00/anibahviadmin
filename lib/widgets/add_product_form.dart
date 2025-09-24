import 'package:flutter/material.dart';
import '../widgets/barcode_generator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../services/app_data_repo.dart';
import '../constants/image_placeholder.dart';



class AddProductForm extends StatefulWidget {
  final void Function()? onSubmit;
  const AddProductForm({this.onSubmit, super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();

    bool _isSubmitting = false;


  List<Map<String, dynamic>> products = [];
  bool loadingProducts = false;
  String selectedProductId = '';
  Map<String, dynamic>? selectedProduct;
  List<Map<String, dynamic>> sizeOptions = [];
bool loadingSizes = false;


  TextEditingController nameController = TextEditingController();
  String parentProduct = '';
  TextEditingController lotNumberController = TextEditingController();
  int pcsInSet = 1;
  int lotStock = 1;
  int singlePicPrice = 1;
  DateTime? dateOfOpening;
  TextEditingController descriptionController = TextEditingController();
  String status = 'In Stock';
  TextEditingController barcodeController = TextEditingController();
  String generatedBarcode = '';
  List<String> selectedSizes = [];
  List<String> availableSizes = ['28', '30', '32', '34', '36', '38', '40'];
  List<File> imageFiles = [];
  String finalPrice = '0';

  List<String> statusOptions = ['In Stock', 'Out of Stock'];
  List<String> activeOptions = ['Active', 'Inactive'];
  String activeStatus = 'Active';

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

  Future<void> _fetchProducts() async {
    setState(() { loadingProducts = true; });
    final repo = AppDataRepo();
    final res = await repo.fetchAllProducts();
    setState(() {
      products = res;
      loadingProducts = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchSizes();
  }


Future<void> _fetchSizes() async {
  setState(() { loadingSizes = true; });
  final repo = AppDataRepo();
  final sizes = await repo.fetchAllSizes();
  setState(() {
    sizeOptions = sizes;
    loadingSizes = false;
  });
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

  Widget _imageUploadSection() {
  int totalSlots = 8;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: totalSlots,
          separatorBuilder: (_, __) => SizedBox(width: 8),
          itemBuilder: (context, idx) {
            if (idx < imageFiles.length) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageFiles[idx],
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
                          imageFiles.removeAt(idx);
                        });
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Placeholder for empty slots
              return GestureDetector(
                onTap: () async {
                  if (imageFiles.length >= 8) return;
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage();
                  if (picked != null) {
                    setState(() {
                      imageFiles.addAll(picked.map((x) => File(x.path)));
                      if (imageFiles.length > 8) imageFiles = imageFiles.sublist(0, 8);
                    });
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    kImagePlaceholderUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
          },
        ),
      ),
      SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: () async {
          if (imageFiles.length >= 8) return;
          final picker = ImagePicker();
          final picked = await picker.pickMultiImage();
          if (picked != null) {
            setState(() {
              imageFiles.addAll(picked.map((x) => File(x.path)));
              if (imageFiles.length > 8) imageFiles = imageFiles.sublist(0, 8);
            });
          }
        },
        icon: Icon(Icons.upload),
        label: Text('Upload Images (3-8)'),
      ),
      if (imageFiles.length < 3)
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Please upload at least 3 images.', style: TextStyle(color: Colors.red)),
        ),
    ],
  );
}


  // Widget _sizesSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
  //       Wrap(
  //         spacing: 8,
  //         children: availableSizes.map((size) {
  //           return ChoiceChip(
  //             label: Text(size),
  //             selected: false,
  //             onSelected: (_) {
  //               setState(() {
  //                 selectedSizes.add(size);
  //               });
  //             },
  //           );
  //         }).toList(),
  //       ),
  //       SizedBox(height: 8),
  //       Text('Selected Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
  //       Wrap(
  //         spacing: 8,
  //         children: selectedSizes.map((size) {
  //           return Chip(
  //             label: Text(size),
  //             onDeleted: () {
  //               setState(() {
  //                 selectedSizes.remove(size);
  //               });
  //             },
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }


Widget _sizesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
      loadingSizes
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            )
          : Wrap(
              spacing: 8,
              children: sizeOptions.map((sizeObj) {
                final size = sizeObj['size']?.toString() ?? '';
                return ActionChip(
                  label: Text(size),
                  onPressed: () {
                    setState(() {
                      selectedSizes.add(size); // Always add, even if already present
                    });
                  },
                );
              }).toList(),
            ),
      SizedBox(height: 8),
      Text('Selected Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(
        spacing: 8,
        children: selectedSizes.asMap().entries.map((entry) {
          final idx = entry.key;
          final size = entry.value;
          return Chip(
            label: Text(size),
            onDeleted: () {
              setState(() {
                selectedSizes.removeAt(idx); // Remove only this instance
              });
            },
          );
        }).toList(),
      ),
    ],
  );
}

  // Generates a valid random EAN13 barcode
  String _generateRandomEAN13() {
    final rand = List.generate(12, (_) => (1 + (DateTime.now().microsecond + DateTime.now().millisecond) % 9).toString());
    final base = rand.join();
    int sum = 0;
    for (int i = 0; i < base.length; i++) {
      int digit = int.parse(base[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return base + checkDigit.toString();
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
                  counterText: '', // Hide character counter
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Always generate a new random EAN13 barcode
                String randomBarcode = _generateRandomEAN13();
                setState(() {
                  barcodeController.text = randomBarcode;
                  generatedBarcode = randomBarcode;
                });
              },
              child: Text('Generate Barcode'),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (generatedBarcode.isNotEmpty)
          Column(
            children: [
              SizedBox(
                height: 48,
                child: BarcodeGenerator(barcode: generatedBarcode),
              ),
              SizedBox(height: 8),
              Text(generatedBarcode, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int lotPrice = 0;
if (selectedProduct != null) {
  final price = selectedProduct!['price'] is int || selectedProduct!['price'] is double
      ? int.tryParse(selectedProduct!['price'].toString()) ?? 0
      : 0;
  final pcs = pcsInSet;
  lotPrice = price * pcs;
}
final String filnalLotPrice = lotPrice.toString();
  
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageUploadSection(),
            SizedBox(height: 16),
            loadingProducts
                ? Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: selectedProductId.isNotEmpty ? selectedProductId : null,
                   items: products.map((prod) => DropdownMenuItem(
  value: prod['_id']?.toString() ?? '',
  child: Text(prod['productName']?.toString() ?? ''),
)).toList(),
                    decoration: InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final prod = products.firstWhere((p) => p['_id'] == val, orElse: () => {});
                      setState(() {
                        selectedProductId = val ?? '';
                        selectedProduct = prod;
                        lotNumberController.text = prod['productName'] ?? '';
                        // singlePicPrice = prod['price'] is int || prod['price'] is double ? double.parse(prod['price'].toString()) : 1;
                       singlePicPrice = prod['price'] is int || prod['price'] is double
    ? int.tryParse(prod['price'].toString().split('.').first) ?? 1
    : 1; 
                      });
                    },
                  ),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: lotNumberController,
              decoration: InputDecoration(
                labelText: 'Lot Number',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
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
            numberField(
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
                TextButton(
                  onPressed: () {
                    setState(() {
                      dateOfOpening = DateTime.now();
                    });
                  },
                  child: Text('Today'),
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
                labelText: 'Stock Status',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  status = val ?? 'In Stock';
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: activeStatus,
              items: activeOptions.map((opt) => DropdownMenuItem(
                value: opt,
                child: Text(opt),
              )).toList(),
              decoration: InputDecoration(
                labelText: 'Active Status',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  activeStatus = val ?? 'Active';
                });
              },
            ),
            SizedBox(height: 16),
            _barcodeSection(),
            SizedBox(height: 16),
            _sizesSection(),
            SizedBox(height: 24),
            Text('Final Lot Price: ₹$filnalLotPrice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (imageFiles.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload at least 3 images.')));
                              return;
                            }
                            if (selectedProductId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select a product.')));
                              return;
                            }
                            setState(() => _isSubmitting = true);
                            try {
                              final repo = AppDataRepo();
                              final res = await repo.createSubProduct(
                                images: imageFiles,
                                productId: selectedProductId,
                                name: nameController.text,
                                description: descriptionController.text,
                                color: nameController.text,
                                selectedSizes: selectedSizes,
                                lotNumber: lotNumberController.text,
                                singlePicPrice: singlePicPrice,
                                barcode: barcodeController.text,
                                pcsInSet: pcsInSet,
                                dateOfOpening: dateOfOpening ?? DateTime.now(),
                                status: status == 'In Stock',
                                stock: status,
                                lotStock: lotStock,
                                isActive: activeStatus == 'Active',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                                filnalLotPrice: filnalLotPrice, // <-- changed here
                              );
                              if (res['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sub-product created successfully!')));
                                if (widget.onSubmit != null) widget.onSubmit!();
                                Navigator.of(context).pop(true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create sub-product.')));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            } finally {
                              setState(() => _isSubmitting = false);
                            }
                          },
                    child: _isSubmitting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Add Product'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}