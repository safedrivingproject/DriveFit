import 'package:drive_fit/driving_mode/driving_view.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../driving_mode/driving_view.dart';
import '../global_variables.dart' as globals;

class DrivePage extends StatefulWidget {
  const DrivePage({super.key});

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        globals.useAccelerometer = (prefs.getBool('useAccelerometer') ?? false);
        globals.showCameraPreview =
            (prefs.getBool('showCameraPreview') ?? true);
        globals.useHighCameraResolution =
            (prefs.getBool('useHighCameraResolution') ?? false);
        globals.showDebug = (prefs.getBool('showDebug') ?? false);
        globals.hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lightColorScheme.primary, lcsPrimaryTransparent],
                stops: const [0, 1],
                begin: const AlignmentDirectional(0, -1),
                end: const AlignmentDirectional(0, 1),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.1,
                child: Align(
                  alignment: const AlignmentDirectional(0, 0),
                  child: Text(
                    'DriveFit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.2,
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
                        child: Text(
                          'Road Conditions',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 0, 16, 16),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 8, 0, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              8, 0, 8, 0),
                                      child: Icon(
                                        Icons.cloud_queue,
                                        color: lightColorScheme.onBackground,
                                        size: 24,
                                      ),
                                    ),
                                    Text(
                                      'Slippery roads',
                                      textAlign: TextAlign.start,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 8, 0, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              8, 0, 8, 0),
                                      child: Icon(
                                        Icons.waves,
                                        color: lightColorScheme.onBackground,
                                        size: 24,
                                      ),
                                    ),
                                    Text(
                                      'Strong Wind',
                                      textAlign: TextAlign.start,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.2,
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 0),
                        child: Text(
                          'Caution',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 0, 16, 16),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 8, 0, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              8, 8, 8, 0),
                                      child: Icon(
                                        Icons.speed,
                                        color: lightColorScheme.onBackground,
                                        size: 24,
                                      ),
                                    ),
                                    Text('Slow down',
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8, 8, 0, 0),
                                child: Text(
                                    'The roads are especially slippery today \nfrom the rain.',
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(16.0))),
                      backgroundColor: globals.hasCalibrated
                          ? lightColorScheme.surfaceVariant
                          : lightColorScheme.primary,
                      minimumSize: const Size.fromHeight(50.0),
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0)),
                  icon: Icon(
                    Icons.architecture,
                    color: globals.hasCalibrated
                        ? lightColorScheme.primary
                        : lightColorScheme.background,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DrivingView(
                                  calibrationMode: true,
                                  accelerometerOn: true,
                                )));
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
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 32),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(16.0))),
                      backgroundColor: globals.hasCalibrated
                          ? lightColorScheme.primary
                          : lightColorScheme.surfaceVariant,
                      minimumSize: const Size.fromHeight(50.0),
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0)),
                  icon: Icon(
                    Icons.directions_car_outlined,
                    color: globals.hasCalibrated
                        ? lightColorScheme.background
                        : lightColorScheme.outline,
                  ),
                  onPressed: () {
                    if (globals.hasCalibrated == true) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DrivingView(
                                    calibrationMode: false,
                                    accelerometerOn:
                                        globals.useAccelerometer ? true : false,
                                  )));
                    } else if (globals.hasCalibrated == false) {
                      null;
                    }
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
            ],
          ),
        ],
      ),
    );
  }
}
