import 'package:flutter/material.dart';

class RefundCreditPage extends StatefulWidget {
  @override
  State<RefundCreditPage> createState() => _RefundCreditPageState();
}


class _RefundCreditPageState extends State<RefundCreditPage> {
  String type = 'Refund';
  final List<String> types = ['Refund', 'Credit Note'];
  TextEditingController amountController = TextEditingController();
  List<Map<String, dynamic>> history = [];

  void _createEntry() {
    setState(() {
      history.insert(0, {
        'type': type,
        'amount': amountController.text,
        'date': DateTime.now(),
      });
      amountController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type created (dummy)')),
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
                    history.removeAt(index);
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
          title: Text('${entry['type']} Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${entry['type']}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Amount: ₹${entry['amount']}'),
              SizedBox(height: 8),
              Text('Date: ${entry['date'].toString().substring(0, 19)}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Refund/Credit Note'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.receipt_long, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Refund/Credit Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => type = val ?? 'Refund'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.receipt_long),
              label: Text('Create $type'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: _createEntry,
            ),
            SizedBox(height: 24),
            Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            Expanded(
              child: history.isEmpty
                  ? Center(child: Text('No entries yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.receipt_long, color: Colors.indigo),
                            title: Text('${entry['type']}'),
                            subtitle: Text('Amount: ₹${entry['amount']}'),
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
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: Icon(Icons.receipt_long),
        label: Text('Add Entry'),
        onPressed: () {
          amountController.clear();
          setState(() {
            type = 'Refund';
          });
        },
      ),
    );
  }
}
