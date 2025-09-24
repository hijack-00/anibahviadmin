import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_data_repo.dart';
import '../constants/image_placeholder.dart';

class UpdateProductPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final void Function()? onUpdated;
  const UpdateProductPage({required this.productData, this.onUpdated, super.key});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late Map<String, dynamic> initialData;
  late TextEditingController nameController;
  late TextEditingController lotNumberController;
  late TextEditingController descriptionController;
  late TextEditingController barcodeController;
  late int pcsInSet;
  late int lotStock;
  late int singlePicPrice;
  late String color;
  late String status;
  late String activeStatus;
  late DateTime? dateOfOpening;
  late List<String> selectedSizes;
  late List<File> imageFiles;
  late List<String> existingImages;
  late String filnalLotPrice;
String generatedBarcode = '';

  @override
  void initState() {
    super.initState();
    final data = widget.productData;
    initialData = Map<String, dynamic>.from(data);

    nameController = TextEditingController(text: data['color']?.toString() ?? '');
    lotNumberController = TextEditingController(text: data['lotNumber']?.toString() ?? '');
    descriptionController = TextEditingController(text: data['description']?.toString() ?? '');
    barcodeController = TextEditingController(text: data['barcode']?.toString() ?? '');
    pcsInSet = int.tryParse(data['pcsInSet']?.toString() ?? '') ?? 1;
    lotStock = int.tryParse(data['lotStock']?.toString() ?? '') ?? 1;
    singlePicPrice = int.tryParse(data['singlePicPrice']?.toString() ?? '') ?? 1;
    color = data['color']?.toString() ?? '';
    status = data['stock']?.toString() ?? (data['status'] == true ? 'In Stock' : 'Out of Stock');
    activeStatus = data['isActive'] == true ? 'Active' : 'Inactive';
    dateOfOpening = data['dateOfOpening'] != null
        ? DateTime.tryParse(data['dateOfOpening'].toString())
        : null;
    selectedSizes = [];
    try {
      final sizesRaw = data['sizes'];
      if (sizesRaw is String) {
        selectedSizes = List<String>.from(jsonDecode(sizesRaw));
      } else if (sizesRaw is List) {
        selectedSizes = sizesRaw.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    existingImages = [];
    final imgs = data['subProductImages'] ?? [];
    if (imgs is String) {
      existingImages = imgs.split(',').map((e) => e.trim()).toList();
    } else if (imgs is List) {
      for (var item in imgs) {
        if (item is String && item.contains(',')) {
          existingImages.addAll(item.split(',').map((e) => e.trim()));
        } else if (item != null) {
          existingImages.add(item.toString());
        }
      }
    }
    imageFiles = [];
    filnalLotPrice = data['filnalLotPrice']?.toString() ?? '';
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null) {
      setState(() {
        imageFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
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

  Future<void> _submit() async {
     final totalImages = existingImages.length + imageFiles.length;
  if (totalImages < 3 || totalImages > 8) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please provide between 3 and 8 images.')),
    );
    return;
  }
    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> updatedFields = {};

      if (nameController.text != (initialData['color']?.toString() ?? '')) {
        updatedFields['color'] = nameController.text;
      }
      if (lotNumberController.text != (initialData['lotNumber']?.toString() ?? '')) {
        updatedFields['lotNumber'] = lotNumberController.text;
      }
      if (descriptionController.text != (initialData['description']?.toString() ?? '')) {
        updatedFields['description'] = descriptionController.text;
      }
      if (barcodeController.text != (initialData['barcode']?.toString() ?? '')) {
        updatedFields['barcode'] = barcodeController.text;
      }
      if (pcsInSet != int.tryParse(initialData['pcsInSet']?.toString() ?? '')) {
        updatedFields['pcsInSet'] = pcsInSet.toString();
      }
      if (lotStock != int.tryParse(initialData['lotStock']?.toString() ?? '')) {
        updatedFields['lotStock'] = lotStock.toString();
      }
      if (singlePicPrice != int.tryParse(initialData['singlePicPrice']?.toString() ?? '')) {
        updatedFields['singlePicPrice'] = singlePicPrice;
      }
      if (status != (initialData['stock']?.toString() ?? (initialData['status'] == true ? 'In Stock' : 'Out of Stock'))) {
        updatedFields['stock'] = status;
      }
      if (activeStatus != (initialData['isActive'] == true ? 'Active' : 'Inactive')) {
        updatedFields['isActive'] = activeStatus == 'Active';
      }
      if (dateOfOpening?.toIso8601String() != (initialData['dateOfOpening']?.toString() ?? '')) {
        updatedFields['dateOfOpening'] = dateOfOpening?.toIso8601String();
      }
      if (jsonEncode(selectedSizes) != (initialData['sizes'] is String ? initialData['sizes'] : jsonEncode(initialData['sizes']))) {
        updatedFields['selectedSizes'] = jsonEncode(selectedSizes);
      }
      if (filnalLotPrice != (initialData['filnalLotPrice']?.toString() ?? '')) {
        updatedFields['filnalLotPrice'] = filnalLotPrice;
      }
      if (imageFiles.isNotEmpty) {
        updatedFields['subProductImages'] = imageFiles;
      }

      if (updatedFields.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No changes to update.')));
        setState(() => _isSubmitting = false);
        return;
      }

      final id = initialData['_id']?.toString() ?? '';
      final res = await AppDataRepo().updateSubProduct(id, updatedFields);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product updated successfully!')));
        if (widget.onUpdated != null) widget.onUpdated!();
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update product.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Product'), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              // In your image list builder inside UpdateProductPage:
SizedBox(
  height: 100,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: 8,
    separatorBuilder: (_, __) => SizedBox(width: 8),
    itemBuilder: (context, idx) {
      if (idx < existingImages.length) {
        // Existing images
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                existingImages[idx],
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
                    existingImages.removeAt(idx);
                  });
                },
              ),
            ),
          ],
        );
      } else if (idx < existingImages.length + imageFiles.length) {
        // New images
        final fileIdx = idx - existingImages.length;
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFiles[fileIdx],
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
                    imageFiles.removeAt(fileIdx);
                  });
                },
              ),
            ),
          ],
        );
      } else {
        // Placeholder for empty slots
        return GestureDetector(
          onTap: _pickImages,
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
                onPressed: _pickImages,
                icon: Icon(Icons.upload),
                label: Text('Upload Images'),
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
//               TextField(
//                 controller: barcodeController,
//                 decoration: InputDecoration(
//                   labelText: 'Barcode',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 8),
//            ElevatedButton.icon(
//   onPressed: () {
//     final rand = Random();
//     final barcode = List.generate(13, (_) => rand.nextInt(10).toString()).join();
//     setState(() {
//       barcodeController.text = barcode;
//     });
//   },
//   icon: Icon(Icons.qr_code),
//   label: Text('Generate Barcode'),
// ),

// TextField(
//   controller: barcodeController,
//   decoration: InputDecoration(
//     labelText: 'Barcode',
//     border: OutlineInputBorder(),
//   ),
// ),
SizedBox(height: 8),
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
          counterText: '',
        ),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          setState(() {
            generatedBarcode = val;
          });
        },
      ),
    ),
    SizedBox(width: 8),
    ElevatedButton(
      onPressed: () {
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
if (barcodeController.text.isNotEmpty)
  Row(
    children: [
      SizedBox(
        height: 60,
        child: Image.network(
          'https://barcode.tec-it.com/barcode.ashx?data=${barcodeController.text}&code=EAN13',
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
      SizedBox(height: 8),
      Text(barcodeController.text, style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  ),// SizedBox(height: 16),
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
                decoration: InputDecoration(
                  labelText: 'Pcs in Set',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: pcsInSet.toString()),
                onChanged: (val) => pcsInSet = int.tryParse(val) ?? pcsInSet,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Lot Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: lotStock.toString()),
                onChanged: (val) => lotStock = int.tryParse(val) ?? lotStock,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Single Pic Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: singlePicPrice.toString()),
                onChanged: (val) => singlePicPrice = int.tryParse(val) ?? singlePicPrice,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Final Lot Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: filnalLotPrice),
                onChanged: (val) => filnalLotPrice = val,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                items: ['In Stock', 'Out of Stock'].map((opt) => DropdownMenuItem(
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
                items: ['Active', 'Inactive'].map((opt) => DropdownMenuItem(
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
              Text('Selected Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: ['28', '30', '32', '34', '36', '38', '40'].map((size) {
                  final isSelected = selectedSizes.contains(size);
                  return ChoiceChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (!selectedSizes.contains(size)) selectedSizes.add(size);
                        } else {
                          selectedSizes.remove(size);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Update Product'),
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
      ),
    );
  }
}