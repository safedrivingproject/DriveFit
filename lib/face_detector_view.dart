import 'dart:async';
import 'dart:core';
import 'dart:html';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_view.dart';
import 'face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.8,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  double? rotX;
  double? rotY;
  double? rotZ;
  double? smileProb;
  double? leftEyeOpenProb;
  double? rightEyeOpenProb;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraView(
          title: 'Face Detector',
          customPaint: _customPaint,
          text: _text,
          onImage: (inputImage) {
            processImage(inputImage);
          },
          initialDirection: CameraLensDirection.front,
        ),
        Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              const SizedBox(
                height: 78,
              ),
              Container(
                width: double.infinity,
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    FaceValueWidget(text: "rotX", value: rotX),
                    FaceValueWidget(text: "rotY", value: rotY),
                    FaceValueWidget(text: "rotZ", value: rotZ),
                    FaceValueWidget(text: "smileProb", value: smileProb),
                    FaceValueWidget(
                        text: "leftEyeOpenProb", value: leftEyeOpenProb),
                    FaceValueWidget(
                        text: "rightEyeOpenProb", value: rightEyeOpenProb),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
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
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}

class FaceValueWidget extends StatelessWidget {
  const FaceValueWidget({
    Key? key,
    required this.text,
    required this.value,
  }) : super(key: key);

  final String text;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 50,
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: Theme.of(context).textTheme.displaySmall),
            Text(value.toString(),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
