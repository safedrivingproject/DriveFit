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

import '../service/navigation.dart';
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

import 'package:localization/localization.dart';

class DrivingView extends StatefulWidget {
  const DrivingView({
    super.key,
    required this.calibrationMode,
    this.accelerometerOn = false,
    required this.enableGeolocation,
    required this.enableSpeedReminders,
  });

  final bool calibrationMode;
  final bool accelerometerOn;
  final bool enableGeolocation;
  final bool enableSpeedReminders;

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
  final AudioPlayer speedingAudioPlayer = AudioPlayer();
  final AudioPlayer restAudioPlayer = AudioPlayer();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 1.0,
    ),
  );

  final MaterialStatesController _statesController = MaterialStatesController();

  int caliSeconds = 3;
  Timer? periodicDetectionTimer, periodicCalibrationTimer;
  bool cancelTimer = false;
  bool carMoving = false;
  bool speeding = false;
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
    speedingCount: 0,
    speedingTimestampsList: [],
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
        faceDetectionService.additionalDelay =
            SharedPreferencesService.getInt('additionalDelay', 50);
        globals.showDebug =
            SharedPreferencesService.getBool('showDebug', false);
        globals.hasCalibrated =
            SharedPreferencesService.getBool('hasCalibrated', false);
        faceDetectionService.neutralRotX =
            SharedPreferencesService.getDouble('neutralRotX', 0.0);
        faceDetectionService.neutralRotY =
            SharedPreferencesService.getDouble('neutralRotY', -25.0);
        faceDetectionService.rotYLeftOffset =
            SharedPreferencesService.getDouble('rotYLeftOffset', 20.0);
        faceDetectionService.rotYRightOffset =
            SharedPreferencesService.getDouble('rotYRightOffset', 10.0);
        faceDetectionService.rotXDelay =
            SharedPreferencesService.getInt('rotXDelay', 15);
        faceDetectionService.rotYDelay =
            SharedPreferencesService.getInt('rotYDelay', 25);
        geolocationService.carVelocityThreshold =
            SharedPreferencesService.getDouble('carVelocityThreshold', 4.16);
        globals.drowsyAlarmValue = SharedPreferencesService.getStringList(
            'drowsyAlarm', ["assets", "audio/car_horn_high.mp3"]);
        globals.inattentiveAlarmValue = SharedPreferencesService.getStringList(
            'inattentiveAlarm', ["assets", "audio/double_beep.mp3"]);
        restReminderTime =
            SharedPreferencesService.getInt('restReminderTime', 3600);
        geolocationService.speedingVelocityThreshold =
            SharedPreferencesService.getDouble('speedVelocityThreshold', 16.6);
        faceDetectionService.eyeProbThreshold =
            SharedPreferencesService.getDouble('eyeProbThreshold', 0.5);
        faceDetectionService.rotXOffset =
            SharedPreferencesService.getDouble('rotXOffset', 18);
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
    drowsyAudioPlayer.setPlayerMode(PlayerMode.lowLatency);
    drowsyAudioPlayer.setReleaseMode(ReleaseMode.stop);
    inattentiveAudioPlayer.setPlayerMode(PlayerMode.lowLatency);
    inattentiveAudioPlayer.setReleaseMode(ReleaseMode.stop);
    passengerAudioPlayer.setReleaseMode(ReleaseMode.stop);
    speedingAudioPlayer.setReleaseMode(ReleaseMode.stop);
    restAudioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Source getDrowsyAudioSource() {
    return globals.drowsyAlarmValue[0] == "asset"
        ? AssetSource(globals.drowsyAlarmValue[1])
        : globals.drowsyAlarmValue[0] == "file"
            ? DeviceFileSource(globals.drowsyAlarmValue[1])
            : AssetSource("audio/car_horn_high.mp3");
  }

  Source getInattentiveAudioSource() {
    return globals.inattentiveAlarmValue[0] == "asset"
        ? AssetSource(globals.inattentiveAlarmValue[1])
        : globals.inattentiveAlarmValue[0] == "file"
            ? DeviceFileSource(globals.inattentiveAlarmValue[1])
            : AssetSource("audio/double_beep.mp3");
  }

  Source getPassengerAudioSource() {
    final locale = Localizations.localeOf(context);
    if (locale == const Locale('zh', 'HK')) {
      return AssetSource("audio/passenger_alert_chi.mp3");
    } else {
      return AssetSource("audio/passenger_alert_eng.mp3");
    }
  }

  Source getSpeedingAudioSource() {
    final locale = Localizations.localeOf(context);
    if (locale == const Locale('zh', 'HK')) {
      return AssetSource("audio/speeding_reminder_chi.mp3");
    } else {
      return AssetSource("audio/speeding_reminder_eng.mp3");
    }
  }

  Source getRestAudioSource() {
    final locale = Localizations.localeOf(context);
    if (locale == const Locale('zh', 'HK')) {
      return AssetSource("audio/rest_reminder_chi.mp3");
    } else {
      return AssetSource("audio/rest_reminder_eng.mp3");
    }
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
          speedingCount: 0,
          speedingTimestampsList: [],
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

    cancelTimer = true;
    periodicCalibrationTimer?.cancel();
    periodicCalibrationTimer = null;
    periodicDetectionTimer?.cancel();
    periodicDetectionTimer = null;
    cancelTimer = false;

    _initSessionData();

    if (widget.calibrationMode == true) {
      if (mounted) {
        setState(() {
          globals.inCalibrationMode = true;
        });
      }
    } else if (widget.calibrationMode == false) {
      _startForegroundTask();
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

  Future<void> _startForegroundTask() async {
    if (!await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.startService(
        notificationTitle: "foreground-notification-title-driving".i18n(),
        notificationText: "foreground-notification-text-driving".i18n(),
      );
    }
  }

  Future<void> _stopForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void dispose() {
    _disableWakeLock();

    _canProcess = false;
    cancelTimer = true;
    periodicCalibrationTimer?.cancel();
    periodicCalibrationTimer = null;
    periodicDetectionTimer?.cancel();
    periodicDetectionTimer = null;

    geolocationService.stopGeolocationStream();
    globals.inCalibrationMode = false;

    drowsyAudioPlayer.dispose();
    inattentiveAudioPlayer.dispose();
    passengerAudioPlayer.dispose();
    speedingAudioPlayer.dispose();
    restAudioPlayer.dispose();

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
    drowsyAudioPlayer.stop();
    drowsyAudioPlayer.play(getDrowsyAudioSource());
    print("drowsy audio played");
    NotificationController.dismissAlertNotifications();
    NotificationController.createSleepyNotification();
  }

  void sendDistractedReminder() {
    inattentiveAudioPlayer.stop();
    inattentiveAudioPlayer.play(getInattentiveAudioSource());
    print("inattentive audio played");
    NotificationController.dismissAlertNotifications();
    NotificationController.createDistractedNotification();
  }

  void sendPassengerReminder() {
    passengerAudioPlayer.stop();
    passengerAudioPlayer.play(getPassengerAudioSource());
    print("passenger reminder played");
  }

  void sendRestReminder() {
    restAudioPlayer.stop();
    restAudioPlayer.play(getRestAudioSource());
    NotificationController.dismissAlertNotifications();
    NotificationController.createRestNotification();
  }

  void sendSpeedingReminder() {
    speedingAudioPlayer.stop();
    speedingAudioPlayer.play(getSpeedingAudioSource());
    NotificationController.dismissAlertNotifications();
    NotificationController.createSpeedingNotification();
  }

  void updateDuration() {
    currentSession.duration = DateTime.now()
        .difference(DateTime.parse(currentSession.startTime))
        .inSeconds;
  }

  void detectionTimer() async {
    canExit = false;
    faceDetectionService.clearPreviousFilteredFace();
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _statesController.update(MaterialState.disabled, true);
    });
    await Future.delayed(const Duration(seconds: 1));
    canExit = true;
    if (mounted) {
      _statesController.update(MaterialState.disabled, false);
    }
    if (!globals.showDebug) await Future.delayed(const Duration(seconds: 4));

    if (periodicDetectionTimer != null) return;
    periodicDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (cancelTimer) {
        cancelTimer = false;
        timer.cancel();
      }

      updateDuration();
      if (currentSession.duration > 0 &&
          currentSession.duration % restReminderTime == 0) {
        sendRestReminder();
      }

      if (widget.enableGeolocation) {
        carMoving = geolocationService.checkCarMoving();

        if (widget.enableSpeedReminders) {
          speeding = geolocationService.checkSpeeding();
        } else {
          speeding = false;
        }
      } else {
        carMoving = true;
        speeding = false;
      }

      if (speeding) {
        if (geolocationService.hasReminded == false) {
          sendSpeedingReminder();
          currentSession.speedingCount++;
          currentSession.speedingTimestampsList
              .insert(0, noMillis.format(DateTime.now()));
          geolocationService.hasReminded = true;
        }
        if (mounted) setState(() {});
      }

      faceDetectionService.checkHasFace();

      if (!faceDetectionService.hasFace) return;

      faceDetectionService.runLowPassFilter();
      faceDetectionService.updatePreviousFilteredFace();

      faceDetectionService.checkNotEyesClosed();
      faceDetectionService.checkNotDrowsy();
      faceDetectionService.checkNotInattentive();

      faceDetectionService.checkEyesClosed();

      if (geolocationService.stationaryAlertsDisabled) {
        if (carMoving) {
          faceDetectionService.checkHeadUpDown(faceDetectionService.rotXDelay);
          faceDetectionService
              .checkHeadLeftRight(faceDetectionService.rotYDelay);
        }
      } else {
        faceDetectionService.checkHeadUpDown(faceDetectionService.rotXDelay +
            (!carMoving ? faceDetectionService.additionalDelay : 0));
        faceDetectionService.checkHeadLeftRight(faceDetectionService.rotYDelay +
            (!carMoving ? faceDetectionService.additionalDelay : 0));
      }

      faceDetectionService.setReminderType();

      if (faceDetectionService.remindTick != "None") {
        if (faceDetectionService.reminderType == "Sleeping" &&
            faceDetectionService.remindTick == "Sleeping") {
          faceDetectionService.reminderCount++;
          if (faceDetectionService.reminderCount <= 3) {
            sendSleepyReminder();
          }
          if (faceDetectionService.reminderCount == 4) {
            sendPassengerReminder();
          }
          if (faceDetectionService.hasReminded == false) {
            currentSession.drowsyAlertCount++;
            currentSession.drowsyAlertTimestampsList
                .insert(0, noMillis.format(DateTime.now()));
            faceDetectionService.hasReminded = true;
          }
        } else if (faceDetectionService.reminderType == "Drowsy" &&
            faceDetectionService.remindTick == "Drowsy") {
          faceDetectionService.reminderCount++;
          if (faceDetectionService.reminderCount <= 3) {
            sendSleepyReminder();
          }
          if (faceDetectionService.reminderCount == 4) {
            sendPassengerReminder();
          }
          if (faceDetectionService.hasReminded == false) {
            currentSession.drowsyAlertCount++;
            currentSession.drowsyAlertTimestampsList
                .insert(0, noMillis.format(DateTime.now()));
            faceDetectionService.hasReminded = true;
          }
        } else if (faceDetectionService.reminderType == "Inattentive" &&
            faceDetectionService.remindTick == "Inattentive") {
          faceDetectionService.reminderCount++;
          if (faceDetectionService.reminderCount <= 3) {
            sendDistractedReminder();
          }
          if (faceDetectionService.reminderCount == 4) {
            sendPassengerReminder();
          }
          if (faceDetectionService.hasReminded == false) {
            currentSession.inattentiveAlertCount++;
            currentSession.inattentiveAlertTimestampsList
                .insert(0, noMillis.format(DateTime.now()));
            faceDetectionService.hasReminded = true;
          }
        }
        faceDetectionService.remindTick = "None";
      }

      isReminding = faceDetectionService.isReminding;
      if (mounted) setState(() {});
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
      if (cancelTimer) {
        cancelTimer = false;
        timer.cancel();
      }
      timeCounter++;
      if (timeCounter % 10 == 0) {
        caliSeconds--;
      }
      if (caliSeconds < 0) {
        if (mounted) {
          SharedPreferencesService.setBool('hasCalibrated', true);
          SharedPreferencesService.setDouble(
              'neutralRotX', faceDetectionService.neutralRotX);
          SharedPreferencesService.setDouble(
              'neutralRotY', faceDetectionService.neutralRotY);
          SharedPreferencesService.setDouble(
              'rotYLeftOffset', faceDetectionService.rotYLeftOffset);
          SharedPreferencesService.setDouble(
              'rotYRightOffset', faceDetectionService.rotYRightOffset);
          setState(() {
            startCalibration = false;
          });
          FadeNavigator.pushReplacement(
              context,
              const HomePage(index: 0),
              FadeNavigator.opacityTweenSequence,
              lightColorScheme.primary,
              const Duration(milliseconds: 1500));
          timer.cancel();
        }
      } else {
        liveRotXList.add(faceDetectionService.rotX ?? 0);
        if (liveRotXList.length > 10) {
          liveRotXList.removeAt(0);
        }
        liveRotYList.add(faceDetectionService.rotY ?? -25);
        if (liveRotYList.length > 10) {
          liveRotYList.removeAt(0);
        }
        faceDetectionService.neutralRotX = average(liveRotXList);
        faceDetectionService.neutralRotY = average(liveRotYList);
        globals.neutralAccelX = _rawAccelX;
        globals.neutralAccelY = _rawAccelY;
        globals.neutralAccelZ = _rawAccelZ;
        calcRotYOffsets();
        if (mounted) setState(() {});
      }
    });
  }

  void calcRotYOffsets() {
    var neutralY = faceDetectionService.neutralRotY;
    var leftOffset = 15.0;
    var rightOffset = 15.0;
    if (neutralY <= 0) {
      if (neutralY > -25) {
        leftOffset = 25 - (neutralY.abs() / 10);
        rightOffset = 25 - (neutralY.abs() / 5);
      } else {
        leftOffset = 25 - (neutralY.abs() / 8);
        rightOffset = 25 - (neutralY.abs() / 4);
      }
    } else if (neutralY > 0) {
      if (neutralY < 25) {
        leftOffset = 25 - (neutralY.abs() / 5);
        rightOffset = 25 - (neutralY.abs() / 10);
      } else {
        leftOffset = 25 - (neutralY.abs() / 4);
        rightOffset = 25 - (neutralY.abs() / 8);
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
    if (count == 0) throw StateError('No elements to average');
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
        accelData = sensorEvent.data;
        _rawAccelX = accelData[0];
        _rawAccelY = accelData[1];
        _rawAccelZ = accelData[2];
        accelX = _rawAccelX - globals.neutralAccelX;
        accelY = _rawAccelY - globals.neutralAccelY;
        accelZ = _rawAccelZ - globals.neutralAccelZ;
        globals.resultantAccel = calcResultantAccel();
        if (mounted) setState(() {});
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

    faceDetectionService.faces = await _faceDetector.processImage(inputImage);
    if (faceDetectionService.faces.isNotEmpty) {
      final face = faceDetectionService.faces[0];
      faceDetectionService.rotX = face.headEulerAngleX;
      faceDetectionService.rotY = face.headEulerAngleY;
      faceDetectionService.leftEyeOpenProb = face.leftEyeOpenProbability;
      faceDetectionService.rightEyeOpenProb = face.rightEyeOpenProbability;

      Size size = const Size(1.0, 1.0);
      InputImageRotation? imageRotation = inputImage.metadata?.rotation;
      Size? imageSize = inputImage.metadata?.size;
      if (imageSize != null && imageRotation != null) {
        globals.faceCenterX = calcFaceCenterX(
            translateX(face.boundingBox.left, imageRotation, size, imageSize),
            translateX(face.boundingBox.right, imageRotation, size, imageSize));
        globals.faceCenterY = calcFaceCenterY(
            translateY(face.boundingBox.top, imageRotation, size, imageSize),
            translateY(
                face.boundingBox.bottom, imageRotation, size, imageSize));
        final painter = FaceDetectorPainter(faceDetectionService.faces,
            inputImage.metadata!.size, inputImage.metadata!.rotation);
        _customPaint = CustomPaint(painter: painter);
      }
    }

    _isBusy = false;
    if (mounted) setState(() {});
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
                widget.calibrationMode ? "calibrate".i18n() : "driving".i18n(),
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
                                doubleValue: widget.calibrationMode
                                    ? faceDetectionService.rotX
                                    : faceDetectionService.filteredRotX),
                            DataValueWidget(
                                text: "rotY",
                                doubleValue: widget.calibrationMode
                                    ? faceDetectionService.rotY
                                    : faceDetectionService.filteredRotY),
                            DataValueWidget(
                                text: "neutralRotX",
                                doubleValue: faceDetectionService.neutralRotX),
                            DataValueWidget(
                                text: "neutralRotY",
                                doubleValue: faceDetectionService.neutralRotY),
                            DataValueWidget(
                                text: "rotYLeftOffset",
                                doubleValue:
                                    faceDetectionService.rotYLeftOffset),
                            DataValueWidget(
                                text: "rotYRightOffset",
                                doubleValue:
                                    faceDetectionService.rotYRightOffset),
                            DataValueWidget(
                                text: "reminderType",
                                stringValue: faceDetectionService.reminderType),
                            DataValueWidget(
                                text: "reminderCount",
                                intValue: faceDetectionService.reminderCount),
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
                                  const SizedBox(width: 10),
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
                                  const SizedBox(width: 10),
                                  if (geolocationService
                                      .speedDifference.isNotEmpty)
                                    Expanded(
                                      child: SizedBox(
                                        height: 150,
                                        child: ListView.builder(
                                          itemCount: geolocationService
                                              .speedDifference.length,
                                          itemBuilder: (context, index) {
                                            final speedItem = geolocationService
                                                .speedDifference[index];
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
                            FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
                                backgroundColor: lightColorScheme.primary,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: () {
                                sendRestReminder();
                              },
                              child: Text(
                                "Send rest reminder (debug)",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: lightColorScheme.onPrimary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
                                backgroundColor: lightColorScheme.primary,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: () {
                                geolocationService.debugAddSpeed();
                              },
                              child: Text(
                                "Add speed (debug)",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: lightColorScheme.onPrimary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
                                backgroundColor: lightColorScheme.primary,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: () async {
                                stopDrivingMode(true);
                              },
                              child: Text(
                                "Stop driving w/ + duration (debug)",
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
                                "calibrate".i18n(),
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
                      if (!globals.showDebug)
                        Column(
                          children: [
                            const Spacer(),
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
                                stopDrivingMode(false);
                              },
                              child: Text(
                                "stop-driving".i18n(),
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

  void stopDrivingMode(bool debug) {
    if (!canExit) return;
    cancelTimer = true;
    periodicDetectionTimer = null;
    _stopForegroundTask();
    finalizeSessionData(debug);
    isValidSession = _validateSession();
    if (isValidSession) {
      databaseService.saveSessionDataToLocal(currentSession);
      updateScores();
      if (globals.hasSignedIn) {
        databaseService.saveSessionDataToFirebase(currentSession);
      }
    }
    if (mounted) setState(() {});
    FadeNavigator.pushReplacement(
        context,
        DriveSessionSummary(
          session: currentSession,
          isValidSession: isValidSession,
          fromHistoryPage: false,
          sessionIndex: 0,
        ),
        FadeNavigator.opacityTweenSequence,
        lightColorScheme.primary,
        const Duration(milliseconds: 1500));
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
    var duration = currentSession.duration;
    var drowsyCount = currentSession.drowsyAlertCount;
    var inattentiveCount = currentSession.inattentiveAlertCount;
    var speedingCount = currentSession.speedingCount;
    var score = (duration / 60).ceil() -
        2 * (drowsyCount + inattentiveCount + speedingCount);
    return score < 0 ? 0 : score;
  }

  void finalizeSessionData(bool debug) {
    if (mounted) {
      setState(() {
        currentSession.endTime = saveCurrentTime(noMillis);
        currentSession.duration = DateTime.parse(currentSession.endTime)
            .difference(DateTime.parse(currentSession.startTime))
            .inSeconds;
        if (currentSession.distance > -1) {
          currentSession.distance += geolocationService.accumulatedDistance;
        }
        if (debug) currentSession.duration += 1800;
        currentSession.score = calcDrivingScore();
        currentSession.drowsyAlertTimestamps =
            currentSession.drowsyAlertTimestampsList.join(", ");
        currentSession.inattentiveAlertTimestamps =
            currentSession.inattentiveAlertTimestampsList.join(", ");
      });
    }
  }

  bool _validateSession() {
    if (globals.showDebug) return true;
    if (currentSession.distance == -1) {
      if (currentSession.duration < 60) return false;
      return true;
    }
    if (currentSession.distance < 500 || currentSession.duration < 60) {
      return false;
    }
    return true;
  }

  void updateScores() {
    rankingService.updateDriveScore(currentSession.score);
    rankingService.updateScoreStreak(
        currentSession.score, currentSession.duration);
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
              child: Text(
                "you-are-now-protected".i18n(),
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
              child: Text(
                "drive-safely".i18n(),
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
            children: [
              CalibrateInstruction(
                bullet: "1.",
                instruction: "calibrate-instruction-1".i18n(),
              ),
              const SizedBox(height: 5),
              CalibrateInstruction(
                bullet: "2.",
                instruction: "calibrate-instruction-2".i18n(),
              ),
              const SizedBox(height: 5),
              CalibrateInstruction(
                bullet: "3.",
                instruction: "calibrate-instruction-3".i18n(),
              ),
              const SizedBox(height: 5),
              CalibrateInstruction(
                bullet: "4.",
                instruction: "calibrate-instruction-4".i18n(),
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
              caliSeconds < 1 ? "complete".i18n() : "$caliSeconds",
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
    super.key,
    required this.text,
    this.doubleValue,
    this.intValue,
    this.boolValue,
    this.stringValue,
  });

  final String text;
  final double? doubleValue;
  final int? intValue;
  final bool? boolValue;
  final String? stringValue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 41,
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
