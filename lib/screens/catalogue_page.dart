import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _productsFuture = AppDataRepo().fetchCatalogueProducts();
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
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CatalogueSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading products',
                style: TextStyle(color: Colors.red.shade400, fontSize: 13),
              ),
            );
          }

          if (_allProducts.isEmpty) {
            final data = snapshot.data ?? [];
            _allProducts = data.reversed.toList();
            _filteredProducts = List.from(_allProducts);
          }

          return Column(
            children: [
              // 🔍 Floating Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
                    onChanged: (val) {
                      setState(() {
                        _filteredProducts = _allProducts.where((product) {
                          final productId = product['productId'] ?? {};
                          final name =
                              productId['productName']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          return name.contains(val.toLowerCase());
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by product name',
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
                    ),
                  ),
                ),
              ),

              // 🛒 Product Grid
              Expanded(
                child: RefreshIndicator(
                  color: Colors.indigo,
                  onRefresh: () async {
                    setState(() {
                      _productsFuture = AppDataRepo().fetchCatalogueProducts();
                      _allProducts = [];
                      _filteredProducts = [];
                    });
                    await _productsFuture;
                  },
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 800) {
                              crossAxisCount = 5;
                            } else if (constraints.maxWidth > 600) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth > 400) {
                              crossAxisCount = 3;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
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
                                final productId = product['productId'] ?? {};
                                final name =
                                    productId['productName'] ?? 'Unnamed';
                                final price =
                                    product['finalPrice'] ??
                                    product['price'] ??
                                    productId['price'] ??
                                    '-';

                                // ✅ Handle images gracefully
                                dynamic imagesRaw =
                                    product['subProductImages'] ??
                                    product['images'] ??
                                    [];
                                List<String> images = [];
                                if (imagesRaw is String) {
                                  images = imagesRaw
                                      .split(',')
                                      .map((e) => e.trim())
                                      .toList();
                                } else if (imagesRaw is List) {
                                  for (var item in imagesRaw) {
                                    if (item is String && item.contains(',')) {
                                      images.addAll(
                                        item.split(',').map((e) => e.trim()),
                                      );
                                    } else if (item != null) {
                                      images.add(item.toString());
                                    }
                                  }
                                }
                                final imageUrl = images.isNotEmpty
                                    ? images.first
                                    : null;

                                return GestureDetector(
                                  onTap: () {
                                    final id =
                                        product['_id'] ?? productId['_id'];
                                    if (id != null) {
                                      Navigator.pushNamed(
                                        context,
                                        '/product-detail',
                                        arguments: id,
                                      );
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.indigo.shade100
                                              .withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // 🖼 Product Image
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
                                                          context,
                                                          error,
                                                          stackTrace,
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
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons.image_rounded,
                                                      color:
                                                          Colors.grey.shade400,
                                                      size: 30,
                                                    ),
                                                  ),
                                          ),
                                        ),

                                        // 📦 Product Info
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
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
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade900,
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
                                                    color: Colors.green.shade50,
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
                                                      color:
                                                          Colors.green.shade700,
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
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Product',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        onPressed: () async {
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
      ),

      bottomNavigationBar: UniversalNavBar(
        selectedIndex: 3,
        onTap: (index) {
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
        },
      ),
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
