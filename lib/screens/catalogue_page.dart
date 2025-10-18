import 'package:flutter/material.dart';
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
            return const Center(child: CircularProgressIndicator());
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
            _allProducts = snapshot.data ?? [];
            _filteredProducts = _allProducts;
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     appBar: AppBar(
  //       title: Text('Catalogue'),
  //       // backgroundColor: Colors.indigo,
  //     ),
  //     body: FutureBuilder<List<Map<String, dynamic>>>(
  //       future: _productsFuture,
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return Center(child: CircularProgressIndicator());
  //         }
  //         if (snapshot.hasError) {
  //           return Center(child: Text('Error loading products'));
  //         }
  //         if (_allProducts.isEmpty) {
  //           _allProducts = snapshot.data ?? [];
  //           _filteredProducts = _allProducts;
  //           print('Catalogue API response: ${snapshot.data}');
  //         }
  //         return Column(
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.all(12.0),
  //               child: TextField(
  //                 controller: _searchController,
  //                 decoration: InputDecoration(
  //                   labelText: 'Search products',
  //                   border: OutlineInputBorder(),
  //                   prefixIcon: Icon(Icons.search),
  //                 ),
  //                 onChanged: (val) {
  //                   setState(() {
  //                     _filteredProducts = _allProducts.where((product) {
  //                       final productId = product['productId'] ?? {};
  //                       final name =
  //                           productId['productName']
  //                               ?.toString()
  //                               .toLowerCase() ??
  //                           '';
  //                       return name.contains(val.toLowerCase());
  //                     }).toList();
  //                   });
  //                 },
  //               ),
  //             ),
  //             Expanded(
  //               child: RefreshIndicator(
  //                 onRefresh: () async {
  //                   setState(() {
  //                     _productsFuture = AppDataRepo().fetchCatalogueProducts();
  //                     _allProducts = [];
  //                     _filteredProducts = [];
  //                   });
  //                   await _productsFuture;
  //                 },
  //                 child: _filteredProducts.isEmpty
  //                     ? Center(child: Text('No products found'))
  //                     : GridView.builder(
  //                         padding: EdgeInsets.all(12),
  //                         gridDelegate:
  //                             SliverGridDelegateWithFixedCrossAxisCount(
  //                               crossAxisCount: 3,
  //                               childAspectRatio: 0.7,
  //                               crossAxisSpacing: 12,
  //                               mainAxisSpacing: 12,
  //                             ),
  //                         itemCount: _filteredProducts.length,
  //                         itemBuilder: (context, index) {
  //                           final product = _filteredProducts[index];
  //                           final productId = product['productId'] ?? {};
  //                           final name = productId['productName'] ?? 'No Name';
  //                           final price =
  //                               product['finalPrice'] ??
  //                               product['price'] ??
  //                               productId['price'] ??
  //                               '-';
  //                           dynamic imagesRaw =
  //                               product['subProductImages'] ??
  //                               product['images'] ??
  //                               [];
  //                           List<String> images = [];
  //                           if (imagesRaw is String) {
  //                             // Split by comma and trim
  //                             images = imagesRaw
  //                                 .split(',')
  //                                 .map((e) => e.trim())
  //                                 .toList();
  //                           } else if (imagesRaw is List) {
  //                             for (var item in imagesRaw) {
  //                               if (item is String && item.contains(',')) {
  //                                 images.addAll(
  //                                   item.split(',').map((e) => e.trim()),
  //                                 );
  //                               } else if (item != null) {
  //                                 images.add(item.toString());
  //                               }
  //                             }
  //                           } else {
  //                             images = [];
  //                           }
  //                           final imageUrl = images.isNotEmpty
  //                               ? images[0]
  //                               : null;

  //                           return GestureDetector(
  //                             onTap: () {
  //                               final id = product['_id'] ?? productId['_id'];
  //                               if (id != null) {
  //                                 Navigator.pushNamed(
  //                                   context,
  //                                   '/product-detail',
  //                                   arguments: id,
  //                                 );
  //                               }
  //                             },
  //                             child: Card(
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(12),
  //                               ),
  //                               elevation: 2,
  //                               child: Padding(
  //                                 padding: EdgeInsets.all(8),
  //                                 child: Column(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.center,
  //                                   children: [
  //                                     if (imageUrl != null)
  //                                       ClipRRect(
  //                                         borderRadius: BorderRadius.circular(
  //                                           8,
  //                                         ),
  //                                         child: Image.network(
  //                                           imageUrl,
  //                                           height: 80,
  //                                           width: double.infinity,
  //                                           fit: BoxFit.cover,
  //                                           errorBuilder:
  //                                               (
  //                                                 context,
  //                                                 error,
  //                                                 stackTrace,
  //                                               ) => Container(
  //                                                 height: 80,
  //                                                 width: double.infinity,
  //                                                 color: Colors.grey.shade200,
  //                                                 child: Icon(
  //                                                   Icons.image_not_supported,
  //                                                   color: Colors.grey,
  //                                                   size: 40,
  //                                                 ),
  //                                               ),
  //                                         ),
  //                                       ),
  //                                     SizedBox(height: 8),
  //                                     Text(
  //                                       name,
  //                                       style: TextStyle(
  //                                         fontWeight: FontWeight.bold,
  //                                         fontSize: 14,
  //                                       ),
  //                                       maxLines: 2,
  //                                       overflow: TextOverflow.ellipsis,
  //                                       textAlign: TextAlign.center,
  //                                     ),
  //                                     SizedBox(height: 4),
  //                                     Text(
  //                                       '₹$price',
  //                                       style: TextStyle(
  //                                         color: Colors.green,
  //                                         fontWeight: FontWeight.bold,
  //                                         fontSize: 13,
  //                                       ),
  //                                       textAlign: TextAlign.center,
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //               ),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //     floatingActionButton: FloatingActionButton(
  //       backgroundColor: Colors.indigo,
  //       foregroundColor: Colors.white,
  //       child: Icon(Icons.add),
  //       tooltip: 'Add Product',
  //       onPressed: () async {
  //         final result = await showModalBottomSheet(
  //           context: context,
  //           isScrollControlled: true,
  //           backgroundColor: Colors.white,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //           ),
  //           builder: (context) => Padding(
  //             padding: EdgeInsets.only(
  //               bottom: MediaQuery.of(context).viewInsets.bottom,
  //             ),
  //             child: AddProductForm(),
  //           ),
  //         );
  //         if (result == true) {
  //           setState(() {
  //             _productsFuture = AppDataRepo().fetchCatalogueProducts();
  //             _allProducts = [];
  //             _filteredProducts = [];
  //           });
  //         }
  //       },
  //     ),
  //     bottomNavigationBar: UniversalNavBar(
  //       selectedIndex: 3,
  //       onTap: (index) {
  //         String? route;
  //         switch (index) {
  //           case 0:
  //             route = '/dashboard';
  //             break;
  //           case 1:
  //             route = '/orders';
  //             break;
  //           case 2:
  //             route = '/users';
  //             break;
  //           case 3:
  //             route = '/catalogue';
  //             break;
  //           case 4:
  //             route = '/challan';
  //             break;
  //         }
  //         if (route != null && ModalRoute.of(context)?.settings.name != route) {
  //           Navigator.pushNamedAndRemoveUntil(
  //             context,
  //             route,
  //             (r) => r.settings.name == '/dashboard',
  //           );
  //         }
  //       },
  //     ),
  //   );
  // }
}
