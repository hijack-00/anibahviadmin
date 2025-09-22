import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

class BarcodeGenerator extends StatelessWidget {
  final String barcode;
  final double width;
  final double height;
  const BarcodeGenerator({
    Key? key,
    required this.barcode,
    this.width = 200,
    this.height = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: Barcode.ean13(),
      data: barcode,
      width: width,
      height: height,
      drawText: true,
      errorBuilder: (context, error) => Center(child: Text('Invalid EAN13')),
    );
  }
}
