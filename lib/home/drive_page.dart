import 'dart:math';

import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '/service/geolocation_service.dart';
import '/service/database_service.dart';
import '/driving_mode/driving_view.dart';
import '/settings/settings_page.dart';
import '../global_variables.dart' as globals;

class DrivePage extends StatefulWidget {
  const DrivePage({super.key});

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  final List<String> drowsyTipsList = [
    "Get a good night's sleep 💤",
    "Try to get 8 hours of sleep 💤",
    "Get some fresh air 😎",
    "Let's do some stretching 🙆‍♂️",
    "Get comfortable before you drive 🙆‍♂️",
    "Let's listen to the radio 📻",
  ];
  final List<String> inattentiveTipsList = [
    "Hands always on steering wheel, right? 😉",
    "Let the road be your new phone 😉",
    "Meerkats 🐱 are always alert, you can too!",
    "Set your phone to silent before you start driving 🤫",
    "Don't multitask, just drive safely 🚗",
    "Better watch out! 👀",
  ];
  final List<String> genericTipsList = [
    "Remember the 2 second rule ⏱",
    "Keep your distance ↔",
    "Take your time, better safe than sorry 🙏",
    "Avoid speeding 🏎",
    "Mind your driving speed 🏎",
    "Have you checked your car tires recently? 🚗",
    "Keep your car in good shape 🚗",
    "Don't race the yellow traffic light 🚦",
  ];

  final GeolocationService geolocationService = GeolocationService();
  final DatabaseService databaseService = DatabaseService();
  final MaterialStatesController _statesController = MaterialStatesController();
  List<SessionData> driveSessionsList = [];

  int totalAlerts = 0, drowsyAlertCount = 0, inattentiveAlertCount = 0;
  String tipType = "Generic";
  String drivingTip = "";
  int tipsIndex = 0;

  DateTime currentDate = DateTime.now();
  String previousDate =
      DateTime.now().subtract(const Duration(days: 1)).toString();
  DateTime expirationDay = DateTime.now();

  bool canPress = false;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    globals.enableGeolocation = (prefs.getBool('enableGeolocation') ?? true);
    globals.hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
    globals.showDebug = (prefs.getBool('showDebug') ?? false);
    previousDate = (prefs.getString('previousDate') ??
        DateTime.now().subtract(const Duration(days: 1)).toString());
    expirationDay = DateTime.parse(previousDate).add(const Duration(days: 1));
    tipsIndex = (prefs.getInt('tipsIndex') ?? 0);
    if (mounted) {
      setState(() {
        _statesController.update(
            MaterialState.disabled, !globals.hasCalibrated);
        canPress = globals.hasCalibrated;
      });
    }
    getTipData();
  }

  Future<void> getSessionData() async {
    driveSessionsList = await databaseService.getAllSessions();
    drowsyAlertCount = databaseService.getDrowsyAlertCount(driveSessionsList);
    inattentiveAlertCount =
        databaseService.getInattentiveAlertCount(driveSessionsList);
    totalAlerts = drowsyAlertCount + inattentiveAlertCount;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> getTipData() async {
    currentDate = DateTime.now();
    if (currentDate.isAfter(expirationDay)) {
      print("After");
      previousDate = currentDate.toString();
      expirationDay = DateTime.parse(previousDate).add(const Duration(days: 1));
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('previousDate', currentDate.toString());
      tipType = getTipType(driveSessionsList);
      if (tipType == "Drowsy") {
        tipsIndex = Random().nextInt(drowsyTipsList.length);
      } else if (tipType == "Inattentive") {
        tipsIndex = Random().nextInt(inattentiveTipsList.length);
      } else {
        tipsIndex = Random().nextInt(genericTipsList.length);
      }
      prefs.setInt('tipsIndex', tipsIndex);
    }
    drivingTip = getTip(tipType, tipsIndex);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    String permissionType = "";

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      permissionType = "Services";
      geolocationService.hasPermission = false;
      showRequestPermissionsDialog(permissionType);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        permissionType = "Permissions";
        geolocationService.hasPermission = false;
        showRequestPermissionsDialog(permissionType);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      permissionType = "Permissions";
      geolocationService.hasPermission = false;
      showRequestPermissionsDialog(permissionType);
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    geolocationService.hasPermission = true;
  }

  void showRequestPermissionsDialog(String permissionType) {
    showDialog(
        context: context,
        builder: (BuildContext context) => RequestPermissionDialog(
              type: permissionType,
            ));
  }

  String getTipType(List<SessionData> session) {
    if (totalAlerts > 5) {
      if (drowsyAlertCount - inattentiveAlertCount > 5) {
        return "Drowsy";
      } else if (inattentiveAlertCount - drowsyAlertCount > 5) {
        return "Inattentive";
      }
    }
    return "Generic";
  }

  String getTip(String tipType, int index) {
    if (tipType == "Drowsy") {
      return drowsyTipsList[index];
    } else if (tipType == "Inattentive") {
      return inattentiveTipsList[index];
    }
    return genericTipsList[index];
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    getSessionData();
    checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [lightColorScheme.primary, lcsPrimaryTransparent],
              stops: const [0.15, 1],
              begin: const AlignmentDirectional(0, -1),
              end: const AlignmentDirectional(0, 1),
            ),
          ),
        ),
        CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              leading: IconButton(
                icon: const Icon(Icons.settings),
                color: lightColorScheme.background,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          const SettingsPage(title: "Settings")));
                },
              ),
              toolbarHeight: kToolbarHeight + 1.25,
              backgroundColor: Colors.transparent,
              expandedHeight: 0,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
            SliverToBoxAdapter(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        kBottomNavigationBarHeight,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.1,
                          child: Align(
                            alignment: const AlignmentDirectional(0, 0),
                            child: Text(
                              'DriveFit',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(color: lightColorScheme.onPrimary),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              28, 28, 28, 0),
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
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 0, 0),
                                  child: Text(
                                    'Road & Weather Conditions',
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 16, 16),
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 8, 0, 0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(8, 0, 8, 0),
                                              child: Icon(
                                                Icons.cloud_queue,
                                                color: lightColorScheme
                                                    .onBackground,
                                                size: 28,
                                              ),
                                            ),
                                            Text(
                                              'Slippery roads',
                                              textAlign: TextAlign.start,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 8, 0, 0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(8, 0, 8, 0),
                                              child: Icon(
                                                Icons.waves,
                                                color: lightColorScheme
                                                    .onBackground,
                                                size: 28,
                                              ),
                                            ),
                                            Text(
                                              'Strong Wind',
                                              textAlign: TextAlign.start,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 0, 0),
                                  child: Text(
                                    'Caution',
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 16, 16),
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 8, 0, 0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(8, 4, 8, 0),
                                              child: Icon(
                                                Icons.speed,
                                                color: lightColorScheme
                                                    .onBackground,
                                                size: 28,
                                              ),
                                            ),
                                            Text('Slow down',
                                                textAlign: TextAlign.start,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(8, 8, 8, 0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  'The roads are especially slippery today from the rain.',
                                                  textAlign: TextAlign.start,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              28, 14, 28, 0),
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
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 0, 0),
                                  child: Text(
                                    'Tip of the day:',
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 16, 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 0, 8, 0),
                                        child: Icon(
                                          Icons.lightbulb_outlined,
                                          color: lightColorScheme.onBackground,
                                        ),
                                      ),
                                      Expanded(
                                        child: AutoSizeText(drivingTip,
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                      ),
                                    ],
                                  ),
                                ),
                                if (globals.showDebug)
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16, 16, 16, 16),
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 0, 8, 0),
                                            child: Text(previousDate)),
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 0, 8, 0),
                                            child:
                                                Text(expirationDay.toString())),
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 0, 8, 0),
                                            child:
                                                Text(currentDate.toString())),
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 0, 8, 0),
                                            child: Text(tipsIndex.toString())),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 16, 16, 0),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
                                backgroundColor: globals.hasCalibrated
                                    ? lightColorScheme.surfaceVariant
                                    : lightColorScheme.primary,
                                minimumSize: const Size.fromHeight(50.0),
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0)),
                            icon: Icon(
                              Icons.architecture,
                              color: globals.hasCalibrated
                                  ? lightColorScheme.primary
                                  : lightColorScheme.background,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const DrivingView(
                                            calibrationMode: true,
                                            enableGeolocation: false,
                                          )));
                            },
                            label: Text(
                              "Calibrate",
                              style: globals.hasCalibrated
                                  ? Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: lightColorScheme.primary)
                                  : Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: lightColorScheme.onPrimary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 16, 16, 32),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(16.0))),
                                minimumSize: const Size.fromHeight(50.0),
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0)),
                            icon: const Icon(
                              Icons.directions_car_outlined,
                            ),
                            statesController: _statesController,
                            onPressed: () {
                              if (!canPress) return;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DrivingView(
                                            calibrationMode: false,
                                            enableGeolocation:
                                                globals.enableGeolocation
                                                    ? true
                                                    : false,
                                          )));
                            },
                            label: Text(
                              "Start Driving",
                              style: globals.hasCalibrated
                                  ? Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: lightColorScheme.onPrimary)
                                  : Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: lightColorScheme.outline),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
