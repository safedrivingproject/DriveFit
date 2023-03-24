import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  bool positionStreamStarted = false;
  List<PositionValue> positionList = [];
  double currentLatitude = 0.0, currentLongitude = 0.0, currentSpeed = 0.0;
  DateTime currentTimeStamp = DateTime.now();

  GeolocationService._internal() {
    hasPermission = false;
    permissionType = "";
    positionStreamStarted = false;
    currentLatitude = 0.0;
    currentLongitude = 0.0;
    currentSpeed = 0.0;
    _initSettings();
  }

  void _initSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
          );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
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
        accuracy: LocationAccuracy.best,
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
    positionList.add(PositionValue(
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
    updatePositionList(position);
  }

  void startGeolocationStream(StreamSubscription<Position>? positionStream) {
    if (!hasPermission) return;
    if (positionStreamStarted) return;
    // ignore: no_leading_underscores_for_local_identifiers
    final _positionStream =
        Geolocator.getPositionStream(locationSettings: _locationSettings);
    positionStream = _positionStream.handleError((error) {
      positionStream?.cancel();
      positionStream = null;
    }).listen((Position? position) {
      if (position != null) {
        updatePositionList(position);
      }
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
    });
    positionStreamStarted = true;
  }

  void stopGeolocationStream(StreamSubscription<Position>? positionStream) {
    if (positionStream != null) {
      positionStream.cancel();
      positionStream = null;
      positionStreamStarted = false;
    }
    positionStreamStarted = false;
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
