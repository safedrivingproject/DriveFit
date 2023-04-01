import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '/service/geolocation_service.dart';
import '/driving_mode/driving_view.dart';
import '/settings/settings_page.dart';
import '../global_variables.dart' as globals;

class DrivePage extends StatefulWidget {
  const DrivePage({super.key});

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  List<String> drowsyTipsList = [
    "Get a good night's sleep zZZ"
        "Have you gotten 7-8 hours of sleep? zZZ"
        "Don't stay in the car, get some fresh air ~~"
        "Take a break, stretch your legs :)"
        "Get comfortable before you drive Orz"
        "Why not turn on the radio? :)"
  ];
  List<String> inattentiveTipsList = [
    "Hands on steering wheel, am I right? ;)"
        "Eyes always on the phone? Now the road's your new phone ;)"
        "Meerkats are always alert, you can too ;)"
        "Set your phone to silent before you start driving :)"
        "Don't multitask, your only task is to drive safely :)"
        "Take your time, better safe than sorry :)"
  ];

  GeolocationService geolocationService = GeolocationService();
  final MaterialStatesController _statesController = MaterialStatesController();

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        globals.enableGeolocation =
            (prefs.getBool('enableGeolocation') ?? true);
        globals.hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
      });
    }

    setState(() {
      _statesController.update(MaterialState.disabled, !globals.hasCalibrated);
    });
  }

  Future<void> _checkPermissions() async {
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
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
                                    'Road Conditions',
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
                                            .fromSTEB(8, 8, 0, 0),
                                        child: Text(
                                            'The roads are especially slippery today \nfrom the rain.',
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
                                    'Driving tips',
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 16, 16),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 8, 0, 0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(8, 4, 8, 0),
                                          child: Icon(
                                            Icons.speed,
                                            color:
                                                lightColorScheme.onBackground,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 4),
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
