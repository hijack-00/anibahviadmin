import 'package:flutter/material.dart';

class SalesReturnPage extends StatefulWidget {
  @override
  State<SalesReturnPage> createState() => _SalesReturnPageState();
}



class _SalesReturnPageState extends State<SalesReturnPage> {
  String reason = 'Damage';
  final List<String> reasons = ['Damage', 'Mismatch', 'Excess'];
  TextEditingController noteController = TextEditingController();
  List<Map<String, dynamic>> returnHistory = [];
  List<Map<String, dynamic>> refundHistory = [];
  List<Map<String, dynamic>> challanHistory = [];
  String reportType = 'Daily';
  String selectedFranchisee = 'Franchisee A';

  void _createReturn() {
    setState(() {
      returnHistory.insert(0, {
        'reason': reason,
        'note': noteController.text,
        'date': DateTime.now(),
        'stockAdjusted': true,
      });
      noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sales return created (dummy) & stock auto-adjusted')),
    );
  }

  void _createRefund() {
    setState(() {
      refundHistory.insert(0, {
        'type': 'Refund',
        'amount': '1000',
        'date': DateTime.now(),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refund/Credit note created (dummy)')),
    );
  }

  void _createChallan() {
    setState(() {
      challanHistory.insert(0, {
        'challan': 'RC${DateTime.now().millisecondsSinceEpoch}',
        'date': DateTime.now(),
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Return challan created (dummy)')),
    );
  }

  void _showOptions(Map<String, dynamic> entry, int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.info, color: Colors.indigo),
                title: Text('Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showDetails(entry);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  setState(() {
                    returnHistory.removeAt(index);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sales Return Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reason: ${entry['reason']}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Note: ${entry['note']}'),
              SizedBox(height: 8),
              Text('Date: ${entry['date'].toString().substring(0, 19)}'),
              SizedBox(height: 8),
              Text('Stock Adjusted: ${entry['stockAdjusted'] == true ? 'Yes' : 'No'}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportGraph() {
    // Dummy graph widget
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.indigo.shade100, blurRadius: 6)],
      ),
      child: Center(child: Text('Graph: Sales vs Returns (Dummy)', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildFranchiseeReport() {
    // Dummy franchisee-wise report
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: ListTile(
        leading: Icon(Icons.store, color: Colors.indigo),
        title: Text(selectedFranchisee, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Sales Returns: ₹5,000 | Sales: ₹95,000', style: TextStyle(color: Colors.indigo)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sales Return'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.assignment_return, color: Colors.white)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Sales Return', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: reason,
              items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => reason = val ?? 'Damage'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.assignment_return, color: Colors.white),
                    label: Text('Create Sales Return',style: TextStyle(fontSize: 8, color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: _createReturn,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.receipt_long, color: Colors.white),
                    label: Text('Refund/Credit Note',style: TextStyle(fontSize: 8,color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: _createRefund,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.assignment, color: Colors.white),
                    label: Text('Return Challan',style: TextStyle(fontSize: 8,color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _createChallan,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text('Return History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            if (returnHistory.isEmpty)
              Center(child: Text('No sales returns yet', style: TextStyle(color: Colors.grey)))
            else
              Column(
                children: returnHistory.map((entry) {
                  int index = returnHistory.indexOf(entry);
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.assignment_return, color: Colors.indigo),
                      title: Text(entry['reason']),
                      subtitle: Text('Note: ${entry['note']}'),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.indigo),
                        onSelected: (value) {
                          if (value == 'options') _showOptions(entry, index);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'options', child: Text('Options')),
                        ],
                      ),
                      onTap: () => _showDetails(entry),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 24),
            Text('Refund/Credit Note History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.purple)),
            SizedBox(height: 8),
            if (refundHistory.isEmpty)
              Center(child: Text('No refund/credit notes yet', style: TextStyle(color: Colors.grey)))
            else
              Column(
                children: refundHistory.map((entry) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.receipt_long, color: Colors.purple),
                      title: Text(entry['type']),
                      subtitle: Text('Amount: ₹${entry['amount']}'),
                      trailing: Text(entry['date'].toString().substring(0, 19)),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 24),
            Text('Return Challan History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
            SizedBox(height: 8),
            if (challanHistory.isEmpty)
              Center(child: Text('No return challans yet', style: TextStyle(color: Colors.grey)))
            else
              Column(
                children: challanHistory.map((entry) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.assignment, color: Colors.green),
                      title: Text(entry['challan']),
                      subtitle: Text(entry['date'].toString().substring(0, 19)),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 24),
            Text('Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            Row(
              children: [
                Text('Type:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: reportType,
                  items: ['Daily', 'Monthly', 'Yearly']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => reportType = val ?? 'Daily'),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildReportGraph(),
            SizedBox(height: 24),
            // Text('Franchisee-wise Sales Return Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            // SizedBox(height: 8),
            // DropdownButton<String>(
            //   value: selectedFranchisee,
            //   items: ['Franchisee A', 'Franchisee B', 'Franchisee C']
            //       .map((f) => DropdownMenuItem(value: f, child: Text(f)))
            //       .toList(),
            //   onChanged: (val) => setState(() => selectedFranchisee = val ?? 'Franchisee A'),
            // ),
            SizedBox(height: 70),
            // _buildFranchiseeReport(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: Icon(Icons.assignment_return),
        label: Text('Add Return'),
        onPressed: () {
          noteController.clear();
          setState(() {
            reason = 'Damage';
          });
        },
      ),
    );
  }
}