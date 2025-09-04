        import 'package:flutter/material.dart';
        import 'package:flutter_riverpod/flutter_riverpod.dart';
        import 'theme/app_theme.dart';
        import 'screens/login_screen.dart';
        import 'screens/dashboard_screen.dart';
        import 'screens/catalogue_screen.dart';
        import 'screens/orders_screen.dart';
        import 'screens/inventory_screen.dart';
        import 'screens/job_slip_screen.dart';
        import 'screens/dispatch_screen.dart';
        import 'screens/invoice_screen.dart';
        import 'screens/reports_screen.dart';
        import 'screens/dispatch_detail_screen.dart';
        import 'screens/order_detail_screen.dart';
        import 'screens/job_slip_detail_screen.dart';
        import 'screens/catalogue_detail_screen.dart';
        import 'screens/inventory_detail_screen.dart';
        import 'screens/invoice_detail_screen.dart';
        import 'screens/report_detail_screen.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vastra ERP',
      theme: appTheme,
      home: LoginScreen(),
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/catalogue': (context) => CatalogueScreen(),
        '/orders': (context) => OrdersScreen(),
        '/inventory': (context) => InventoryScreen(),
        '/jobslips': (context) => JobSlipScreen(),
        '/dispatch': (context) => DispatchScreen(),
        '/invoices': (context) => InvoiceScreen(),
        '/reports': (context) => ReportsScreen(),
        '/dispatch_detail': (context) {
          final dispatchId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return DispatchDetailScreen(dispatchId: dispatchId);
        },
        '/order_detail': (context) {
          final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return OrderDetailScreen(orderId: orderId);
        },
        '/job_slip_detail': (context) {
          final jobSlipId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return JobSlipDetailScreen(jobSlipId: jobSlipId);
        },
        '/catalogue_detail': (context) {
          final designId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return CatalogueDetailScreen(designId: designId);
        },
        '/inventory_detail': (context) {
          final locationId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return InventoryDetailScreen(locationId: locationId);
        },
        '/invoice_detail': (context) {
          final invoiceId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return InvoiceDetailScreen(invoiceId: invoiceId);
        },
        '/report_detail': (context) {
          final reportType = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return ReportDetailScreen(reportType: reportType);
        },
      },
    );
  }
}