// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dashboard_screen.dart';
// import '../services/app_data_repo.dart';

// // Reusable sales bar chart widget
// class SalesBarChart extends StatelessWidget {
//   final List<dynamic> jeansDaily;
//   final List<dynamic> shirtsDaily;
//   final String section;
//   const SalesBarChart({required this.jeansDaily, required this.shirtsDaily, required this.section});

//   @override
//   Widget build(BuildContext context) {
//     int barCount = section == 'overview'
//         ? jeansDaily.length + shirtsDaily.length
//         : section == 'jeans'
//             ? jeansDaily.length
//             : shirtsDaily.length;
//     return SizedBox(
//       height: 180,
//       child: BarChart(
//         BarChartData(
//           alignment: BarChartAlignment.spaceAround,
//           barGroups: List.generate(barCount, (idx) {
//             if (section == 'overview') {
//               var allDaily = [
//                 ...jeansDaily,
//                 ...shirtsDaily,
//               ];
//               final d = allDaily[idx];
//               final sales = (d['sales'] ?? 0);
//               return BarChartGroupData(
//                 x: idx,
//                 barRods: [
//                   BarChartRodData(
//                     toY: (sales is num ? sales.toDouble() : 0),
//                     color: Colors.deepPurple,
//                     width: 18,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ],
//               );
//             } else {
//               final d = section == 'jeans'
//                   ? jeansDaily[idx]
//                   : shirtsDaily[idx];
//               final sales = (d['sales'] ?? 0);
//               return BarChartGroupData(
//                 x: idx,
//                 barRods: [
//                   BarChartRodData(
//                     toY: (sales is num ? sales.toDouble() : 0),
//                     color: section == 'jeans' ? Colors.indigo : Colors.green,
//                     width: 18,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ],
//               );
//             }
//           }),
//           gridData: FlGridData(show: true, drawVerticalLine: true),
//           borderData: FlBorderData(show: false),
//         ),
//       ),
//     );
//   }
// }

// class SalesReportsPage extends StatefulWidget {
//   @override
//   State<SalesReportsPage> createState() => _SalesReportsPageState();
// }

// class _SalesReportsPageState extends State<SalesReportsPage> {
//   String _selectedFilter = 'This Month';
//   DateTimeRange? _customDateRange;
//   String _selectedSection = 'Overview';
//   String _selectedReport = 'Section Wise';

//   final List<String> filters = [
//     'Today',
//     'This Week',
//     'This Month',
//     'This Year',
//     'Custom Range',
//   ];
//   final List<String> sections = ['Overview', 'Jeans', 'Shirts'];
//   final List<String> reports = ['Section Wise', 'Daily Sales', 'Top Products'];

//   // API Data
//   Map<String, dynamic>? jeansShirtData;
//   Map<String, dynamic>? salesData;
//   List<dynamic>? topProducts;
//   bool loading = true;
//   String? error;

//   // Dummy fallback data
//   final Map<String, dynamic> dummyData = {
//     'Overview': {
//       'jeans': {'total': 23040, 'orders': 2, 'pieces': 16, 'growth': "100.00"},
//       'shirts': {'total': 60000, 'orders': 2, 'pieces': 2, 'growth': "100.00"},
//     },
//     'SalesData': {
//       'jeans': {
//         'total': 23040,
//         'orders': 2,
//         'pieces': 16,
//         'growth': "100.00",
//         'dailyData': [
//           {"date": "2025-09-24", "sales": 1440, "orders": 0, "pieces": 1},
//           {"date": "2025-09-25", "sales": 21600, "orders": 0, "pieces": 15},
//         ],
//       },
//       'shirts': {
//         'total': 60000,
//         'orders': 2,
//         'pieces': 2,
//         'growth': "100.00",
//         'dailyData': [
//           {"date": "2025-09-25", "sales": 30000, "orders": 0, "pieces": 1},
//           {"date": "2025-09-26", "sales": 30000, "orders": 0, "pieces": 1},
//         ],
//       },
//     },
//     'TopProducts': [
//       {
//         "name": "Black Shirt",
//         "sales": 60000,
//         "pieces": 6,
//         "units": 2,
//         "growth": 100,
//       },
//       {
//         "name": "Jeans",
//         "sales": 23040,
//         "pieces": 192,
//         "units": 16,
//         "growth": 100,
//       },
//     ],
//   };

//   @override
//   void initState() {
//     super.initState();
//     fetchAllData();
//   }

//   Future<void> fetchAllData() async {
//     setState(() {
//       loading = true;
//       error = null;
//     });
//     try {
//       final jeansShirtResp = await AppDataRepo().getJeansShirtRevenueAndOrder();
//       print('API Request: getJeansShirtRevenueAndOrder');
//       print('API Response: jeansShirtResp = ' + jeansShirtResp.toString());
//       final salesResp = await AppDataRepo().getSalesData();
//       print('API Request: getSalesData');
//       print('API Response: salesResp = ' + salesResp.toString());
//       if (salesResp['data'] != null) {
//         print(
//           'AvgOrder (jeans): ' +
//               (salesResp['data']['jeans']?['avgOrder']?.toString() ?? 'null'),
//         );
//         print(
//           'AvgOrder (shirts): ' +
//               (salesResp['data']['shirts']?['avgOrder']?.toString() ?? 'null'),
//         );
//       }
//       final topProductsResp = await AppDataRepo().getTopProducts();
//       print('API Request: getTopProducts');
//       print('API Response: topProductsResp = ' + topProductsResp.toString());

//       jeansShirtData = jeansShirtResp['data'] ?? dummyData['Overview'];
//       salesData = salesResp['data'] ?? dummyData['SalesData'];
//       topProducts = topProductsResp['data'] ?? dummyData['TopProducts'];
//     } catch (e) {
//       error = e.toString();
//       jeansShirtData = dummyData['Overview'];
//       salesData = dummyData['SalesData'];
//       topProducts = dummyData['TopProducts'];
//     }
//     setState(() {
//       loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget sectionWidget;
//     if (loading) {
//       sectionWidget = Center(child: CircularProgressIndicator());
//     } else if (error != null) {
//       sectionWidget = Center(child: Text('Error: $error'));
//     } else {
//       final section = _selectedSection.toLowerCase();
//       final jeans = jeansShirtData?['jeans'] ?? dummyData['Overview']['jeans'];
//       final shirts =
//           jeansShirtData?['shirts'] ?? dummyData['Overview']['shirts'];
//       final jeansDaily = salesData?['jeans']?['dailyData'] ?? [];
//       final shirtsDaily = salesData?['shirts']?['dailyData'] ?? [];
//       final products = topProducts ?? dummyData['TopProducts'];

//       // Filter daily data by selected filter
//       List<dynamic> filteredJeansDaily = jeansDaily;
//       List<dynamic> filteredShirtsDaily = shirtsDaily;
//       DateTime now = DateTime.now();
//       if (_selectedFilter == 'Today') {
//         String today =
//             "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
//         filteredJeansDaily = jeansDaily
//             .where((d) => d['date'] == today)
//             .toList();
//         filteredShirtsDaily = shirtsDaily
//             .where((d) => d['date'] == today)
//             .toList();
//       } else if (_selectedFilter == 'This Week') {
//         DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
//         filteredJeansDaily = jeansDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return !date.isBefore(weekStart) && !date.isAfter(now);
//         }).toList();
//         filteredShirtsDaily = shirtsDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return !date.isBefore(weekStart) && !date.isAfter(now);
//         }).toList();
//       } else if (_selectedFilter == 'This Month') {
//         DateTime monthStart = DateTime(now.year, now.month, 1);
//         filteredJeansDaily = jeansDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return !date.isBefore(monthStart) && !date.isAfter(now);
//         }).toList();
//         filteredShirtsDaily = shirtsDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return !date.isBefore(monthStart) && !date.isAfter(now);
//         }).toList();
//       } else if (_selectedFilter == 'This Year') {
//         DateTime yearStart = DateTime(now.year, 1, 1);
//         filteredJeansDaily = jeansDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return !date.isBefore(yearStart) && !date.isAfter(now);
//         }).toList();
//         filteredShirtsDaily = shirtsDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return !date.isBefore(yearStart) && !date.isAfter(now);
//         }).toList();
//       } else if (_selectedFilter == 'Custom Range' &&
//           _customDateRange != null) {
//         filteredJeansDaily = jeansDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return date.isAfter(
//                 _customDateRange!.start.subtract(Duration(days: 1)),
//               ) &&
//               date.isBefore(_customDateRange!.end.add(Duration(days: 1)));
//         }).toList();
//         filteredShirtsDaily = shirtsDaily.where((d) {
//           DateTime date = DateTime.parse(d['date']);
//           return date.isAfter(
//                 _customDateRange!.start.subtract(Duration(days: 1)),
//               ) &&
//               date.isBefore(_customDateRange!.end.add(Duration(days: 1)));
//         }).toList();
//       }

//       // Calculate filtered totals for cards/blocks
//     int jeansSales = 0,
//       shirtsSales = 0,
//       jeansOrders = 0,
//       shirtsOrders = 0,
//       jeansPieces = 0,
//       shirtsPieces = 0;
//       double jeansGrowth = 0, shirtsGrowth = 0;
//       // Use filtered data for calculations
//       for (var d in filteredJeansDaily) {
//         jeansSales += (d['sales'] ?? 0) as int;
//         jeansOrders += (d['orders'] ?? 0) as int;
//         jeansPieces += (d['pieces'] ?? 0) as int;
//       }
//       for (var d in filteredShirtsDaily) {
//         shirtsSales += (d['sales'] ?? 0) as int;
//         shirtsOrders += (d['orders'] ?? 0) as int;
//         shirtsPieces += (d['pieces'] ?? 0) as int;
//       }
//       // Fallback to overall if no filtered data
//       if (filteredJeansDaily.isEmpty) {
//         jeansSales = jeans['total'] ?? 0;
//         jeansOrders = jeans['orders'] ?? 0;
//         jeansPieces = jeans['pieces'] ?? 0;
//       }
//       if (filteredShirtsDaily.isEmpty) {
//         shirtsSales = shirts['total'] ?? 0;
//         shirtsOrders = shirts['orders'] ?? 0;
//         shirtsPieces = shirts['pieces'] ?? 0;
//       }
//       jeansGrowth = double.tryParse(jeans['growth']?.toString() ?? '0') ?? 0;
//       shirtsGrowth = double.tryParse(shirts['growth']?.toString() ?? '0') ?? 0;

//       if (section == 'overview') {
//         // Overview: Total Sales, Total Jeans Sale, Total Shirts Sale, Total Orders, Growth
//         int totalSales = jeansSales + shirtsSales;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _KpiCard(
//                     label: 'Total Sales',
//                     value: '₹$totalSales',
//                     icon: Icons.attach_money,
//                     color: Colors.deepPurple,
//                     width: 90,
//                     height: 90,
//                   ),
//                   SizedBox(width: 8),
//                   _KpiCard(
//                     label: 'Total Orders',
//                     value:
//                         '${(jeansShirtData?['jeans']?['orders'] ?? jeans['orders'] ?? 0) + (jeansShirtData?['shirts']?['orders'] ?? shirts['orders'] ?? 0)}',
//                     icon: Icons.receipt_long,
//                     color: Colors.deepPurple,
//                     width: 90,
//                     height: 90,
//                   ),
//                   SizedBox(width: 8),
//                   _KpiCard(
//                     label: 'Total Pieces',
//                     value: '${(jeans['pieces'] ?? 0) + (shirts['pieces'] ?? 0)}',
//                     icon: Icons.widgets,
//                     color: Colors.blueGrey,
//                     width: 90,
//                     height: 90,
//                   ),
//                   SizedBox(width: 8),
//                   _KpiCard(
//                     label: 'Growth',
//                     value:
//                         '${((jeansGrowth + shirtsGrowth) / 2).toStringAsFixed(2)}%',
//                     icon: Icons.trending_up,
//                     color: Colors.orange,
//                     width: 90,
//                     height: 90,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 24),
//             SalesBarChart(
//               jeansDaily: filteredJeansDaily,
//               shirtsDaily: filteredShirtsDaily,
//               section: section,
//             ),
//             SizedBox(height: 24),
//             Text(
//               'Top Performing Products',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//                 color: Colors.indigo,
//               ),
//             ),
//             SizedBox(height: 12),
//             ListView.separated(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: products.length,
//               separatorBuilder: (_, __) => SizedBox(height: 8),
//               itemBuilder: (context, idx) {
//                 final prod = products[idx];
//                 return Card(
//                   color: Colors.indigo.shade50,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 prod['name'],
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                   color: Colors.indigo,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Sales: ₹${prod['sales']}',
//                                 style: TextStyle(
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               Text(
//                                 'Units Sold: ${prod['pieces']}',
//                                 style: TextStyle(color: Colors.indigo),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               '${prod['growth']}%',
//                               style: TextStyle(
//                                 color: (prod['growth'] ?? 0) > 0
//                                     ? Colors.green
//                                     : Colors.red,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               'Growth',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         );
//       } else {
//         // Jeans/Shirts: Total Revenue, Total Orders (with units), Avg Order Value
//         final isJeans = section == 'jeans';
//         final sales = isJeans ? jeansSales : shirtsSales;
//         final orders = isJeans
//             ? (jeansShirtData?['jeans']?['orders'] ?? jeans['orders'] ?? 0)
//             : (jeansShirtData?['shirts']?['orders'] ?? shirts['orders'] ?? 0);
//         final pieces = isJeans ? jeansPieces : shirtsPieces;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _KpiCard(
//                     label: 'Total Revenue',
//                     value: '₹$sales',
//                     icon: Icons.attach_money,
//                     color: isJeans ? Colors.indigo : Colors.green,
//                     width: 90,
//                     height: 90,
//                   ),
//                   SizedBox(width: 8),
//                   _KpiCard(
//                     label: 'Total Orders',
//                     value: '$orders',
//                     icon: Icons.receipt_long,
//                     color: isJeans ? Colors.indigo : Colors.green,
//                     width: 90,
//                     height: 90,
//                   ),
//                   SizedBox(width: 8),
//                   _KpiCard(
//                     label: 'Units',
//                     value: '$pieces',
//                     icon: Icons.check_circle,
//                     color: isJeans ? Colors.indigo : Colors.green,
//                     width: 90,
//                     height: 90,
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 24),
//             SalesBarChart(
//               jeansDaily: filteredJeansDaily,
//               shirtsDaily: filteredShirtsDaily,
//               section: section,
//             ),
//             SizedBox(height: 24),
//             Text(
//               'Top Performing Products',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//                 color: Colors.indigo,
//               ),
//             ),
//             SizedBox(height: 12),
//             ListView.separated(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: products.length,
//               separatorBuilder: (_, __) => SizedBox(height: 8),
//               itemBuilder: (context, idx) {
//                 final prod = products[idx];
//                 return Card(
//                   color: Colors.indigo.shade50,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 prod['name'],
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                   color: Colors.indigo,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Sales: ₹${prod['sales']}',
//                                 style: TextStyle(
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               Text(
//                                 'Units Sold: ${prod['pieces']}',
//                                 style: TextStyle(color: Colors.indigo),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               '${prod['growth']}%',
//                               style: TextStyle(
//                                 color: (prod['growth'] ?? 0) > 0
//                                     ? Colors.green
//                                     : Colors.red,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               'Growth',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         );
//               _KpiCard(
//                 label: 'Total Orders',
//                 value: '$orders',
//                 icon: Icons.receipt_long,
//                 color: isJeans ? Colors.indigo : Colors.green,
//                 width: 90,
//                 height: 90,
//               ),
//               SizedBox(width: 8),
//               _KpiCard(
//                 label: 'Units',
//                 value: '$pieces',
//                 icon: Icons.check_circle,
//                 color: isJeans ? Colors.indigo : Colors.green,
//                 width: 90,
//                 height: 90,
//               ),
//         SalesBarChart(
//           jeansDaily: filteredJeansDaily,
//           shirtsDaily: filteredShirtsDaily,
//           section: section,
//         ),
//         SizedBox(height: 24),

//             // Top Products
//             Text(
//               'Top Performing Products',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//                 color: Colors.indigo,
//               ),
//             ),
//             SizedBox(height: 12),
//             ListView.separated(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: products.length,
//               separatorBuilder: (_, __) => SizedBox(height: 8),
//               itemBuilder: (context, idx) {
//                 final prod = products[idx];
//                 return Card(
//                   color: Colors.indigo.shade50,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 prod['name'],
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                   color: Colors.indigo,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Sales: ₹${prod['sales']}',
//                                 style: TextStyle(
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               Text(
//                                 'Units Sold: ${prod['pieces']}',
//                                 style: TextStyle(color: Colors.indigo),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               '${prod['growth']}%',
//                               style: TextStyle(
//                                 color: (prod['growth'] ?? 0) > 0
//                                     ? Colors.green
//                                     : Colors.red,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               'Growth',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//           ),

//         );

//     }
//     }

//     return UniversalScaffold(
//       selectedIndex: -1,
//       body: Container(
//         color: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
//                 child: Text(
//                   'Sales & Reports',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 26,
//                     color: Colors.indigo,
//                   ),
//                 ),
//               ),
//               // Filter + Section Dropdown (evenly spaced)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       value: _selectedFilter,
//                       decoration: InputDecoration(
//                         labelText: 'Filter',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                       ),
//                       items: filters
//                           .map(
//                             (f) => DropdownMenuItem(value: f, child: Text(f)),
//                           )
//                           .toList(),
//                       onChanged: (val) async {
//                         if (val == 'Custom Range') {
//                           final picked = await showDateRangePicker(
//                             context: context,
//                             firstDate: DateTime(2020),
//                             lastDate: DateTime.now(),
//                           );
//                           if (picked != null) {
//                             setState(() {
//                               _customDateRange = picked;
//                               _selectedFilter = val!;
//                             });
//                           }
//                         } else {
//                           setState(() {
//                             _selectedFilter = val!;
//                           });
//                         }
//                       },
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       value: _selectedSection,
//                       decoration: InputDecoration(
//                         labelText: 'Section',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                       ),
//                       items: sections
//                           .map(
//                             (s) => DropdownMenuItem(value: s, child: Text(s)),
//                           )
//                           .toList(),
//                       onChanged: (val) {
//                         setState(() {
//                           _selectedSection = val!;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),

//               // Report Chips
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: reports
//                       .map(
//                         (r) => Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                           child: ChoiceChip(
//                             label: Text(
//                               r,
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             selected: _selectedReport == r,
//                             selectedColor: Colors.indigo,
//                             backgroundColor: Colors.white,
//                             labelStyle: TextStyle(
//                               color: _selectedReport == r
//                                   ? Colors.white
//                                   : Colors.indigo,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(color: Colors.indigo.shade100),
//                             ),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _selectedReport = r;
//                               });
//                             },
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 ),
//               ),
//               SizedBox(height: 16),

//               Expanded(
//                 child: sectionWidget ?? SizedBox.shrink(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _KpiCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final IconData icon;
//   final Color color;
//   final double width;
//   final double height;
//   const _KpiCard({
//     required this.label,
//     required this.value,
//     required this.icon,
//     required this.color,
//     this.width = 110,
//     this.height = 110,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: width,
//       height: height,
//       child: Card(
//         color: color.withOpacity(0.15),
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: color, size: 18),
//               // SizedBox(height: 2),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 10,
//                   color: color,
//                 ),
//               ),
//               // SizedBox(height: 2),
//               Text(label, style: TextStyle(fontSize: 9, color: color)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_screen.dart';
import '../services/app_data_repo.dart';

// Reusable sales bar chart widget
class SalesBarChart extends StatelessWidget {
  final List<dynamic> jeansDaily;
  final List<dynamic> shirtsDaily;
  final String section;

  const SalesBarChart({
    required this.jeansDaily,
    required this.shirtsDaily,
    required this.section,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    int barCount = section == 'overview'
        ? jeansDaily.length + shirtsDaily.length
        : section == 'jeans'
        ? jeansDaily.length
        : shirtsDaily.length;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(barCount, (idx) {
            if (section == 'overview') {
              var allDaily = [...jeansDaily, ...shirtsDaily];
              final d = allDaily[idx];
              final sales = (d['sales'] ?? 0);
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: (sales is num ? sales.toDouble() : 0),
                    color: Colors.deepPurple,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            } else {
              final d = section == 'jeans' ? jeansDaily[idx] : shirtsDaily[idx];
              final sales = (d['sales'] ?? 0);
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: (sales is num ? sales.toDouble() : 0),
                    color: section == 'jeans' ? Colors.indigo : Colors.green,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }
          }),
          gridData: FlGridData(show: true, drawVerticalLine: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  String _selectedFilter = 'This Month';
  DateTimeRange? _customDateRange;
  String _selectedSection = 'Overview';
  String _selectedReport = 'Section Wise';

  final List<String> filters = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'Custom Range',
  ];
  final List<String> sections = ['Overview', 'Jeans', 'Shirts'];
  final List<String> reports = ['Section Wise', 'Daily Sales', 'Top Products'];

  Map<String, dynamic>? jeansShirtData;
  Map<String, dynamic>? salesData;
  List<dynamic>? topProducts;
  bool loading = true;
  String? error;

  final Map<String, dynamic> dummyData = {
    'Overview': {
      'jeans': {'total': 23040, 'orders': 2, 'pieces': 16, 'growth': "100.00"},
      'shirts': {'total': 60000, 'orders': 2, 'pieces': 2, 'growth': "100.00"},
    },
    'SalesData': {
      'jeans': {
        'total': 23040,
        'orders': 2,
        'pieces': 16,
        'growth': "100.00",
        'dailyData': [
          {"date": "2025-09-24", "sales": 1440, "orders": 0, "pieces": 1},
          {"date": "2025-09-25", "sales": 21600, "orders": 0, "pieces": 15},
        ],
      },
      'shirts': {
        'total': 60000,
        'orders': 2,
        'pieces': 2,
        'growth': "100.00",
        'dailyData': [
          {"date": "2025-09-25", "sales": 30000, "orders": 0, "pieces": 1},
          {"date": "2025-09-26", "sales": 30000, "orders": 0, "pieces": 1},
        ],
      },
    },
    'TopProducts': [
      {
        "name": "Black Shirt",
        "sales": 60000,
        "pieces": 6,
        "units": 2,
        "growth": 100,
      },
      {
        "name": "Jeans",
        "sales": 23040,
        "pieces": 192,
        "units": 16,
        "growth": 100,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final jeansShirtResp = await AppDataRepo().getJeansShirtRevenueAndOrder();
      final salesResp = await AppDataRepo().getSalesData();
      final topProductsResp = await AppDataRepo().getTopProducts();

      jeansShirtData = jeansShirtResp['data'] ?? dummyData['Overview'];
      salesData = salesResp['data'] ?? dummyData['SalesData'];
      topProducts = topProductsResp['data'] ?? dummyData['TopProducts'];
    } catch (e) {
      error = e.toString();
      jeansShirtData = dummyData['Overview'];
      salesData = dummyData['SalesData'];
      topProducts = dummyData['TopProducts'];
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget sectionWidget;

    if (loading) {
      sectionWidget = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      sectionWidget = Center(child: Text('Error: $error'));
    } else {
      sectionWidget = _buildSectionContent();
    }

    return UniversalScaffold(
      selectedIndex: -1,
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
                  child: Text(
                    'Sales & Reports',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                // Filter + Section Dropdowns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: filters
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                        onChanged: (val) async {
                          if (val == 'Custom Range') {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _customDateRange = picked;
                                _selectedFilter = val!;
                              });
                            }
                          } else {
                            setState(() {
                              _selectedFilter = val!;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: sections
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSection = val!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Report Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: reports
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(
                                r,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: _selectedReport == r,
                              selectedColor: Colors.indigo,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _selectedReport == r
                                    ? Colors.white
                                    : Colors.indigo,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.indigo.shade100),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedReport = r;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Section Content
                sectionWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    final section = _selectedSection.toLowerCase();
    final jeans = jeansShirtData?['jeans'] ?? dummyData['Overview']['jeans'];
    final shirts = jeansShirtData?['shirts'] ?? dummyData['Overview']['shirts'];
    final jeansDaily = salesData?['jeans']?['dailyData'] ?? [];
    final shirtsDaily = salesData?['shirts']?['dailyData'] ?? [];
    final products = topProducts ?? dummyData['TopProducts'];

    // Filter daily data by selected filter
    List<dynamic> filteredJeansDaily = jeansDaily;
    List<dynamic> filteredShirtsDaily = shirtsDaily;
    DateTime now = DateTime.now();
    if (_selectedFilter == 'Today') {
      String today =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      filteredJeansDaily = jeansDaily.where((d) => d['date'] == today).toList();
      filteredShirtsDaily = shirtsDaily
          .where((d) => d['date'] == today)
          .toList();
    } else if (_selectedFilter == 'This Week') {
      DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
      filteredJeansDaily = jeansDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return !date.isBefore(weekStart) && !date.isAfter(now);
      }).toList();
      filteredShirtsDaily = shirtsDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return !date.isBefore(weekStart) && !date.isAfter(now);
      }).toList();
    } else if (_selectedFilter == 'This Month') {
      DateTime monthStart = DateTime(now.year, now.month, 1);
      filteredJeansDaily = jeansDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return !date.isBefore(monthStart) && !date.isAfter(now);
      }).toList();
      filteredShirtsDaily = shirtsDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return !date.isBefore(monthStart) && !date.isAfter(now);
      }).toList();
    } else if (_selectedFilter == 'This Year') {
      DateTime yearStart = DateTime(now.year, 1, 1);
      filteredJeansDaily = jeansDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return !date.isBefore(yearStart) && !date.isAfter(now);
      }).toList();
      filteredShirtsDaily = shirtsDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return !date.isBefore(yearStart) && !date.isAfter(now);
      }).toList();
    } else if (_selectedFilter == 'Custom Range' && _customDateRange != null) {
      filteredJeansDaily = jeansDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return date.isAfter(
              _customDateRange!.start.subtract(Duration(days: 1)),
            ) &&
            date.isBefore(_customDateRange!.end.add(Duration(days: 1)));
      }).toList();
      filteredShirtsDaily = shirtsDaily.where((d) {
        DateTime date = DateTime.parse(d['date']);
        return date.isAfter(
              _customDateRange!.start.subtract(Duration(days: 1)),
            ) &&
            date.isBefore(_customDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    // Calculate filtered totals for cards/blocks
    int jeansSales = 0,
        shirtsSales = 0,
        jeansOrders = 0,
        shirtsOrders = 0,
        jeansPieces = 0,
        shirtsPieces = 0;
    double jeansGrowth = 0, shirtsGrowth = 0;
    // Use filtered data for calculations
    for (var d in filteredJeansDaily) {
      jeansSales += (d['sales'] ?? 0) as int;
      jeansOrders += (d['orders'] ?? 0) as int;
      jeansPieces += (d['pieces'] ?? 0) as int;
    }
    for (var d in filteredShirtsDaily) {
      shirtsSales += (d['sales'] ?? 0) as int;
      shirtsOrders += (d['orders'] ?? 0) as int;
      shirtsPieces += (d['pieces'] ?? 0) as int;
    }
    // Fallback to overall if no filtered data
    if (filteredJeansDaily.isEmpty) {
      jeansSales = jeans['total'] ?? 0;
      jeansOrders = jeans['orders'] ?? 0;
      jeansPieces = jeans['pieces'] ?? 0;
    }
    if (filteredShirtsDaily.isEmpty) {
      shirtsSales = shirts['total'] ?? 0;
      shirtsOrders = shirts['orders'] ?? 0;
      shirtsPieces = shirts['pieces'] ?? 0;
    }
    jeansGrowth = double.tryParse(jeans['growth']?.toString() ?? '0') ?? 0;
    shirtsGrowth = double.tryParse(shirts['growth']?.toString() ?? '0') ?? 0;

    if (section == 'overview') {
      int totalSales = jeansSales + shirtsSales;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _KpiCard(
                  label: 'Total Sales',
                  value: '₹$totalSales',
                  icon: Icons.attach_money,
                  color: Colors.deepPurple,
                  // width: 100,
                  // height: 100,
                ),
                // SizedBox(width: 4),
                _KpiCard(
                  label: 'Total Orders',
                  value:
                      '${(jeansShirtData?['jeans']?['orders'] ?? jeans['orders'] ?? 0) + (jeansShirtData?['shirts']?['orders'] ?? shirts['orders'] ?? 0)}',
                  icon: Icons.receipt_long,
                  color: Colors.deepPurple,
                  // width: 100,
                  // height: 100,
                ),
                // SizedBox(width: 8),
                _KpiCard(
                  label: 'Total Pieces',
                  value: '${(jeans['pieces'] ?? 0) + (shirts['pieces'] ?? 0)}',
                  icon: Icons.widgets,
                  color: Colors.blueGrey,
                  // width: 100,
                  // height: 100,
                ),
                // SizedBox(width: 8),
                _KpiCard(
                  label: 'Growth',
                  value:
                      '${((jeansGrowth + shirtsGrowth) / 2).toStringAsFixed(2)}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  // width: 100,
                  // height: 100,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          SalesBarChart(
            jeansDaily: filteredJeansDaily,
            shirtsDaily: filteredShirtsDaily,
            section: section,
          ),
          SizedBox(height: 24),
          Text(
            'Top Performing Products',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final prod = products[idx];
              return _buildProductCard(prod);
            },
          ),
        ],
      );
    } else {
      final isJeans = section == 'jeans';
      final sales = isJeans ? jeansSales : shirtsSales;
      final orders = isJeans
          ? (jeansShirtData?['jeans']?['orders'] ?? jeans['orders'] ?? 0)
          : (jeansShirtData?['shirts']?['orders'] ?? shirts['orders'] ?? 0);
      final pieces = isJeans ? jeansPieces : shirtsPieces;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _KpiCard(
                  label: 'Total Revenue',
                  value: '₹$sales',
                  icon: Icons.attach_money,
                  color: isJeans ? Colors.indigo : Colors.green,
                  // width: 90,
                  // height: 90,
                ),
                // SizedBox(width: 8),
                _KpiCard(
                  label: 'Total Orders',
                  value: '$orders',
                  icon: Icons.receipt_long,
                  color: isJeans ? Colors.indigo : Colors.green,
                  // width: 90,
                  // height: 90,
                ),
                // SizedBox(width: 8),
                _KpiCard(
                  label: 'Pcs',
                  value: '$pieces',
                  icon: Icons.check_circle,
                  color: isJeans ? Colors.indigo : Colors.green,
                  // width: 90,
                  // height: 90,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          SalesBarChart(
            jeansDaily: filteredJeansDaily,
            shirtsDaily: filteredShirtsDaily,
            section: section,
          ),
          SizedBox(height: 24),
          Text(
            'Top Performing Products',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final prod = products[idx];
              return _buildProductCard(prod);
            },
          ),
        ],
      );
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double width;
  final double height;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.width = 100,
    this.height = 100,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        color: color.withOpacity(0.15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: color,
                ),
              ),
              Text(label, style: TextStyle(fontSize: 9, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildProductCard(Map<String, dynamic> prod) {
  return Card(
    color: Colors.indigo.shade50,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sales: ₹${prod['sales']}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Pcs Sold: ${prod['pieces']}',
                  style: const TextStyle(color: Colors.indigo),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${prod['growth']}%',
                style: TextStyle(
                  color: (prod['growth'] ?? 0) > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Growth',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
