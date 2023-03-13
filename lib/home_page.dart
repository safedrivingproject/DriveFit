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
          color: lightColorScheme.onPrimary,
          iconSize: 30.0,
          padding: const EdgeInsets.all(8.0),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsPage(title: "Settings")));
          },
        ),
        backgroundColor: lightColorScheme.primary,
        elevation: 0,
        toolbarHeight: kToolbarHeight + 1.25,
      ),
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
                  colors: [lightColorScheme.primary, Color(0x0062A8AC)],
                  stops: [0, 1],
                  begin: AlignmentDirectional(0, -1),
                  end: AlignmentDirectional(0, 1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                              border: Border.all(width: 2.0),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20))),
                          constraints: const BoxConstraints(minHeight: 100),
                          alignment: Alignment.center,
                          child: Text(
                            globals.appName,
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                              minHeight: 100, maxHeight: 500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(70),
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
                        child: Text(
                          "Calibrate",
                          style: Theme.of(context).textTheme.labelLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 10),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(70),
                        ),
                        onPressed: () {
                          if (globals.hasCalibrated == true) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DrivingView(
                                          calibrationMode: false,
                                          accelerometerOn:
                                              globals.useAccelerometer
                                                  ? true
                                                  : false,
                                        )));
                          } else if (globals.hasCalibrated == false) {
                            null;
                          }
                        },
                        child: Text(
                          "Start Driving",
                          style: globals.hasCalibrated == true
                              ? Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: lightColorScheme.secondary)
                              : Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: lightColorScheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
