import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import '../services/app_data_repo.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'update_product_page.dart';


class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productFuture;

  List<String> selectedSizes = [];
  List<String> imageUrls = [];



Future<void> _downloadBarcodePdf(String barcode) async {
  final pdf = pw.Document();
  final barcodeUrl = 'https://barcode.tec-it.com/barcode.ashx?data=$barcode&code=EAN13';

  // Download the barcode image as bytes
  final response = await http.get(Uri.parse(barcodeUrl));
  final imageBytes = response.bodyBytes;

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Barcode', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Image(pw.MemoryImage(imageBytes), height: 80),
            pw.SizedBox(height: 16),
            pw.Text(barcode, style: pw.TextStyle(fontSize: 20)),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'barcode_$barcode.pdf',
  );
}





  @override
  void initState() {
    super.initState();
    _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          print('Product Details API response: ${snapshot.data}');
          final data = snapshot.data?['data'] ?? {};
          final productId = data['productId'] ?? {};
          final images = data['subProductImages'] ?? [];
          final statusApi = data['status'] == true ? 'In Stock' : 'Out of Stock';
          final sizesApiRaw = data['sizes'] ?? [];
          List<String> sizesApi;
          if (sizesApiRaw is String) {
            try {
              sizesApi = List<String>.from(jsonDecode(sizesApiRaw));
            } catch (e) {
              sizesApi = [];
            }
          } else if (sizesApiRaw is List) {
            sizesApi = sizesApiRaw.map((e) => e.toString()).toList();
          } else {
            sizesApi = [];
          }
          selectedSizes = List<String>.from(sizesApi);

          // Robustly parse images into a list of URLs
          List<String> parsedImages = [];
          if (images is String) {
            parsedImages = images.split(',').map((e) => e.trim()).toList();
          } else if (images is List) {
            for (var item in images) {
              if (item is String && item.contains(',')) {
                parsedImages.addAll(item.split(',').map((e) => e.trim()));
              } else if (item != null) {
                parsedImages.add(item.toString());
              }
            }
          }
          if (imageUrls.isEmpty && parsedImages.isNotEmpty) imageUrls = parsedImages;

          // Prepare fields for display
          final color = data['color']?.toString() ?? '';
          final parentProduct = productId['productName']?.toString() ?? '';
          final lotNumber = data['lotNumber']?.toString() ?? '';
          final pcsInSet = data['pcsInSet']?.toString() ?? '';
          final lotStock = data['lotStock']?.toString() ?? '';
          final singlePicPrice = data['singlePicPrice']?.toString() ?? '';
          // --- Price logic: check all possible locations ---
          final price = data['filnalLotPrice']?.toString()
              ?? data['price']?.toString()
              ?? productId['price']?.toString()
              ?? '-';
          final description = data['description']?.toString() ?? '';
          final barcode = data['barcode']?.toString() ?? '';

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Images
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8),
                    itemBuilder: (context, idx) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrls[idx],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              _detailRow('Color', color),
              _detailRow('Parent Product', parentProduct),
              _detailRow('Lot Number', lotNumber),
              _detailRow('Pcs in Set', pcsInSet),
              _detailRow('Lot Stock', lotStock),
              _detailRow('Single Pic Price', singlePicPrice),
              _detailRow('Status', statusApi),
              _detailRow('Description', description),
              // _detailRow('Barcode', barcode),
              // SizedBox(height: 16),
              if (barcode.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barcode:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Image.network(
                      'https://barcode.tec-it.com/barcode.ashx?data=$barcode&code=EAN13',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 8),
                    Text(barcode, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _downloadBarcodePdf(barcode),
                      icon: Icon(Icons.download),
                      label: Text('Download Barcode PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16),
              Text('Selected Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: selectedSizes.map((size) => Chip(label: Text(size))).toList(),
              ),
              SizedBox(height: 24),
              Text('Final Price: ₹$price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
              SizedBox(height: 24),
            ],
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {},
      //   label: Text('Update'),
      //   icon: Icon(Icons.edit),
      //   backgroundColor: Colors.indigo,
      // ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
  future: _productFuture,
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
      return SizedBox.shrink();
    }
    final data = snapshot.data?['data'] ?? {};
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UpdateProductPage(
              productData: data,
              onUpdated: () {
                setState(() {
                  _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
                });
              },
            ),
          ),
        );
        if (result == true) {
          setState(() {
            _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
          });
        }
      },
      label: Text('Update'),
      icon: Icon(Icons.edit),
      backgroundColor: Colors.indigo,
    );
  },
),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
