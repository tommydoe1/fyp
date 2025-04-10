// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class BeverageScanner extends StatefulWidget {
//   @override
//   _BeverageScannerState createState() => _BeverageScannerState();
// }
//
// class _BeverageScannerState extends State<BeverageScanner> {
//   late CameraController _cameraController;
//   late BarcodeScanner _barcodeScanner;
//   late ImageLabeler _imageLabeler;
//   late TextRecognizer _textRecognizer;
//   bool _isProcessing = false;
//   bool _isCameraInitialized = false;
//   String _scanResult = "Scan a barcode or label";
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _barcodeScanner = BarcodeScanner();
//     _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
//     _textRecognizer = TextRecognizer();
//   }
//
//   Future<void> _initializeCamera() async {
//     final status = await Permission.camera.request();
//     if (status.isDenied || status.isPermanentlyDenied) {
//       setState(() {
//         _scanResult = "Camera permission required!";
//       });
//       return;
//     }
//
//     final cameras = await availableCameras();
//     if (cameras.isEmpty) {
//       setState(() {
//         _scanResult = "No camera found!";
//       });
//       return;
//     }
//
//     _cameraController = CameraController(cameras.first, ResolutionPreset.high);
//     await _cameraController.initialize();
//     setState(() {
//       _isCameraInitialized = true;
//     });
//   }
//
//   Future<void> _captureAndProcessImage() async {
//     if (!_isCameraInitialized || _isProcessing) return;
//
//     _isProcessing = true;
//
//     try {
//       final imageFile = await _takePicture();
//       if (imageFile == null) {
//         _isProcessing = false;
//         return;
//       }
//
//       final inputImage = InputImage.fromFile(imageFile);
//
//       // Try barcode scanning first
//       final barcodes = await _barcodeScanner.processImage(inputImage);
//       if (barcodes.isNotEmpty) {
//         _handleBarcode(barcodes.first);
//       } else {
//         // If no barcode found, try text recognition
//         final recognizedText = await _textRecognizer.processImage(inputImage);
//         if (recognizedText.text.isNotEmpty) {
//           _handleText(recognizedText.text);
//         } else {
//           // If no text, try image labeling
//           final labels = await _imageLabeler.processImage(inputImage);
//           if (labels.isNotEmpty) {
//             _handleLabel(labels.first);
//           } else {
//             setState(() {
//               _scanResult = "No recognizable data found.";
//             });
//           }
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _scanResult = "Error: $e";
//       });
//     }
//
//     _isProcessing = false;
//   }
//
//   Future<File?> _takePicture() async {
//     if (!_cameraController.value.isInitialized) {
//       print("Camera is not initialized.");
//       return null;
//     }
//
//     try {
//       final XFile imageFile = await _cameraController.takePicture();
//
//       final directory = await getTemporaryDirectory();
//       final savedImage = File('${directory.path}/scan.jpg');
//
//       await imageFile.saveTo(savedImage.path);
//       return savedImage;
//     } catch (e) {
//       print("Error taking picture: $e");
//       return null;
//     }
//   }
//
//   void _handleBarcode(Barcode barcode) {
//     setState(() {
//       _scanResult = "Barcode: ${barcode.displayValue}";
//     });
//   }
//
//   void _handleText(String text) {
//     setState(() {
//       _scanResult = "Recognized Text: $text";
//     });
//   }
//
//   void _handleLabel(ImageLabel label) {
//     setState(() {
//       _scanResult = "Detected: ${label.label} (Confidence: ${label.confidence.toStringAsFixed(2)})";
//     });
//   }
//
//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _barcodeScanner.close();
//     _imageLabeler.close();
//     _textRecognizer.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Beverage Scanner')),
//       body: Column(
//         children: [
//           Expanded(
//             child: _isCameraInitialized
//                 ? CameraPreview(_cameraController)
//                 : Center(child: CircularProgressIndicator()),
//           ),
//           Container(
//             padding: EdgeInsets.all(12),
//             color: Colors.black87,
//             width: double.infinity,
//             child: Text(
//               _scanResult,
//               style: TextStyle(color: Colors.white, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           SizedBox(height: 10),
//           ElevatedButton.icon(
//             onPressed: _captureAndProcessImage,
//             icon: Icon(Icons.camera_alt),
//             label: Text("Scan Beverage"),
//             style: ElevatedButton.styleFrom(
//               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//             ),
//           ),
//           SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }
