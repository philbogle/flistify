import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// A screen that allows the user to take a picture.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

/// State class for [TakePictureScreen].
class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  /// Initializes the state of the widget.
  ///
  /// This method is called once when the widget is inserted into the widget tree.
  /// It initializes the camera controller and prepares the camera for use.
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  /// Initializes the camera.
  ///
  /// This method retrieves available cameras, selects the rear camera (or the first available),
  /// initializes the [CameraController] with a medium resolution preset, and locks the
  /// capture orientation for non-web platforms.
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras found.');
    }
    // Find the rear camera
    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first, // Fallback to the first camera if no rear camera is found
    );
    _controller = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller.initialize();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await _controller.lockCaptureOrientation();
    }
  }

  @override
  /// Disposes of the controller when the widget is disposed.
  ///
  /// This method is called when the widget is removed from the widget tree.
  /// It disposes of the [CameraController] to release camera resources.
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Builds the widget.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a list')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Make a picture of handwriting, text, or objects.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.previewSize!.height,
                      height: _controller.value.previewSize!.width,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();
                if (!mounted) return;
                Navigator.of(context).pop(image);
              } catch (e) {
                debugPrint('$e');
              }
            },
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null && mounted) {
                Navigator.of(context).pop(image);
              }
            },
            heroTag: 'gallery',
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
      
    );
  }
}
