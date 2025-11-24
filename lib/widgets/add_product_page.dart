import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _mainCategories = [];
  List<Map<String, dynamic>> _allCategories = [];

  String? _selectedMainId;
  List<String> _selectedSubIds = [];

  String _type = 'New Arrival';
  String _status = 'Active';

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  List<File> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Future<void> _loadCategories() async {
  //   setState(() => _loading = true);
  //   try {
  //     final mains = await AppDataRepo().fetchAllMainCategories();
  //     final cats = await AppDataRepo().fetchAllCategories();
  //     // AppDataRepo helpers may return list or map; normalize
  //     setState(() {
  //       _mainCategories = (mains is List) ? List<Map<String, dynamic>>.from(mains) : (mains['data'] is List ? List<Map<String,dynamic>>.from(mains['data']) : []);
  //       _allCategories = (cats is List) ? List<Map<String, dynamic>>.from(cats) : (cats['data'] is List ? List<Map<String,dynamic>>.from(cats['data']) : []);
  //     });
  //   } catch (e) {
  //     // ignore - keep empty lists
  //   } finally {
  //     setState(() => _loading = false);
  //   }
  // }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final mains = await AppDataRepo().fetchAllMainCategories();
      final cats = await AppDataRepo().fetchAllCategories();

      List<Map<String, dynamic>> _toList(
        dynamic resp, [
        String dataKey = 'data',
      ]) {
        if (resp == null) return [];
        if (resp is List) {
          return resp
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
        if (resp is Map && resp[dataKey] is List) {
          return (resp[dataKey] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
        return [];
      }

      setState(() {
        _mainCategories = _toList(mains, 'data');
        _allCategories = _toList(cats, 'data');
      });
    } catch (e, st) {
      debugPrint('_loadCategories error: $e\n$st');
      setState(() {
        _mainCategories = [];
        _allCategories = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _subcategoriesForSelectedMain {
    if (_selectedMainId == null) return _allCategories;
    return _allCategories.where((c) {
      final main = c['mainCategoryId'];
      final mid = (main is Map) ? main['_id']?.toString() : main?.toString();
      return mid == _selectedMainId;
    }).toList();
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _pickedImages.addAll(picked.map((p) => File(p.path)));
      if (_pickedImages.length > 8) _pickedImages = _pickedImages.sublist(0, 8);
    });
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (x == null) return;
    setState(() {
      _pickedImages.add(File(x.path));
      if (_pickedImages.length > 8) _pickedImages = _pickedImages.sublist(0, 8);
    });
  }

  void _removeImage(int i) {
    setState(() => _pickedImages.removeAt(i));
  }

  Future<void> _showSubcategorySelector() async {
    final subs = _subcategoriesForSelectedMain;
    final tmp = Set<String>.from(_selectedSubIds);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Sub-Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subs.length,
              itemBuilder: (c, i) {
                final s = subs[i];
                final id = s['_id']?.toString() ?? i.toString();
                final label = s['name'] ?? s['categoryName'] ?? id;
                return CheckboxListTile(
                  value: tmp.contains(id),
                  title: Text(label),
                  onChanged: (v) {
                    setState(() {
                      if (v == true)
                        tmp.add(id);
                      else
                        tmp.remove(id);
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedSubIds = tmp.toList());
                Navigator.of(ctx).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      // rebuild form state
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainId == null || _selectedSubIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select category and sub-category'),
        ),
      );
      return;
    }
    if (_pickedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 3 images')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // normalize ids (trim) before sending
      final cleanSubIds = _selectedSubIds
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final resp = await AppDataRepo().createProduct(
        name: _nameCtrl.text.trim(),
        type: _type,
        categoryId: _selectedMainId!.toString(),
        categoryIds: cleanSubIds,
        price: _priceCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        images: _pickedImages,
        status: _status == 'Active',
      );

      if (resp['success'] == true || resp['status'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product created')));
        Navigator.of(context).pop(true);
      } else {
        final msg = resp['message']?.toString() ?? 'Create failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = ['New Arrival', 'Featured Product', 'Best Seller', 'Regular'];
    final statusOptions = ['Active', 'Inactive'];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Row 1: name & SKU
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _skuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'SKU',
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Category & Subcategory
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isDense: true,
                              value: _selectedMainId,
                              items: _mainCategories.map((m) {
                                final id = m['_id']?.toString() ?? '';
                                final label =
                                    m['mainCategoryName'] ?? m['name'] ?? id;
                                return DropdownMenuItem(
                                  value: id,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() {
                                _selectedMainId = v;
                                _selectedSubIds.clear();
                              }),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FormField<List<String>>(
                              initialValue: _selectedSubIds,
                              validator: (vals) {
                                return (vals == null || vals.isEmpty)
                                    ? 'Required'
                                    : null;
                              },
                              builder: (state) {
                                final selectedLabels =
                                    _subcategoriesForSelectedMain
                                        .where(
                                          (s) => _selectedSubIds.contains(
                                            s['_id']?.toString(),
                                          ),
                                        )
                                        .map(
                                          (s) =>
                                              (s['name'] ??
                                                      s['categoryName'] ??
                                                      s['_id'])
                                                  .toString(),
                                        )
                                        .toList();
                                return InkWell(
                                  onTap: _showSubcategorySelector,
                                  child: InputDecorator(
                                    isEmpty: _selectedSubIds.isEmpty,
                                    decoration: InputDecoration(
                                      labelText: 'Sub-Category',
                                      errorText: state.errorText,
                                      isDense: true,
                                    ),
                                    child: Text(
                                      selectedLabels.isEmpty
                                          ? 'Select sub-categories'
                                          : selectedLabels.join(', '),
                                      style: TextStyle(
                                        color: selectedLabels.isEmpty
                                            ? Colors.black45
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Type & Price
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isDense: true,
                              value: _type,
                              items: types
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _type = v ?? _type),
                              decoration: const InputDecoration(
                                labelText: 'Type',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                prefixText: '₹ ',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Images upload
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Product Images (3-8)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Upload Images'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _pickFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                          const SizedBox(width: 12),
                          Text('${_pickedImages.length} selected'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_pickedImages.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _pickedImages[i],
                                      width: 120,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(i),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Status
                      DropdownButtonFormField<String>(
                        isDense: true,
                        value: _status,
                        items: statusOptions
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Add Product'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
