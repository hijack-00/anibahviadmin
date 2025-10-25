import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import '../services/app_data_repo.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
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
    final barcodeUrl =
        'https://barcode.tec-it.com/barcode.ashx?data=$barcode&code=EAN13';
    final response = await http.get(Uri.parse(barcodeUrl));
    final imageBytes = response.bodyBytes;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Barcode',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Image(pw.MemoryImage(imageBytes), height: 100),
              pw.SizedBox(height: 16),
              pw.Text(barcode, style: pw.TextStyle(fontSize: 20)),
            ],
          ),
        ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Product Details', style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonLoader(context);
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading product details',
                style: TextStyle(fontSize: 12),
              ),
            );
          }

          final data = snapshot.data?['data'] ?? {};
          final productId = data['productId'] ?? {};
          final images = data['subProductImages'] ?? [];
          final statusApi = data['status'] == true
              ? 'In Stock'
              : 'Out of Stock';

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
          if (imageUrls.isEmpty && parsedImages.isNotEmpty)
            imageUrls = parsedImages;

          final color = data['color']?.toString() ?? '';
          final parentProduct = productId['productName']?.toString() ?? '';
          final lotNumber = data['lotNumber']?.toString() ?? '';
          final pcsInSet = data['pcsInSet']?.toString() ?? '';
          final lotStock = data['lotStock']?.toString() ?? '';
          final singlePicPrice = data['singlePicPrice']?.toString() ?? '';
          final price =
              data['filnalLotPrice']?.toString() ??
              data['price']?.toString() ??
              productId['price']?.toString() ??
              '-';
          final description = data['description']?.toString() ?? '';
          final barcode = data['barcode']?.toString() ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrls[idx],
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _detailCard([
                _stunningRow('Parent Product', parentProduct),
                _stunningRow('Color', color),
                _stunningRow('Lot Number', lotNumber),
                _stunningRow('Pcs in Set', pcsInSet),
                _stunningRow('Lot Stock', lotStock),
                _stunningRow('Single Pic Price', singlePicPrice),
                _stunningRow(
                  'Status',
                  statusApi,
                  valueColor: statusApi == 'In Stock'
                      ? Colors.green
                      : Colors.red,
                ),
                _stunningRow('Description', description),
              ]),
              const SizedBox(height: 16),
              if (barcode.isNotEmpty) _barcodeCard(barcode),
              const SizedBox(height: 16),
              _sizesCard(),
              const SizedBox(height: 16),
              _priceCard(price),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
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
                        _productFuture = AppDataRepo().fetchProductDetailById(
                          widget.productId,
                        );
                      });
                    },
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                  _productFuture = AppDataRepo().fetchProductDetailById(
                    widget.productId,
                  );
                });
              }
            },
            label: const Text('Update', style: TextStyle(fontSize: 12)),
            icon: const Icon(Icons.edit, size: 18),
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _detailCard(List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: rows),
      ),
    );
  }

  Widget _barcodeCard(String barcode) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barcode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Center(
              child: Image.network(
                'https://barcode.tec-it.com/barcode.ashx?data=$barcode&code=EAN13',
                height: 60,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                barcode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _downloadBarcodePdf(barcode),
                icon: const Icon(Icons.download, size: 14),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(fontSize: 10),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Sizes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: selectedSizes
                  .map(
                    (size) => Chip(
                      label: Text(size, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.indigo.shade50,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceCard(String price) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.currency_rupee, color: Colors.green, size: 14),
            const SizedBox(width: 6),
            Text(
              'Final Price: ₹$price',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stunningRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(6, (_) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}




// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
// import '../services/app_data_repo.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:http/http.dart' as http;
// import 'update_product_page.dart';


// class ProductDetailPage extends StatefulWidget {
//   final String productId;
//   const ProductDetailPage({required this.productId});

//   @override
//   State<ProductDetailPage> createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   late Future<Map<String, dynamic>> _productFuture;

//   List<String> selectedSizes = [];
//   List<String> imageUrls = [];



// Future<void> _downloadBarcodePdf(String barcode) async {
//   final pdf = pw.Document();
//   final barcodeUrl = 'https://barcode.tec-it.com/barcode.ashx?data=$barcode&code=EAN13';

//   // Download the barcode image as bytes
//   final response = await http.get(Uri.parse(barcodeUrl));
//   final imageBytes = response.bodyBytes;

//   pdf.addPage(
//     pw.Page(
//       build: (pw.Context context) {
//         return pw.Column(
//           mainAxisAlignment: pw.MainAxisAlignment.center,
//           crossAxisAlignment: pw.CrossAxisAlignment.center,
//           children: [
//             pw.Text('Barcode', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
//             pw.SizedBox(height: 16),
//             pw.Image(pw.MemoryImage(imageBytes), height: 80),
//             pw.SizedBox(height: 16),
//             pw.Text(barcode, style: pw.TextStyle(fontSize: 20)),
//           ],
//         );
//       },
//     ),
//   );

//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//     name: 'barcode_$barcode.pdf',
//   );
// }





//   @override
//   void initState() {
//     super.initState();
//     _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text('Product Details'),
//         backgroundColor: Colors.indigo,
//       ),
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _productFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading product details'));
//           }
//           print('Product Details API response: ${snapshot.data}');
//           final data = snapshot.data?['data'] ?? {};
//           final productId = data['productId'] ?? {};
//           final images = data['subProductImages'] ?? [];
//           final statusApi = data['status'] == true ? 'In Stock' : 'Out of Stock';
//           final sizesApiRaw = data['sizes'] ?? [];
//           List<String> sizesApi;
//           if (sizesApiRaw is String) {
//             try {
//               sizesApi = List<String>.from(jsonDecode(sizesApiRaw));
//             } catch (e) {
//               sizesApi = [];
//             }
//           } else if (sizesApiRaw is List) {
//             sizesApi = sizesApiRaw.map((e) => e.toString()).toList();
//           } else {
//             sizesApi = [];
//           }
//           selectedSizes = List<String>.from(sizesApi);

//           // Robustly parse images into a list of URLs
//           List<String> parsedImages = [];
//           if (images is String) {
//             parsedImages = images.split(',').map((e) => e.trim()).toList();
//           } else if (images is List) {
//             for (var item in images) {
//               if (item is String && item.contains(',')) {
//                 parsedImages.addAll(item.split(',').map((e) => e.trim()));
//               } else if (item != null) {
//                 parsedImages.add(item.toString());
//               }
//             }
//           }
//           if (imageUrls.isEmpty && parsedImages.isNotEmpty) imageUrls = parsedImages;

//           // Prepare fields for display
//           final color = data['color']?.toString() ?? '';
//           final parentProduct = productId['productName']?.toString() ?? '';
//           final lotNumber = data['lotNumber']?.toString() ?? '';
//           final pcsInSet = data['pcsInSet']?.toString() ?? '';
//           final lotStock = data['lotStock']?.toString() ?? '';
//           final singlePicPrice = data['singlePicPrice']?.toString() ?? '';
//           // --- Price logic: check all possible locations ---
//           final price = data['filnalLotPrice']?.toString()
//               ?? data['price']?.toString()
//               ?? productId['price']?.toString()
//               ?? '-';
//           final description = data['description']?.toString() ?? '';
//           final barcode = data['barcode']?.toString() ?? '';

//           return ListView(
//             padding: EdgeInsets.all(16),
//             children: [
//               // Images
//               if (imageUrls.isNotEmpty)
//                 SizedBox(
//                   height: 120,
//                   child: ListView.separated(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: imageUrls.length,
//                     separatorBuilder: (_, __) => SizedBox(width: 8),
//                     itemBuilder: (context, idx) => ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         imageUrls[idx],
//                         width: 120,
//                         height: 120,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) => Container(
//                           width: 120,
//                           height: 120,
//                           color: Colors.grey[300],
//                           child: Icon(Icons.broken_image, color: Colors.grey),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               SizedBox(height: 16),
//               _detailRow('Color', color),
//               _detailRow('Parent Product', parentProduct),
//               _detailRow('Lot Number', lotNumber),
//               _detailRow('Pcs in Set', pcsInSet),
//               _detailRow('Lot Stock', lotStock),
//               _detailRow('Single Pic Price', singlePicPrice),
//               _detailRow('Status', statusApi),
//               _detailRow('Description', description),
//               // _detailRow('Barcode', barcode),
//               // SizedBox(height: 16),
//               if (barcode.isNotEmpty)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Barcode:', style: TextStyle(fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     Image.network(
//                       'https://barcode.tec-it.com/barcode.ashx?data=$barcode&code=EAN13',
//                       height: 60,
//                       fit: BoxFit.contain,
//                     ),
//                     SizedBox(height: 8),
//                     Text(barcode, style: TextStyle(fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     ElevatedButton.icon(
//                       onPressed: () => _downloadBarcodePdf(barcode),
//                       icon: Icon(Icons.download),
//                       label: Text('Download Barcode PDF'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.indigo,
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               SizedBox(height: 16),
//               Text('Selected Sizes', style: TextStyle(fontWeight: FontWeight.bold)),
//               Wrap(
//                 spacing: 8,
//                 children: selectedSizes.map((size) => Chip(label: Text(size))).toList(),
//               ),
//               SizedBox(height: 24),
//               Text('Final Price: ₹$price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
//               SizedBox(height: 24),
//             ],
//           );
//         },
//       ),
//       // floatingActionButton: FloatingActionButton.extended(
//       //   onPressed: () {},
//       //   label: Text('Update'),
//       //   icon: Icon(Icons.edit),
//       //   backgroundColor: Colors.indigo,
//       // ),
//       floatingActionButton: FutureBuilder<Map<String, dynamic>>(
//   future: _productFuture,
//   builder: (context, snapshot) {
//     if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
//       return SizedBox.shrink();
//     }
//     final data = snapshot.data?['data'] ?? {};
//     return FloatingActionButton.extended(
//       onPressed: () async {
//         final result = await Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => UpdateProductPage(
//               productData: data,
//               onUpdated: () {
//                 setState(() {
//                   _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
//                 });
//               },
//             ),
//           ),
//         );
//         if (result == true) {
//           setState(() {
//             _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
//           });
//         }
//       },
//       label: Text('Update'),
//       icon: Icon(Icons.edit),
//       backgroundColor: Colors.indigo,
//     );
//   },
// ),
//     );
//   }

//   Widget _detailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 140,
//             child: Text(
//               '$label:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(value.isNotEmpty ? value : '-', style: TextStyle(fontSize: 16)),
//           ),
//         ],
//       ),
//     );
//   }
// }
