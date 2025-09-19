import 'package:flutter/material.dart';


class StockAdjustmentPage extends StatefulWidget {
  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  List<Map<String, dynamic>> adjustments = [
    {'item': 'Lot A123', 'change': '+10', 'type': 'Auto'},
    {'item': 'Lot B456', 'change': '-5', 'type': 'Manual'},
  ];
  TextEditingController itemController = TextEditingController();
  TextEditingController changeController = TextEditingController();
  String type = 'Auto';
  final List<String> types = ['Auto', 'Manual'];

  void _addAdjustment() {
    final item = itemController.text.trim();
    final change = changeController.text.trim();
    if (item.isEmpty || change.isEmpty) return;
    setState(() {
      adjustments.insert(0, {
        'item': item,
        'change': change,
        'type': type,
      });
      itemController.clear();
      changeController.clear();
      type = 'Auto';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stock adjustment added (dummy)')),
    );
  }

  void _showOptions(Map<String, dynamic> adj, int index) {
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
                  _showDetails(adj);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                onTap: () {
                  setState(() {
                    adjustments.removeAt(index);
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

  void _showDetails(Map<String, dynamic> adj) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adjustment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item: ${adj['item']}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Change: ${adj['change']}'),
              SizedBox(height: 8),
              Text('Type: ${adj['type']}'),
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
        title: Text('Stock Adjustment'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.inventory, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Add Stock Adjustment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: itemController,
                    decoration: InputDecoration(
                      labelText: 'Item',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: changeController,
                    decoration: InputDecoration(
                      labelText: 'Change (+/-)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: type,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => type = val ?? 'Auto'),
                  style: TextStyle(color: Colors.indigo),
                  dropdownColor: Colors.indigo.shade50,
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: _addAdjustment,
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Adjustment History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: adjustments.isEmpty
                  ? Center(child: Text('No adjustments yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: adjustments.length,
                      itemBuilder: (context, index) {
                        final adj = adjustments[index];
                        final isAdd = adj['change'].toString().startsWith('+');
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: isAdd ? Colors.green.shade50 : Colors.red.shade50,
                          child: ListTile(
                            leading: Icon(
                              isAdd ? Icons.add : Icons.remove,
                              color: isAdd ? Colors.green : Colors.red,
                            ),
                            title: Text(adj['item'], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Change: ${adj['change']}'),
                                Text('Type: ${adj['type']}', style: TextStyle(color: Colors.indigo)),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.indigo),
                              onSelected: (value) {
                                if (value == 'options') _showOptions(adj, index);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'options', child: Text('Options')),
                              ],
                            ),
                            onTap: () => _showDetails(adj),
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
        icon: Icon(Icons.inventory),
        label: Text('Add Adjustment'),
        onPressed: () {
          itemController.clear();
          changeController.clear();
          setState(() {
            type = 'Auto';
          });
        },
      ),
    );
  }
}
