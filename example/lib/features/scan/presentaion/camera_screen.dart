// ignore_for_file: unused_field

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controllers/scan_controller.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  String _originalSize = "0 KB";
  String _compressedSize = "0 KB";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final statuses = await [Permission.camera].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      Get.snackbar("Permission Denied", "Camera permission required");
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      Get.snackbar("Error", "No camera found");
      return;
    }

    _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);

    try {
      await _controller!.initialize();

      /// SAFE DEFAULT ZOOM
      double minZoom = await _controller!.getMinZoomLevel();
      double maxZoom = await _controller!.getMaxZoomLevel();
      double zoom = 1.1.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(zoom);

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      Get.snackbar("Camera Error", e.toString());
    }
  }

  Future<void> _captureAndCompress() async {
    if (!_controller!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      final XFile originalImage = await _controller!.takePicture();
      final File originalFile = File(originalImage.path);
      final int originalBytes = await originalFile.length();

      setState(() {
        _originalSize = "${(originalBytes / 1024).toStringAsFixed(2)} KB";
      });

      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final File squareFile = await cropToSquare(originalFile);

      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(squareFile.absolute.path, targetPath, quality: 50);

      if (compressedImage != null) {
        final File compressedFile = File(compressedImage.path);
        final int compressedBytes = await compressedFile.length();

        setState(() {
          _compressedSize = "${(compressedBytes / 1024).toStringAsFixed(2)} KB";
        });

        final scanController = Get.find<ScanController>();
        scanController.selectedImage.value = compressedFile;

        Get.back();
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<File> cropToSquare(File file) async {
    final bytes = await file.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) return file;

    int size = original.width < original.height ? original.width : original.height;

    int offsetX = (original.width - size) ~/ 2;
    int offsetY = (original.height - size) ~/ 2;

    final img.Image cropped = img.copyCrop(original, offsetX, offsetY, size, size);

    final croppedFile = File("${file.path}_square.jpg");
    await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));

    return croppedFile;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _buildCameraBox()),
          Positioned(bottom: 80, left: 0, right: 0, child: _buildButton()),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraBox() {
    return Container(
      width: 300.w,
      height: 300.h,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.r), color: Colors.black),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: _isCameraInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(width: _controller!.value.previewSize!.height, height: _controller!.value.previewSize!.width, child: CameraPreview(_controller!)),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: _captureAndCompress,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 3),
          ),
          child: Text(
            "CLICK",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
