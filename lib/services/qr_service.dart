import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'analytics_service.dart';

class QRService {
  static const String _baseUrl = 'https://campuslf.app'; // Replace with your app's URL

  // Generate QR code data for an item
  static String generateItemQRData({
    required String itemId,
    required String itemType,
    required String title,
    required String description,
    String? contactInfo,
  }) {
    final qrData = {
      'type': 'item',
      'itemId': itemId,
      'itemType': itemType,
      'title': title,
      'description': description,
      'contactInfo': contactInfo,
      'url': '$_baseUrl/item/$itemId',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return jsonEncode(qrData);
  }

  // Generate QR code data for user profile
  static String generateUserQRData({
    required String userId,
    required String userName,
    required String email,
    String? phoneNumber,
  }) {
    final qrData = {
      'type': 'user',
      'userId': userId,
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'url': '$_baseUrl/user/$userId',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return jsonEncode(qrData);
  }

  // Generate QR code data for contact sharing
  static String generateContactQRData({
    required String name,
    required String email,
    String? phone,
    String? telegram,
    String? whatsapp,
  }) {
    final qrData = {
      'type': 'contact',
      'name': name,
      'email': email,
      'phone': phone,
      'telegram': telegram,
      'whatsapp': whatsapp,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    return jsonEncode(qrData);
  }

  // Create QR code widget
  static Widget createQRWidget({
    required String data,
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    String? logoAsset,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      gapless: false,
      embeddedImage: logoAsset != null ? AssetImage(logoAsset) : null,
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(40, 40),
      ),
      errorStateBuilder: (cxt, err) {
        return Container(
          child: Center(
            child: Text(
              'Something went wrong...',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  // Generate QR code as image bytes
  static Future<Uint8List?> generateQRImageBytes({
    required String data,
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: foregroundColor,
          emptyColor: backgroundColor,
          gapless: false,
        );

        final pictureBounds = Rect.fromLTWH(0, 0, size, size);
        final picture = painter.toPicture(size);
        final image = await picture.toImage(size.toInt(), size.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        return byteData?.buffer.asUint8List();
      }
    } catch (e) {
      print('Error generating QR code: $e');
    }
    return null;
  }

  // Parse QR code data
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      // Try to parse as JSON first
      final data = jsonDecode(qrData);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      // If not JSON, treat as plain text
      return {
        'type': 'text',
        'data': qrData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
    return null;
  }

  // Check camera permission
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return false;
  }

  // Handle scanned QR code
  static Future<QRScanResult> handleScannedQR(String qrData) async {
    try {
      final parsedData = parseQRData(qrData);
      if (parsedData == null) {
        return QRScanResult(
          success: false,
          error: 'Invalid QR code format',
        );
      }

      final type = parsedData['type'] as String?;
      
      // Log analytics
      await AnalyticsService.logQRCodeScanned(
        qrType: type ?? 'unknown',
        qrData: qrData,
      );

      switch (type) {
        case 'item':
          return QRScanResult(
            success: true,
            type: QRType.item,
            data: parsedData,
            message: 'Item QR code scanned successfully',
          );
        case 'user':
          return QRScanResult(
            success: true,
            type: QRType.user,
            data: parsedData,
            message: 'User profile QR code scanned successfully',
          );
        case 'contact':
          return QRScanResult(
            success: true,
            type: QRType.contact,
            data: parsedData,
            message: 'Contact QR code scanned successfully',
          );
        case 'text':
        default:
          return QRScanResult(
            success: true,
            type: QRType.text,
            data: parsedData,
            message: 'QR code scanned successfully',
          );
      }
    } catch (e) {
      return QRScanResult(
        success: false,
        error: 'Error processing QR code: $e',
      );
    }
  }

  // Create QR scanner widget
  static Widget createQRScanner({
    required Function(QRViewController) onQRViewCreated,
    required GlobalKey qrKey,
    bool showOverlay = true,
    String? overlayText,
  }) {
    return QRView(
      key: qrKey,
      onQRViewCreated: onQRViewCreated,
      overlay: showOverlay ? QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 300,
        overlayColor: Colors.black54,
      ) : null,
    );
  }

  // Validate QR data before generating
  static bool validateQRData(String data) {
    if (data.isEmpty) return false;
    if (data.length > 2953) return false; // QR code data limit
    return true;
  }

  // Get QR code info
  static QRCodeInfo getQRCodeInfo(String data) {
    final parsedData = parseQRData(data);
    if (parsedData == null) {
      return QRCodeInfo(
        isValid: false,
        type: QRType.text,
        dataLength: data.length,
      );
    }

    final type = parsedData['type'] as String?;
    QRType qrType;
    
    switch (type) {
      case 'item':
        qrType = QRType.item;
        break;
      case 'user':
        qrType = QRType.user;
        break;
      case 'contact':
        qrType = QRType.contact;
        break;
      default:
        qrType = QRType.text;
    }

    return QRCodeInfo(
      isValid: true,
      type: qrType,
      dataLength: data.length,
      parsedData: parsedData,
    );
  }
}

// Enums and data classes
enum QRType {
  item,
  user,
  contact,
  text,
}

class QRScanResult {
  final bool success;
  final QRType? type;
  final Map<String, dynamic>? data;
  final String? message;
  final String? error;

  QRScanResult({
    required this.success,
    this.type,
    this.data,
    this.message,
    this.error,
  });
}

class QRCodeInfo {
  final bool isValid;
  final QRType type;
  final int dataLength;
  final Map<String, dynamic>? parsedData;

  QRCodeInfo({
    required this.isValid,
    required this.type,
    required this.dataLength,
    this.parsedData,
  });
}