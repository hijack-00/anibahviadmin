import 'package:flutter/material.dart';

class BarcodePage extends StatefulWidget {
  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  TextEditingController barcodeController = TextEditingController();
  String scannedBarcode = '';

  void _scanBarcode() {
    setState(() {
      scannedBarcode = '9876543210123'; // Dummy scanned value
      barcodeController.text = scannedBarcode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Barcode Scan/Manual Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Scan Barcode'),
              onPressed: _scanBarcode,
            ),
            SizedBox(height: 16),
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Enter Barcode Manually',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            if (barcodeController.text.isNotEmpty)
              Column(
                children: [
                  Image.network(
                    'https://barcode.tec-it.com/barcode.ashx?data=${barcodeController.text}&code=EAN13',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 8),
                  Text(barcodeController.text, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
