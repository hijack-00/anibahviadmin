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
              final lotNumber = product['lotNumber'] ?? '';
              final parentName = productId['parentProductName'] ?? '';
              final pcsInSet = product['set'] ?? '-';
              final lotStock = product['lotStock'] ?? '-';
              final singlePicPrice = product['singlePicPrice'] ?? '-';
              final dateOfOpening = product['dateOfOpening'] ?? product['createdAt'] ?? '-';
              final sizes = product['sizes'] ?? [];
              final status = product['status'] == true ? 'In Stock' : 'Out of Stock';

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
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Set', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'In Stock' ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status, style: TextStyle(color: status == 'In Stock' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('$name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        if (lotNumber != '') Text('Lot: $lotNumber', style: TextStyle(color: Colors.grey)),
                        if (parentName != '') Text('Parent: $parentName', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Pcs in Set: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('$pcsInSet', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                            SizedBox(width: 16),
                            Text('Final Lot Price: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('₹$price', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Lot Stock: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('$lotStock pcs', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                            SizedBox(width: 16),
                            Text('Single Pic Price: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('₹$singlePicPrice', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Date of Opening: $dateOfOpening', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        if (sizes.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: sizes.map<Widget>((sz) {
                              final size = sz['size'] ?? '-';
                              return Chip(
                                label: Text(size.toString()),
                                backgroundColor: Colors.indigo.shade50,
                              );
                            }).toList(),
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
