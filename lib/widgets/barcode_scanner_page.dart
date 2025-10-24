import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController();
  late final AnimationController _animController;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _scanned = true;
      _cameraController.stop();
      Navigator.of(context).pop(barcodes.first.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final squareSize = (size.width * 0.82).clamp(240.0, size.height * 0.7);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan barcode',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          Positioned.fill(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: _onDetect,
            ),
          ),

          // Dark overlay with transparent square hole
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                holeSize: squareSize,
                borderRadius: 12,
                borderColor: Colors.white70,
                borderWidth: 2,
              ),
            ),
          ),

          // Animated horizontal line
          Center(
            child: SizedBox(
              width: squareSize,
              height: squareSize,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final y = (_animController.value) * (squareSize - 4);
                  return Stack(
                    children: [
                      Positioned(
                        top: y,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.greenAccent.withOpacity(0.0),
                                Colors.greenAccent.withOpacity(0.95),
                                Colors.greenAccent.withOpacity(0.0),
                              ],
                              stops: const [0.15, 0.5, 0.85],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Instructions & cancel
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Place the barcode inside the square. The scanner will detect automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double holeSize;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;

  _ScannerOverlayPainter({
    required this.holeSize,
    this.borderRadius = 12,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    // draw full screen dim
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // compute centered square
    final left = (size.width - holeSize) / 2;
    final top = (size.height - holeSize) / 2;
    final holeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, holeSize, holeSize),
      Radius.circular(borderRadius),
    );

    // Clear the hole using BlendMode.clear
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    // clear hole
    canvas.drawRRect(holeRect, clearPaint);

    // draw border around hole
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;
    canvas.drawRRect(holeRect, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}





// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';


// class BarcodeScannerPage extends StatelessWidget {
//   // final Function(String barcode) onScanned;

//   const BarcodeScannerPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Scan Barcode')),
//       body: MobileScanner(
//         onDetect: (capture) {
//           print('Frame detected. Barcodes count: ${capture.barcodes.length}');
//           for (final b in capture.barcodes) {
//             print('Barcode: ${b.rawValue}, Format: ${b.format}');
//             if (b.rawValue != null && b.rawValue!.isNotEmpty) {
//               print('Detected: ${b.rawValue}');
//               // onScanned(b.rawValue!);
//               print('Scanner closing with context: $context');
//               Navigator.of(context).pop(b.rawValue);
//               return;
//             }
//           }
//         },
//       ),
//     );
//   }
// }



