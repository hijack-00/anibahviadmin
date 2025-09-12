import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading product details'));
          }
          final data = snapshot.data?['data'] ?? {};
          final productId = data['productId'] ?? {};
          final images = data['subProductImages'] ?? [];
          final categories = productId['categoryId'] ?? [];
          final sizes = data['sizes'] ?? [];
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12),
                    itemBuilder: (context, idx) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(images[idx], width: 180, height: 180, fit: BoxFit.cover),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Text(productId['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              SizedBox(height: 8),
              Text('Price: ₹${data['finalPrice'] ?? data['price'] ?? '-'}', style: TextStyle(fontSize: 16, color: Colors.indigo)),
              SizedBox(height: 8),
              Text('Set: ${data['set'] ?? '-'}'),
              SizedBox(height: 8),
              Text('Color: ${data['color'] ?? '-'}'),
              SizedBox(height: 8),
              Text('Status: ${data['status'] == true ? 'Active' : 'Inactive'}'),
              SizedBox(height: 8),
              Text('Created At: ${data['createdAt'] ?? '-'}'),
              SizedBox(height: 8),
              Text('Updated At: ${data['updatedAt'] ?? '-'}'),
              SizedBox(height: 16),
              Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...categories.map<Widget>((cat) => ListTile(
                title: Text(cat['name'] ?? ''),
                subtitle: Text(cat['description'] ?? ''),
                leading: cat['images'] != null && cat['images'].isNotEmpty
                  ? Image.network(cat['images'][0], width: 40, height: 40, fit: BoxFit.cover)
                  : null,
              )),
              SizedBox(height: 16),
              Text('Sizes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...sizes.map<Widget>((sz) => ListTile(
                title: Text('Size: ${sz['size'] ?? '-'}'),
                subtitle: Text('Status: ${sz['status'] == true ? 'Active' : 'Inactive'}'),
              )),
            ],
          );
        },
      ),
    );
  }
}
