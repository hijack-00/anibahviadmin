import 'package:flutter/material.dart';

class PushNotificationsPage extends StatefulWidget {
  @override
  State<PushNotificationsPage> createState() => _PushNotificationsPageState();
}

class _PushNotificationsPageState extends State<PushNotificationsPage> {
  TextEditingController messageController = TextEditingController();
  List<Map<String, String>> history = [
    {'msg': 'Welcome to Anibhavi!', 'date': '2025-09-01'},
    {'msg': 'New catalogue available.', 'date': '2025-09-10'},
  ];

  void _sendNotification() {
    if (messageController.text.trim().isNotEmpty) {
      setState(() {
        history.insert(0, {'msg': messageController.text.trim(), 'date': DateTime.now().toString().split(' ')[0]});
        messageController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent (dummy)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Push Notifications'),
        // backgroundColor: Colors.indigo,
        actions: [Icon(Icons.notifications_active, color: Colors.white)],
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
                  Icon(Icons.notifications_active, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Send Push Notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Write message',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.send,color: Colors.white,),
              label: Text('Send Notification',style: TextStyle(fontSize: 16, color: Colors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: _sendNotification,
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
                  Text('Notification History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: history.isEmpty
                  ? Center(child: Text('No notifications yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        final h = history[i];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.notifications_active, color: Colors.indigo),
                            title: Text(h['msg'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(h['date'] ?? '', style: TextStyle(color: Colors.indigo)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
