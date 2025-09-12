import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';

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
          return ListView.builder(
            padding: EdgeInsets.all(16),
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
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                          )
                        : Container(width: 56, height: 56, color: Colors.grey.shade200),
                    title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('₹$price', style: TextStyle(color: Colors.indigo)),
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }
}
