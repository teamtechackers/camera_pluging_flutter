import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [Permission.camera, Permission.microphone].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      Get.snackbar("Permission Denied", "Camera permission is required to use this feature.", backgroundColor: Colors.orange);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      Get.snackbar("No Camera Found", "This device does not have any available cameras.", backgroundColor: Colors.orange);
      return;
    }

    _controller = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);

    try {
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera error: $e");
      Get.snackbar("Camera Error", "Could not initialize camera: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _captureAndCompress() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      Get.snackbar("Error", "Camera is not ready yet.", backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Take Picture
      final XFile originalImage = await _controller!.takePicture();
      final File originalFile = File(originalImage.path);
      final int originalBytes = await originalFile.length();

      setState(() {
        _originalSize = "${(originalBytes / 1024).toStringAsFixed(2)} KB";
      });

      // 2. Compress Image
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 50, // Compress to 50% quality
      );

      if (compressedImage != null) {
        final File compressedFile = File(compressedImage.path);
        final int compressedBytes = await compressedFile.length();

        setState(() {
          _compressedSize = "${(compressedBytes / 1024).toStringAsFixed(2)} KB";
        });

        // Return the compressed image to ScanPage
        final scanController = Get.find<ScanController>();
        scanController.selectedImage.value = compressedFile;
        scanController.isFromUsb.value = false;
        
        // Use a short delay or ensure Get.back() targets the screen
        Get.back(); 
      }
    } catch (e) {
      debugPrint("Processing error: $e");
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment.center, radius: 1.5, colors: [const Color(0xFF1A1A1A), const Color(0xFF000000)]),
            ),
          ),

          // Header
          Positioned(top: 50.h, left: 0, right: 0, child: _buildHeader()),

          // Camera Viewport
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCameraBox(),
                SizedBox(height: 20.h),
                _buildSizeIndicators(),
                SizedBox(height: 20.h),
              ],
            ),
          ),

          // Bottom "Analyze" Button
          Positioned(bottom: 60.h, left: 0, right: 0, child: _buildAnalyzeButton()),

          // Nav Bar Placeholder
          Positioned(bottom: 20.h, left: 0, right: 0, child: _buildNavigationBar()),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFC5A358))),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ULTRASCAN',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900, letterSpacing: 2.5),
                ),
                TextSpan(
                  text: ' 4D',
                  style: GoogleFonts.inter(color: const Color(0xFFC5A358), fontSize: 14.sp, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Container(
            height: 44.r,
            width: 44.r,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBox() {
    return Container(
      width: 300.w,
      height: 300.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isCameraInitialized && _controller != null) CameraPreview(_controller!) else const Center(child: CircularProgressIndicator(color: Color(0xFFC5A358))),

            Padding(
              padding: EdgeInsets.all(30.r),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  borderRadius: BorderRadius.circular(15.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeIndicators() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sizeIndicator("Original", _originalSize, Colors.grey),
          SizedBox(width: 20.w),
          _sizeIndicator("Compressed", _compressedSize, const Color(0xFFC5A358)),
        ],
      ),
    );
  }

  Widget _sizeIndicator(String label, String size, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 10.sp),
        ),
        Text(
          size,
          style: GoogleFonts.inter(color: color, fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _captureAndCompress,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(25.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0A0A),
              border: Border.all(color: const Color(0xFFC5A358), width: 3.r),
              boxShadow: [BoxShadow(color: const Color(0xFFC5A358).withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBinocularLens(),
                    SizedBox(width: 4.w),
                    _buildBinocularLens(),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Click',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinocularLens() {
    return Container(
      width: 20.r,
      height: 18.r,
      decoration: BoxDecoration(color: const Color(0xFFC5A358), borderRadius: BorderRadius.circular(4.r)),
      child: Center(
        child: Container(
          width: 8.r,
          height: 8.r,
          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.menu, color: Colors.white.withOpacity(0.4), size: 26.r),
          Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.4), size: 26.r),
          Icon(Icons.arrow_back_ios_new, color: Colors.white.withOpacity(0.4), size: 20.r),
        ],
      ),
    );
  }
}
