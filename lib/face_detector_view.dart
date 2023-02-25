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
  const FaceDetectorView({
    Key? key,
    required this.calibrationMode,
  }) : super(key: key);

  final bool calibrationMode;

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

  int caliSeconds = 5;
  Timer? periodicDetectionTimer, periodicCalibrationTimer;
  bool cancelTimer = false;
  bool _canProcess = true, _isBusy = false;
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

  void detectionTimer() {
    var rotXCounter = 0;
    var rotYCounter = 0;
    var eyeCounter = 0;
    var reminderCount = 0;
    periodicDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (faces.isNotEmpty) {
        if (rotX! < (globals.neutralRotX - 15) ||
            rotX! > (globals.neutralRotX + 15)) {
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
        if (rotY! < (globals.neutralRotY - 40) ||
            rotY! > (globals.neutralRotY + 40)) {
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
        if (rotX! > (globals.neutralRotX - 15) &&
            rotY! > (globals.neutralRotY - 40) &&
            rotY! < (globals.neutralRotY + 40) &&
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
  }

  void calibrationTimer() {
    periodicCalibrationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        globals.neutralRotX = rotX ?? 0;
        globals.neutralRotY = rotY ?? -35;
        caliSeconds--;
      });
      if (caliSeconds < 0) {
        setState(() {
          globals.hasCalibrated = true;
        });
        Navigator.pop(context);
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _assetsAudioPlayer.setVolume(0.75);
    periodicCalibrationTimer?.cancel();
    periodicDetectionTimer?.cancel();
    if (widget.calibrationMode == true) {
      calibrationTimer();
    } else if (widget.calibrationMode == false) {
      detectionTimer();
    }
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
              if (MediaQuery.of(context).orientation == Orientation.portrait)
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
                      //FaceValueWidget(text: "rotZ", value: rotZ),
                      FaceValueWidget(
                          text: "neutralRotX", value: globals.neutralRotX),
                      FaceValueWidget(
                          text: "neutralRotY", value: globals.neutralRotY),
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
        if (widget.calibrationMode == true)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Get into your normal driving position",
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 30)),
                Text(
                  caliSeconds < 1 ? "Complete!" : "$caliSeconds",
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (widget.calibrationMode == false)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(70),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Stop driving",
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 80),
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
