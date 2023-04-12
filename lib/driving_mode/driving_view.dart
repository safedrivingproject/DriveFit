import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'package:drive_fit/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '/theme/color_schemes.g.dart';
import 'camera_view.dart';
import '../notifications/notification_controller.dart';
import 'face_detector_painter.dart';
import 'coordinates_translator.dart';
import '../service/face_detection_service.dart';
import '../service/geolocation_service.dart';
import '../service/database_service.dart';
import '../service/shared_preferences_service.dart';
import '../service/ranking_service.dart';
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
  final RankingService rankingService = RankingService();

  final AudioPlayer drowsyAudioPlayer = AudioPlayer();
  final AudioPlayer inattentiveAudioPlayer = AudioPlayer();
  final AudioPlayer passengerAudioPlayer = AudioPlayer();

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
  bool showCameraPreview = false;

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
    score: 0,
    drowsyAlertTimestampsList: [],
    inattentiveAlertTimestampsList: [],
  );
  int restReminderTime = 3600;
  bool isValidSession = false;
  bool canExit = false;
  bool wakeLockEnabled = false;

  DateFormat noMillis = DateFormat("yyyy-MM-dd HH:mm:ss");
  DateFormat noSeconds = DateFormat("yyyy-MM-dd HH:mm");
  DateFormat noYearsSeconds = DateFormat("MM-dd HH:mm");

  String text = "Stop service";

  bool isReminding = false;
  var opacityTweenSequence = <TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: ConstantTween<double>(0.0),
      weight: 50.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutExpo)),
      weight: 50.0,
    ),
  ];

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
    if (mounted) {
      setState(() {
        faceDetectionService.isReminding = false;
        showCameraPreview =
            SharedPreferencesService.getBool('showCameraPreview', false);
        geolocationService.stationaryAlertsDisabled =
            SharedPreferencesService.getBool('stationaryAlertsDisabled', false);
        geolocationService.additionalDelay =
            SharedPreferencesService.getInt('additionalDelay', 20);
        globals.showDebug =
            SharedPreferencesService.getBool('showDebug', false);
        globals.hasCalibrated =
            SharedPreferencesService.getBool('hasCalibrated', false);
        faceDetectionService.neutralRotX =
            SharedPreferencesService.getDouble('neutralRotX', 5.0);
        faceDetectionService.neutralRotY =
            SharedPreferencesService.getDouble('neutralRotY', -25.0);
        faceDetectionService.rotYLeftOffset =
            SharedPreferencesService.getDouble('rotYLeftOffset', 20.0);
        faceDetectionService.rotYRightOffset =
            SharedPreferencesService.getDouble('rotYRightOffset', 10.0);
        faceDetectionService.rotXDelay =
            SharedPreferencesService.getInt('rotXDelay', 10);
        faceDetectionService.rotYDelay =
            SharedPreferencesService.getInt('rotYDelay', 25);
        geolocationService.carVelocityThreshold =
            SharedPreferencesService.getDouble('carVelocityThreshold', 8.3);
        globals.drowsyAlarmValue = SharedPreferencesService.getStringList(
            'drowsyAlarm', ["assets", "audio/car_horn_high.mp3"]);
        globals.inattentiveAlarmValue = SharedPreferencesService.getStringList(
            'inattentiveAlarm', ["assets", "audio/double_beep.mp3"]);
        restReminderTime =
            SharedPreferencesService.getInt('restReminderTime', 3600);
      });
    }
    initAudioPlayers();
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

  Future<void> _enableWakeLock() async {
    wakeLockEnabled = await Wakelock.enabled;
    if (!wakeLockEnabled) {
      Wakelock.enable();
    }
  }

  Future<void> _disableWakeLock() async {
    wakeLockEnabled = await Wakelock.enabled;
    if (wakeLockEnabled) {
      Wakelock.disable();
    }
  }

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
    passengerAudioPlayer.setSource(AssetSource("audio/passenger_alert.mp3"));
    passengerAudioPlayer.setVolume(1.0);
    passengerAudioPlayer.setReleaseMode(ReleaseMode.stop);
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
          score: 0,
          drowsyAlertTimestampsList: [],
          inattentiveAlertTimestampsList: [],
        );
        currentSession.startTime = saveCurrentTime(noMillis);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _enableWakeLock();

    geolocationService.positionList.clear();
    geolocationService.speedList.clear();

    _loadSettings();

    periodicCalibrationTimer?.cancel();
    periodicDetectionTimer?.cancel();

    _initSessionData();

    if (widget.calibrationMode == true) {
      if (mounted) {
        setState(() {
          globals.inCalibrationMode = true;
        });
      }
    } else if (widget.calibrationMode == false) {
      FlutterForegroundTask.updateService(
          notificationTitle: "DriveFit is protecting you :)",
          notificationText: "Tap to return to app!");
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
    _disableWakeLock();

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
  /// DRIVING REMINDERS
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

  void sendPassengerReminder() {
    passengerAudioPlayer.resume();
  }

  void updateDuration() {
    currentSession.duration = DateTime.now()
        .difference(DateTime.parse(currentSession.startTime))
        .inSeconds;
  }

  void sendRestReminder() {
    NotificationController.dismissAlertNotifications();
    NotificationController.createRestReminderNotification();
  }

  void detectionTimer() async {
    canExit = false;
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _statesController.update(MaterialState.disabled, true);
    });
    await Future.delayed(const Duration(seconds: 1));
    canExit = true;
    if (mounted) {
      _statesController.update(MaterialState.disabled, false);
    }
    await Future.delayed(const Duration(seconds: 4));

    periodicDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      updateDuration();
      if (currentSession.duration > 0 &&
          currentSession.duration % restReminderTime == 0) {
        sendRestReminder();
      }

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
        if (faceDetectionService.reminderCount <= 5) {
          sendSleepyReminder();
        }
        if (faceDetectionService.reminderCount == 10) {
          sendPassengerReminder();
        }
        if (mounted) {
          setState(() {
            if (faceDetectionService.hasReminded == false) {
              currentSession.drowsyAlertCount++;
              currentSession.drowsyAlertTimestampsList
                  .insert(0, noMillis.format(DateTime.now()));
              faceDetectionService.hasReminded = true;
            }
            faceDetectionService.reminderType = "None";
          });
        }
      } else if (faceDetectionService.reminderType == "Inattentive") {
        if (faceDetectionService.reminderCount <= 5) {
          sendDistractedReminder();
        }
        if (faceDetectionService.reminderCount == 6) {
          sendPassengerReminder();
        }
        if (mounted) {
          setState(() {
            if (faceDetectionService.hasReminded == false) {
              currentSession.inattentiveAlertCount++;
              currentSession.inattentiveAlertTimestampsList
                  .insert(0, noMillis.format(DateTime.now()));
              faceDetectionService.hasReminded = true;
            }
            faceDetectionService.reminderType = "None";
          });
        }
      }
      if (mounted) {
        setState(() {
          isReminding = faceDetectionService.isReminding;
        });
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
            SharedPreferencesService.setBool('hasCalibrated', true);
            SharedPreferencesService.setDouble(
                'neutralRotX', faceDetectionService.neutralRotX);
            SharedPreferencesService.setDouble(
                'neutralRotY', faceDetectionService.neutralRotY);
            SharedPreferencesService.setDouble(
                'rotYLeftOffset', faceDetectionService.rotYLeftOffset);
            SharedPreferencesService.setDouble(
                'rotYRightOffset', faceDetectionService.rotYRightOffset);
            startCalibration = false;
          });
          showSnackBar("Calibration complete!");
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              barrierColor: lightColorScheme.primary,
              transitionDuration: const Duration(milliseconds: 1500),
              pageBuilder: (BuildContext context, Animation<double> animation,
                  Animation<double> secondaryAnimation) {
                return const HomePage(index: 0);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: TweenSequence<double>(opacityTweenSequence)
                      .animate(animation),
                  child: child,
                );
              },
            ),
          );
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
      if (neutralY > -25) {
        leftOffset = 20 - (neutralY.abs() / 10);
        rightOffset = 20 + (neutralY.abs() / 2);
      } else {
        leftOffset = 20 + (neutralY.abs() / 5);
        rightOffset = 20 - (neutralY.abs() / 7);
      }
    } else if (neutralY > 0) {
      if (neutralY < 25) {
        leftOffset = 20 + (neutralY.abs() / 2);
        rightOffset = 20 - (neutralY.abs() / 10);
      } else {
        leftOffset = 20 - (neutralY.abs() / 7);
        rightOffset = 20 + (neutralY.abs() / 5);
      }
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
    return WithForegroundTask(
      child: WillPopScope(
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
                  isReminding: isReminding,
                ),
                if (globals.showDebug)
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
                                text: "reminderCount",
                                intValue: faceDetectionService.reminderCount),
                            DataValueWidget(
                                text: "hasReminded",
                                boolValue: faceDetectionService.hasReminded),
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
                                          final positionItem =
                                              geolocationService
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
                                          itemCount: geolocationService
                                              .speedList.length,
                                          itemBuilder: (context, index) {
                                            final speedItem = geolocationService
                                                .speedList[index];
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              color: lightColorScheme.secondary,
                                              alignment: Alignment.center,
                                              child: Center(
                                                child: SizedBox(
                                                  child: Wrap(
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        speedItem.toString(),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                if (widget.calibrationMode)
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
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
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
                                    ?.copyWith(
                                        color: lightColorScheme.onPrimary),
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
                            PageCenterText(
                              showCameraPreview: showCameraPreview,
                              isReminding: isReminding,
                            ),
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
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
                                backgroundColor: lightColorScheme.primary,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              statesController: _statesController,
                              onPressed: () async {
                                stopDrivingMode();
                              },
                              child: Text(
                                "Stop driving",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: lightColorScheme.onPrimary),
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
      ),
    );
  }

  void stopDrivingMode() {
    if (!canExit) return;
    FlutterForegroundTask.updateService(
      notificationTitle: 'Going to drive?',
      notificationText: 'Tap to start DriveFit!',
    );
    finalizeSessionData();
    isValidSession = _validateSession();
    if (isValidSession) {
      databaseService.saveSessionDataToLocal(currentSession);
      updateScores();
      if (globals.hasSignedIn) {
        if (currentSession.drowsyAlertCount > 0 ||
            currentSession.inattentiveAlertCount > 0) {
          databaseService.saveSessionDataToFirebase(currentSession);
        }
      }
    }
    if (mounted) setState(() {});
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      barrierColor: lightColorScheme.primary,
      transitionDuration: const Duration(seconds: 1),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return DriveSessionSummary(
          session: currentSession,
          isValidSession: isValidSession,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity:
              TweenSequence<double>(opacityTweenSequence).animate(animation),
          child: child,
        );
      },
    ));
  }

  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  /// SESSION END FUNCTIONS & OTHER UTILS
  ///
  /// *******************************************************
  /// *******************************************************
  /// *******************************************************
  ///
  void showSnackBar(String text) {
    var snackBar =
        SnackBar(content: Text(text), duration: const Duration(seconds: 2));
    globals.snackbarKey.currentState?.showSnackBar(snackBar);
  }

  int calcDrivingScore() {
    if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (1 / 600) &&
        (currentSession.inattentiveAlertCount / currentSession.duration) <=
            (1 / 600)) {
      return 5;
    } else if ((currentSession.drowsyAlertCount / currentSession.duration) <=
            (3 / 600) &&
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

  void finalizeSessionData() {
    if (mounted) {
      setState(() {
        currentSession.endTime = saveCurrentTime(noMillis);
        currentSession.duration = DateTime.parse(currentSession.endTime)
            .difference(DateTime.parse(currentSession.startTime))
            .inSeconds;
        currentSession.distance += geolocationService.accumulatedDistance;
        currentSession.score = calcDrivingScore();
        currentSession.drowsyAlertTimestamps =
            currentSession.drowsyAlertTimestampsList.join(", ");
      });
    }
  }

  bool _validateSession() {
    if (globals.showDebug) return true;
    if (currentSession.distance < 500 || currentSession.duration < 60) {
      return false;
    }
    return true;
  }

  void updateScores() {
    rankingService.updateDriveScore(currentSession.score);
    rankingService.updateScoreStreak(currentSession.score);
    rankingService.updateTotalScore();
  }
}

class PageCenterText extends StatefulWidget {
  const PageCenterText({
    super.key,
    required this.showCameraPreview,
    required this.isReminding,
  });

  final bool showCameraPreview;
  final bool isReminding;

  @override
  State<PageCenterText> createState() => _PageCenterTextState();
}

class _PageCenterTextState extends State<PageCenterText> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedCrossFade(
              duration: const Duration(seconds: 1),
              firstChild: Icon(
                Icons.security,
                size: 69,
                color: lightColorScheme.onPrimary,
              ),
              secondChild: Icon(
                Icons.security,
                size: 69,
                color: lightColorScheme.primary,
              ),
              crossFadeState: widget.showCameraPreview
                  ? CrossFadeState.showFirst
                  : widget.isReminding
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedDefaultTextStyle(
              style: widget.showCameraPreview
                  ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: widget.isReminding
                          ? lightColorScheme.errorContainer
                          : lightColorScheme.background)
                  : Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: widget.isReminding
                          ? lightColorScheme.onPrimary
                          : lightColorScheme.onPrimaryContainer),
              duration: const Duration(seconds: 1),
              child: const Text(
                "You are now protected!",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AnimatedDefaultTextStyle(
              style: widget.showCameraPreview
                  ? Theme.of(context).textTheme.displayMedium!.copyWith(
                      color: widget.isReminding
                          ? lightColorScheme.errorContainer
                          : lightColorScheme.background)
                  : Theme.of(context).textTheme.displayMedium!.copyWith(
                      color: widget.isReminding
                          ? lightColorScheme.onPrimary
                          : lightColorScheme.onPrimaryContainer),
              duration: const Duration(seconds: 1),
              child: const Text(
                "Drive Safely!",
              ),
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
