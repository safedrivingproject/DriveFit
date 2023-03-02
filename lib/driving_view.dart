import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sensors/flutter_sensors.dart';

import 'notification_controller.dart';
import 'camera_view.dart';
import 'face_detector_painter.dart';
import 'coordinates_translator.dart';
import 'global_variables.dart' as globals;

class DrivingView extends StatefulWidget {
  const DrivingView({
    Key? key,
    required this.calibrationMode,
    required this.accelerometerOn,
  }) : super(key: key);

  final bool calibrationMode;
  final bool accelerometerOn;

  @override
  State<DrivingView> createState() => _DrivingViewState();
}

class _DrivingViewState extends State<DrivingView> {
  final AudioPlayer audioPlayer = AudioPlayer();
  // StreamSubscription? audioSubscription;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.8,
    ),
  );

  int caliSeconds = 5;
  Timer? periodicDetectionTimer, periodicCalibrationTimer;
  bool cancelTimer = false;
  bool carMoving = false;

  bool _canProcess = true, _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  double? rotX = 0,
      rotY = globals.neutralRotX,
      rotZ = globals.neutralRotY,
      leftEyeOpenProb = 1.0,
      rightEyeOpenProb = 1.0;
  double rotXOffset = 20,
      rotYLeftOffset = 25,
      rotYRightOffset = 30,
      eyeProbThreshold = 0.3,
      maxAccelThreshold = 1.0;
  List<Face> faces = [];

  bool startCalibration = false;

  bool _accelAvailable = false;
  List<double> accelData = List.filled(3, 0.0);
  StreamSubscription? _accelSubscription;
  double _rawAccelX = 0, _rawAccelY = 9.8, _rawAccelZ = 0;
  double accelX = 0, accelY = 0, accelZ = 0;
  var tempAccelList = <double>[];

  /// *******************************************************
  /// INIT & DISPOSE
  /// *******************************************************
  @override
  void initState() {
    super.initState();
    audioPlayer.setSource(AssetSource('audio/car_horn_high.mp3'));
    audioPlayer.setVolume(1.0);
    audioPlayer.setReleaseMode(ReleaseMode.stop);

    periodicCalibrationTimer?.cancel();
    periodicDetectionTimer?.cancel();
    if (widget.calibrationMode == true) {
      if (mounted) {
        setState(() {
          globals.inCalibrationMode = true;
        });
      }
    } else if (widget.calibrationMode == false) {
      detectionTimer();
    }
    if (widget.accelerometerOn) {
      _initAccelerometer();
    }

    // audioSubscription = audioPlayer.onPlayerComplete.listen((event) {
    //   setState(() {
    //     audioPlayer.stop();
    //   });
    // });
  }

  @override
  void dispose() {
    _canProcess = false;
    cancelTimer = true;
    globals.inCalibrationMode = false;
    // audioSubscription?.cancel();
    audioPlayer.dispose();
    _faceDetector.close();
    _stopAccelerometer();
    super.dispose();
  }

  /// *******************************************************
  /// INATTENTIVENESS DETECTION
  /// *******************************************************
  void sendSleepyReminder() {
    audioPlayer.resume();
    NotificationController.createSleepyNotification();
  }

  void sendDistractedReminder() {
    audioPlayer.resume();
    NotificationController.createDistractedNotification();
  }

  void detectionTimer() {
    var rotXCounter = 0;
    var rotYCounter = 0;
    var eyeCounter = 0;
    var accelMovingCounter = 0;
    var accelStoppedCounter = 0;
    var faceEmptyCounter = 0;
    var hasFace = true;
    var needReminderType = 0;
    // ReminderType => 0: No need reminder, 1: Sleepy (Eyes Closed), 2: Distracted(Head rotation)
    double maxAccel = 0;
    var reminderCount = 0;
    periodicDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // if (faces.isEmpty) return; (will lead to inaccurate detection)
      if (faces.isEmpty) {
        faceEmptyCounter++;
      } else {
        faceEmptyCounter = 0;
        if (mounted) {
          setState(() {
            hasFace = true;
          });
        }
      }
      if (faceEmptyCounter > 50) {
        if (mounted) {
          setState(() {
            hasFace = false;
          });
        }
      }
      if (!hasFace) return;

      ///TODO: replace with GPS
      if (widget.accelerometerOn) {
        tempAccelList.add(globals.resultantAccel);
        if (tempAccelList.length > 10) {
          tempAccelList.removeAt(0);
        }
        maxAccel = tempAccelList.fold<double>(0, max);
        if (maxAccel > maxAccelThreshold) {
          accelMovingCounter++;
        } else {
          accelMovingCounter = 0;
        }
        if (accelMovingCounter > 20) {
          if (mounted) {
            setState(() {
              carMoving = true;
            });
          }
        }
        if (maxAccel <= maxAccelThreshold) {
          accelStoppedCounter++;
        } else {
          accelStoppedCounter = 0;
        }
        if (accelStoppedCounter > 20) {
          if (mounted) {
            setState(() {
              carMoving = false;
            });
          }
        }
      } else {
        carMoving = true;
      }

      /// Eyes Closed
      if (leftEyeOpenProb! < eyeProbThreshold &&
          rightEyeOpenProb! < eyeProbThreshold) {
        eyeCounter++;
      } else {
        eyeCounter = 0;
      }
      if (reminderCount < 3) {
        if (eyeCounter > 10) {
          needReminderType = 1;
          reminderCount++;
          eyeCounter = 0;
        }
      }

      if (rotX! > (globals.neutralRotX - rotXOffset) &&
          rotX! < (globals.neutralRotX + rotXOffset) &&
          rotY! > (globals.neutralRotY - rotYRightOffset) &&
          rotY! < (globals.neutralRotY + rotYLeftOffset) &&
          leftEyeOpenProb! > eyeProbThreshold &&
          rightEyeOpenProb! > eyeProbThreshold) {
        reminderCount = 0;
      }

      if (cancelTimer == true) {
        cancelTimer = false;
        timer.cancel();
      }

      if (!carMoving) return;

      /// Head up or down
      if (rotX! < (globals.neutralRotX - rotXOffset) ||
          rotX! > (globals.neutralRotX + rotXOffset)) {
        rotXCounter++;
      } else {
        rotXCounter = 0;
      }
      if (reminderCount < 3) {
        if (rotXCounter > 10) {
          needReminderType = 2;
          reminderCount++;
          rotXCounter = 0;
        }
      }

      /// Head Left or Right
      if (rotY! > (globals.neutralRotY + rotYLeftOffset) ||
          rotY! < (globals.neutralRotY - rotYRightOffset)) {
        rotYCounter++;
      } else {
        rotYCounter = 0;
      }
      if (reminderCount < 3) {
        if (rotYCounter > 25) {
          needReminderType = 2;
          reminderCount++;
          rotYCounter = 0;
        }
      }

      if (needReminderType > 0) {
        if (needReminderType == 1) {
          sendSleepyReminder();
        } else if (needReminderType == 2) {
          sendDistractedReminder();
        }
        needReminderType = 0;
      }
    });
  }

  /// *******************************************************
  /// CALIBRATION
  /// *******************************************************
  void calibrationTimer() {
    if (mounted) {
      setState(() {
        startCalibration = true;
      });
    }
    periodicCalibrationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          globals.neutralRotX = rotX ?? 5;
          globals.neutralRotY = rotY ?? -25;
          globals.neutralAccelX = _rawAccelX;
          globals.neutralAccelY = _rawAccelY;
          globals.neutralAccelZ = _rawAccelZ;
          caliSeconds--;
        });
      }
      if (caliSeconds < 0) {
        if (mounted) {
          setState(() {
            globals.hasCalibrated = true;
            startCalibration = false;
          });
        }
        Navigator.pop(context);
        timer.cancel();
      }
    });
  }

  /// *******************************************************
  /// ACCELEROMETER STUFF
  /// *******************************************************
  void _initAccelerometer() async {
    await SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result) {
      if (mounted) {
        setState(() {
          _accelAvailable = result;
        });
      }
      _startAccelerometer();
    });
  }

  Future<void> _startAccelerometer() async {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: Sensors.SENSOR_DELAY_GAME,
      );
      _accelSubscription = stream.listen((sensorEvent) {
        if (mounted) {
          setState(() {
            accelData = sensorEvent.data;
            _rawAccelX = accelData[0];
            _rawAccelY = accelData[1];
            _rawAccelZ = accelData[2];
            accelX = _rawAccelX - globals.neutralAccelX;
            accelY = _rawAccelY - globals.neutralAccelY;
            accelZ = _rawAccelZ - globals.neutralAccelZ;
            globals.resultantAccel = calcResultantAccel();
          });
        }
      });
    }
  }

  void _stopAccelerometer() {
    if (_accelSubscription == null) return;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  double calcResultantAccel() {
    return sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
  }

  /// *******************************************************
  /// FACE DETECTION
  /// *******************************************************
  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    if (mounted) {
      setState(() {
        _text = '';
      });
    }
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

  /// *******************************************************
  /// WIDGET BUILD
  /// *******************************************************

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
        Column(
          children: [
            const SizedBox(
              height: 78,
            ),
            if (MediaQuery.of(context).orientation == Orientation.portrait)
              Column(
                children: [
                  if (globals.showDebug)
                    Container(
                      width: double.infinity,
                      height: widget.accelerometerOn ? 700 : 350,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          DataValueWidget(text: "rotX", value: rotX),
                          DataValueWidget(text: "rotY", value: rotY),
                          //FaceValueWidget(text: "rotZ", value: rotZ),
                          DataValueWidget(
                              text: "neutralRotX", value: globals.neutralRotX),
                          DataValueWidget(
                              text: "neutralRotY", value: globals.neutralRotY),
                          DataValueWidget(
                              text: "leftEyeOpenProb", value: leftEyeOpenProb),
                          DataValueWidget(
                              text: "rightEyeOpenProb",
                              value: rightEyeOpenProb),
                          if (widget.accelerometerOn == true)
                            Column(
                              children: [
                                DataValueWidget(
                                    text: "carMoving",
                                    value: carMoving ? 1 : 0),
                                DataValueWidget(
                                    text: "resultantAccel",
                                    value: globals.resultantAccel),
                                DataValueWidget(text: "accelX", value: accelX),
                                DataValueWidget(text: "accelY", value: accelY),
                                DataValueWidget(text: "accelZ", value: accelZ),
                              ],
                            )
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
        if (widget.calibrationMode == true)
          Stack(
            children: [
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
                        if (startCalibration == false) {
                          calibrationTimer();
                        }
                      },
                      child: Text(
                        "Calibrate",
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      "Please look straight and get into normal driving position",
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (startCalibration == true)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black.withOpacity(0.5),
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        caliSeconds < 1 ? "Complete!" : "$caliSeconds",
                        style: Theme.of(context).textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ],
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
}

class DataValueWidget extends StatelessWidget {
  const DataValueWidget({
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
