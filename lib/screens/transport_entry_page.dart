import 'package:flutter/material.dart';

class TransportEntryPage extends StatefulWidget {
  @override
  State<TransportEntryPage> createState() => _TransportEntryPageState();
}


class _TransportEntryPageState extends State<TransportEntryPage> {
  TextEditingController controller = TextEditingController();
  List<String> transportHistory = [];
  bool isEditing = false;
  int? editingIndex;

  void _saveTransport() {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (isEditing && editingIndex != null) {
        transportHistory[editingIndex!] = name;
        isEditing = false;
        editingIndex = null;
      } else {
        transportHistory.insert(0, name);
      }
      controller.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transport name saved (dummy)')),
    );
  }

  void _editTransport(int index) {
    setState(() {
      controller.text = transportHistory[index];
      isEditing = true;
      editingIndex = index;
    });
  }

  void _deleteTransport(int index) {
    setState(() {
      transportHistory.removeAt(index);
      if (isEditing && editingIndex == index) {
        isEditing = false;
        editingIndex = null;
        controller.clear();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Transport Name Entry'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.local_shipping, color: Colors.white)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Transport Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Enter Transport Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.edit : Icons.save),
                  label: Text(isEditing ? 'Update' : 'Save'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: _saveTransport,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text('Transport History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo)),
            SizedBox(height: 8),
            Expanded(
              child: transportHistory.isEmpty
                  ? Center(child: Text('No transport names added yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: transportHistory.length,
                      itemBuilder: (context, index) {
                        final name = transportHistory[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.local_shipping, color: Colors.indigo),
                            title: Text(name),
                            subtitle: Text('Saved (dummy)'),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.indigo),
                              onSelected: (value) {
                                if (value == 'edit') _editTransport(index);
                                if (value == 'delete') _deleteTransport(index);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: Icon(Icons.local_shipping),
        label: Text('Add Transport'),
        onPressed: () {
          controller.clear();
          setState(() {
            isEditing = false;
            editingIndex = null;
          });
        },
      ),
    );
  }
}
