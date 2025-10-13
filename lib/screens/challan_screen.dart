import 'universal_navbar.dart';
import 'package:flutter/material.dart';
import '../widgets/searchable_dropdown.dart';
import 'package:fl_chart/fl_chart.dart'; // For graph view

class ChallanScreen extends StatefulWidget {
  const ChallanScreen({super.key});

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  String searchText = '';
  String selectedStatus = 'All';
  DateTime? fromDate;
  DateTime? toDate;
  String selectedReport = 'Daily';
  bool showGraph = false;

  List<Map<String, dynamic>> challans = [
    {
      'number': 'CH1001',
      'date': DateTime(2025, 9, 1),
      'shop': 'Shop A',
      'client': 'Client X',
      'amount': 12000,
      'pieces': 50,
      'items': 'Shirts, Trousers',
      'status': 'Pending',
      'deliveryPartner': 'DP Express',
      'editable': true,
      'lrUploaded': false,
      'mismatch': false,
    },
    {
      'number': 'CH1002',
      'date': DateTime(2025, 9, 2),
      'shop': 'Shop B',
      'client': 'Client Y',
      'amount': 8000,
      'pieces': 30,
      'items': 'Jeans',
      'status': 'Approved',
      'deliveryPartner': 'DP Fast',
      'editable': false,
      'lrUploaded': true,
      'mismatch': true,
    },
    // ...more dummy data
  ];

  List<Map<String, dynamic>> returns = [
    {
      'number': 'RET2001',
      'date': DateTime(2025, 9, 3),
      'client': 'Client X',
      'amount': 2000,
      'reason': 'Damage',
    },
    {
      'number': 'RET2002',
      'date': DateTime(2025, 9, 4),
      'client': 'Client Y',
      'amount': 1500,
      'reason': 'Excess',
    },
  ];

  List<String> statuses = [
    'All',
    'Pending',
    'Approved',
    'Completed',
    'Dispatched',
    'Rejected',
  ];

  List<String> reportTypes = ['Daily', 'Monthly', 'Yearly'];

  List<Map<String, dynamic>> get filteredChallans {
    return challans.where((c) {
      final matchesSearch =
          c['number'].toLowerCase().contains(searchText.toLowerCase()) ||
          c['shop'].toLowerCase().contains(searchText.toLowerCase()) ||
          c['client'].toLowerCase().contains(searchText.toLowerCase());
      final matchesStatus =
          selectedStatus == 'All' || c['status'] == selectedStatus;
      final matchesFrom =
          fromDate == null ||
          c['date'].isAfter(fromDate!.subtract(Duration(days: 1)));
      final matchesTo =
          toDate == null || c['date'].isBefore(toDate!.add(Duration(days: 1)));
      return matchesSearch && matchesStatus && matchesFrom && matchesTo;
    }).toList();
  }

  void _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  void _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  Future<void> _showCreateChallanDialog() async {
    String? selectedCustomer;
    String? selectedOrder;
    String? selectedVendor;
    String notes = '';
    bool lrUploaded = false;
    List<String> customers = ['Client X', 'Client Y', 'Client Z'];
    List<String> orders = ['Order 101', 'Order 102', 'Order 103'];
    List<String> vendors = ['DP Express', 'DP Fast', 'DP Quick'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Create Challan',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdown(
                  label: 'Select Customer',
                  items: customers,
                  value: selectedCustomer,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedCustomer = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Select Order',
                  items: orders,
                  value: selectedOrder,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedOrder = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Delivery Vendor',
                  items: vendors,
                  value: selectedVendor,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedVendor = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                Text(
                  'Notes (optional)',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  decoration: InputDecoration(hintText: 'Add notes'),
                  onChanged: (val) {
                    notes = val;
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: lrUploaded,
                      onChanged: (val) {
                        lrUploaded = val ?? false;
                        setState(() {});
                      },
                    ),
                    Text('LR Uploaded', style: TextStyle(color: Colors.indigo)),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Auto Stock Adjustment Enabled',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement create challan logic
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: Text('Create Challan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateReturnDialog() async {
    String? selectedCustomer;
    String? selectedOrder;
    String? selectedRefund;
    List<String> customers = ['Client X', 'Client Y', 'Client Z'];
    List<String> orders = ['Order 101', 'Order 102', 'Order 103'];
    List<String> refundMethods = ['Bank Transfer', 'UPI', 'Cash'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Create Return',
            style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchableDropdown(
                  label: 'Select Customer',
                  items: customers,
                  value: selectedCustomer,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedCustomer = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Select Order',
                  items: orders,
                  value: selectedOrder,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedOrder = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                SearchableDropdown(
                  label: 'Refund Method',
                  items: refundMethods,
                  value: selectedRefund,
                  labelColor: Colors.indigo,
                  onChanged: (val) {
                    selectedRefund = val;
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Auto Stock Adjustment Enabled',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement create return logic
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: Text('Create Return'),
            ),
          ],
        );
      },
    );
  }

  void _editChallan(Map<String, dynamic> challan) {
    if (!challan['editable']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challan not editable after DC created!')),
      );
      return;
    }
    // TODO: Implement edit challan logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit Challan #${challan['number']}')),
    );
  }

  void _showMismatchDialog(Map<String, dynamic> challan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Mismatch Detected', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          'Sales Order and Delivery Challan do not match for Challan #${challan['number']}.\nPlease review and correct.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo.shade50,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Delivery Challan & Return Graph',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 15,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value % 5 == 0 ? value.toInt().toString() : '',
                            style: TextStyle(color: Colors.indigo),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final labels = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt() % labels.length],
                              style: TextStyle(color: Colors.indigo),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 10,
                          color: Colors.indigo.shade400,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: 3,
                          color: Colors.red.shade400,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 8,
                          color: Colors.indigo.shade400,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: 2,
                          color: Colors.red.shade400,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 12,
                          color: Colors.indigo.shade400,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: 4,
                          color: Colors.red.shade400,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: 7,
                          color: Colors.indigo.shade400,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: 1,
                          color: Colors.red.shade400,
                          width: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: Colors.indigo, size: 12),
                SizedBox(width: 4),
                Text(
                  'Delivery Challan',
                  style: TextStyle(color: Colors.indigo),
                ),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.redAccent, size: 12),
                SizedBox(width: 4),
                Text('Return', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo.shade50,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: reportTypes
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(
                          type,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        selected: selectedReport == type,
                        selectedColor: Colors.indigo,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selectedReport == type
                              ? Colors.white
                              : Colors.indigo,
                        ),
                        onSelected: (_) =>
                            setState(() => selectedReport = type),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 16),
            Text(
              '$selectedReport Report',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(height: 8),
            // Dummy report data
            ...filteredChallans
                .take(2)
                .map(
                  (c) => ListTile(
                    leading: Icon(Icons.receipt_long, color: Colors.indigo),
                    title: Text('Challan #${c['number']}'),
                    subtitle: Text(
                      'Amount: ₹${c['amount']} | Pieces: ${c['pieces']}',
                    ),
                    trailing: Text(
                      c['status'],
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                ),
            ...returns
                .take(2)
                .map(
                  (r) => ListTile(
                    leading: Icon(Icons.undo, color: Colors.redAccent),
                    title: Text('Return #${r['number']}'),
                    subtitle: Text(
                      'Amount: ₹${r['amount']} | Reason: ${r['reason']}',
                    ),
                    trailing: Text(
                      r['client'],
                      style: TextStyle(color: Colors.indigo),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Elegant header
              Text(
                'Challan & Return',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 8),
              // Search Bar
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Challan',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => searchText = val),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Filter Section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statuses
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(
                              status,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            selected: selectedStatus == status,
                            selectedColor: Colors.indigo,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selectedStatus == status
                                  ? Colors.white
                                  : Colors.indigo,
                            ),
                            onSelected: (_) =>
                                setState(() => selectedStatus = status),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(height: 12),
              // Sort by Date
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (fromDate == null)
                      Text(
                        'From:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    if (fromDate == null) SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickFromDate,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        fromDate == null
                            ? 'Select'
                            : '${fromDate!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(':', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(width: 16),
                    if (toDate == null)
                      Text(
                        'To:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    if (toDate == null) SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickToDate,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        toDate == null
                            ? 'Select'
                            : '${toDate!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.clear, size: 20, color: Colors.red),
                      tooltip: 'Clear date range',
                      onPressed: () {
                        setState(() {
                          fromDate = null;
                          toDate = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Graph & Reports
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.bar_chart, color: Colors.white),
                      label: Text(
                        showGraph ? 'Hide Graph' : 'Show Graph',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => setState(() => showGraph = !showGraph),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.receipt_long, color: Colors.white),
                      label: Text(
                        'Show Reports',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (context) => _buildReportSection(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (showGraph) _buildGraphSection(),
              SizedBox(height: 12),
              // Challan Data Table
              Expanded(
                child: ListView.separated(
                  itemCount: filteredChallans.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = filteredChallans[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Challan #${c['number']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (c['editable'])
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Editable',
                                              style: TextStyle(
                                                color: Colors.indigo,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Date: ${c['date'].toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Shop: ${c['shop']}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Client: ${c['client']}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Amount: ',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        '₹${c['amount']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Pieces: ${c['pieces']}',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Items: ${c['items']}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: c['status'] == 'Pending'
                                              ? Colors.yellow.shade100
                                              : c['status'] == 'Approved'
                                              ? Colors.green.shade100
                                              : c['status'] == 'Rejected'
                                              ? Colors.red.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          c['status'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delivery: ${c['deliveryPartner']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        color: c['lrUploaded']
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        c['lrUploaded']
                                            ? 'LR Uploaded'
                                            : 'LR Not Uploaded',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      SizedBox(width: 12),
                                      if (c['mismatch'])
                                        GestureDetector(
                                          onTap: () => _showMismatchDialog(c),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Mismatch',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: c['editable']
                                        ? Colors.indigo
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _editChallan(c),
                                  tooltip: c['editable']
                                      ? 'Edit Challan'
                                      : 'Not Editable',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.upload_file,
                                    color: Colors.indigo,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      c['lrUploaded'] = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'LR uploaded for Challan #${c['number']}',
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Upload LR',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        tooltip: 'Create Challan/Return',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Create Challan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCreateChallanDialog();
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.undo),
                    label: Text('Create Return'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCreateReturnDialog();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: UniversalNavBar(
        selectedIndex: 4,
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
            Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              (r) => r.settings.name == '/dashboard',
            );
          }
        },
      ),
    );
  }
}
