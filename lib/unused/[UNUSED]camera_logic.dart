import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../main.dart';

CameraController? _controller;
int _cameraIndex = -1;
double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
CameraLensDirection initialDirection = CameraLensDirection.front;
final FaceDetector _faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    enableContours: false,
    enableClassification: true,
  ),
);
bool _canProcess = true;
bool _isBusy = false;
String? _text;
double? rotX;
double? rotY;
double? rotZ;
double? smileProb;
double? leftEyeOpenProb;
double? rightEyeOpenProb;

void initState() {
  if (cameras.any(
    (element) =>
        element.lensDirection == initialDirection &&
        element.sensorOrientation == 90,
  )) {
    _cameraIndex = cameras.indexOf(
      cameras.firstWhere((element) =>
          element.lensDirection == initialDirection &&
          element.sensorOrientation == 90),
    );
  } else {
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == initialDirection) {
        _cameraIndex = i;
        break;
      }
    }
  }

  if (_cameraIndex != -1) {
    _startLiveFeed();
  }
}

Future _startLiveFeed() async {
  final camera = cameras[_cameraIndex];
  _controller = CameraController(
    camera,
    ResolutionPreset.low,
    enableAudio: false,
  );
  _controller?.initialize().then((_) {
    _controller?.getMinZoomLevel().then((value) {
      zoomLevel = value;
      minZoomLevel = value;
    });
    _controller?.getMaxZoomLevel().then((value) {
      maxZoomLevel = value;
    });
    _controller?.startImageStream(_processCameraImage);
  });
}

Future _stopLiveFeed() async {
  await _controller?.stopImageStream();
  await _controller?.dispose();
  _controller = null;
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  final CameraController? cameraController = _controller;

  // App state changed before we got the chance to initialize.
  if (cameraController == null || !cameraController.value.isInitialized) {
    return;
  }

  if (state == AppLifecycleState.inactive) {
    cameraController.dispose();
  } else if (state == AppLifecycleState.resumed) {
    _startLiveFeed();
  }
}

Future _processCameraImage(CameraImage image) async {
  print('processing camera image');
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

  final camera = cameras[_cameraIndex];
  final imageRotation =
      InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  if (imageRotation == null) return;

  final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
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
}

Future<void> processImage(InputImage inputImage) async {
  if (!_canProcess) return;
  if (_isBusy) return;
  _isBusy = true;
  final faces = await _faceDetector.processImage(inputImage);
  for (Face face in faces) {
    rotX = face.headEulerAngleX; // Head is tilted up and down rotX degrees
    rotY = face.headEulerAngleY; // Head is rotated to the right rotY degrees
    rotZ = face.headEulerAngleZ; // Head is tilted sideways rotZ degrees
    smileProb = face.smilingProbability;
    leftEyeOpenProb = face.leftEyeOpenProbability;
    rightEyeOpenProb = face.rightEyeOpenProbability;
  }
  if (inputImage.inputImageData?.size != null &&
      inputImage.inputImageData?.imageRotation != null) {
  } else {
    String text = 'Faces found: ${faces.length}\n\n';
    for (final face in faces) {
      text += 'face: ${face.boundingBox}\n\n';
    }
    _text = text;
  }
  _isBusy = false;
}
