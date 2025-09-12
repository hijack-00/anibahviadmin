import 'package:anibhaviadmin/screens/users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:anibhaviadmin/screens/all_orders_page.dart';
// import 'screens/catalogue_screen.dart';
// import 'screens/inventory_screen.dart';
// import 'screens/job_slip_screen.dart';
// import 'screens/dispatch_screen.dart';
// import 'screens/invoice_screen.dart';
import 'screens/sales_reports_page.dart';
import 'screens/catalogue_page.dart';
// import 'screens/dispatch_detail_screen.dart';
import 'screens/order_detail_screen.dart';
// import 'screens/job_slip_detail_screen.dart';
// import 'screens/catalogue_detail_screen.dart';
// import 'screens/inventory_detail_screen.dart';
// import 'screens/invoice_detail_screen.dart';
import 'screens/report_detail_screen.dart';
import 'screens/challan_screen.dart';
import 'screens/product_detail_page.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final navigator = Navigator.of(context);
        // If not on dashboard, go to dashboard
        if (ModalRoute.of(context)?.settings.name != '/dashboard') {
          navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
          return false;
        }
        // If on dashboard, show exit dialog
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text('Exit App'),
              content: Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return result == true;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Anibhavi ERP',
        theme: appTheme,
        home: LoginScreen(),
        navigatorObservers: [routeObserver],
        routes: {
          '/dashboard': (context) => DashboardScreen(),
          '/catalogue': (context) => CataloguePage(),
          '/orders': (context) => AllOrdersPage(),
          '/challan': (context) => ChallanScreen(),
          '/reports': (context) => SalesReportsPage(),
          '/users': (context) =>  UsersPage(showActive: true),
          '/order_detail': (context) {
            final orderId =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return OrderDetailScreen(orderId: orderId);
          },
          '/report_detail': (context) {
            final reportType =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return ReportDetailScreen(reportType: reportType);
          },
          '/product-detail': (context) {
            final productId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return ProductDetailPage(productId: productId);
          },
        },
      ),
    );
  }
}
