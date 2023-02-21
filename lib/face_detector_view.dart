import 'dart:async';
import 'dart:core';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'notification_controller.dart';

import 'camera_view.dart';
import 'face_detector_painter.dart';
import 'coordinates_translator.dart';
import 'global_variables.dart' as globals;

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.8,
    ),
  );

  bool _canProcess = true;
  bool _isBusy = false;
  bool cancelTimer = false;
  CustomPaint? _customPaint;
  String? _text;
  double? rotX, rotY, rotZ, leftEyeOpenProb, rightEyeOpenProb;
  List<Face> faces = [];

  void sendReminder() {
    _assetsAudioPlayer.open(
      Audio('assets/audio/car_horn.mp3'),
      playInBackground: PlayInBackground.enabled,
    );
    NotificationController.cancelNotifications();
    NotificationController.createNewReminderNotification();
  }

  @override
  void initState() {
    _assetsAudioPlayer.setVolume(0.5);

    var rotXCounter = 0;
    var rotYCounter = 0;
    var eyeCounter = 0;
    var reminderCount = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (faces.isNotEmpty) {
        if (rotX! < -15) {
          rotXCounter++;
        } else {
          rotXCounter = 0;
        }
        if (reminderCount < 3) {
          if (rotXCounter > 10) {
            sendReminder();
            reminderCount++;
            rotXCounter = 0;
          }
        }
        if (rotY! < -70 || rotY! > 10) {
          rotYCounter++;
        } else {
          rotYCounter = 0;
        }
        if (reminderCount < 3) {
          if (rotYCounter > 15) {
            sendReminder();
            reminderCount++;
            rotYCounter = 0;
          }
        }
        if (leftEyeOpenProb! < 0.5 && rightEyeOpenProb! < 0.5) {
          eyeCounter++;
        } else {
          eyeCounter = 0;
        }
        if (reminderCount < 3) {
          if (eyeCounter > 10) {
            sendReminder();
            reminderCount++;
            eyeCounter = 0;
          }
        }
        if (rotX! > -15 &&
            rotY! > -70 &&
            rotY! < 10 &&
            leftEyeOpenProb! > 0.5 &&
            rightEyeOpenProb! > 0.5) {
          reminderCount = 0;
        }
      }
      if (cancelTimer == true) {
        cancelTimer = false;
        timer.cancel();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _assetsAudioPlayer.dispose();
    cancelTimer = true;
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
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    FaceValueWidget(text: "rotX", value: rotX),
                    FaceValueWidget(text: "rotY", value: rotY),
                    FaceValueWidget(text: "rotZ", value: rotZ),
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
    faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      final face = faces[0];
      rotX = face.headEulerAngleX; // up and down rotX degrees
      rotY = face.headEulerAngleY; // right and left rotY degrees
      rotZ = face.headEulerAngleZ; // sideways rotZ degrees
      leftEyeOpenProb = face.leftEyeOpenProbability;
      rightEyeOpenProb = face.rightEyeOpenProbability;
      Size size = const Size(1.0, 1.0);
      if (inputImage.inputImageData?.size != null &&
          inputImage.inputImageData?.imageRotation != null) {
        globals.faceCenterX = calcFaceCenterX(
            translateX(
                face.boundingBox.left,
                inputImage.inputImageData!.imageRotation,
                size,
                inputImage.inputImageData!.size),
            translateX(
                face.boundingBox.right,
                inputImage.inputImageData!.imageRotation,
                size,
                inputImage.inputImageData!.size));
        globals.faceCenterY = calcFaceCenterY(
            translateY(
                face.boundingBox.top,
                inputImage.inputImageData!.imageRotation,
                size,
                inputImage.inputImageData!.size),
            translateY(
                face.boundingBox.bottom,
                inputImage.inputImageData!.imageRotation,
                size,
                inputImage.inputImageData!.size));
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
