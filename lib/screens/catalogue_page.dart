import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../services/app_data_repo.dart';
import 'universal_navbar.dart';
import '../widgets/add_product_form.dart';

class CataloguePage extends StatefulWidget {
  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  TextEditingController _searchController = TextEditingController();

  // second page products (from /product/get-all-products)
  late Future<List<Map<String, dynamic>>> _productsPageFuture;
  List<Map<String, dynamic>> _allProductsPage = [];
  List<Map<String, dynamic>> _filteredProductsPage = [];

  final ImagePicker _picker = ImagePicker();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // helper to apply search depending on current page
  void _applySearch(String val) {
    final q = val.toLowerCase();
    if (_currentPage == 0) {
      setState(() {
        _filteredProducts = _allProducts.where((product) {
          final productId = product['productId'] ?? {};
          final name = productId['productName']?.toString().toLowerCase() ?? '';
          return name.contains(q);
        }).toList();
      });
    } else {
      setState(() {
        _filteredProductsPage = _allProductsPage.where((product) {
          final name = product['productName']?.toString().toLowerCase() ?? '';
          return name.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _showAddProductForm() async {
    String name = '';
    String type = 'Featured Product';
    String? selectedMainCategoryId;
    String? selectedSubCategoryId;
    String price = '';
    String sku = '';
    List<File> pickedImages = [];
    bool submitting = false;

    // fetch categories & main categories
    final mainCatsRaw = await AppDataRepo().fetchAllMainCategories();
    final mainCategories = mainCatsRaw;
    final categoriesRaw = await AppDataRepo().fetchAllCategories();
    List<Map<String, dynamic>> categories = categoriesRaw;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // builder: (ctx) {
      //   return StatefulBuilder(
      //     builder: (ctx2, setModalState) {
      // filter subcategories based on selectedMainCategoryId if available
      // open sheet nearly full height
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              final subcats = selectedMainCategoryId == null
                  ? categories
                  : categories.where((c) {
                      final main = c['mainCategoryId'];
                      final mid = main is Map
                          ? main['_id']?.toString()
                          : main?.toString();
                      return mid == selectedMainCategoryId;
                    }).toList();

              // return Padding(
              //   padding: EdgeInsets.only(
              //     bottom: MediaQuery.of(ctx).viewInsets.bottom,
              //   ),
              //   child: SingleChildScrollView(
              //     child: Padding(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 18,
              //         vertical: 16,
              //       ),
              //       child: Column(
              //         mainAxisSize: MainAxisSize.min,
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add New Product',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Product Name',
                                  isDense: true,
                                ),
                                onChanged: (v) => setModalState(() => name = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'SKU',
                                  isDense: true,
                                ),
                                onChanged: (v) => setModalState(() => sku = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isDense: true,
                                value: type,
                                items:
                                    [
                                          'Featured Product',
                                          'Best Seller',
                                          'New Arrival',
                                        ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setModalState(() => type = v ?? type),
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    setModalState(() => price = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isDense: true,
                                value: selectedMainCategoryId,
                                items: mainCategories
                                    .map((m) {
                                      final id = m['_id']?.toString() ?? '';
                                      final label =
                                          m['mainCategoryName'] ??
                                          m['name'] ??
                                          id;
                                      return DropdownMenuItem(
                                        value: id,
                                        child: Text(label),
                                      );
                                    })
                                    .toList()
                                    .cast<DropdownMenuItem<String>>(),
                                onChanged: (v) => setModalState(() {
                                  selectedMainCategoryId = v;
                                  selectedSubCategoryId = null;
                                }),
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isDense: true,
                                value: selectedSubCategoryId,
                                items: subcats
                                    .map((s) {
                                      final id = s['_id']?.toString() ?? '';
                                      final label =
                                          s['name'] ?? s['categoryName'] ?? id;
                                      return DropdownMenuItem(
                                        value: id,
                                        child: Text(label),
                                      );
                                    })
                                    .toList()
                                    .cast<DropdownMenuItem<String>>(),
                                onChanged: (v) => setModalState(
                                  () => selectedSubCategoryId = v,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Sub-Category',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Product Images (3-8)'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('Upload Images'),
                              onPressed: () async {
                                final picked = await _picker.pickMultiImage(
                                  imageQuality: 80,
                                );
                                if (picked != null && picked.isNotEmpty) {
                                  setModalState(() {
                                    pickedImages.addAll(
                                      picked.map((x) => File(x.path)),
                                    );
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${pickedImages.length} images selected',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pickedImages.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pickedImages.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        pickedImages[i],
                                        width: 110,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => setModalState(
                                          () => pickedImages.removeAt(i),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(ctx).pop(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                child: submitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text('Create Product'),
                                onPressed: submitting
                                    ? null
                                    : () async {
                                        if (name.trim().isEmpty ||
                                            selectedMainCategoryId == null ||
                                            selectedSubCategoryId == null ||
                                            price.trim().isEmpty ||
                                            sku.trim().isEmpty ||
                                            pickedImages.length < 1) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please fill required fields and upload images',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setModalState(() => submitting = true);
                                        final resp = await AppDataRepo()
                                            .createProduct(
                                              name: name.trim(),
                                              type: type,
                                              categoryId:
                                                  selectedMainCategoryId!,
                                              subcategoryId:
                                                  selectedSubCategoryId!,
                                              price: price.trim(),
                                              sku: sku.trim(),
                                              images: pickedImages,
                                            );
                                        setModalState(() => submitting = false);
                                        if (resp['success'] == true) {
                                          Navigator.of(ctx).pop(true);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Product created'),
                                            ),
                                          );
                                          // refresh products page data
                                          setState(() {
                                            _productsPageFuture = AppDataRepo()
                                                .fetchAllProductsCatalog();
                                            _allProductsPage = [];
                                            _filteredProductsPage = [];
                                          });
                                        } else {
                                          final msg =
                                              resp['message']?.toString() ??
                                              'Create failed';
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(msg)),
                                          );
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        //               ],
                        //             ),
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //   );
                        // },
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
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = AppDataRepo().fetchCatalogueProducts();
    _productsPageFuture = AppDataRepo().fetchAllProductsCatalog();
  }

  void _onNavTap(int index) {
    String? route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/orders';
        break;
      case 2:
        route = '/users';
        break;
      case 3:
        route = '/catalogue';
        break;
      case 4:
        route = '/challan';
        break;
    }
    if (route != null && ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (r) => r.settings.name == '/dashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade500, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Catalogue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        // use the first future to avoid quick blank flashes; second page has its own future below
        future: _productsFuture,
        builder: (context, snapshotCatalogue) {
          // when catalogue first load is pending, still allow pageview skeletons
          if (snapshotCatalogue.connectionState == ConnectionState.waiting &&
              _allProducts.isEmpty) {
            return const _CatalogueSkeleton();
          }

          // initialize catalogue lists once data arrives
          if (_allProducts.isEmpty) {
            final data = snapshotCatalogue.data ?? [];
            _allProducts = data.reversed.toList();
            _filteredProducts = List.from(_allProducts);
          }

          return Column(
            children: [
              // top page selector (like tabs)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'Catalogue',
                          style: TextStyle(
                            fontSize: 13,
                            color: _currentPage == 0
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        selected: _currentPage == 0,
                        onSelected: (_) {
                          setState(() {
                            _currentPage = 0;
                            _pageController.jumpToPage(0);
                          });
                        },
                        selectedColor: Colors.indigo.shade400,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 13,
                            color: _currentPage == 1
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        selected: _currentPage == 1,
                        onSelected: (_) {
                          setState(() {
                            _currentPage = 1;
                            _pageController.jumpToPage(1);
                            // trigger fetch for products page if not yet loaded
                            if (_allProductsPage.isEmpty) {
                              _productsPageFuture = AppDataRepo()
                                  .fetchAllProductsCatalog();
                              _productsPageFuture.then((data) {
                                setState(() {
                                  _allProductsPage = data.reversed.toList();
                                  _filteredProductsPage = List.from(
                                    _allProductsPage,
                                  );
                                });
                              });
                            }
                          });
                        },
                        selectedColor: Colors.indigo.shade400,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar (shared, filters current page)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade100.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    onChanged: _applySearch,
                    decoration: InputDecoration(
                      hintText: 'Search by name',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.indigo.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _applySearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // PageView with two pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    // load second page if needed
                    if (i == 1 && _allProductsPage.isEmpty) {
                      _productsPageFuture = AppDataRepo()
                          .fetchAllProductsCatalog();
                      _productsPageFuture.then((data) {
                        setState(() {
                          _allProductsPage = data.reversed.toList();
                          _filteredProductsPage = List.from(_allProductsPage);
                        });
                      });
                    }
                  },
                  children: [
                    // Page 0: existing catalogue UI
                    RefreshIndicator(
                      color: Colors.indigo,
                      onRefresh: () async {
                        setState(() {
                          _productsFuture = AppDataRepo()
                              .fetchCatalogueProducts();
                          _allProducts = [];
                          _filteredProducts = [];
                        });
                        final data = await _productsFuture;
                        setState(() {
                          _allProducts = data.reversed.toList();
                          _filteredProducts = List.from(_allProducts);
                        });
                      },
                      child: _filteredProducts.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = 2;
                                if (constraints.maxWidth > 800)
                                  crossAxisCount = 5;
                                else if (constraints.maxWidth > 600)
                                  crossAxisCount = 4;
                                else if (constraints.maxWidth > 400)
                                  crossAxisCount = 3;

                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    8,
                                    10,
                                    80,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: 0.78,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    // final productId =
                                    //     product['productId'] ?? {};
                                    // final name =
                                    //     productId['productName'] ?? 'Unnamed';
                                    final productId =
                                        product['productId'] ?? {};
                                    // Prefer lotNumber (or top-level name) then parent productName.
                                    final parentName =
                                        (product['lotNumber'] ??
                                                product['name'] ??
                                                productId['productName'] ??
                                                '')
                                            .toString();
                                    final colorVal =
                                        product['color'] ??
                                        product['colour'] ??
                                        product['colorName'] ??
                                        product['colourName'] ??
                                        '';
                                    final colorStr =
                                        colorVal?.toString().trim() ?? '';
                                    final name = colorStr.isNotEmpty
                                        ? '$parentName/$colorStr'
                                        : (parentName.isNotEmpty
                                              ? parentName
                                              : 'Unnamed');

                                    final price =
                                        product['finalPrice'] ??
                                        product['price'] ??
                                        productId['price'] ??
                                        '-';
                                    dynamic imagesRaw =
                                        product['subProductImages'] ??
                                        product['images'] ??
                                        [];
                                    List<String> images = [];
                                    if (imagesRaw is String)
                                      images = imagesRaw
                                          .split(',')
                                          .map((e) => e.trim())
                                          .toList();
                                    else if (imagesRaw is List)
                                      for (var item in imagesRaw)
                                        if (item != null)
                                          images.add(item.toString());
                                    final imageUrl = images.isNotEmpty
                                        ? images.first
                                        : null;

                                    return GestureDetector(
                                      onTap: () {
                                        final id =
                                            product['_id'] ?? productId['_id'];
                                        if (id != null)
                                          Navigator.pushNamed(
                                            context,
                                            '/product-detail',
                                            arguments: id,
                                          );
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.indigo.shade100
                                                  .withOpacity(0.25),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(14),
                                                    ),
                                                child: imageUrl != null
                                                    ? Image.network(
                                                        imageUrl,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Container(
                                                              color: Colors
                                                                  .grey
                                                                  .shade200,
                                                              child: Icon(
                                                                Icons
                                                                    .image_not_supported_rounded,
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                                size: 30,
                                                              ),
                                                            ),
                                                      )
                                                    : Container(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        child: Icon(
                                                          Icons.image_rounded,
                                                          color: Colors
                                                              .grey
                                                              .shade400,
                                                          size: 30,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .grey
                                                            .shade900,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .green
                                                            .shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '₹$price',
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .green
                                                              .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    // Page 1: products from /product/get-all-products
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _productsPageFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            _allProductsPage.isEmpty) {
                          return const _CatalogueSkeleton();
                        }
                        if (snap.hasError && _allProductsPage.isEmpty) {
                          return Center(
                            child: Text(
                              'Error loading products',
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          );
                        }
                        if (_allProductsPage.isEmpty) {
                          final data = snap.data ?? [];
                          _allProductsPage = data.reversed.toList();
                          _filteredProductsPage = List.from(_allProductsPage);
                        }

                        return RefreshIndicator(
                          color: Colors.indigo,
                          onRefresh: () async {
                            setState(() {
                              _productsPageFuture = AppDataRepo()
                                  .fetchAllProductsCatalog();
                              _allProductsPage = [];
                              _filteredProductsPage = [];
                            });
                            final data = await _productsPageFuture;
                            setState(() {
                              _allProductsPage = data.reversed.toList();
                              _filteredProductsPage = List.from(
                                _allProductsPage,
                              );
                            });
                          },
                          child: _filteredProductsPage.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        'No products found',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount = 2;
                                    if (constraints.maxWidth > 800)
                                      crossAxisCount = 5;
                                    else if (constraints.maxWidth > 600)
                                      crossAxisCount = 4;
                                    else if (constraints.maxWidth > 400)
                                      crossAxisCount = 3;

                                    return GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        8,
                                        10,
                                        80,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            childAspectRatio: 0.78,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                      itemCount: _filteredProductsPage.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _filteredProductsPage[index];
                                        final name =
                                            product['productName'] ?? 'Unnamed';
                                        final price = product['price'] ?? '-';
                                        dynamic imagesRaw =
                                            product['images'] ?? [];
                                        List<String> images = [];
                                        if (imagesRaw is String)
                                          images = imagesRaw
                                              .split(',')
                                              .map((e) => e.trim())
                                              .toList();
                                        else if (imagesRaw is List)
                                          for (var item in imagesRaw)
                                            if (item != null)
                                              images.add(item.toString());
                                        final imageUrl = images.isNotEmpty
                                            ? images.first
                                            : null;

                                        return GestureDetector(
                                          onTap: () {
                                            final id = product['_id'];
                                            if (id != null)
                                              Navigator.pushNamed(
                                                context,
                                                '/product-detail',
                                                arguments: id,
                                              );
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.indigo.shade100
                                                      .withOpacity(0.25),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            14,
                                                          ),
                                                        ),
                                                    child: imageUrl != null
                                                        ? Image.network(
                                                            imageUrl,
                                                            width:
                                                                double.infinity,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => Container(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child: Icon(
                                                                    Icons
                                                                        .image_not_supported_rounded,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade400,
                                                                    size: 30,
                                                                  ),
                                                                ),
                                                          )
                                                        : Container(
                                                            color: Colors
                                                                .grey
                                                                .shade200,
                                                            child: Icon(
                                                              Icons
                                                                  .image_rounded,
                                                              color: Colors
                                                                  .grey
                                                                  .shade400,
                                                              size: 30,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          name,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors
                                                                .grey
                                                                .shade900,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .green
                                                                .shade50,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '₹$price',
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .green
                                                                  .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: _currentPage == 0
          // Catalogue page: "Add Catalogue" (existing behavior)
          ? FloatingActionButton.extended(
              backgroundColor: Colors.indigo.shade500,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Add Catalogue',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const AddProductForm(),
                  ),
                );
                if (result == true) {
                  setState(() {
                    _productsFuture = AppDataRepo().fetchCatalogueProducts();
                    _allProducts = [];
                    _filteredProducts = [];
                  });
                }
              },
            )
          // Products page: "Add Product" (new form & API call)
          : FloatingActionButton.extended(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box_rounded, size: 20),
              label: const Text(
                'Add Product',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              onPressed: () async {
                final created = await _showAddProductForm();
                // _showAddProductForm already refreshes on success; nothing else needed
              },
            ),
      bottomNavigationBar: UniversalNavBar(selectedIndex: 3, onTap: _onNavTap),
    );
  }
}

// Simple shimmer skeleton for catalogue grid
class _CatalogueSkeleton extends StatelessWidget {
  const _CatalogueSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        final width = constraints.maxWidth;
        if (width > 800)
          crossAxisCount = 5;
        else if (width > 600)
          crossAxisCount = 4;
        else if (width > 400)
          crossAxisCount = 3;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: crossAxisCount * 4,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Expanded(flex: 3, child: Container(color: Colors.white)),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 80,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
