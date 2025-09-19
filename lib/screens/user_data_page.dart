import 'package:flutter/material.dart';

class UserDataPage extends StatelessWidget {
  final List<Map<String, dynamic>> users = [
    {'name': 'Customer A', 'active': true, 'orders': 5, 'loyalty': 120},
    {'name': 'Customer B', 'active': false, 'orders': 2, 'loyalty': 40},
    {'name': 'Customer C', 'active': true, 'orders': 10, 'loyalty': 200},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backend User Data')),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, i) => ListTile(
          leading: Icon(users[i]['active'] ? Icons.check_circle : Icons.cancel, color: users[i]['active'] ? Colors.green : Colors.red),
          title: Text(users[i]['name']),
          subtitle: Text('Orders: ${users[i]['orders']} | Loyalty: ${users[i]['loyalty']}'),
        ),
      ),
    );
  }
}
