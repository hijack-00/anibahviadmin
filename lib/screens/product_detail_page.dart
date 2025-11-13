import 'dart:convert';
import 'package:anibhaviadmin/permissions/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import '../services/app_data_repo.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'update_product_page.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with PermissionHelper {
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
    // Load permissions for /products (update product)
    initPermissions('/products').then((_) {
      if (!mounted) return;
      debugPrint('ProductDetailPage permissions: canUpdate=$canUpdate');
    });

    _productFuture = AppDataRepo().fetchProductDetailById(widget.productId);
    _productFuture = AppDataRepo().fetchAnyProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        foregroundColor: Colors.white,
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final resp = snapshot.data ?? {};
          final rawData = resp['data'];

          // normalize to a Map representing the item to render and keep original raw for detection
          Map<String, dynamic> product = {};
          if (rawData is List) {
            if (rawData.isEmpty) {
              return Center(
                child: Text(
                  'No product data',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              );
            }
            if (rawData.first is Map<String, dynamic>) {
              product = Map<String, dynamic>.from(rawData.first);
            } else {
              return Center(child: Text('Unexpected product format'));
            }
          } else if (rawData is Map<String, dynamic>) {
            product = Map<String, dynamic>.from(rawData);
          } else if (resp.containsKey('_id')) {
            product = Map<String, dynamic>.from(resp);
          } else {
            return Center(child: Text('No product data'));
          }

          // helper converters
          String _string(dynamic v) {
            if (v == null) return '';
            return v.toString();
          }

          List<String> _toStringList(dynamic v) {
            if (v == null) return [];
            if (v is List) return v.map((e) => e.toString()).toList();
            if (v is String) {
              try {
                final parsed = jsonDecode(v);
                if (parsed is List)
                  return parsed.map((e) => e.toString()).toList();
              } catch (_) {}
              if (v.contains(','))
                return v
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              return [v];
            }
            return [v.toString()];
          }

          // Detect sub-product shape (opened from catalogue) vs parent product shape.
          // Sub-product objects usually contain keys like 'productId', 'lotNumber', 'color', 'subProductImages', 'pcsInSet', 'lotStock'
          final isSubProduct =
              product.containsKey('productId') || resp['data'] is List;

          if (isSubProduct) {
            // Render the "catalogue->grid" detail layout (ListView with multiple cards)
            final data = product;
            final productId = data['productId'] ?? {};
            final imagesRaw = data['subProductImages'] ?? data['images'] ?? [];
            final sizesRaw = data['sizes'] ?? [];
            final statusApi = (data['status'] == true)
                ? 'In Stock'
                : 'Out of Stock';

            // parse sizes
            List<String> sizesApi = [];
            if (sizesRaw is String) {
              try {
                sizesApi = List<String>.from(jsonDecode(sizesRaw));
              } catch (_) {
                sizesApi = sizesRaw
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            } else if (sizesRaw is List) {
              sizesApi = sizesRaw.map((e) => e.toString()).toList();
            }

            selectedSizes = List<String>.from(sizesApi);

            // parse images
            List<String> parsedImages = [];
            if (imagesRaw is String) {
              parsedImages = imagesRaw.split(',').map((e) => e.trim()).toList();
            } else if (imagesRaw is List) {
              for (var item in imagesRaw) {
                if (item is String && item.contains(',')) {
                  parsedImages.addAll(item.split(',').map((e) => e.trim()));
                } else if (item != null) {
                  parsedImages.add(item.toString());
                }
              }
            }
            if (imageUrls.isEmpty && parsedImages.isNotEmpty)
              imageUrls = parsedImages;

            final color = _string(data['color'] ?? data['colour']);
            final parentProduct = _string(
              productId['productName'] ??
                  productId['productname'] ??
                  productId['name'],
            );
            final lotNumber = _string(data['lotNumber'] ?? data['name']);
            final pcsInSet = _string(data['pcsInSet']);
            final lotStock = _string(data['lotStock'] ?? data['stock']);
            final singlePicPrice = _string(
              data['singlePicPrice'] ?? data['price'],
            );
            final price = _string(
              data['filnalLotPrice'] ??
                  data['price'] ??
                  productId['price'] ??
                  '-',
            );
            final description = _string(data['description']);
            final barcode = _string(
              data['barcode'] ?? data['barcodeNo'] ?? data['barCode'],
            );

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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
          } else {
            // Render the parent-product detail layout (single product map)
            final lotNumber = _string(
              product['lotNumber'] ?? product['name'] ?? product['productName'],
            );
            final color = _string(product['color'] ?? product['colour']);
            final displayName = color.isNotEmpty
                ? '$lotNumber/$color'
                : (lotNumber.isNotEmpty ? lotNumber : 'Unnamed');
            final price = _string(
              product['finalLotPrice'] ??
                  product['singlePicPrice'] ??
                  product['price'] ??
                  product['finalPrice'],
            );

            final imagesRaw =
                product['subProductImages'] ??
                product['images'] ??
                product['subImages'] ??
                product['image'];
            final images = _toStringList(imagesRaw);
            final imageUrl = images.isNotEmpty ? images.first : null;
            final sizes = _toStringList(product['sizes']);

            if (mounted) {
              if (selectedSizes.isEmpty && sizes.isNotEmpty)
                selectedSizes = List<String>.from(sizes);
              if (imageUrls.isEmpty && images.isNotEmpty)
                imageUrls = List<String>.from(images);
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(height: 260, color: Colors.grey.shade200),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price: ₹$price',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sizes.isNotEmpty) ...[
                          Text(
                            'Sizes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: sizes
                                .map(
                                  (s) => Chip(
                                    label: Text(
                                      s,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'SKU: ${_string(product['sku'] ?? product['barcode'] ?? '-')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stock: ${_string(product['lotStock'] ?? product['stock'] ?? '-')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Description:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _string(
                            product['description'] ?? product['desc'] ?? '',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),

      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          // final data = snapshot.data?['data'] ?? {};
          final resp = snapshot.data ?? {};
          dynamic rawData = resp['data'];
          Map<String, dynamic> data;
          if (rawData is List && rawData.isNotEmpty && rawData.first is Map) {
            data = Map<String, dynamic>.from(rawData.first);
          } else if (rawData is Map<String, dynamic>) {
            data = rawData;
          } else {
            // last-resort: try top-level fields
            data = Map<String, dynamic>.from(resp);
          }
          // Determine whether the loaded item is a sub-product (catalogue) or a parent product.
          final bool isSubProduct =
              data.containsKey('productId') || resp['data'] is List;
          // if (!isSubProduct) {
          if (!isSubProduct || !canUpdate) {
            // don't show FAB for parent-product detail view
            return const SizedBox.shrink();
          }

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
            label: const Text(
              'Update',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
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
