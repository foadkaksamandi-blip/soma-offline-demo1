import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';

class QRUtils {
  // Generate QR for Seller (مبلغ رو encode کن)
  static Widget generateQR(double amount) {
    final data = jsonEncode({'action': 'pay', 'amount': amount});
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 200.0,
    );
  }

  // Scan QR for Buyer
  static void scanQR(BuildContext context, Function(String) onScan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: 300,
          child: QRView(
            key: GlobalKey(),
            onQRViewCreated: (controller) {
              controller.scannedDataStream.listen((scanData) {
                Navigator.pop(context);
                onScan(scanData.code ?? '');
              });
            },
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> decodeQR(String qrData) {
    return jsonDecode(qrData);
  }
}
