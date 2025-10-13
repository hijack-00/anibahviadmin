import 'package:flutter/material.dart';

class CustomerLedgerPage extends StatelessWidget {
  final List<Map<String, dynamic>> ledger = [
    {'customer': 'Customer A', 'credit': 5000, 'debit': 2000, 'balance': 3000},
    {'customer': 'Customer B', 'credit': 10000, 'debit': 4000, 'balance': 6000},
  ];

  CustomerLedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Customer Ledger'),
        backgroundColor: Colors.indigo,
        actions: [Icon(Icons.account_balance_wallet, color: Colors.white)],
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
                  Icon(Icons.account_balance_wallet, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    'Ledger List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ledger.isEmpty
                  ? Center(
                      child: Text(
                        'No ledger entries yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: ledger.length,
                      itemBuilder: (context, i) {
                        final l = ledger[i];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.indigo,
                            ),
                            title: Text(
                              l['customer'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Credit: ₹${l['credit']}'),
                                Text('Debit: ₹${l['debit']}'),
                                Text(
                                  'Balance: ₹${l['balance']}',
                                  style: TextStyle(color: Colors.indigo),
                                ),
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
    );
  }
}
