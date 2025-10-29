import 'package:anibhaviadmin/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_data_repo.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_data_repo.dart';
import 'package:anibhaviadmin/services/api_service.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({required this.orderId, Key? key}) : super(key: key);

  // Generate Order PDF bytes (similar to challan pdf generation)
  Future<Uint8List> _buildOrderPdfData(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    final pw.Font noto = await PdfGoogleFonts.notoSansRegular();

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    double _unitPriceForItem(Map<String, dynamic> it) {
      final filnal = it['filnalLotPrice'] ?? it['filnalPrice'];
      if (filnal != null && filnal.toString().trim().isNotEmpty) {
        return _toDouble(filnal);
      }
      final single = it['singlePicPrice'] ?? it['singlePrice'] ?? it['price'];
      return _toDouble(single);
    }

    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final customerLabel = (() {
      final cust = order['customer'];
      if (cust is Map) return cust['name']?.toString() ?? '';
      return cust?.toString() ?? '';
    }());
    final orderNumber =
        order['orderNumber']?.toString() ?? order['_id']?.toString() ?? '';
    final dateStr = (order['orderDate'] ?? order['date'] ?? '').toString();
    final displayDate = dateStr.isNotEmpty ? dateStr.substring(0, 10) : '';
    final total = _toDouble(order['total'] ?? order['totalValue'] ?? 0).round();

    final baseTextStyle = pw.TextStyle(font: noto, fontSize: 11);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.DefaultTextStyle(
            style: baseTextStyle,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SALES ORDER',
                          style: baseTextStyle.copyWith(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Order #: $orderNumber'),
                        pw.Text('Date: $displayDate'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Customer',
                          style: baseTextStyle.copyWith(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(customerLabel),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Items:',
                  style: baseTextStyle.copyWith(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Table.fromTextArray(
                  headers: [
                    'Product',
                    'Size',
                    'Qty',
                    'PCS/SET',
                    'Price',
                    'Total',
                  ],
                  data: items.map((it) {
                    final name = it['name']?.toString() ?? '';
                    final size =
                        (it['availableSizes'] is List &&
                            (it['availableSizes'] as List).isNotEmpty)
                        ? (it['availableSizes'] as List).join(', ')
                        : (it['size']?.toString() ?? '');
                    final pcsInSet =
                        int.tryParse(it['pcsInSet']?.toString() ?? '1') ?? 1;
                    final qtySets =
                        int.tryParse(
                          (it['quantity'] ?? it['dispatchedQty'] ?? 0)
                              .toString(),
                        ) ??
                        0;
                    final qtyPieces = qtySets * pcsInSet;
                    final unitPrice = _unitPriceForItem(it);
                    final bool isPerSet =
                        (it['filnalLotPrice'] ?? it['filnalPrice']) != null &&
                        (it['filnalLotPrice']?.toString().trim().isNotEmpty ??
                            false);
                    final totalForRow = isPerSet
                        ? unitPrice * qtySets
                        : unitPrice * qtyPieces;
                    final priceDisplay = unitPrice.round();
                    return [
                      name,
                      size,
                      qtySets.toString(),
                      pcsInSet.toString(),
                      '₹$priceDisplay',
                      '₹${totalForRow.round()}',
                    ];
                  }).toList(),
                  headerStyle: baseTextStyle.copyWith(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: baseTextStyle,
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellHeight: 22,
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total: ₹$total',
                          style: baseTextStyle.copyWith(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Generated on: ${DateTime.now().toIso8601String().substring(0, 10)}',
                    style: baseTextStyle.copyWith(
                      fontSize: 9,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadOrderPdf(
    Map<String, dynamic> order,
    BuildContext context,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      final bytes = await _buildOrderPdfData(order);

      // Request Android permissions when required
      if (Platform.isAndroid) {
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      String? downloadsPath;
      if (Platform.isAndroid) {
        final candidates = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
        ];
        for (var cand in candidates) {
          try {
            final d = Directory(cand);
            if (!await d.exists()) await d.create(recursive: true);
            final testFile = File(p.join(d.path, '.write_test'));
            await testFile.writeAsBytes([0]);
            await testFile.delete();
            downloadsPath = d.path;
            break;
          } catch (_) {
            downloadsPath ??= null;
          }
        }
      } else if (Platform.isIOS) {
        downloadsPath = (await getApplicationDocumentsDirectory()).path;
      } else {
        final dl = await getDownloadsDirectory();
        downloadsPath =
            dl?.path ?? (await getApplicationDocumentsDirectory()).path;
      }

      if (downloadsPath == null) {
        final fallback = Platform.isAndroid
            ? (await getExternalStorageDirectory())?.path
            : (await getApplicationDocumentsDirectory()).path;
        downloadsPath = fallback;
      }

      if (downloadsPath == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Unable to determine save directory')),
          );
        return;
      }

      final nameBase = (order['orderNumber'] ?? 'order').toString().replaceAll(
        RegExp(r'[^A-Za-z0-9\-_]'),
        '_',
      );
      final filename =
          '${nameBase}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pathFile = p.join(downloadsPath, filename);

      try {
        final file = File(pathFile);
        await file.writeAsBytes(bytes, flush: true);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Saved PDF: $pathFile')));
      } on FileSystemException {
        // fallback to app directory
        final fallbackDir = Platform.isAndroid
            ? (await getExternalStorageDirectory())?.path
            : (await getApplicationDocumentsDirectory()).path;
        if (fallbackDir == null) rethrow;
        final fallbackPath = p.join(fallbackDir, filename);
        final f2 = File(fallbackPath);
        await f2.writeAsBytes(bytes, flush: true);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Saved PDF to app folder: $fallbackPath')),
          );
      }
    } catch (e, st) {
      debugPrint('Error saving order pdf: $e\n$st');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
    }
  }

  Future<void> _shareOrderPdf(
    Map<String, dynamic> order,
    BuildContext context,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing PDF for sharing...')),
      );
      final bytes = await _buildOrderPdfData(order);
      final tmpDir = await getTemporaryDirectory();
      final nameBase = (order['orderNumber'] ?? 'order').toString().replaceAll(
        RegExp(r'[^A-Za-z0-9\-_]'),
        '_',
      );
      final tmpPath = p.join(
        tmpDir.path,
        '${nameBase}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      try {
        await Share.shareXFiles([
          XFile(tmpFile.path),
        ], text: 'Order ${order['orderNumber'] ?? ''}');
      } on MissingPluginException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Share plugin not registered. Do a full rebuild (flutter clean && flutter pub get && flutter run)',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Error sharing order pdf: $e\n$st');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to prepare share: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOrders =
        ModalRoute.of(context)?.settings.arguments
            as List<Map<String, dynamic>>?;
    final order = allOrders?.firstWhere(
      (o) => o['_id'] == orderId || o['id'] == orderId,
      orElse: () => {},
    );

    if (order == null || order.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(child: Text('Order not found')),
      );
    }

    final customer = order['customer'] ?? {};
    final user = customer['userId'] ?? {};
    final address = user['address'] ?? {};
    final items = order['items'] ?? [];
    final payments = order['payments'] ?? [];
    final statusHistory = order['statusHistory'] ?? [];
    final paidAmount = order['paidAmount'] ?? 0;
    final balanceAmount = order['balanceAmount'] ?? 0;
    final paymentType = order['paymentType'] ?? '';
    final paymentMethod = order['paymentMethod'] ?? '';
    final subtotal = order['subtotal'] ?? 0;
    final total = order['total'] ?? 0;
    final pointsRedeemed = order['pointsRedeemed'] ?? 0;
    final pointsRedemptionValue = order['pointsRedemptionValue'] ?? 0;
    final pointsEarned = order['pointsEarned'] ?? 0;
    final pointsEarnedValue = order['pointsEarnedValue'] ?? 0;
    final orderNote = order['orderNote'] ?? '';
    final transportName = order['transportName'] ?? '';
    final orderType = order['orderType'] ?? '';
    final orderDate = order['orderDate'] ?? '';
    final status = order['status'] ?? '';
    final deliveryAddress = customer['deliveryAddress'] ?? '';

    Color statusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'packed':
          return Colors.blue;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${order['orderNumber'] ?? ''}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        // ADD: Edit and PDF actions
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Order',
            onPressed: () {
              // simple placeholder — replace with navigation to your edit screen if available
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) {
                  // controllers created here for the sheet lifecycle
                  final TextEditingController transportCtl =
                      TextEditingController(
                        text: order['transportName']?.toString() ?? '',
                      );
                  final TextEditingController noteCtl = TextEditingController(
                    text: order['orderNote']?.toString() ?? '',
                  );
                  final TextEditingController paidCtl = TextEditingController(
                    text: order['paidAmount']?.toString() ?? '',
                  );
                  String statusVal = order['status']?.toString() ?? '';

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
                    ),
                    child: StatefulBuilder(
                      builder: (ctx2, setModalState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Edit Order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: statusVal.isNotEmpty ? statusVal : null,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                isDense: true,
                              ),
                              items:
                                  [
                                        'Pending',
                                        'Packed',
                                        'Shipped',
                                        'Delivered',
                                        'Cancelled',
                                      ]
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setModalState(
                                () => statusVal = v ?? statusVal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: transportCtl,
                              decoration: const InputDecoration(
                                labelText: 'Transport Name',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: paidCtl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Paid Amount',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: noteCtl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Order Note',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // prepare updated map (caller can perform actual API update)
                                      final updated = Map<String, dynamic>.from(
                                        order,
                                      );
                                      updated['transportName'] = transportCtl
                                          .text
                                          .trim();
                                      updated['orderNote'] = noteCtl.text
                                          .trim();
                                      updated['status'] = statusVal;
                                      updated['paidAmount'] =
                                          double.tryParse(
                                            paidCtl.text.trim(),
                                          ) ??
                                          order['paidAmount'] ??
                                          0;

                                      // show simple feedback and return updated object to caller
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Order saved (local).'),
                                        ),
                                      );
                                      Navigator.of(ctx).pop(updated);
                                    },
                                    child: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Order PDF',
            onSelected: (val) async {
              if (val == 'download') {
                await _downloadOrderPdf(order, context);
              } else if (val == 'share') {
                await _shareOrderPdf(order, context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'download',
                child: Text('Download PDF'),
              ),
              const PopupMenuItem(value: 'share', child: Text('Share PDF')),
            ],
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 12.0),
        //     child: ElevatedButton.icon(
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: Colors.green,
        //         foregroundColor: Colors.white,
        //         elevation: 0,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(6),
        //         ),
        //       ),
        //       icon: Icon(Icons.print, size: 18),
        //       label: Text('Print Invoice'),
        //       onPressed: () {},
        //     ),
        //   ),
        // ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Row: Customer Info, Order Info, Status History
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              // margin: EdgeInsets.only(right: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'User ID: ${user['uniqueUserId'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          'Shop Name: ${user['shopname'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Name: ${customer['name'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        Text(
                                          'Phone: ${customer['phone'] ?? ''}',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),

                                    Text(
                                      'Email: ${customer['email'] ?? ''}',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Order Info
                      Card(
                        elevation: 0,
                        // margin: EdgeInsets.only(right: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date: $orderDate',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Type: $orderType',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Type: $paymentType',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  Text(
                                    'Payment Method: $paymentMethod',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (transportName.toString().isNotEmpty)
                                        Text(
                                          'Transport: $transportName',
                                          style: TextStyle(fontSize: 11),
                                        ),

                                      if (orderNote.toString().isNotEmpty)
                                        Text(
                                          'Note: $orderNote',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                    ],
                                  ),

                                  Column(
                                    children: [
                                      Text(
                                        'Subtotal: ₹$subtotal',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        'Total: ₹$total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Status History
                    ],
                  ),

                  // Delivery Address
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''}, ${address['country'] ?? ''} - ${address['zipCode'] ?? ''}',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          ...statusHistory.map<Widget>(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: statusColor(s['status'] ?? ''),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${s['status'] ?? ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${s['date'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'by ${s['updatedBy'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              // Payment Information
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Paid Amount: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$paidAmount',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  Text(
                                    'Redeemed:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,

                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "$pointsRedeemed Points",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  Text(
                                    'Balance Amount: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$balanceAmount',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    'Earned:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "$pointsEarned Points",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              // SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,

                                children: [
                                  Text(
                                    'Discount:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$pointsRedemptionValue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    'Earned Value:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '₹$pointsEarnedValue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 6),

                      // SizedBox(height: 12),
                      Text(
                        'Payments:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...payments.map<Widget>(
                        (pm) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${pm['method'] ?? 'Cash'}:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${pm['amount'] ?? ''}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              // Items
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      ...items.map<Widget>((item) {
                        // Calculate total pieces and total price
                        final sets = item['quantity'] ?? 1;
                        final pcsInSet = item['pcsInSet'] ?? 1;
                        final pricePerPiece = item['singlePicPrice'] ?? 0;
                        final totalPcs = sets * pcsInSet;
                        final totalPrice = pricePerPiece * totalPcs;

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              item['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity: $sets sets × $pcsInSet pcs = $totalPcs pieces',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Price: ₹$pricePerPiece per piece',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₹${totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '$totalPcs pieces',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              // ElevatedButton(
              //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              //   onPressed: () => Navigator.of(context).pop(true),
              //   child: Text(
              //     'Delete Order',
              //     style: TextStyle(color: Colors.white),
              //   ),
              // ),
              // Bottom action row: Update & Create Challan
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        // reuse the edit sheet shown by the AppBar edit icon
                        final updated =
                            await showModalBottomSheet<Map<String, dynamic>?>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (ctx) {
                                final TextEditingController transportCtl =
                                    TextEditingController(
                                      text:
                                          order['transportName']?.toString() ??
                                          '',
                                    );
                                final TextEditingController noteCtl =
                                    TextEditingController(
                                      text:
                                          order['orderNote']?.toString() ?? '',
                                    );
                                final TextEditingController paidCtl =
                                    TextEditingController(
                                      text:
                                          order['paidAmount']?.toString() ?? '',
                                    );
                                String statusVal =
                                    order['status']?.toString() ?? '';

                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 12,
                                    bottom:
                                        MediaQuery.of(ctx).viewInsets.bottom +
                                        18,
                                  ),
                                  child: StatefulBuilder(
                                    builder: (ctx2, setModalState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Edit Order',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: statusVal.isNotEmpty
                                                ? statusVal
                                                : null,
                                            decoration: const InputDecoration(
                                              labelText: 'Status',
                                              isDense: true,
                                            ),
                                            items:
                                                [
                                                      'Pending',
                                                      'Packed',
                                                      'Shipped',
                                                      'Delivered',
                                                      'Cancelled',
                                                    ]
                                                    .map(
                                                      (s) => DropdownMenuItem(
                                                        value: s,
                                                        child: Text(s),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged: (v) => setModalState(
                                              () => statusVal = v ?? statusVal,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: transportCtl,
                                            decoration: const InputDecoration(
                                              labelText: 'Transport Name',
                                              isDense: true,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: paidCtl,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Paid Amount',
                                              isDense: true,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: noteCtl,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              labelText: 'Order Note',
                                              isDense: true,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final updated =
                                                        Map<
                                                          String,
                                                          dynamic
                                                        >.from(order);
                                                    updated['transportName'] =
                                                        transportCtl.text
                                                            .trim();
                                                    updated['orderNote'] =
                                                        noteCtl.text.trim();
                                                    updated['status'] =
                                                        statusVal;
                                                    updated['paidAmount'] =
                                                        double.tryParse(
                                                          paidCtl.text.trim(),
                                                        ) ??
                                                        order['paidAmount'] ??
                                                        0;
                                                    // return updated to caller
                                                    Navigator.of(
                                                      ctx,
                                                    ).pop(updated);
                                                  },
                                                  child: const Text('Save'),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            );

                        if (updated != null && updated.isNotEmpty) {
                          // Try to refresh page by replacing route and providing updated object as argument,
                          // previous screens (orders list) can also receive this when popped.
                          final updatedListArg = [updated];
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsPage(
                                orderId: updated['_id']?.toString() ?? orderId,
                              ),
                              settings: RouteSettings(
                                arguments: updatedListArg,
                              ),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order updated')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Create Challan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Offer download / share options for challan (uses existing pdf helpers)
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          builder: (ctx) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.download),
                                    title: const Text('Download Challan PDF'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      _downloadOrderPdf(order, context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: const Text('Share Challan PDF'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      _shareOrderPdf(order, context);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}
