import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'package:drive_fit/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '/theme/color_schemes.g.dart';
import 'camera_view.dart';
import '../notifications/notification_controller.dart';
import 'face_detector_painter.dart';
import 'coordinates_translator.dart';
import '../service/face_detection_service.dart';
import '../service/geolocation_service.dart';
import '../service/database_service.dart';
import 'drive_session_summary.dart';
import '/global_variables.dart' as globals;

class DrivingView extends StatefulWidget {
  const DrivingView({
    Key? key,
    required this.calibrationMode,
    this.accelerometerOn = false,
    required this.enableGeolocation,
  }) : super(key: key);

  final bool calibrationMode;
  final bool accelerometerOn;
  final bool enableGeolocation;

  @override
  State<DrivingView> createState() => _DrivingViewState();
}

class _DrivingViewState extends State<DrivingView> {
  final FaceDetectionService faceDetectionService = FaceDetectionService();
  final GeolocationService geolocationService = GeolocationService();
  final DatabaseService databaseService = DatabaseService();

  final AudioPlayer drowsyAudioPlayer = AudioPlayer();
  final AudioPlayer inattentiveAudioPlayer = AudioPlayer();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 1.0,
    ),
  );

  final MaterialStatesController _statesController = MaterialStatesController();

  int caliSeconds = 3;
  Timer? periodicDetectionTimer, periodicCalibrationTimer;
  bool carMoving = true;
  bool startCalibration = false;
  bool _canProcess = true, _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  bool showCameraPreview = true;
  double maxAccelThreshold = 1.0;

  bool _accelAvailable = false;
  List<double> accelData = List.filled(3, 0.0);
  StreamSubscription? _accelSubscription;
  double _rawAccelX = 0, _rawAccelY = 9.8, _rawAccelZ = 0;
  double accelX = 0, accelY = 0, accelZ = 0;

  SessionData currentSession = SessionData(
      id: 0,
      startTime: "",
      endTime: "",
      duration: 0,
      distance: 0.0,
      drowsyAlertCount: 0,
      inattentiveAlertCount: 0,
      score: 0);
  bool isValidSession = false;

  DateFormat noMillis = DateFormat("yyyy-MM-dd HH:mm:ss");
  DateFormat noSeconds = DateFormat("yyyy-MM-dd HH:mm");
  DateFormat noYearsSeconds = DateFormat("MM-dd HH:mm");

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// SHARED PREFERENCES
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        showCameraPreview = (prefs.getBool('showCameraPreview') ?? true);
        geolocationService.stationaryAlertsDisabled =
            (prefs.getBool('stationaryAlertsDisabled') ?? false);
        geolocationService.additionalDelay =
            (prefs.getInt('additionalDelay') ?? 20);
        globals.showDebug = (prefs.getBool('showDebug') ?? false);
        globals.hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
        faceDetectionService.neutralRotX =
            (prefs.getDouble('neutralRotX') ?? 5.0);
        faceDetectionService.neutralRotY =
            (prefs.getDouble('neutralRotY') ?? -25.0);
        faceDetectionService.rotYLeftOffset =
            (prefs.getDouble('rotYLeftOffset') ?? 20);
        faceDetectionService.rotYRightOffset =
            (prefs.getDouble('rotYRightOffset') ?? 10);
        faceDetectionService.rotXDelay = (prefs.getInt('rotXDelay') ?? 10);
        faceDetectionService.rotYDelay = (prefs.getInt('rotYDelay') ?? 25);
        geolocationService.carVelocityThreshold =
            (prefs.getDouble('carVelocityThreshold') ?? 5.0);
        globals.drowsyAlarmValue = (prefs.getStringList('drowsyAlarm') ??
            ["assets", "audio/car_horn_high.mp3"]);
        globals.inattentiveAlarmValue =
            (prefs.getStringList('inattentiveAlarm') ??
                ["assets", "audio/double_beep.mp3"]);
      });
    }
    initAudioPlayers();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setBool(key, value);
      });
    }
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setDouble(key, value);
      });
    }
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setInt(key, value);
      });
    }
  }

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// INIT & DISPOSE
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  void initAudioPlayers() {
    drowsyAudioPlayer.setSource(globals.drowsyAlarmValue[0] == "asset"
        ? AssetSource(globals.drowsyAlarmValue[1])
        : globals.drowsyAlarmValue[0] == "file"
            ? DeviceFileSource(globals.drowsyAlarmValue[1])
            : AssetSource("audio/car_horn_high.mp3"));
    drowsyAudioPlayer.setVolume(1.0);
    drowsyAudioPlayer.setReleaseMode(ReleaseMode.stop);
    inattentiveAudioPlayer.setSource(globals.inattentiveAlarmValue[0] == "asset"
        ? AssetSource(globals.inattentiveAlarmValue[1])
        : globals.inattentiveAlarmValue[0] == "file"
            ? DeviceFileSource(globals.inattentiveAlarmValue[1])
            : AssetSource("audio/double_beep.mp3"));
    inattentiveAudioPlayer.setVolume(1.0);
    inattentiveAudioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> saveCurrentPosition(Position? position) async {
    if (!geolocationService.hasPermission) return;
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  String saveCurrentTime(DateFormat format) {
    return format.format(DateTime.now());
  }

  void _initSessionData() {
    if (mounted) {
      setState(() {
        geolocationService.accumulatedDistance = 0.0;
        currentSession = SessionData(
            id: DateTime.now().millisecondsSinceEpoch,
            startTime: "",
            endTime: "",
            duration: 0,
            distance: widget.enableGeolocation
                ? geolocationService.accumulatedDistance
                : -1.0,
            drowsyAlertCount: 0,
            inattentiveAlertCount: 0,
            score: 0);
        currentSession.startTime = saveCurrentTime(noMillis);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    geolocationService.positionList.clear();
    geolocationService.speedList.clear();

    _loadSettings();

    periodicCalibrationTimer?.cancel();
    periodicDetectionTimer?.cancel();

    _initSessionData();

    _statesController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });

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
    if (widget.enableGeolocation) {
      geolocationService.startGeolocationStream();
    } else {
      carMoving = true;
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    periodicDetectionTimer?.cancel();
    periodicCalibrationTimer?.cancel();

    geolocationService.stopGeolocationStream();
    globals.inCalibrationMode = false;

    drowsyAudioPlayer.dispose();
    inattentiveAudioPlayer.dispose();

    _statesController.dispose();

    _faceDetector.close();
    _stopAccelerometer();
    super.dispose();
  }

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// INATTENTIVENESS DETECTION
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  void sendSleepyReminder() {
    drowsyAudioPlayer.resume();
    NotificationController.dismissAlertNotifications();
    NotificationController.createSleepyNotification();
  }

  void sendDistractedReminder() {
    inattentiveAudioPlayer.resume();
    NotificationController.dismissAlertNotifications();
    NotificationController.createDistractedNotification();
  }

  void detectionTimer() async {
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _statesController.update(MaterialState.disabled, true);
    });
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      _statesController.update(MaterialState.disabled, false);
    }
    periodicDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          faceDetectionService.checkHasFace();
        });
      }

      if (!faceDetectionService.hasFace) return;

      if (mounted) {
        setState(() {
          faceDetectionService.checkEyesClosed();
          faceDetectionService.checkNormalPosition();
        });
      }

      if (widget.enableGeolocation) {
        if (mounted) {
          setState(() {
            carMoving = geolocationService.checkCarMoving();
          });
        }
      } else {
        carMoving = true;
      }

      if (geolocationService.stationaryAlertsDisabled) {
        if (carMoving) {
          if (mounted) {
            setState(() {
              faceDetectionService
                  .checkHeadUpDown(faceDetectionService.rotXDelay);
              faceDetectionService
                  .checkHeadLeftRight(faceDetectionService.rotYDelay);
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            faceDetectionService.checkHeadUpDown(
                faceDetectionService.rotXDelay +
                    (!carMoving ? geolocationService.additionalDelay : 0));
            faceDetectionService.checkHeadLeftRight(
                faceDetectionService.rotYDelay +
                    (!carMoving ? geolocationService.additionalDelay : 0));
          });
        }
      }

      if (faceDetectionService.reminderType == "Drowsy") {
        sendSleepyReminder();
        if (mounted) {
          setState(() {
            if (faceDetectionService.hasReminded == false) {
              currentSession.drowsyAlertCount++;
              faceDetectionService.hasReminded = true;
            }
            faceDetectionService.reminderType = "None";
          });
        }
      } else if (faceDetectionService.reminderType == "Inattentive") {
        sendDistractedReminder();
        if (mounted) {
          setState(() {
            if (faceDetectionService.hasReminded == false) {
              currentSession.inattentiveAlertCount++;
              faceDetectionService.hasReminded = true;
            }
            faceDetectionService.reminderType = "None";
          });
        }
      }
    });
  }

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// CALIBRATION
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  void calibrationTimer() {
    var liveRotXList = <double>[], liveRotYList = <double>[];
    int timeCounter = 0;
    if (mounted) {
      setState(() {
        startCalibration = true;
      });
    }
    periodicCalibrationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      timeCounter++;
      if (timeCounter % 10 == 0) {
        caliSeconds--;
      }
      if (caliSeconds < 0) {
        if (mounted) {
          setState(() {
            _saveBool('hasCalibrated', true);
            _saveDouble('neutralRotX', faceDetectionService.neutralRotX);
            _saveDouble('neutralRotY', faceDetectionService.neutralRotY);
            _saveDouble('rotYLeftOffset', faceDetectionService.rotYLeftOffset);
            _saveDouble(
                'rotYRightOffset', faceDetectionService.rotYRightOffset);
            startCalibration = false;
          });
          showSnackBar(context, "Calibration complete!");
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const HomePage(
                    title: globals.appName,
                    index: 0,
                  )));

          timer.cancel();
        }
      } else {
        liveRotXList.add(faceDetectionService.rotX ?? 5);
        if (liveRotXList.length > 10) {
          liveRotXList.removeAt(0);
        }
        liveRotYList.add(faceDetectionService.rotY ?? -25);
        if (liveRotYList.length > 10) {
          liveRotYList.removeAt(0);
        }
        if (mounted) {
          setState(() {
            faceDetectionService.neutralRotX = average(liveRotXList);
            faceDetectionService.neutralRotY = average(liveRotYList);
            globals.neutralAccelX = _rawAccelX;
            globals.neutralAccelY = _rawAccelY;
            globals.neutralAccelZ = _rawAccelZ;
            calcRotYOffsets();
          });
        }
      }
    });
  }

  void calcRotYOffsets() {
    var neutralY = faceDetectionService.neutralRotY;
    var leftOffset = 15.0;
    var rightOffset = 15.0;
    if (neutralY <= 0) {
      leftOffset = 15 + (neutralY.abs() / 8);
      rightOffset = 15 - (neutralY.abs() / 10);
    } else if (neutralY > 0) {
      leftOffset = 15 - (neutralY.abs() / 10);
      rightOffset = 15 + (neutralY.abs() / 8);
    }
    faceDetectionService.rotYLeftOffset = leftOffset;
    faceDetectionService.rotYRightOffset = rightOffset;
  }

  double average(List<double> list) {
    var result = 0.0;
    var count = 0;
    for (var value in list) {
      count += 1;
      result += (value - result) / count;
    }
    if (count == 0) throw StateError('No elements');
    return result;
  }

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// ACCELEROMETER STUFF
  ///
  /// *******************************************************
  /// *******************************************************
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
  /// *******************************************************
  /// *******************************************************
  ///
  /// FACE DETECTION
  ///
  /// *******************************************************
  /// *******************************************************
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

    faceDetectionService.faces = await _faceDetector.processImage(inputImage);
    if (faceDetectionService.faces.isNotEmpty) {
      final face = faceDetectionService.faces[0];
      faceDetectionService.rotX =
          face.headEulerAngleX; // up and down rotX degrees
      faceDetectionService.rotY =
          face.headEulerAngleY; // right and left rotY degrees
      // rotZ = face.headEulerAngleZ; // sideways rotZ degrees
      faceDetectionService.leftEyeOpenProb = face.leftEyeOpenProbability;
      faceDetectionService.rightEyeOpenProb = face.rightEyeOpenProbability;

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
            faceDetectionService.faces,
            inputImage.inputImageData!.size,
            inputImage.inputImageData!.imageRotation);
        _customPaint = CustomPaint(painter: painter);
      } else {
        String text = 'Faces found: ${faceDetectionService.faces.length}\n\n';
        for (final face in faceDetectionService.faces) {
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
  /// *******************************************************
  /// *******************************************************
  ///
  /// WIDGET BUILD
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.calibrationMode) {
          return true;
        } else {
          return false;
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.calibrationMode ? "Calibrate" : "Driving",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: lightColorScheme.onPrimary),
            ),
            iconTheme: IconThemeData(color: lightColorScheme.onPrimary),
            automaticallyImplyLeading: false,
            leading: !widget.calibrationMode
                ? null
                : IconButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.arrow_back)),
            centerTitle: true,
            backgroundColor: lightColorScheme.primary,
          ),
          body: Stack(
            children: [
              CameraView(
                customPaint: showCameraPreview ? _customPaint : null,
                text: _text,
                onImage: (inputImage) {
                  processImage(inputImage);
                },
                initialDirection: CameraLensDirection.front,
              ),
              if (globals.showDebug == true)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          DataValueWidget(
                              text: "rotX",
                              doubleValue: faceDetectionService.rotX),
                          DataValueWidget(
                              text: "rotY",
                              doubleValue: faceDetectionService.rotY),
                          DataValueWidget(
                              text: "neutralRotX",
                              doubleValue: faceDetectionService.neutralRotX),
                          DataValueWidget(
                              text: "neutralRotY",
                              doubleValue: faceDetectionService.neutralRotY),
                          DataValueWidget(
                              text: "leftEyeOpenProb",
                              doubleValue:
                                  faceDetectionService.leftEyeOpenProb),
                          DataValueWidget(
                              text: "rightEyeOpenProb",
                              doubleValue:
                                  faceDetectionService.rightEyeOpenProb),
                          DataValueWidget(
                              text: "leftOffset",
                              doubleValue: faceDetectionService.rotYLeftOffset),
                          DataValueWidget(
                              text: "rightOffset",
                              doubleValue:
                                  faceDetectionService.rotYRightOffset),
                          DataValueWidget(
                              text: "reminderType",
                              stringValue: faceDetectionService.reminderType),
                          DataValueWidget(
                              text: "drowsyAlertCount",
                              intValue: currentSession.drowsyAlertCount),
                          DataValueWidget(
                              text: "inattentiveAlertCount",
                              intValue: currentSession.inattentiveAlertCount),
                          DataValueWidget(
                              text: "carMoving", boolValue: carMoving),
                          if (widget.accelerometerOn == true)
                            Column(
                              children: [
                                DataValueWidget(
                                    text: "resultantAccel",
                                    doubleValue: globals.resultantAccel),
                                DataValueWidget(
                                    text: "accelX", doubleValue: accelX),
                                DataValueWidget(
                                    text: "accelY", doubleValue: accelY),
                                DataValueWidget(
                                    text: "accelZ", doubleValue: accelZ),
                              ],
                            ),
                          if (geolocationService.positionList.isNotEmpty)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 150,
                                    child: ListView.builder(
                                      itemCount: geolocationService
                                          .positionList.length,
                                      itemBuilder: (context, index) {
                                        final positionItem = geolocationService
                                            .positionList[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          color: lightColorScheme.secondary,
                                          alignment: Alignment.center,
                                          child: Center(
                                            child: SizedBox(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    positionItem.latitude
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  const SizedBox(
                                                    width: 2,
                                                  ),
                                                  Text(
                                                    positionItem.longitude
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  const SizedBox(
                                                    width: 2,
                                                  ),
                                                  Text(
                                                    positionItem.speed
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  const SizedBox(
                                                    width: 2,
                                                  ),
                                                  Text(
                                                    positionItem.timestamp
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      shrinkWrap: true,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                if (geolocationService.speedList.isNotEmpty)
                                  Expanded(
                                    child: SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        itemCount:
                                            geolocationService.speedList.length,
                                        itemBuilder: (context, index) {
                                          final speedItem = geolocationService
                                              .speedList[index];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            color: lightColorScheme.secondary,
                                            alignment: Alignment.center,
                                            child: Center(
                                              child: SizedBox(
                                                child: Wrap(
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.start,
                                                  children: [
                                                    Text(
                                                      speedItem.toString(),
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        shrinkWrap: true,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else if (geolocationService.positionList.isEmpty)
                            SizedBox(
                              height: 75,
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                child: Text(
                                  "No positions",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16.0))),
                              backgroundColor: lightColorScheme.primary,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  currentSession.distance += 1000;
                                });
                              }
                            },
                            child: Text(
                              "Add distance (debug only)",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: lightColorScheme.onPrimary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (widget.calibrationMode == true)
                Column(
                  children: [
                    if (!globals.showDebug)
                      CalibrateInstructionList(
                          startCalibration: startCalibration,
                          caliSeconds: caliSeconds),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16.0))),
                              backgroundColor: lightColorScheme.primary,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: () {
                              if (startCalibration == false) {
                                calibrationTimer();
                              }
                            },
                            child: Text(
                              "Calibrate",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: lightColorScheme.onPrimary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                )
              else if (widget.calibrationMode == false)
                Stack(
                  children: [
                    Column(
                      children: [
                        const Spacer(),
                        if (!globals.showDebug)
                          PageCenterText(showCameraPreview: showCameraPreview),
                        const Spacer(),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16.0))),
                              backgroundColor: lightColorScheme.primary,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            statesController: _statesController,
                            onPressed: () {
                              _saveSessionData();
                              isValidSession = _validateSession();
                              if (isValidSession) {
                                databaseService.saveSessionData(currentSession);
                              }
                              Navigator.of(context).pop(true);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => DriveSessionSummary(
                                        session: currentSession,
                                        isValidSession: isValidSession,
                                      )));
                            },
                            child: Text(
                              "Stop driving",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: lightColorScheme.onPrimary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!globals.showDebug) const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          )),
    );
  }

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// OTHER UTILS
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  void showSnackBar(BuildContext context, String text) {
    var snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  int calcDrivingScore() {
    if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (1 / 600) &&
        (currentSession.inattentiveAlertCount / currentSession.duration) <=
            (1 / 600)) {
      return 5;
    } else if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (3 / 600) ||
        (currentSession.inattentiveAlertCount / currentSession.duration) <=
            (3 / 600)) {
      return 4;
    } else if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (5 / 600) &&
        (currentSession.inattentiveAlertCount / currentSession.duration) <=
            (5 / 600)) {
      return 3;
    } else if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (7 / 600) &&
        (currentSession.inattentiveAlertCount / currentSession.duration) <=
            (7 / 600)) {
      return 2;
    } else if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (9 / 600) &&
        (currentSession.inattentiveAlertCount / currentSession.duration) <=
            (9 / 600)) {
      return 1;
    } else {
      return 0;
    }
  }

  Future<void> _saveSessionData() async {
    if (mounted) {
      setState(() {
        currentSession.endTime = saveCurrentTime(noMillis);
        currentSession.duration = DateTime.parse(currentSession.endTime)
            .difference(DateTime.parse(currentSession.startTime))
            .inSeconds;
        currentSession.distance += geolocationService.accumulatedDistance;
        currentSession.score = calcDrivingScore();
      });
    }
  }

  bool _validateSession() {
    if (currentSession.distance < 500 || currentSession.duration < 60) {
      return false;
    }
    return true;
  }
}

class PageCenterText extends StatelessWidget {
  const PageCenterText({
    super.key,
    required this.showCameraPreview,
  });

  final bool showCameraPreview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.security,
              size: 69,
              color: showCameraPreview
                  ? lightColorScheme.onPrimary
                  : lightColorScheme.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "You are now protected!",
              style: showCameraPreview
                  ? Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: lightColorScheme.onPrimary)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              "Drive Safely!",
              style: showCameraPreview
                  ? Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(color: lightColorScheme.onPrimary)
                  : Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class CalibrateInstructionList extends StatelessWidget {
  const CalibrateInstructionList({
    super.key,
    required this.startCalibration,
    required this.caliSeconds,
  });

  final bool startCalibration;
  final int caliSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          color: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.all(30),
          child: Column(
            children: const [
              CalibrateInstruction(
                bullet: "1.",
                instruction: "Secure your phone in the phone holder",
              ),
              SizedBox(height: 5),
              CalibrateInstruction(
                bullet: "2.",
                instruction:
                    "Make sure your head is visible in the camera preview",
              ),
              SizedBox(height: 5),
              CalibrateInstruction(
                bullet: "3.",
                instruction:
                    "Look forward towards the road (just like when you are driving attentively)",
              ),
              SizedBox(height: 5),
              CalibrateInstruction(
                bullet: "4.",
                instruction: "Press 'Calibrate' and wait 3 seconds",
              ),
            ],
          ),
        ),
        if (startCalibration == true)
          Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(15),
            child: Text(
              caliSeconds < 1 ? "Complete!" : "$caliSeconds",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: lightColorScheme.onPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class CalibrateInstruction extends StatelessWidget {
  const CalibrateInstruction({
    super.key,
    required this.bullet,
    required this.instruction,
  });

  final String bullet;
  final String instruction;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            bullet,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: lightColorScheme.onPrimary),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 10,
          child: Text(
            instruction,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: lightColorScheme.onPrimary),
            textAlign: TextAlign.left,
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
    this.doubleValue,
    this.intValue,
    this.boolValue,
    this.stringValue,
  }) : super(key: key);

  final String text;
  final double? doubleValue;
  final int? intValue;
  final bool? boolValue;
  final String? stringValue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 40,
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: lightColorScheme.onPrimary)),
            Text(
                doubleValue != null
                    ? doubleValue.toString()
                    : intValue != null
                        ? intValue.toString()
                        : boolValue != null
                            ? boolValue.toString()
                            : stringValue.toString(),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: lightColorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}
