import 'package:flutter/material.dart';

class ReturnChallanPage extends StatefulWidget {
  @override
  State<ReturnChallanPage> createState() => _ReturnChallanPageState();
}


class _ReturnChallanPageState extends State<ReturnChallanPage> {
  TextEditingController challanController = TextEditingController();
  TextEditingController itemsController = TextEditingController();
  List<Map<String, dynamic>> challanHistory = [];

  void _createChallan() {
    setState(() {
      challanHistory.insert(0, {
        'challan': challanController.text,
        'items': itemsController.text,
        'date': DateTime.now(),
      });
      challanController.clear();
      itemsController.clear();
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
                    challanHistory.removeAt(index);
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
          title: Text('Return Challan Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Challan: ${entry['challan']}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Items: ${entry['items']}'),
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
        title: Text('Return Challan Creation'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.assignment, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Return Challan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 8),
            TextField(
              controller: challanController,
              decoration: InputDecoration(
                labelText: 'Challan Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: itemsController,
              decoration: InputDecoration(
                labelText: 'Items',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.assignment),
              label: Text('Create Return Challan'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: _createChallan,
            ),
            SizedBox(height: 24),
            Text('Challan History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            Expanded(
              child: challanHistory.isEmpty
                  ? Center(child: Text('No challans yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: challanHistory.length,
                      itemBuilder: (context, index) {
                        final entry = challanHistory[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.assignment, color: Colors.indigo),
                            title: Text(entry['challan']),
                            subtitle: Text('Items: ${entry['items']}'),
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
        icon: Icon(Icons.assignment),
        label: Text('Add Challan'),
        onPressed: () {
          challanController.clear();
          itemsController.clear();
        },
      ),
    );
  }
}
