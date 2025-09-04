
import 'package:flutter/material.dart';


class OrderStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const OrderStatCard({Key? key, required this.label, required this.count, required this.color, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              // SizedBox(height: 6),
              // SizedBox(height: 2),
                Text('$count', style: TextStyle(fontSize: 14, color: color,fontWeight: FontWeight.w600)),

              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class UserStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const UserStatCard({Key? key, required this.label, required this.count, required this.icon, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 28)),
              SizedBox(height: 6),
              Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  const QuickActionButton({Key? key, required this.label, required this.icon, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,      
        foregroundColor: Colors.white,
        minimumSize: Size(140, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}

class RecentOrderCard extends StatelessWidget {
  final String id;
  final String customer;
  final String status;
  final String total;
  const RecentOrderCard({Key? key, required this.id, required this.customer, required this.status, required this.total}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Shipped':
        statusColor = Colors.blue;
        break;
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.shopping_cart, color: statusColor),
        ),
        title: Text('Order #$id', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Customer: $customer\nStatus: $status'),
        trailing: Text(total, style: TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {
          Navigator.pushNamed(context, '/order_detail', arguments: id);
        },
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const KpiCard({Key? key, required this.title, required this.value, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.circular(12),
        
        ),
        width: 90,
        height: 100,
        // padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: Colors.white),
            SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 1),
            Text(title, style: TextStyle(fontSize: 9, color: Colors.white), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}



class ShortcutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  const ShortcutButton({Key? key, required this.label, required this.icon, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        minimumSize: Size(140, 40),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}