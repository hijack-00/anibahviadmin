
import 'package:flutter/material.dart';

class WhatsAppNotificationsPage extends StatefulWidget {
  @override
  State<WhatsAppNotificationsPage> createState() => _WhatsAppNotificationsPageState();
}

class _WhatsAppNotificationsPageState extends State<WhatsAppNotificationsPage> {
  final List<Map<String, String>> logs = [
    {'type': 'Signup', 'msg': 'Signup request approved'},
    {'type': 'Order', 'msg': 'Order confirmation sent'},
    {'type': 'LR', 'msg': 'LR uploaded and sent'},
    {'type': 'Delivery', 'msg': 'Delivery status updated'},
    {'type': 'Return', 'msg': 'Sales return confirmation sent'},
  ];
  String filter = 'All';
  TextEditingController messageController = TextEditingController();

  List<String> types = ['All', 'Signup', 'Order', 'LR', 'Delivery', 'Return'];

  void _sendNotification() {
    if (messageController.text.trim().isNotEmpty) {
      setState(() {
        logs.insert(0, {'type': 'Custom', 'msg': messageController.text.trim()});
        messageController.clear();
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent (dummy)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = filter == 'All'
        ? logs
        : logs.where((l) => l['type'] == filter).toList();
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('WhatsApp Notifications'),
        backgroundColor: Colors.indigo,
        actions: [
          Icon(Icons.chat, color: Colors.white),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: filter,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => filter = val ?? 'All'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(child: Text('No notifications found'))
                  : ListView.separated(
                      itemCount: filteredLogs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (context, i) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Icon(Icons.chat, color: Colors.green),
                          ),
                          title: Text(filteredLogs[i]['type'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(filteredLogs[i]['msg'] ?? ''),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: Icon(Icons.send),
        tooltip: 'Send Notification',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (context) => Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Send WhatsApp Notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                          onPressed: _sendNotification,
                          child: Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}