import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatelessWidget {
  // final Function(String barcode) onScanned;

  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          print('Frame detected. Barcodes count: ${capture.barcodes.length}');
          for (final b in capture.barcodes) {
            print('Barcode: ${b.rawValue}, Format: ${b.format}');
            if (b.rawValue != null && b.rawValue!.isNotEmpty) {
              print('Detected: ${b.rawValue}');
              // onScanned(b.rawValue!);
              print('Scanner closing with context: $context');
              Navigator.of(context).pop(b.rawValue);
              return;
            }
          }
        },
      ),
    );
  }
}
