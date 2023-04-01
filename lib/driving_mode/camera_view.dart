import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '/global_variables.dart' as globals;

class CameraView extends StatefulWidget {
  const CameraView(
      {Key? key,
      required this.customPaint,
      this.text,
      required this.onImage,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  int _cameraIndex = -1;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 5.0;
  //double _maxAvailableExposureOffset = 0.0, _minAvailableExposureOffset = 0.0;
  //bool _changingCameraLens = false;
  bool _cameraOn = false;
  Timer? exposureTimer;
  bool showCameraPreview = true, useHighCameraResolution = false;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        showCameraPreview = (prefs.getBool('showCameraPreview') ?? true);
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

  void _initCamera() {
    _loadSettings();
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
      if (!_cameraOn) {
        _cameraOn = true;
        _startLiveFeed();
      }
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    exposureTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container(
        alignment: Alignment.center,
        color: lightColorScheme.background,
        child: Text("Initializing Camera...",
            style: Theme.of(context).textTheme.headlineLarge),
      );
    } else {
      final size = MediaQuery.of(context).size;
      // calculate scale depending on screen and camera ratios
      // this is actually size.aspectRatio / (1 / camera.aspectRatio)
      // because camera preview size is received as landscape
      // but we're calculating for portrait orientation
      var scale = size.aspectRatio * _controller!.value.aspectRatio;

      // to prevent scaling down, invert the value
      if (scale < 1) scale = 1 / scale;

      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Transform.scale(
              scale: scale,
              child: Center(
                child: globals.inCalibrationMode
                    ? CameraPreview(_controller!)
                    : showCameraPreview
                        ? CameraPreview(_controller!)
                        : Container(
                            color: lightColorScheme.background,
                          ),
              ),
            ),
            if (widget.customPaint != null) widget.customPaint!,
          ],
        ),
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
    _cameraOn = true;
    _controller?.getMinZoomLevel().then((value) {
      zoomLevel = value;
    });
    //_controller?.getMinExposureOffset().then((value) {
    //  _minAvailableExposureOffset = value;
    //});
    //_controller?.getMaxExposureOffset().then((value) {
    //  _maxAvailableExposureOffset = value;
    //});
    _controller?.startImageStream(_processCameraImage);
    setState(() {});

    await Future.delayed(const Duration(seconds: 1));
    exposureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        if (mounted) {
          _controller?.setExposurePoint(
              Offset(globals.faceCenterX, globals.faceCenterY));
          // _controller?.setExposurePoint(const Offset(0.5, 0.5));
        }
      } catch (e) {
        log("$e");
      }
    });
  }

  Future _stopLiveFeed() async {
    _cameraOn = false;
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  //Future _switchLiveCamera() async {
  //  setState(() => _changingCameraLens = true);
  //  _cameraIndex = (_cameraIndex + 1) % cameras.length;
  //
  //  await _stopLiveFeed();
  //  await _startLiveFeed();
  //  setState(() => _changingCameraLens = false);
  //}

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   final CameraController? cameraController = _controller;

  //   // App state changed before we got the chance to initialize.
  //   if (cameraController == null || !cameraController.value.isInitialized) {
  //     return;
  //   }

  //   if (state == AppLifecycleState.resumed) {
  //     _startLiveFeed();
  //     if (mounted) {
  //       setState(() {});
  //     }
  //   }
  // }

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
