import 'dart:math';

import 'package:drive_fit/home/tips.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:drive_fit/theme/custom_color.g.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../service/navigation.dart';
import '/service/geolocation_service.dart';
import '/service/database_service.dart';
import '/service/weather_service.dart';
import '/service/shared_preferences_service.dart';
import '/driving_mode/driving_view.dart';
import 'weather_codes.dart';
import '../global_variables.dart' as globals;

class DrivePage extends StatefulWidget {
  const DrivePage({
    super.key,
    required this.sessionsList,
  });
  final List<SessionData> sessionsList;

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  final GeolocationService geolocationService = GeolocationService();
  final DatabaseService databaseService = DatabaseService();
  final WeatherService weatherService = WeatherService();
  final MaterialStatesController _statesController = MaterialStatesController();
  List<SessionData> driveSessionsList = [];

  DateTime currentDate = DateTime.now();
  String expirationDay =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .toString();

  bool canPress = false;
  bool hasNewSession = false;
  bool _isInitialized = false;

  void _loadSettings() {
    globals.enableGeolocation =
        SharedPreferencesService.getBool('enableGeolocation', true);
    globals.globalSpeedReminders =
        SharedPreferencesService.getBool('globalSpeedReminders', false);
    globals.hasCalibrated =
        SharedPreferencesService.getBool('hasCalibrated', false);
    globals.showDebug = SharedPreferencesService.getBool('showDebug', true);
    _statesController.update(MaterialState.disabled, !globals.hasCalibrated);
    canPress = globals.hasCalibrated;
    hasNewSession = databaseService.needSessionDataUpdate;
  }

  void getSessionData() {
    driveSessionsList = widget.sessionsList;
  }

  void showRequestPermissionsDialog(String permissionType) {
    showDialog(
        context: context,
        builder: (BuildContext context) => RequestPermissionDialog(
              type: permissionType,
            ));
  }

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _loadSettings();
      getSessionData();
      if (mounted) setState(() {});
    }
    _isInitialized = true;
  }

  Widget _body() {
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    return SizedBox(
      height: MediaQuery.of(context).size.height -
          kToolbarHeight -
          kBottomNavigationBarHeight * 2,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 14, 0, 14),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: lightColorScheme.onPrimary,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Color(0x33000000),
                    offset: Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 8),
                    child: Text(
                      'Weather Conditions',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(
                          decelerationRate: ScrollDecelerationRate.fast),
                      children: [
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 8, 0),
                                  child: (weatherService
                                          .currentWeatherIconURL.isNotEmpty)
                                      ? Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            color: lightColorScheme.outline,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: weatherService
                                                .currentWeatherIconURL,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                              Icons.error,
                                              color:
                                                  lightColorScheme.onSecondary,
                                            ),
                                            height: 50,
                                            width: 50,
                                          ))
                                      : const SizedBox(
                                          height: 50,
                                          width: 50,
                                        )),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weatherService.currentWeatherMain ??
                                        "Oops...",
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  Text(
                                    weatherService.currentWeatherDescription ??
                                        "No weather information yet :(",
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  getCautionMessage(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: lightColorScheme.onPrimary,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 4,
                    color: Color(0x33000000),
                    offset: Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
                    child: Row(
                      children: [
                        Text(
                          "Today's tip",
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                          child: Icon(
                            Icons.lightbulb,
                            color: sourceXanthous,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
                    child: AutoSizeText(
                        databaseService.drivingTip ??
                            genericTipsList[
                                Random().nextInt(genericTipsList.length)],
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0))),
                  backgroundColor: globals.hasCalibrated
                      ? lightColorScheme.surfaceVariant
                      : lightColorScheme.primary,
                  minimumSize: const Size.fromHeight(50.0),
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0)),
              icon: Icon(
                Icons.architecture,
                color: globals.hasCalibrated
                    ? lightColorScheme.primary
                    : lightColorScheme.background,
              ),
              onPressed: () {
                FadeNavigator.push(
                    context,
                    const DrivingView(
                      calibrationMode: true,
                      enableGeolocation: false,
                      enableSpeedReminders: false,
                    ),
                    FadeNavigator.opacityTweenSequence,
                    lightColorScheme.primary,
                    const Duration(milliseconds: 1500));
              },
              label: Text(
                "Calibrate",
                style: globals.hasCalibrated
                    ? Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.primary)
                    : Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.onPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 32),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0))),
                minimumSize: const Size.fromHeight(50.0),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                backgroundColor: globals.hasCalibrated
                    ? lightColorScheme.primary
                    : lightColorScheme.surfaceVariant,
              ),
              icon: const Icon(
                Icons.directions_car_outlined,
              ),
              statesController: _statesController,
              onPressed: () {
                if (!canPress) return;
                FadeNavigator.push(
                    context,
                    DrivingView(
                      calibrationMode: false,
                      enableGeolocation: globals.enableGeolocation,
                      enableSpeedReminders: globals.globalSpeedReminders ? true : weatherService.enableSpeedReminders,
                    ),
                    FadeNavigator.opacityTweenSequence,
                    lightColorScheme.primary,
                    const Duration(milliseconds: 1500));
              },
              label: Text(
                "Start Driving",
                style: globals.hasCalibrated
                    ? Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.onPrimary)
                    : Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget getCautionMessage() {
    if (globals.globalSpeedReminders) {
      weatherService.enableSpeedReminders = true;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Slow down!",
            description: "'Always enable speeding reminders' is on.",
          ),
        ],
      );
    }
    if (weatherService.currentWeatherConditionCode == -1 ||
        weatherService.currentWeatherConditionCode == null) {
      weatherService.enableSpeedReminders = false;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text(
              "No weather information available :(",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    if (lightRainCodes
        .contains(weatherService.currentWeatherConditionCode!.toInt())) {
      weatherService.enableSpeedReminders = true;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Slow down!",
            description: "The roads are quite slippery in light rain!",
          ),
        ],
      );
    } else if (heavyRainCodes
        .contains(weatherService.currentWeatherConditionCode!.toInt())) {
      weatherService.enableSpeedReminders = true;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Slow down!!!",
            description: "The roads are very slippery in heavy rain!",
          ),
        ],
      );
    } else if (snowCodes
        .contains(weatherService.currentWeatherConditionCode!.toInt())) {
      weatherService.enableSpeedReminders = false;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Be careful!",
            description: "Beware of road conditions when it is snowing!",
          ),
        ],
      );
    } else if (thunderstormCodes
        .contains(weatherService.currentWeatherConditionCode!.toInt())) {
      weatherService.enableSpeedReminders = false;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Be careful!",
            description: "Beware of road conditions in a thunderstorm!",
          ),
        ],
      );
    } else if (visibilityCodes
        .contains(weatherService.currentWeatherConditionCode!.toInt())) {
      weatherService.enableSpeedReminders = false;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Be careful!",
            description: "Slow down when driving in low visilibity!",
          ),
        ],
      );
    } else if (windCodes
        .contains(weatherService.currentWeatherConditionCode!.toInt())) {
      weatherService.enableSpeedReminders = true;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "Slow down!",
            description: "Be careful when driving in strong wind!",
          ),
        ],
      );
    } else {
      weatherService.enableSpeedReminders = false;
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 4),
                    child: Icon(
                      Icons.check_circle,
                      color: lightColorScheme.primary,
                      size: 28,
                    ),
                  ),
                  Text("You're good to go!",
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AutoSizeText(
                      "Drive Safely!",
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 14),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            AutoSizeText(
              'DriveFit',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(height: 1, color: lightColorScheme.onPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            _body(),
          ],
        ),
      ),
    );
  }
}

class CautionMessage extends StatelessWidget {
  const CautionMessage({
    super.key,
    required this.context,
    required this.main,
    required this.description,
  });

  final BuildContext context;
  final String main;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
          child: Text(
            'Caution',
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 4),
                      child: Icon(
                        Icons.warning_outlined,
                        color: lightColorScheme.onBackground,
                        size: 28,
                      ),
                    ),
                    Text(main,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        description,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
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
}

class RequestPermissionDialog extends StatelessWidget {
  const RequestPermissionDialog({super.key, required this.type});
  final String? type;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("We would like your permission!"),
      content: Text("Please open settings and enable Location $type"),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge),
          onPressed: () async {
            Navigator.of(context).pop();
            if (type == "Services") {
              await Geolocator.openLocationSettings();
            } else if (type == "Permissions") {
              await Geolocator.openAppSettings();
            } else {
              const snackBar =
                  SnackBar(content: Text("Unknown perimission type..."));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
          child: const Text("Open"),
        ),
      ],
    );
  }
}
