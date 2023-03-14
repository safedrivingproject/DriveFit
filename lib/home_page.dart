import 'package:drive_fit/settings_page.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'driving_mode/driving_view.dart';
import 'global_variables.dart' as globals;

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    setState(() {});
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          color: lightColorScheme.background,
          iconSize: 30.0,
          padding: const EdgeInsets.all(8.0),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsPage(title: "Settings")));
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
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
                ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 0),
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16, 16, 0, 0),
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
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 8, 0, 0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(8, 0, 8, 0),
                                            child: Icon(
                                              Icons.cloud_queue,
                                              color:
                                                  lightColorScheme.onBackground,
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
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 8, 0, 0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(8, 0, 8, 0),
                                            child: Icon(
                                              Icons.waves,
                                              color:
                                                  lightColorScheme.onBackground,
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
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 0),
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16, 16, 0, 0),
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
                                  children: [
                                    Padding(
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
                                                .fromSTEB(8, 8, 8, 0),
                                            child: Icon(
                                              Icons.speed,
                                              color:
                                                  lightColorScheme.onBackground,
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
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              8, 8, 0, 0),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DrivingView(
                                    calibrationMode: true,
                                    accelerometerOn: true,
                                  ))).then(((value) {
                        setState(() {});
                      }));
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
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 96),
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DrivingView(
                                      calibrationMode: false,
                                      accelerometerOn: globals.useAccelerometer
                                          ? true
                                          : false,
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

            /// OLD
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 10.0),
            //   child: Column(
            //     children: [
            //       Container(
            //         height: kToolbarHeight,
            //       ),
            //       Expanded(
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             Container(
            //               padding: const EdgeInsets.all(8.0),
            //               decoration: BoxDecoration(
            //                   border: Border.all(width: 2.0),
            //                   borderRadius:
            //                       const BorderRadius.all(Radius.circular(20))),
            //               constraints: const BoxConstraints(minHeight: 100),
            //               alignment: Alignment.center,
            //               child: Text(
            //                 globals.appName,
            //                 style: Theme.of(context).textTheme.displayLarge,
            //               ),
            //             ),
            //             ConstrainedBox(
            //               constraints: const BoxConstraints(
            //                   minHeight: 100, maxHeight: 500),
            //             ),
            //           ],
            //         ),
            //       ),
            //       Column(
            //         mainAxisAlignment: MainAxisAlignment.end,
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           FilledButton.icon(
            //             style: FilledButton.styleFrom(
            //               shape: const RoundedRectangleBorder(
            //                   borderRadius:
            //                       BorderRadius.all(Radius.circular(16.0))),
            //               backgroundColor: globals.hasCalibrated
            //                   ? lightColorScheme.surfaceVariant
            //                   : lightColorScheme.primary,
            //               disabledBackgroundColor:
            //                   lightColorScheme.surfaceVariant,
            //             ),
            //             icon: Icon(
            //               Icons.architecture,
            //               color: globals.hasCalibrated
            //                   ? lightColorScheme.primary
            //                   : bgColorVerdigris,
            //             ),
            //             onPressed: () {
            //               Navigator.push(
            //                   context,
            //                   MaterialPageRoute(
            //                       builder: (context) => const DrivingView(
            //                             calibrationMode: true,
            //                             accelerometerOn: true,
            //                           ))).then(((value) {
            //                 setState(() {});
            //               }));
            //             },
            //             label: Text(
            //               "Calibrate",
            //               style: Theme.of(context).textTheme.bodyLarge,
            //               textAlign: TextAlign.center,
            //             ),
            //           ),
            //           ConstrainedBox(
            //             constraints: const BoxConstraints(minHeight: 10),
            //           ),
            //           FilledButton(
            //             style: FilledButton.styleFrom(
            //               shape: const RoundedRectangleBorder(
            //                   borderRadius:
            //                       BorderRadius.all(Radius.circular(16.0))),
            //               backgroundColor: globals.hasCalibrated
            //                   ? lightColorScheme.surfaceVariant
            //                   : lightColorScheme.primary,
            //             ),
            //             onPressed: () {
            //               if (globals.hasCalibrated == true) {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                         builder: (context) => DrivingView(
            //                               calibrationMode: false,
            //                               accelerometerOn:
            //                                   globals.useAccelerometer
            //                                       ? true
            //                                       : false,
            //                             )));
            //               } else if (globals.hasCalibrated == false) {
            //                 null;
            //               }
            //             },
            //             child: Text(
            //               "Start Driving",
            //               style: globals.hasCalibrated == true
            //                   ? Theme.of(context)
            //                       .textTheme
            //                       .labelLarge
            //                       ?.copyWith(color: lightColorScheme.secondary)
            //                   : Theme.of(context)
            //                       .textTheme
            //                       .labelLarge
            //                       ?.copyWith(color: lightColorScheme.outline),
            //               textAlign: TextAlign.center,
            //             ),
            //           ),
            //           ConstrainedBox(
            //             constraints: const BoxConstraints(minHeight: 10),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
      // drawer: const NavigationDrawer(),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          buildHeader(context),
          buildMenuItems(context),
        ],
      )),
    );
  }
}

Widget buildHeader(BuildContext context) {
  return Container(
    color: Theme.of(context).primaryColor,
    padding:
        EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 24),
    child: Column(
      children: [
        SizedBox.fromSize(
          size: const Size.fromRadius(80),
          child: const FittedBox(
            child: Icon(
              Icons.directions_car,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        Text(
          globals.appName.toString(),
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ],
    ),
  );
}

Widget buildMenuItems(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(24),
    child: Wrap(
      runSpacing: 16,
      children: [
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: Text(
            "Home",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.black),
          ),
          onTap: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const HomePage(
                      title: globals.appName,
                    )));
          },
        ),
        const Divider(color: Colors.black54),
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(
            "Settings",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.black),
          ),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsPage(title: "Settings")));
          },
        )
      ],
    ),
  );
}
