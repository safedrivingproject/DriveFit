import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';

import '/home/home_page.dart';
import 'camera_view.dart';
import '/notification_controller.dart';
import 'driving_view.dart';
import 'face_detector_painter.dart';
import 'coordinates_translator.dart';
import '/global_variables.dart' as globals;

class DrivingLogic extends StatefulWidget {
  const DrivingLogic({
    Key? key,
    required this.calibrationMode,
    required this.accelerometerOn,
  }) : super(key: key);

  final bool calibrationMode;
  final bool accelerometerOn;

  @override
  State<DrivingLogic> createState() => DrivingLogicState();
}

class DrivingLogicState extends State<DrivingLogic> {
  final AudioPlayer audioPlayer = AudioPlayer();
  // StreamSubscription? audioSubscription;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.8,
    ),
  );

  int caliSeconds = 3;
  Timer? periodicDetectionTimer, periodicCalibrationTimer;
  bool cancelTimer = false;
  bool carMoving = false;

  bool _canProcess = true, _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  double? rotX = globals.neutralRotX,
      rotY = globals.neutralRotY,
      rotZ = 0,
      leftEyeOpenProb = 1.0,
      rightEyeOpenProb = 1.0;
  double maxAccelThreshold = 1.0;
  List<Face> faces = [];

  bool startCalibration = false;

  bool _accelAvailable = false;
  List<double> accelData = List.filled(3, 0.0);
  StreamSubscription? _accelSubscription;
  double _rawAccelX = 0, _rawAccelY = 9.8, _rawAccelZ = 0;
  double accelX = 0, accelY = 0, accelZ = 0;

  /// *******************************************************
  /// SHARED PREFERENCES
  /// *******************************************************
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        globals.useAccelerometer = (prefs.getBool('useAccelerometer') ?? false);
        globals.showCameraPreview =
            (prefs.getBool('showCameraPreview') ?? true);
        globals.useHighCameraResolution =
            (prefs.getBool('useHighCameraResolution') ?? false);
        globals.showDebug = (prefs.getBool('showDebug') ?? false);
        globals.hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
      });
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setBool(key, value);
      });
    }
  }

  /// *******************************************************
  /// INIT & DISPOSE
  /// *******************************************************
  @override
  void initState() {
    super.initState();
    audioPlayer.setSource(AssetSource('audio/car_horn_high.mp3'));
    audioPlayer.setVolume(1.0);
    audioPlayer.setReleaseMode(ReleaseMode.stop);
    _loadSettings();
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
    NotificationController.dismissAlertNotifications();
    NotificationController.createSleepyNotification();
  }

  void sendDistractedReminder() {
    audioPlayer.resume();
    NotificationController.dismissAlertNotifications();
    NotificationController.createDistractedNotification();
  }

  void detectionTimer() {
    int rotXTimerCounter = 0;
    int rotYCounter = 0;
    int eyeCounter = 0;
    int accelMovingCounter = 0;
    int accelStoppedCounter = 0;
    int faceEmptyCounter = 0;
    bool hasFace = true;
    int needReminderType = 0;
    var liveAccelList = List<double>.filled(10, 0);
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
        liveAccelList.add(globals.resultantAccel);
        if (liveAccelList.length > 10) {
          liveAccelList.removeAt(0);
        }
        maxAccel = liveAccelList.fold<double>(0, max);
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
      if (leftEyeOpenProb! < globals.eyeProbThreshold &&
          rightEyeOpenProb! < globals.eyeProbThreshold) {
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

      /// Restored normal position
      if (rotX! > (globals.neutralRotX - globals.rotXOffset) &&
          rotX! < (globals.neutralRotX + globals.rotXOffset) &&
          rotY! > (globals.neutralRotY - globals.rotYRightOffset) &&
          rotY! < (globals.neutralRotY + globals.rotYLeftOffset) &&
          leftEyeOpenProb! > globals.eyeProbThreshold &&
          rightEyeOpenProb! > globals.eyeProbThreshold) {
        reminderCount = 0;
      }

      if (cancelTimer == true) {
        cancelTimer = false;
        timer.cancel();
      }

      if (!carMoving) return;

      /// Head up or down
      if (rotX! < (globals.neutralRotX - globals.rotXOffset) ||
          rotX! > (globals.neutralRotX + globals.rotXOffset)) {
        rotXTimerCounter++;
      } else {
        rotXTimerCounter = 0;
      }
      if (reminderCount < 3) {
        if (rotXTimerCounter > 10) {
          needReminderType = 2;
          reminderCount++;
          rotXTimerCounter = 0;
        }
      }

      /// Head Left or Right
      if (rotY! > (globals.neutralRotY + globals.rotYLeftOffset) ||
          rotY! < (globals.neutralRotY - globals.rotYRightOffset)) {
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
      caliSeconds--;
      if (caliSeconds < 0) {
        if (mounted) {
          setState(() {
            _saveBool('hasCalibrated', true);
            startCalibration = false;
          });
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return const HomePage(title: globals.appName);
          }));
          timer.cancel();
        } else {
          if (mounted) {
            setState(() {
              globals.neutralRotX = rotX ?? 5;
              globals.neutralRotY = rotY ?? -25;
              globals.neutralAccelX = _rawAccelX;
              globals.neutralAccelY = _rawAccelY;
              globals.neutralAccelZ = _rawAccelZ;
              if (globals.neutralRotY <= 0) {
                globals.rotYLeftOffset = 25;
                globals.rotYRightOffset = 20;
              } else if (globals.neutralRotY > 0) {
                globals.rotYLeftOffset = 20;
                globals.rotYRightOffset = 25;
              }
            });
          }
        }
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
    return Scaffold(
        appBar: AppBar(
          title: Text(
            globals.inCalibrationMode ? "Calibrate" : "Driving",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: lightColorScheme.onPrimary),
          ),
          iconTheme: IconThemeData(color: lightColorScheme.onPrimary),
          leading: !widget.calibrationMode
              ? null
              : IconButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (context) {
                      return const HomePage(title: globals.appName);
                    }));
                  },
                  icon: const Icon(Icons.arrow_back)),
          centerTitle: true,
          backgroundColor: lightColorScheme.primary,
        ),
        body: Stack(
          children: [
            CameraView(
              customPaint: _customPaint,
              text: _text,
              onImage: (inputImage) {
                processImage(inputImage);
              },
              initialDirection: CameraLensDirection.front,
            ),
            DrivingView(
                calibrationMode: widget.calibrationMode,
                accelerometerOn: widget.accelerometerOn),
          ],
        ));
  }
}
