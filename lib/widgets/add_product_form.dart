import 'dart:convert';

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

  // new: main category map and loader
  Map<String, String> mainCategoryNames = {};
  bool loadingMainCategories = false;

  final TextEditingController pcsController = TextEditingController();
  final TextEditingController lotStockController = TextEditingController();
  final TextEditingController singlePicPriceController =
      TextEditingController();

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
    setState(() {
      loadingProducts = true;
    });
    final repo = AppDataRepo();
    final res = await repo.fetchAllProducts();
    setState(() {
      products = res;
      loadingProducts = false;
    });
    // print full API response (safe JSON encode)
    try {
      debugPrint('Fetched products response: ${jsonEncode(res)}');
    } catch (e) {
      debugPrint('Fetched products (toString): $res');
    }
  }

  @override
  void initState() {
    super.initState();
    pcsController.text = pcsInSet.toString();
    lotStockController.text = lotStock.toString();
    singlePicPriceController.text = singlePicPrice.toString();
    _fetchProducts();
    _fetchSizes();
    _fetchMainCategories(); // fetch main categories
  }

  @override
  void dispose() {
    pcsController.dispose();
    lotStockController.dispose();
    singlePicPriceController.dispose();
    nameController.dispose();
    lotNumberController.dispose();
    descriptionController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSizes() async {
    setState(() {
      loadingSizes = true;
    });
    final repo = AppDataRepo();
    final sizes = await repo.fetchAllSizes();
    setState(() {
      sizeOptions = sizes;
      loadingSizes = false;
    });
  }

  Future<void> _fetchMainCategories() async {
    setState(() {
      loadingMainCategories = true;
    });
    final repo = AppDataRepo();
    try {
      final res = await repo.fetchAllMainCategories();
      final map = <String, String>{};
      for (var m in res) {
        if (m['_id'] != null && m['mainCategoryName'] != null) {
          map[m['_id'].toString()] = m['mainCategoryName'].toString();
        }
      }
      setState(() {
        mainCategoryNames = map;
      });
      try {
        debugPrint('Fetched main categories: ${jsonEncode(res)}');
      } catch (e) {
        debugPrint('Fetched main categories (toString): $res');
      }
    } catch (e) {
      debugPrint('Error fetching main categories: $e');
    } finally {
      setState(() {
        loadingMainCategories = false;
      });
    }
  }

  void _printDropdownProducts() {
    try {
      debugPrint('Dropdown products: ${jsonEncode(products)}');
    } catch (e) {
      debugPrint('Dropdown products (toString): $products');
    }
  }

  Widget numberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
    required TextEditingController controller,
  }) {
    // use the passed controller (do not recreate it)
    controller.text = controller.text.isEmpty
        ? value.toString()
        : controller.text;
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
                      final newVal = value + 1;
                      controller.text = newVal.toString();
                      onChanged(newVal);
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
                      if (value > 1) {
                        final newVal = value - 1;
                        controller.text = newVal.toString();
                        onChanged(newVal);
                      }
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
    required TextEditingController controller,
  }) {
    controller.text = controller.text.isEmpty
        ? value.toStringAsFixed(0)
        : controller.text;
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
                      final newVal = value + 1;
                      controller.text = newVal.toStringAsFixed(0);
                      onChanged(newVal);
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
                      if (value > 1) {
                        final newVal = value - 1;
                        controller.text = newVal.toStringAsFixed(0);
                        onChanged(newVal);
                      }
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
                        if (imageFiles.length > 8)
                          imageFiles = imageFiles.sublist(0, 8);
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

            // Ask user to choose between camera or gallery
            final source = await showDialog<ImageSource>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text('Select Image Source'),
                content: const Text(
                  'Choose how you want to upload your images.',
                ),
                actions: [
                  TextButton.icon(
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.indigo,
                    ),
                    label: const Text('Camera'),
                    onPressed: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.indigo,
                    ),
                    label: const Text('Gallery'),
                    onPressed: () =>
                        Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            );

            if (source == null) return; // user cancelled

            if (source == ImageSource.camera) {
              final captured = await picker.pickImage(
                source: ImageSource.camera,
              );
              if (captured != null) {
                setState(() {
                  imageFiles.add(File(captured.path));
                  if (imageFiles.length > 8) {
                    imageFiles = imageFiles.sublist(0, 8);
                  }
                });
              }
            } else {
              final picked = await picker.pickMultiImage();
              if (picked != null && picked.isNotEmpty) {
                setState(() {
                  imageFiles.addAll(picked.map((x) => File(x.path)));
                  if (imageFiles.length > 8) {
                    imageFiles = imageFiles.sublist(0, 8);
                  }
                });
              }
            }
          },
          icon: const Icon(Icons.upload_rounded),
          label: const Text('Upload Images (3–8)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ElevatedButton.icon(
        //   onPressed: () async {
        //     if (imageFiles.length >= 8) return;
        //     final picker = ImagePicker();
        //     final picked = await picker.pickMultiImage();
        //     if (picked != null) {
        //       setState(() {
        //         imageFiles.addAll(picked.map((x) => File(x.path)));
        //         if (imageFiles.length > 8)
        //           imageFiles = imageFiles.sublist(0, 8);
        //       });
        //     }
        //   },
        //   icon: Icon(Icons.upload),
        //   label: Text('Upload Images (3-8)'),
        // ),
        if (imageFiles.length < 3)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Please upload at least 3 images.',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

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
                        selectedSizes.add(
                          size,
                        ); // Always add, even if already present
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
    final rand = List.generate(
      12,
      (_) => (1 + (DateTime.now().microsecond + DateTime.now().millisecond) % 9)
          .toString(),
    );
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

        SizedBox(height: 8),

        if (generatedBarcode.isNotEmpty)
          Column(
            children: [
              SizedBox(
                height: 48,
                child: BarcodeGenerator(barcode: generatedBarcode),
              ),
              SizedBox(height: 8),
              Text(
                generatedBarcode,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int lotPrice = 0;
    if (selectedProduct != null) {
      final price =
          selectedProduct!['price'] is int ||
              selectedProduct!['price'] is double
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
                    // print products to console as soon as dropdown is clicked/opened
                    onTap: () {
                      try {
                        debugPrint(
                          'Dropdown opened — products: ${jsonEncode(products)}',
                        );
                      } catch (e) {
                        debugPrint(
                          'Dropdown opened — products (toString): $products',
                        );
                      }
                    },
                    value: selectedProductId.isNotEmpty
                        ? selectedProductId
                        : null,
                    items: products
                        .map((prod) {
                          final productName =
                              prod['productName']?.toString() ?? '';

                          // derive main category id from product's categoryId array (if present)
                          String mainName = '';
                          try {
                            if (prod['categoryId'] is List &&
                                (prod['categoryId'] as List).isNotEmpty) {
                              final firstCat =
                                  (prod['categoryId'] as List).first;
                              String? mainCatId;
                              if (firstCat is Map) {
                                mainCatId = firstCat['mainCategoryId']
                                    ?.toString();
                              } else if (firstCat is String) {
                                mainCatId = firstCat;
                              }
                              if (mainCatId != null &&
                                  mainCategoryNames.containsKey(mainCatId)) {
                                mainName = mainCategoryNames[mainCatId]!;
                              }
                            }
                          } catch (_) {
                            mainName = '';
                          }

                          final display = mainName.isNotEmpty
                              ? '$productName (${mainName.toUpperCase()})'
                              : productName;

                          return DropdownMenuItem(
                            value: prod['_id']?.toString() ?? '',
                            child: Text(display),
                          );
                        })
                        .toList()
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final prod = products.firstWhere(
                        (p) => p['_id'] == val,
                        orElse: () => {},
                      );
                      setState(() {
                        selectedProductId = val ?? '';
                        selectedProduct = prod;
                        lotNumberController.text = prod['productName'] ?? '';
                        singlePicPrice =
                            prod['price'] is int || prod['price'] is double
                            ? int.tryParse(
                                    prod['price'].toString().split('.').first,
                                  ) ??
                                  1
                            : 1;
                        singlePicPriceController.text = singlePicPrice
                            .toString();
                      });
                      // print selected product API response
                      try {
                        debugPrint(
                          'Selected product response: ${jsonEncode(prod)}',
                        );
                      } catch (e) {
                        debugPrint('Selected product (toString): $prod');
                      }
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
              onChanged: (val) => setState(() {
                pcsInSet = val;
                pcsController.text = val.toString();
              }),
              controller: pcsController,
            ),
            SizedBox(height: 16),
            numberField(
              label: 'Lot Stock',
              value: lotStock,
              onChanged: (val) => setState(() {
                lotStock = val;
                lotStockController.text = val.toString();
              }),
              controller: lotStockController,
            ),
            SizedBox(height: 16),
            numberField(
              label: 'Single Pic Price',
              value: singlePicPrice,
              onChanged: (val) => setState(() {
                singlePicPrice = val;
                singlePicPriceController.text = val.toString();
              }),
              controller: singlePicPriceController,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date of Opening',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  dateOfOpening != null
                      ? '${dateOfOpening!.day}/${dateOfOpening!.month}/${dateOfOpening!.year}'
                      : 'Select Date',
                ),
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
              items: statusOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
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
              items: activeOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
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
            Text(
              'Final Lot Price: ₹$filnalLotPrice',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (imageFiles.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Upload at least 3 images.'),
                                ),
                              );
                              return;
                            }
                            if (selectedProductId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Select a product.')),
                              );
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
                                filnalLotPrice:
                                    filnalLotPrice, // <-- changed here
                              );
                              if (res['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sub-product created successfully!',
                                    ),
                                  ),
                                );
                                if (widget.onSubmit != null) widget.onSubmit!();
                                Navigator.of(context).pop(true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to create sub-product.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
