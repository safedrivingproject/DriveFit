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
  GeolocationService._internal();

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';
  final List<PositionItem> positionItems = <PositionItem>[];
  StreamSubscription<Position>? positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;

  /// *******************************************
  /// *******************************************
  /// FUNCTIONS
  /// *******************************************
  /// *******************************************

  Future<void> getCurrentPosition() async {
    final hasPermission = await handlePermission();

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 0));
    updatePositionList(
      PositionItemType.position,
      position.toString(),
    );
  }

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      updatePositionList(
        PositionItemType.log,
        _kLocationServicesDisabledMessage,
      );

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        updatePositionList(
          PositionItemType.log,
          _kPermissionDeniedMessage,
        );

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      updatePositionList(
        PositionItemType.log,
        _kPermissionDeniedForeverMessage,
      );

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    updatePositionList(
      PositionItemType.log,
      _kPermissionGrantedMessage,
    );
    return true;
  }

  void updatePositionList(PositionItemType type, String displayValue) {
    positionItems.add(PositionItem(type, displayValue));
  }

  bool isListening() => !(positionStreamSubscription == null ||
      positionStreamSubscription!.isPaused);

  void toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      }).listen((serviceStatus) {
        String serviceStatusValue;
        if (serviceStatus == ServiceStatus.enabled) {
          if (positionStreamStarted) {
            toggleListening();
          }
          serviceStatusValue = 'enabled';
        } else {
          if (positionStreamSubscription != null) {
            positionStreamSubscription?.cancel();
            positionStreamSubscription = null;
            updatePositionList(
                PositionItemType.log, 'Position Stream has been canceled');
          }
          serviceStatusValue = 'disabled';
        }
        updatePositionList(
          PositionItemType.log,
          'Location service has been $serviceStatusValue',
        );
      });
    }
  }

  void toggleListening() {
    if (positionStreamSubscription == null) {
      final positionStream = _geolocatorPlatform.getPositionStream();
      positionStreamSubscription = positionStream.handleError((error) {
        positionStreamSubscription?.cancel();
        positionStreamSubscription = null;
      }).listen((position) => updatePositionList(
            PositionItemType.position,
            position.toString(),
          ));
      positionStreamSubscription?.pause();
    }

    if (positionStreamSubscription == null) {
      return;
    }

    String statusDisplayValue;
    if (positionStreamSubscription!.isPaused) {
      positionStreamSubscription!.resume();
      statusDisplayValue = 'resumed';
    } else {
      positionStreamSubscription!.pause();
      statusDisplayValue = 'paused';
    }

    updatePositionList(
      PositionItemType.log,
      'Listening for position updates $statusDisplayValue',
    );
  }

  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {
      updatePositionList(
        PositionItemType.position,
        position.toString(),
      );
    } else {
      updatePositionList(
        PositionItemType.log,
        'No last known position available',
      );
    }
  }

  void getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    handleLocationAccuracyStatus(status);
  }

  void requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform.requestTemporaryFullAccuracy(
      purposeKey: "TemporaryPreciseAccuracy",
    );
    handleLocationAccuracyStatus(status);
  }

  void handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
    updatePositionList(
      PositionItemType.log,
      '$locationAccuracyStatusValue location accuracy granted.',
    );
  }

  void openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Application Settings.';
    } else {
      displayValue = 'Error opening Application Settings.';
    }

    updatePositionList(
      PositionItemType.log,
      displayValue,
    );
  }

  void openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Location Settings';
    } else {
      displayValue = 'Error opening Location Settings';
    }

    updatePositionList(
      PositionItemType.log,
      displayValue,
    );
  }
}

enum PositionItemType {
  log,
  position,
}

class PositionItem {
  PositionItem(this.type, this.displayValue);

  final PositionItemType type;
  final String displayValue;
}
