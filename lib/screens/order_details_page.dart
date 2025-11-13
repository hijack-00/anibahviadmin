import 'package:anibhaviadmin/permissions/permission_helper.dart';
import 'package:anibhaviadmin/services/api_service.dart';
import 'package:anibhaviadmin/widgets/universal_scaffold.dart';
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

// class OrderDetailsPage extends StatelessWidget {
//   final String orderId;
//   const OrderDetailsPage({required this.orderId, Key? key}) : super(key: key);

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  const OrderDetailsPage({required this.orderId, Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with PermissionHelper {
  @override
  void initState() {
    super.initState();
    // Load permissions for /orders (update/delete order)
    initPermissions('/orders').then((_) {
      if (!mounted) return;
      debugPrint(
        'OrderDetailsPage permissions: canUpdate=$canUpdate canDelete=$canDelete canWrite=$canWrite',
      );
    });
  }

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

  Future<void> _openCreateChallanFromOrder(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    // This implementation mirrors ChallanScreen._showCreateChallanDialog
    // but pre-selects customer and order coming from the OrderDetailsPage.
    Map<String, dynamic>? selectedCustomer;
    Map<String, dynamic>? selectedOrder;
    String selectedVendor = 'BlueDart';
    String notes = '';
    List<Map<String, dynamic>> userOrders = [];
    List<Map<String, dynamic>> existingChallans = [];
    final vendors = ['BlueDart', 'Delhivery', 'DTDC', 'Transport', 'Other'];

    // map of order item idx -> new dispatch int
    final Map<int, int> newDispatchMap = {};
    // controllers for each item input so UI updates when value changes
    final Map<int, TextEditingController> dispatchControllers = {};

    // ensure users list is available (used if user wants to change customer)
    await AppDataRepo().loadAllUsers();

    // Pre-select customer & order from passed `order`
    // normalize customer object
    final orderCustomer = order['customer'];
    if (orderCustomer is Map && orderCustomer['_id'] != null) {
      selectedCustomer = Map<String, dynamic>.from(orderCustomer);
    } else if (order['customerId'] != null) {
      // try to find in cached users
      final cid = order['customerId'].toString();
      final found = AppDataRepo.users.firstWhere(
        (u) => (u['_id']?.toString() ?? '') == cid,
        orElse: () => {},
      );
      if (found.isNotEmpty)
        selectedCustomer = Map<String, dynamic>.from(found);
      else
        selectedCustomer = {
          '_id': cid,
          'name': orderCustomer?.toString() ?? '',
        };
    } else {
      selectedCustomer = null;
    }

    selectedOrder = Map<String, dynamic>.from(order);
    notes = order['notes']?.toString() ?? '';

    final List<Map<String, dynamic>> initialOrderItems =
        List<Map<String, dynamic>>.from(order['items'] ?? []);
    // Preload existing challans and initialize controllers BEFORE opening the sheet.
    // This prevents the async loader running after the first build and resetting
    // controller values when user taps + / - quickly.
    bool _preloaded = false;
    try {
      if (selectedCustomer != null &&
          (selectedCustomer!['_id'] ?? selectedCustomer!['id']) != null &&
          selectedOrder != null &&
          (selectedOrder!['_id'] ?? selectedOrder!['id']) != null) {
        final resp = await AppDataRepo().getChallansByCustomerAndOrder(
          customerId: (selectedCustomer!['_id'] ?? selectedCustomer!['id'])
              .toString(),
          orderId: (selectedOrder!['_id'] ?? selectedOrder!['id']).toString(),
        );
        if ((resp['status'] == true || resp['success'] == true) &&
            resp['data'] is List) {
          existingChallans = List<Map<String, dynamic>>.from(
            resp['data'] as List,
          );
        } else {
          existingChallans = [];
        }
      }
    } catch (_) {
      existingChallans = [];
    }

    // compute alreadyDispatched into items copy
    for (var it in initialOrderItems) {
      final name = (it['name'] ?? '').toString();
      int already = 0;
      for (var ch in existingChallans) {
        final chItems = (ch['items'] as List<dynamic>?) ?? [];
        for (var cit in chItems) {
          if ((cit['name'] ?? '').toString() == name) {
            already +=
                int.tryParse((cit['dispatchedQty'] ?? '0').toString()) ?? 0;
          }
        }
      }
      it['alreadyDispatched'] = already;
    }

    // initialize controllers with defaults (0) and dispatch map
    newDispatchMap.clear();
    dispatchControllers.clear();
    for (var i = 0; i < initialOrderItems.length; i++) {
      dispatchControllers[i] = TextEditingController(text: '0');
      newDispatchMap[i] = 0;
    }
    _preloaded = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        final height = MediaQuery.of(sheetCtx).size.height;
        return SafeArea(
          child: SizedBox(
            height: height * 0.98, // almost full screen
            child: StatefulBuilder(
              builder: (ctx2, setStateModal) {
                // load existing challans for this order/customer to compute alreadyDispatched
                Future<void> _loadExistingChallans() async {
                  existingChallans = [];
                  if (selectedCustomer != null &&
                      (selectedCustomer!['_id'] ?? selectedCustomer!['id']) !=
                          null &&
                      selectedOrder != null &&
                      (selectedOrder!['_id'] ?? selectedOrder!['id']) != null) {
                    try {
                      final resp = await AppDataRepo()
                          .getChallansByCustomerAndOrder(
                            customerId:
                                (selectedCustomer!['_id'] ??
                                        selectedCustomer!['id'])
                                    .toString(),
                            orderId:
                                (selectedOrder!['_id'] ?? selectedOrder!['id'])
                                    .toString(),
                          );
                      if ((resp['status'] == true || resp['success'] == true) &&
                          resp['data'] is List) {
                        existingChallans = List<Map<String, dynamic>>.from(
                          resp['data'] as List,
                        );
                      } else {
                        existingChallans = [];
                      }
                    } catch (_) {
                      existingChallans = [];
                    }
                  } else {
                    existingChallans = [];
                  }

                  // compute alreadyDispatched into items copy
                  for (var it in initialOrderItems) {
                    final name = (it['name'] ?? '').toString();
                    int already = 0;
                    for (var ch in existingChallans) {
                      final chItems = (ch['items'] as List<dynamic>?) ?? [];
                      for (var cit in chItems) {
                        if ((cit['name'] ?? '').toString() == name) {
                          already +=
                              int.tryParse(
                                (cit['dispatchedQty'] ?? '0').toString(),
                              ) ??
                              0;
                        }
                      }
                    }
                    it['alreadyDispatched'] = already;
                  }

                  // initialize controllers with defaults
                  newDispatchMap.clear();
                  dispatchControllers.clear();
                  for (var i = 0; i < initialOrderItems.length; i++) {
                    // final defaultQty =
                    //     (initialOrderItems[i]['dispatchedQty'] ??
                    //             initialOrderItems[i]['quantity'] ??
                    //             0)
                    //         .toString();
                    // default to 0 so user explicitly sets dispatch qty (limited by remaining)
                    final defaultQty = '0';

                    dispatchControllers[i] = TextEditingController(
                      text: defaultQty,
                    );
                    newDispatchMap[i] = int.tryParse(defaultQty) ?? 0;
                  }

                  setStateModal(() {});
                }

                // helper to compute already dispatched for a single item
                int _alreadyDispatchedForItem(Map<String, dynamic> item) {
                  return int.tryParse(
                        item['alreadyDispatched']?.toString() ?? '0',
                      ) ??
                      0;
                }

                final orderItems =
                    List<Map<String, dynamic>>.from(initialOrderItems).where((
                      it,
                    ) {
                      final status = (it['status'] ?? '')
                          .toString()
                          .toLowerCase();
                      return !(status == 'cancelled' ||
                          status == 'returned' ||
                          status == 'dispatched');
                    }).toList();

                int _computeTotalValue() {
                  double total = 0;
                  for (int i = 0; i < orderItems.length; i++) {
                    final item = orderItems[i];
                    final int dispatchSets = newDispatchMap[i] ?? 0;
                    final prod = item['productId'] as Map<String, dynamic>?;
                    final filnalRaw =
                        item['filnalLotPrice'] ?? prod?['filnalLotPrice'];
                    final bool hasFilnal =
                        filnalRaw != null &&
                        filnalRaw.toString().trim().isNotEmpty;

                    if (hasFilnal) {
                      final double pricePerSet =
                          double.tryParse(filnalRaw.toString()) ?? 0.0;
                      total += pricePerSet * dispatchSets;
                    } else {
                      final double pricePerPiece =
                          double.tryParse(
                            (item['singlePicPrice'] ?? item['price'] ?? 0)
                                .toString(),
                          ) ??
                          0.0;
                      final int pcsInSet =
                          int.tryParse(item['pcsInSet']?.toString() ?? '1') ??
                          1;
                      total += pricePerPiece * pcsInSet * dispatchSets;
                    }
                  }
                  return total.round();
                }

                // initial load existing challans when sheet opens
                // if (existingChallans.isEmpty) {
                //   Future.microtask(_loadExistingChallans);
                // }

                // avoid re-loading after we've preloaded above
                if (!_preloaded) {
                  Future.microtask(_loadExistingChallans);
                }

                return Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 12,
                  ),
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 11, color: Colors.black),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Create Delivery Challan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(sheetCtx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // const Text('Customer'),
                          // const SizedBox(height: 6),
                          // InkWell(
                          //   onTap: () async {
                          //     // allow user to change customer if needed
                          //     final picked = await showModalBottomSheet<Map<String, dynamic>>(
                          //       context: sheetCtx,
                          //       isScrollControlled: true,
                          //       backgroundColor: Colors.white,
                          //       constraints: BoxConstraints(
                          //         maxHeight:
                          //             MediaQuery.of(sheetCtx).size.height *
                          //             0.95,
                          //       ),
                          //       shape: const RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.vertical(
                          //           top: Radius.circular(16),
                          //         ),
                          //       ),
                          //       builder: (pickerCtx) {
                          //         String q = '';
                          //         final users = AppDataRepo.users;
                          //         return StatefulBuilder(
                          //           builder: (pc, pcSet) {
                          //             final filtered = users.where((u) {
                          //               final label =
                          //                   '${u['name'] ?? ''} ${u['phone'] ?? ''}'
                          //                       .toLowerCase();
                          //               return label.contains(q.toLowerCase());
                          //             }).toList();

                          //             return SafeArea(
                          //               child: Padding(
                          //                 padding: const EdgeInsets.all(12.0),
                          //                 child: Column(
                          //                   children: [
                          //                     Row(
                          //                       children: [
                          //                         const Expanded(
                          //                           child: Text(
                          //                             'Select Customer',
                          //                             style: TextStyle(
                          //                               fontWeight:
                          //                                   FontWeight.bold,
                          //                               fontSize: 16,
                          //                             ),
                          //                           ),
                          //                         ),
                          //                         IconButton(
                          //                           icon: const Icon(
                          //                             Icons.close,
                          //                           ),
                          //                           onPressed: () =>
                          //                               Navigator.pop(
                          //                                 pickerCtx,
                          //                               ),
                          //                         ),
                          //                       ],
                          //                     ),
                          //                     const SizedBox(height: 8),
                          //                     TextField(
                          //                       decoration:
                          //                           const InputDecoration(
                          //                             prefixIcon: Icon(
                          //                               Icons.search,
                          //                             ),
                          //                             hintText:
                          //                                 'Search customer...',
                          //                             isDense: true,
                          //                             border:
                          //                                 OutlineInputBorder(),
                          //                           ),
                          //                       onChanged: (v) =>
                          //                           pcSet(() => q = v),
                          //                     ),
                          //                     const SizedBox(height: 8),
                          //                     Expanded(
                          //                       child: ListView.separated(
                          //                         itemCount: filtered.length,
                          //                         separatorBuilder: (_, __) =>
                          //                             const Divider(height: 1),
                          //                         itemBuilder: (context, i) {
                          //                           final u = filtered[i];
                          //                           final label =
                          //                               '${u['name'] ?? ''} • ${u['phone'] ?? ''}';
                          //                           return ListTile(
                          //                             title: Text(label),
                          //                             onTap: () =>
                          //                                 Navigator.pop(
                          //                                   pickerCtx,
                          //                                   u,
                          //                                 ),
                          //                           );
                          //                         },
                          //                       ),
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             );
                          //           },
                          //         );
                          //       },
                          //     );

                          //     if (picked != null) {
                          //       selectedCustomer = picked;
                          //       // reload existing challans / orders for newly selected customer
                          //       await _loadExistingChallans();
                          //     }
                          //     setStateModal(() {});
                          //   },
                          //   child: InputDecorator(
                          //     decoration: const InputDecoration(
                          //       labelText: 'Customer',
                          //       border: OutlineInputBorder(),
                          //       isDense: true,
                          //     ),
                          //     child: Text(
                          //       selectedCustomer != null
                          //           ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
                          //           : 'Select Customer',
                          //       style: const TextStyle(fontSize: 13),
                          //     ),
                          //   ),
                          // ),
                          const Text('Customer'),
                          const SizedBox(height: 6),
                          // show customer pre-selected (not editable here)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Customer',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              selectedCustomer != null
                                  ? '${selectedCustomer!['name'] ?? ''} • ${selectedCustomer!['phone'] ?? ''}'
                                  : '${order['customer'] is Map ? order['customer']['name'] ?? '' : order['customer'] ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // const Text('Order'),
                          // const SizedBox(height: 6),
                          // InkWell(
                          //   onTap: () async {
                          //     // allow changing order — show orders for this customer
                          //     if (selectedCustomer == null ||
                          //         (selectedCustomer!['_id'] ??
                          //                 selectedCustomer!['id']) ==
                          //             null) {
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         const SnackBar(
                          //           content: Text('Select customer first'),
                          //         ),
                          //       );
                          //       return;
                          //     }

                          //     // fetch orders for user
                          //     final resp = await AppDataRepo()
                          //         .fetchOrdersByUser(
                          //           (selectedCustomer!['_id'] ??
                          //                   selectedCustomer!['id'])
                          //               .toString(),
                          //         );
                          //     if (resp['success'] == true &&
                          //         resp['orders'] is List) {
                          //       userOrders = List<Map<String, dynamic>>.from(
                          //         resp['orders'] as List,
                          //       );
                          //     } else {
                          //       userOrders = [];
                          //     }

                          //     final picked =
                          //         await showModalBottomSheet<
                          //           Map<String, dynamic>
                          //         >(
                          //           context: sheetCtx,
                          //           isScrollControlled: true,
                          //           backgroundColor: Colors.white,
                          //           constraints: BoxConstraints(
                          //             maxHeight:
                          //                 MediaQuery.of(sheetCtx).size.height *
                          //                 0.95,
                          //           ),
                          //           shape: const RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.vertical(
                          //               top: Radius.circular(16),
                          //             ),
                          //           ),
                          //           builder: (pickerCtx) {
                          //             String q = '';
                          //             final orders = userOrders;
                          //             return StatefulBuilder(
                          //               builder: (pc, pcSet) {
                          //                 final delivered = orders.where((o) {
                          //                   final label =
                          //                       '${o['orderNumber'] ?? ''} ${o['total'] ?? o['subtotal'] ?? ''}'
                          //                           .toLowerCase();
                          //                   return label.contains(
                          //                     q.toLowerCase(),
                          //                   );
                          //                 }).toList();

                          //                 return SafeArea(
                          //                   child: Padding(
                          //                     padding: const EdgeInsets.all(
                          //                       12.0,
                          //                     ),
                          //                     child: Column(
                          //                       children: [
                          //                         Row(
                          //                           children: [
                          //                             const Expanded(
                          //                               child: Text(
                          //                                 'Select Order',
                          //                                 style: TextStyle(
                          //                                   fontWeight:
                          //                                       FontWeight.bold,
                          //                                   fontSize: 16,
                          //                                 ),
                          //                               ),
                          //                             ),
                          //                             IconButton(
                          //                               icon: const Icon(
                          //                                 Icons.close,
                          //                               ),
                          //                               onPressed: () =>
                          //                                   Navigator.pop(
                          //                                     pickerCtx,
                          //                                   ),
                          //                             ),
                          //                           ],
                          //                         ),
                          //                         const SizedBox(height: 8),
                          //                         TextField(
                          //                           decoration:
                          //                               const InputDecoration(
                          //                                 prefixIcon: Icon(
                          //                                   Icons.search,
                          //                                 ),
                          //                                 hintText:
                          //                                     'Search order...',
                          //                                 isDense: true,
                          //                                 border:
                          //                                     OutlineInputBorder(),
                          //                               ),
                          //                           onChanged: (v) =>
                          //                               pcSet(() => q = v),
                          //                         ),
                          //                         const SizedBox(height: 8),
                          //                         Expanded(
                          //                           child: ListView.separated(
                          //                             itemCount:
                          //                                 delivered.length,
                          //                             separatorBuilder:
                          //                                 (_, __) =>
                          //                                     const Divider(
                          //                                       height: 1,
                          //                                     ),
                          //                             itemBuilder: (context, i) {
                          //                               final o = delivered[i];
                          //                               final label =
                          //                                   '${o['orderNumber'] ?? ''} • ₹${o['total'] ?? o['subtotal'] ?? ''} (${o['status'] ?? ''})';
                          //                               return ListTile(
                          //                                 title: Text(label),
                          //                                 onTap: () =>
                          //                                     Navigator.pop(
                          //                                       pickerCtx,
                          //                                       o,
                          //                                     ),
                          //                               );
                          //                             },
                          //                           ),
                          //                         ),
                          //                       ],
                          //                     ),
                          //                   ),
                          //                 );
                          //               },
                          //             );
                          //           },
                          //         );

                          //     if (picked != null) {
                          //       selectedOrder = Map<String, dynamic>.from(
                          //         picked,
                          //       );
                          //       // reinitialize item state to selected order
                          //       initialOrderItems.clear();
                          //       initialOrderItems.addAll(
                          //         List<Map<String, dynamic>>.from(
                          //           selectedOrder!['items'] ?? [],
                          //         ),
                          //       );
                          //       await _loadExistingChallans();
                          //     }
                          //     setStateModal(() {});
                          //   },
                          //   child: InputDecorator(
                          //     decoration: const InputDecoration(
                          //       labelText: 'Order',
                          //       border: OutlineInputBorder(),
                          //       isDense: true,
                          //     ),
                          //     child: Text(
                          //       selectedOrder != null
                          //           ? '${selectedOrder!['orderNumber'] ?? ''} • ₹${selectedOrder!['total'] ?? selectedOrder!['subtotal'] ?? ''}'
                          //           : 'Select Order',
                          //       style: const TextStyle(fontSize: 13),
                          //     ),
                          //   ),
                          // ),
                          const Text('Order'),
                          const SizedBox(height: 6),
                          // show order pre-selected (not editable here)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Order',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            child: Text(
                              selectedOrder != null
                                  ? '${selectedOrder!['orderNumber'] ?? ''} • ₹${selectedOrder!['total'] ?? selectedOrder!['subtotal'] ?? ''}'
                                  : '${order['orderNumber'] ?? order['_id'] ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (selectedOrder != null) ...[
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Dispatch Quantities per Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Fill max quantities',
                                  icon: const Icon(
                                    Icons.playlist_add_check,
                                    size: 20,
                                    color: Colors.indigo,
                                  ),
                                  onPressed: () {
                                    // Fill every item's qty to remaining (ordered - alreadyDispatched)
                                    for (
                                      var i = 0;
                                      i < orderItems.length;
                                      i++
                                    ) {
                                      final orderedSets =
                                          int.tryParse(
                                            orderItems[i]['quantity']
                                                    ?.toString() ??
                                                '0',
                                          ) ??
                                          0;
                                      final already = _alreadyDispatchedForItem(
                                        orderItems[i],
                                      );
                                      final remaining =
                                          (orderedSets - already) > 0
                                          ? (orderedSets - already)
                                          : 0;

                                      newDispatchMap[i] = remaining;

                                      // ensure controller exists and update text/cursor
                                      final ctrl = dispatchControllers
                                          .putIfAbsent(
                                            i,
                                            () => TextEditingController(
                                              text: remaining.toString(),
                                            ),
                                          );
                                      if (ctrl.text != remaining.toString()) {
                                        ctrl.value = TextEditingValue(
                                          text: remaining.toString(),
                                          selection: TextSelection.collapsed(
                                            offset: remaining.toString().length,
                                          ),
                                        );
                                      }
                                    }
                                    setStateModal(() {});
                                  },
                                ),
                              ],
                            ),
                            // const Text(
                            //   'Dispatch Quantities per Item',
                            //   style: TextStyle(fontWeight: FontWeight.bold),
                            // ),
                            const SizedBox(height: 8),
                            for (int i = 0; i < orderItems.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: Colors.grey.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orderItems[i]['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if ((orderItems[i]['availableSizes'] ??
                                                [])
                                            .isNotEmpty)
                                          Text(
                                            'Sizes: ${(orderItems[i]['availableSizes'] as List).join(", ")}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text(
                                              'Ordered Qty',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${orderItems[i]['quantity'] ?? ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Already Dispatched',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${_alreadyDispatchedForItem(orderItems[i])}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                final orderedSets =
                                                    int.tryParse(
                                                      orderItems[i]['quantity']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;
                                                final already =
                                                    _alreadyDispatchedForItem(
                                                      orderItems[i],
                                                    );
                                                final remaining =
                                                    (orderedSets - already) > 0
                                                    ? (orderedSets - already)
                                                    : 0;
                                                int cur =
                                                    (newDispatchMap[i] ?? 0) -
                                                    1;
                                                if (cur < 0) cur = 0;
                                                newDispatchMap[i] = cur;
                                                dispatchControllers
                                                    .putIfAbsent(
                                                      i,
                                                      () =>
                                                          TextEditingController(),
                                                    )
                                                    .text = newDispatchMap[i]
                                                    .toString();
                                                setStateModal(() {});
                                              },
                                            ),
                                            Expanded(
                                              child: Builder(
                                                builder: (_) {
                                                  final orderedSets =
                                                      int.tryParse(
                                                        orderItems[i]['quantity']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0;
                                                  final already =
                                                      _alreadyDispatchedForItem(
                                                        orderItems[i],
                                                      );
                                                  final remaining =
                                                      (orderedSets - already) >
                                                          0
                                                      ? (orderedSets - already)
                                                      : 0;
                                                  final controller =
                                                      dispatchControllers.putIfAbsent(
                                                        i,
                                                        () => TextEditingController(
                                                          text:
                                                              (newDispatchMap[i] ??
                                                                      0)
                                                                  .toString(),
                                                        ),
                                                      );
                                                  return TextFormField(
                                                    controller: controller,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration:
                                                        const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                vertical: 6,
                                                              ),
                                                        ),
                                                    onChanged: (v) {
                                                      int val =
                                                          int.tryParse(v) ?? 0;
                                                      if (val < 0) val = 0;
                                                      if (val > remaining)
                                                        val = remaining;
                                                      newDispatchMap[i] = val;
                                                      if (controller.text !=
                                                          val.toString())
                                                        controller.text = val
                                                            .toString();
                                                      controller.selection =
                                                          TextSelection.collapsed(
                                                            offset: controller
                                                                .text
                                                                .length,
                                                          );
                                                      setStateModal(() {});
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                final orderedSets =
                                                    int.tryParse(
                                                      orderItems[i]['quantity']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;
                                                final already =
                                                    _alreadyDispatchedForItem(
                                                      orderItems[i],
                                                    );
                                                final remaining =
                                                    (orderedSets - already) > 0
                                                    ? (orderedSets - already)
                                                    : 0;
                                                int cur =
                                                    (newDispatchMap[i] ?? 0) +
                                                    1;
                                                if (cur > remaining)
                                                  cur = remaining;
                                                newDispatchMap[i] = cur;
                                                dispatchControllers
                                                    .putIfAbsent(
                                                      i,
                                                      () =>
                                                          TextEditingController(),
                                                    )
                                                    .text = newDispatchMap[i]
                                                    .toString();
                                                setStateModal(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Value: ₹${(() {
                                            final item = orderItems[i];
                                            final prod = item['productId'] as Map<String, dynamic>?;
                                            final filnal = item['filnalLotPrice'] ?? prod?['filnalLotPrice'];
                                            final hasFilnal = filnal != null && filnal.toString().trim().isNotEmpty;
                                            final int sets = newDispatchMap[i] ?? 0;
                                            if (hasFilnal) {
                                              final double pricePerSet = double.tryParse(filnal.toString()) ?? 0.0;
                                              return (pricePerSet * sets).round();
                                            } else {
                                              final double pricePerPiece = double.tryParse((item['singlePicPrice'] ?? item['price'] ?? 0).toString()) ?? 0.0;
                                              final int pcs = int.tryParse(item['pcsInSet']?.toString() ?? '1') ?? 1;
                                              return (pricePerPiece * pcs * sets).round();
                                            }
                                          }())}',
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Card(
                              color: Colors.indigo.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Total Dispatch Value:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${_computeTotalValue()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedVendor,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery Vendor',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: vendors
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setStateModal(
                                    () => selectedVendor = v ?? selectedVendor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Notes / Tracking ID',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(
                                    text: notes,
                                  ),
                                  onChanged: (v) => notes = v,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(sheetCtx).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                // onPressed: () async {
                                //   if (selectedCustomer == null ||
                                //       selectedOrder == null) {
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(
                                //         content: Text(
                                //           'Select customer and order',
                                //         ),
                                //       ),
                                //     );
                                //     return;
                                //   }

                                //   final itemsPayload = <Map<String, dynamic>>[];
                                //   for (int i = 0; i < orderItems.length; i++) {
                                //     final item = orderItems[i];
                                //     final int newDispatchSets =
                                //         newDispatchMap[i] ?? 0;
                                //     if (newDispatchSets <= 0) continue;
                                //     final already = _alreadyDispatchedForItem(
                                //       item,
                                //     );
                                //     final prod =
                                //         item['productId']
                                //             as Map<String, dynamic>?;
                                //     final filnalRaw =
                                //         item['filnalLotPrice'] ??
                                //         prod?['filnalLotPrice'];
                                //     final bool hasFilnal =
                                //         filnalRaw != null &&
                                //         filnalRaw.toString().trim().isNotEmpty;
                                //     double priceValue = 0.0;
                                //     String priceUnit = 'piece';
                                //     if (hasFilnal) {
                                //       priceValue =
                                //           double.tryParse(
                                //             filnalRaw.toString(),
                                //           ) ??
                                //           0.0;
                                //       priceUnit = 'set';
                                //     } else {
                                //       priceValue =
                                //           double.tryParse(
                                //             (item['singlePicPrice'] ??
                                //                     item['price'] ??
                                //                     0)
                                //                 .toString(),
                                //           ) ??
                                //           0.0;
                                //       priceUnit = 'piece';
                                //     }
                                //     final pcsInSet =
                                //         int.tryParse(
                                //           item['pcsInSet']?.toString() ?? '1',
                                //         ) ??
                                //         1;
                                //     itemsPayload.add({
                                //       'name': item['name'] ?? '',
                                //       'availableSizes':
                                //           item['availableSizes'] ?? [],
                                //       'dispatchedQty': newDispatchSets,
                                //       'price': priceValue,
                                //       'priceUnit': priceUnit,
                                //       'pcsInSet': pcsInSet,
                                //       'selectedSizes':
                                //           item['selectedSizes'] ?? [],
                                //       'alreadyDispatched': already,
                                //     });
                                //   }

                                //   if (itemsPayload.isEmpty) {
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(
                                //         content: Text(
                                //           'Enter dispatch qty for at least one item',
                                //         ),
                                //       ),
                                //     );
                                //     return;
                                //   }

                                //   final totalValue = itemsPayload.fold<int>(0, (
                                //     sum,
                                //     it,
                                //   ) {
                                //     final p =
                                //         double.tryParse(
                                //           (it['price'] ?? 0).toString(),
                                //         ) ??
                                //         0.0;
                                //     final pcs =
                                //         int.tryParse(
                                //           (it['pcsInSet'] ?? 1).toString(),
                                //         ) ??
                                //         1;
                                //     final sets =
                                //         int.tryParse(
                                //           (it['dispatchedQty'] ?? 0).toString(),
                                //         ) ??
                                //         0;
                                //     final unit = (it['priceUnit'] ?? 'piece')
                                //         .toString();
                                //     if (unit == 'set')
                                //       return sum + (p * sets).round();
                                //     return sum + (p * pcs * sets).round();
                                //   });

                                //   final body = {
                                //     "customerId":
                                //         (selectedCustomer!['_id'] ??
                                //                 selectedCustomer!['id'])
                                //             ?.toString(),
                                //     "customer": selectedCustomer!['name'] ?? '',
                                //     "orderId":
                                //         (selectedOrder!['_id'] ??
                                //                 selectedOrder!['id'])
                                //             ?.toString(),
                                //     "orderNumber":
                                //         selectedOrder!['orderNumber'] ?? '',
                                //     "items": itemsPayload,
                                //     "totalValue": totalValue,
                                //     "date": DateTime.now()
                                //         .toIso8601String()
                                //         .substring(0, 10),
                                //     "status": "Dispatched",
                                //     "vendor": selectedVendor,
                                //     "notes": notes,
                                //   };

                                //   try {
                                //     final resp = await AppDataRepo()
                                //         .createChallan(body);
                                //     if (resp['success'] == true ||
                                //         resp['status'] == true ||
                                //         resp['challan'] != null) {
                                //       Navigator.of(sheetCtx).pop();
                                //       ScaffoldMessenger.of(
                                //         context,
                                //       ).showSnackBar(
                                //         const SnackBar(
                                //           content: Text('Challan created'),
                                //         ),
                                //       );
                                //       // Optionally navigate to challan screen or refresh parent - caller can implement refresh
                                //     } else {
                                //       final msg =
                                //           resp['message']?.toString() ??
                                //           'Failed to create challan';
                                //       ScaffoldMessenger.of(
                                //         context,
                                //       ).showSnackBar(
                                //         SnackBar(content: Text(msg)),
                                //       );
                                //     }
                                //   } catch (e) {
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       SnackBar(content: Text('Error: $e')),
                                //     );
                                //   }
                                // },
                                onPressed: () async {
                                  debugPrint('Create Challan tapped');

                                  // Derive customerId from selectedCustomer OR from order payload
                                  String? effectiveCustomerId;
                                  if (selectedCustomer != null) {
                                    effectiveCustomerId =
                                        (selectedCustomer!['_id'] ??
                                                selectedCustomer!['id'])
                                            ?.toString();
                                  }
                                  // order might store customer.userId._id (see console output), or customerId field
                                  effectiveCustomerId ??=
                                      (order['customer'] is Map)
                                      ? (order['customer']['userId']?['_id']
                                                ?.toString() ??
                                            order['customer']['_id']
                                                ?.toString())
                                      : null;
                                  effectiveCustomerId ??= order['customerId']
                                      ?.toString();

                                  // Derive orderId
                                  final String? effectiveOrderId =
                                      (selectedOrder?['_id'] ??
                                              selectedOrder?['id'] ??
                                              order['_id'] ??
                                              order['id'])
                                          ?.toString();

                                  debugPrint(
                                    'effectiveCustomerId: $effectiveCustomerId',
                                  );
                                  debugPrint(
                                    'effectiveOrderId: $effectiveOrderId',
                                  );

                                  if (effectiveCustomerId == null ||
                                      effectiveOrderId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Missing customerId or orderId',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final itemsPayload = <Map<String, dynamic>>[];
                                  for (int i = 0; i < orderItems.length; i++) {
                                    final item = orderItems[i];
                                    final int newDispatchSets =
                                        newDispatchMap[i] ?? 0;
                                    if (newDispatchSets <= 0) continue;
                                    final already = _alreadyDispatchedForItem(
                                      item,
                                    );
                                    final prod =
                                        item['productId']
                                            as Map<String, dynamic>?;
                                    final filnalRaw =
                                        item['filnalLotPrice'] ??
                                        prod?['filnalLotPrice'];
                                    final bool hasFilnal =
                                        filnalRaw != null &&
                                        filnalRaw.toString().trim().isNotEmpty;
                                    double priceValue = 0.0;
                                    String priceUnit = 'piece';
                                    if (hasFilnal) {
                                      priceValue =
                                          double.tryParse(
                                            filnalRaw.toString(),
                                          ) ??
                                          0.0;
                                      priceUnit = 'set';
                                    } else {
                                      priceValue =
                                          double.tryParse(
                                            (item['singlePicPrice'] ??
                                                    item['price'] ??
                                                    0)
                                                .toString(),
                                          ) ??
                                          0.0;
                                      priceUnit = 'piece';
                                    }
                                    final pcsInSet =
                                        int.tryParse(
                                          item['pcsInSet']?.toString() ?? '1',
                                        ) ??
                                        1;
                                    itemsPayload.add({
                                      'name': item['name'] ?? '',
                                      'availableSizes':
                                          item['availableSizes'] ?? [],
                                      'dispatchedQty': newDispatchSets,
                                      'price': priceValue,
                                      'priceUnit': priceUnit,
                                      'pcsInSet': pcsInSet,
                                      'selectedSizes':
                                          item['selectedSizes'] ?? [],
                                      'alreadyDispatched': already,
                                    });
                                  }

                                  if (itemsPayload.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter dispatch qty for at least one item',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final totalValue = itemsPayload.fold<int>(0, (
                                    sum,
                                    it,
                                  ) {
                                    final p =
                                        double.tryParse(
                                          (it['price'] ?? 0).toString(),
                                        ) ??
                                        0.0;
                                    final pcs =
                                        int.tryParse(
                                          (it['pcsInSet'] ?? 1).toString(),
                                        ) ??
                                        1;
                                    final sets =
                                        int.tryParse(
                                          (it['dispatchedQty'] ?? 0).toString(),
                                        ) ??
                                        0;
                                    final unit = (it['priceUnit'] ?? 'piece')
                                        .toString();
                                    if (unit == 'set')
                                      return sum + (p * sets).round();
                                    return sum + (p * pcs * sets).round();
                                  });

                                  final body = {
                                    "customerId": effectiveCustomerId,
                                    "customer":
                                        selectedCustomer?['name'] ??
                                        ((order['customer'] is Map)
                                            ? (order['customer']['name']
                                                      ?.toString() ??
                                                  '')
                                            : (order['customer']?.toString() ??
                                                  '')),
                                    "orderId": effectiveOrderId,
                                    "orderNumber":
                                        selectedOrder?['orderNumber'] ??
                                        order['orderNumber'] ??
                                        '',
                                    "items": itemsPayload,
                                    "totalValue": totalValue,
                                    "date": DateTime.now()
                                        .toIso8601String()
                                        .substring(0, 10),
                                    "status": "Dispatched",
                                    "vendor": selectedVendor,
                                    "notes": notes,
                                  };

                                  // Print URL/body/response to console
                                  const String reqUrl =
                                      'https://api.sddipl.com/api/challan/create-challan';
                                  debugPrint('POST $reqUrl');
                                  try {
                                    debugPrint(
                                      'Request body: ${jsonEncode(body)}',
                                    );
                                  } catch (_) {
                                    debugPrint('Request body (raw): $body');
                                  }

                                  try {
                                    final resp = await AppDataRepo()
                                        .createChallan(body);
                                    try {
                                      debugPrint(
                                        'Response body: ${jsonEncode(resp)}',
                                      );
                                    } catch (_) {
                                      debugPrint('Response (raw): $resp');
                                    }

                                    if (resp['success'] == true ||
                                        resp['status'] == true ||
                                        resp['challan'] != null) {
                                      Navigator.of(sheetCtx).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Challan created'),
                                        ),
                                      );
                                    } else {
                                      final msg =
                                          resp['message']?.toString() ??
                                          'Failed to create challan';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(msg)),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Create challan error: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'Create Challan',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrders =
        ModalRoute.of(context)?.settings.arguments
            as List<Map<String, dynamic>>?;
    final order = allOrders?.firstWhere(
      // (o) => o['_id'] == orderId || o['id'] == orderId,
      (o) => o['_id'] == widget.orderId || o['id'] == widget.orderId,

      orElse: () => {},
    );

    if (order == null || order.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(child: Text('Order not found')),
      );
    } else {
      try {
        debugPrint(
          'OrderDetailsPage: displaying order for id=${widget.orderId} -> ${jsonEncode(order)}',
        );
      } catch (_) {
        debugPrint(
          'OrderDetailsPage: displaying order for id=${widget.orderId} -> $order',
        );
      }
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

    if (!permissionsReady()) {
      // show the same visible skeleton used while _loading to avoid a black/empty screen
      return UniversalScaffold(
        selectedIndex: 1,
        title: 'Orders',
        appIcon: Icons.list_alt,
        body: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, idx) {
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    4,
                    (i) => Container(
                      height: 14,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // If no read permission, show access denied inside scaffold
    if (!canRead) {
      return UniversalScaffold(
        selectedIndex: 1,
        title: 'Orders',
        appIcon: Icons.list_alt,
        body: Center(child: Text('You do not have permission to view Orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${order['orderNumber'] ?? ''}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        // ADD: Edit and PDF actions
        actions: [
          if (canUpdate)
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
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
                                        final updated =
                                            Map<String, dynamic>.from(order);
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
                                            content: Text(
                                              'Order saved (local).',
                                            ),
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
                  if (canUpdate)
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
                                            order['transportName']
                                                ?.toString() ??
                                            '',
                                      );
                                  final TextEditingController
                                  noteCtl = TextEditingController(
                                    text: order['orderNote']?.toString() ?? '',
                                  );
                                  final TextEditingController
                                  paidCtl = TextEditingController(
                                    text: order['paidAmount']?.toString() ?? '',
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                                () =>
                                                    statusVal = v ?? statusVal,
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
                                              keyboardType:
                                                  TextInputType.number,
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
                                            const SizedBox(height: 40),
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
                                  orderId:
                                      updated['_id']?.toString() ??
                                      widget.orderId,
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

                  // else
                  //   Expanded(
                  //     child: ElevatedButton.icon(
                  //       icon: const Icon(Icons.save, size: 18),
                  //       label: const Text('Update'),
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.grey.shade400,
                  //         foregroundColor: Colors.white,
                  //       ),
                  //       onPressed: null,
                  //     ),
                  //   ),
                  const SizedBox(width: 12),
                  if (canWrite)
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
                        onPressed: () =>
                            _openCreateChallanFromOrder(context, order),
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
