import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class BarcodeScannerButton extends StatelessWidget {
  final Function(String) onBarcodeScanned;
  final IconData icon;
  final String tooltip;
  final Color? color;

  const BarcodeScannerButton({
    Key? key,
    required this.onBarcodeScanned,
    this.icon = Icons.qr_code_scanner,
    this.tooltip = 'Scan Barcode',
    this.color,
  }) : super(key: key);

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        onBarcodeScanned(barcodeScanRes);
      }
    } on PlatformException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan barcode')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: () => _scanBarcode(context),
    );
  }
}
