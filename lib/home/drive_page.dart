import 'dart:math';

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

import 'package:localization/localization.dart';

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

  List<String> genericTipsList = [
    "tip-general-1".i18n(),
    "tip-general-2".i18n(),
    "tip-general-3".i18n(),
    "tip-general-4".i18n(),
    "tip-general-5".i18n(),
    "tip-general-6".i18n(),
    "tip-general-7".i18n(),
    "tip-general-8".i18n(),
  ];

  void _loadSettings() {
    globals.enableGeolocation =
        SharedPreferencesService.getBool('enableGeolocation', true);
    globals.globalSpeedingReminders =
        SharedPreferencesService.getBool('globalSpeedingReminders', false);
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

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
                    "weather-conditions".i18n(),
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
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
                              child: !globals.showDebug
                                  ? (weatherService
                                          .currentWeatherIconURL.isNotEmpty)
                                      ? Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            color: lightColorScheme.primary,
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
                                        )
                                  : Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        color: lightColorScheme.primary,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: globals.debugWeatherIconURL,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            Icon(
                                          Icons.error,
                                          color: lightColorScheme.onSecondary,
                                        ),
                                        height: 50,
                                        width: 50,
                                      )),
                            ),
                            const SizedBox(width: 10),
                            AutoSizeText(
                              globals.showDebug
                                  ? globals.debugWeatherDescription
                                  : weatherService.currentWeatherDescription ??
                                      "no-weather-info".i18n(),
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.headlineMedium,
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
                        "today's-tip".i18n(),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                  child: AutoSizeText(
                    databaseService.drivingTip ??
                        genericTipsList[
                            Random().nextInt(genericTipsList.length)],
                    maxLines: 1,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textScaleFactor: 0.9,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
              "calibrate".i18n(),
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
                    enableSpeedReminders: globals.globalSpeedingReminders
                        ? true
                        : weatherService.enableSpeedReminders,
                  ),
                  FadeNavigator.opacityTweenSequence,
                  lightColorScheme.primary,
                  const Duration(milliseconds: 1500));
            },
            label: Text(
              "start-driving".i18n(),
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
      ],
    );
  }

  Widget getCautionMessage() {
    if (globals.showDebug) {
      weatherService.enableSpeedReminders = false;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "slow-down".i18n(),
            description: "slippery-in-heavy-rain".i18n(),
          ),
        ],
      );
    }
    if (globals.globalSpeedingReminders) {
      weatherService.enableSpeedReminders = true;
      return Column(
        children: [
          CautionMessage(
            context: context,
            main: "slow-down".i18n(),
            description: "speeding-reminders-is-enabled".i18n(),
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
              "no-weather-info".i18n(),
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
            main: "slow-down".i18n(),
            description: "slippery-in-light-rain".i18n(),
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
            main: "slow-down".i18n(),
            description: "slippery-in-heavy-rain".i18n(),
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
            main: "be-careful".i18n(),
            description: "beware-when-snowing".i18n(),
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
            main: "be-careful".i18n(),
            description: "beware-in-storm".i18n(),
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
            main: "slow-down".i18n(),
            description: "slow-down-in-low-visibility".i18n(),
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
            main: "be-careful".i18n(),
            description: "beware-in-strong-wind".i18n(),
          ),
        ],
      );
    } else {
      weatherService.enableSpeedReminders = false;
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Text(
          "drive-safely".i18n(),
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 14),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          AutoSizeText(
            'app-title'.i18n(),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
          child: Text(
            "caution".i18n(),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                      child: Icon(
                        Icons.warning_outlined,
                        color: lightColorScheme.onBackground,
                        size: 28,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                      child: Text(main,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
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
                        style: Theme.of(context).textTheme.bodyLarge,
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
