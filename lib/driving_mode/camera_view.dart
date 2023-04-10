import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:drive_fit/service/face_detection_service.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '/global_variables.dart' as globals;

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.customPaint,
    this.text,
    required this.onImage,
    this.initialDirection = CameraLensDirection.back,
    required this.isReminding,
  }) : super(key: key);

  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;
  final bool isReminding;

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  final FaceDetectionService faceDetectionService = FaceDetectionService();
  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 5.0;
  bool _cameraOn = false;
  Timer? exposureTimer;
  bool showCameraPreview = false, useHighCameraResolution = false;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        showCameraPreview = (prefs.getBool('showCameraPreview') ?? false);
        useHighCameraResolution =
            (prefs.getBool('useHighCameraResolution') ?? false);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  void _initCamera() async {
    _loadSettings();
    final CameraController? oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }
    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() async {
    _stopLiveFeed();
    exposureTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    final CameraController? cameraController = _controller;
    if (cameraController?.value.isInitialized == false ||
        cameraController == null) {
      return Container(
        alignment: Alignment.center,
        color: lightColorScheme.background,
        child: Text("Initializing Camera...",
            style: Theme.of(context).textTheme.headlineLarge),
      );
    } else {
      final size = MediaQuery.of(context).size;
      var scale = size.aspectRatio * _controller!.value.aspectRatio;
      if (scale < 1) scale = 1 / scale;
      if (!globals.inCalibrationMode && !showCameraPreview) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: widget.isReminding
                ? lightColorScheme.error
                : lightColorScheme.background,
          ),
        );
      }
      return Stack(
        children: [
          Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(_controller!),
                ),
              ),
              if (widget.customPaint != null) widget.customPaint!,
            ],
          ),
          AnimatedOpacity(
            opacity: widget.isReminding ? 0.6 : 0.0,
            duration: const Duration(seconds: 1),
            child: Container(
              color: lightColorScheme.error,
            ),
          ),
        ],
      );
    }
  }

  void pauseCameraPreview() {
    _controller!.pausePreview();
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      useHighCameraResolution ? ResolutionPreset.high : ResolutionPreset.low,
      enableAudio: false,
    );
    try {
      await _controller?.initialize();
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          showInSnackBar('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('Audio access is restricted.');
          break;
        default:
          _showCameraException(e);
          break;
      }
    }

    if (!mounted) {
      return;
    }
    if (_cameraOn) return;
    _cameraOn = true;

    _controller?.startImageStream(_processCameraImage);

    setState(() {});

    exposureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        if (mounted) {
          _controller?.setExposurePoint(
              Offset(globals.faceCenterX, globals.faceCenterY));
        }
      } catch (e) {
        log("$e");
      }
    });
  }

  Future _stopLiveFeed() async {
    if (_cameraOn) {
      _cameraOn = false;
      await _controller?.stopImageStream();
      await _controller?.dispose();
      _controller = null;
    }
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  void _logError(String code, String? message) {
    // ignore: avoid_print
    print('Error: $code${message == null ? '' : '\nError Message: $message'}');
  }
}
