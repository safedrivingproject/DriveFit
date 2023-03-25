import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io' show Platform;

class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();

  factory GeolocationService() => _instance;

  /// *******************************************
  /// *******************************************
  /// INITIALIZATION
  /// *******************************************
  /// *******************************************
  bool hasPermission = false;
  String permissionType = "";
  late LocationSettings _locationSettings;
  //
  bool positionStreamStarted = false;
  StreamSubscription<Position>? positionStreamSubscription;
  //
  List<PositionValue> positionList = [];
  List<double> speedList = [];
  double currentLatitude = 0.0,
      currentLongitude = 0.0,
      currentSpeed = 0.0,
      currentCalculatedSpeed = 0.0;
  DateTime currentTimeStamp = DateTime.now();
  //
  int speedCounter = 0;
  double carVelocityThreshold = 5.0;

  GeolocationService._internal() {
    hasPermission = false;
    permissionType = "";
    positionStreamStarted = false;
    //
    currentLatitude = 0.0;
    currentLongitude = 0.0;
    currentSpeed = 0.0;
    currentTimeStamp = DateTime.now();
    currentCalculatedSpeed = 0.0;
    //
    speedCounter = 0;
    carVelocityThreshold = 5.0;
    _initSettings();
  }

  void _initSettings() {
    if (Platform.isAndroid) {
      _locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      _locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      _locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }
  }

  /// *******************************************
  /// *******************************************
  /// FUNCTIONS
  /// *******************************************
  /// *******************************************

  void updatePositionList(Position position, double speed) {
    currentLatitude = position.latitude;
    currentLongitude = position.longitude;
    currentSpeed = position.speed;
    currentTimeStamp = position.timestamp ?? DateTime.now();
    positionList.insert(
        0,
        PositionValue(
          latitude: currentLatitude,
          longitude: currentLongitude,
          speed: currentSpeed,
          timestamp: currentTimeStamp,
        ));
  }

  Future<void> getCurrentPosition() async {
    if (!hasPermission) return;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    updatePositionList(position, 0);
    var speed = calculateSpeed();
    updateSpeedList(speed);
  }

  Future<void> getLastKnownPosition() async {
    if (!hasPermission) return;
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) updatePositionList(position, 0);
    var speed = calculateSpeed();
    updateSpeedList(speed);
  }

  void startGeolocationStream() {
    if (!hasPermission) return;
    if (positionStreamStarted) return;
    positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: _locationSettings)
            .listen((Position? position) {
      if (position != null) {
        updatePositionList(position, 0);
      }
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
      var speed = calculateSpeed();
      updateSpeedList(speed);
      print(speed);
    });
    positionStreamStarted = true;
  }

  void stopGeolocationStream() {
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null;
    positionStreamStarted = false;
  }

  double calculateSpeed() {
    if (positionList.length < 2) return 0.0;
    var distanceDifference = Geolocator.distanceBetween(
        positionList[1].latitude,
        positionList[1].longitude,
        positionList[0].latitude,
        positionList[0].longitude);
    var timeDifference =
        positionList[1].timestamp.difference(positionList[0].timestamp);
    return (distanceDifference /
            (timeDifference.inSeconds == 0 ? 1 : timeDifference.inSeconds))
        .abs();
  }

  void updateSpeedList(double speed) {
    speedList.insert(0, speed);
  }

  double getCurrentSpeed() {
    if (speedList.isEmpty) return 0.0;
    return speedList[0];
  }

  bool checkCarMoving() {
    currentCalculatedSpeed = getCurrentSpeed();
    if (currentCalculatedSpeed > carVelocityThreshold) {
      speedCounter++;
    } else {
      speedCounter = 0;
    }
    if (speedCounter > 50) {
      return true;
    }
    return false;
  }
}

class PositionValue {
  double latitude, longitude, speed;
  DateTime timestamp;

  PositionValue({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });
}
