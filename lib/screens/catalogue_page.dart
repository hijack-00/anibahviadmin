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

  @override
  void initState() {
    super.initState();
    _productsFuture = AppDataRepo().fetchCatalogueProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Catalogue'),
        // backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Center(child: Text('No products found'));
          }
          // Use GridView for smaller cards
          return GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Show 3 cards per row
              childAspectRatio: 0.7, // Adjust for 6-7 cards per screen
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productId = product['productId'] ?? {};
              final name = productId['productName'] ?? 'No Name';
              final price = product['finalPrice'] ?? product['price'] ?? '-';
              final images = product['subProductImages'] ?? product['images'] ?? [];
              final imageUrl = images.isNotEmpty ? images[0] : null;

              return GestureDetector(
                onTap: () {
                  final id = product['_id'] ?? productId['_id'];
                  if (id != null) {
                    Navigator.pushNamed(
                      context,
                      '/product-detail',
                      arguments: id,
                    );
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        SizedBox(height: 8),
                        Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹$price',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        tooltip: 'Add Product',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddProductForm(),
            ),
          );
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
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => r.settings.name == '/dashboard');
          }
        },
      ),
    );
  }
}
