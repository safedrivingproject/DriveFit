import 'package:collection/collection.dart';
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
      currentCalculatedSpeed = 0.0,
      accumulatedDistance = 0.0;
  DateTime currentTimeStamp = DateTime.now();
  //
  int speedCounter = 0;
  double carVelocityThreshold = 8.3;
  double speedingVelocityThreshold = 18.0;
  //
  int additionalDelay = 20;
  bool stationaryAlertsDisabled = false;
  bool hasReminded = false;

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
    accumulatedDistance = 0.0;
    //
    speedCounter = 0;
    carVelocityThreshold = 8.3;
    speedingVelocityThreshold = 18.0;
    //
    additionalDelay = 20;
    _initSettings();
  }

  void _initSettings() {
    if (Platform.isAndroid) {
      _locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      _locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
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

  void updatePositionList(Position position) {
    currentLatitude = position.latitude;
    currentLongitude = position.longitude;
    currentSpeed = position.speed;
    currentTimeStamp = position.timestamp ?? DateTime.now();
    accumulatedDistance += calcDistanceDifference();
    positionList.insert(
        0,
        PositionValue(
          latitude: currentLatitude,
          longitude: currentLongitude,
          speed: currentSpeed,
          timestamp: currentTimeStamp,
        ));
  }

  Future<Position?> getCurrentPosition() async {
    if (!hasPermission) return null;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    return position;
  }

  Future<Position?> getLastKnownPosition() async {
    if (!hasPermission) return null;
    Position? position = await Geolocator.getLastKnownPosition();
    return position;
  }

  void startGeolocationStream() {
    if (!hasPermission) return;
    if (positionStreamStarted) return;
    positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: _locationSettings)
            .listen((Position? position) {
      if (position != null) {
        updatePositionList(position);
        print(
            '${position.latitude.toString()}, ${position.longitude.toString()}');
        var calcSpeed = calculateSpeed();
        updateSpeedList(
            position.speed < calcSpeed ? position.speed : calcSpeed);
        print(calcSpeed);
      }
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
    var distanceDifference = calcDistanceDifference();
    var timeDifference =
        positionList[1].timestamp.difference(positionList[0].timestamp);
    return (distanceDifference /
            (timeDifference.inSeconds == 0 ? 1 : timeDifference.inSeconds))
        .abs();
  }

  double calcDistanceDifference() {
    if (positionList.length < 2) return 0.0;
    var distanceDifference = Geolocator.distanceBetween(
        positionList[1].latitude,
        positionList[1].longitude,
        positionList[0].latitude,
        positionList[0].longitude);
    return distanceDifference;
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
    if (speedCounter > 2 * 10) {
      return true;
    }
    return false;
  }

  bool checkSpeeding() {
    currentCalculatedSpeed = getCurrentSpeed();
    var liveSpeedList = <double>[];
    liveSpeedList.insert(0, currentCalculatedSpeed);
    if (liveSpeedList.length > 10 * 10) {
      liveSpeedList.removeLast();
    }
    if (liveSpeedList.sum > 18 * 10 * 10) {
      return true;
    }
    hasReminded = false;
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
