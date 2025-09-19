import 'package:flutter/material.dart';

class FranchiseeSelectPage extends StatefulWidget {
  @override
  State<FranchiseeSelectPage> createState() => _FranchiseeSelectPageState();
}


class _FranchiseeSelectPageState extends State<FranchiseeSelectPage> {
  String? selectedFranchisee;
  final List<String> franchisees = [
    'Franchisee A',
    'Franchisee B',
    'Franchisee C',
  ];
  List<String> selectionHistory = [];

  void _selectFranchisee(String? val) {
    if (val == null) return;
    setState(() {
      selectedFranchisee = val;
      selectionHistory.insert(0, val);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Franchisee selected (dummy)')),
    );
  }

  void _showOptions(String franchisee, int index) {
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
                  _showDetails(franchisee);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  setState(() {
                    selectionHistory.removeAt(index);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted $franchisee')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(String franchisee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Franchisee Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.store, size: 48, color: Colors.indigo),
              SizedBox(height: 8),
              Text(franchisee, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Details simulated.'),
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
        title: Text('Franchisee Selection'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.store, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Franchisee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFranchisee,
              items: franchisees.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              decoration: InputDecoration(
                labelText: 'Select Franchisee',
                border: OutlineInputBorder(),
              ),
              onChanged: _selectFranchisee,
            ),
            SizedBox(height: 24),
            Text('Selection History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            Expanded(
              child: selectionHistory.isEmpty
                  ? Center(child: Text('No franchisee selected yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: selectionHistory.length,
                      itemBuilder: (context, index) {
                        final franchisee = selectionHistory[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.store, color: Colors.indigo),
                            title: Text(franchisee),
                            subtitle: Text('Selected (dummy)'),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.indigo),
                              onSelected: (value) {
                                if (value == 'options') _showOptions(franchisee, index);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'options', child: Text('Options')),
                              ],
                            ),
                            onTap: () => _showDetails(franchisee),
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
        icon: Icon(Icons.store),
        label: Text('Select Franchisee'),
        onPressed: () {
          setState(() {
            selectedFranchisee = null;
          });
        },
      ),
    );
  }
}
