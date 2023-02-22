import 'dart:core';
import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
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
  AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: true,
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
  List<Face> faces = [];
  bool cancelTimer = false;

  void sendReminder() {
    _assetsAudioPlayer.open(
      Audio('assets/audio/car_horn.mp3'),
      playInBackground: PlayInBackground.enabled,
    );
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
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("rotX",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text(rotX.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("rotY",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text(rotY.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("rotZ",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text(rotZ.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("smileProb",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text(smileProb.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("leftEyeOpenProb",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text(leftEyeOpenProb.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("rightEyeOpenProb",
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text(rightEyeOpenProb.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
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
      Face face = faces[0];
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
