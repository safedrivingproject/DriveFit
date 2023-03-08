import 'package:drive_fit/settings_page.dart';
import 'package:flutter/material.dart';
import 'driving_view.dart';
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
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
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
                            border: Border.all(
                                color: Theme.of(context).primaryColorDark,
                                width: 2.0),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20))),
                        constraints: const BoxConstraints(minHeight: 100),
                        alignment: Alignment.center,
                        child: Text(
                          globals.appName,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                  color: Theme.of(context).primaryColorDark),
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
                        style: Theme.of(context).textTheme.displayMedium,
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
                                .displayMedium
                                ?.copyWith(color: Colors.white)
                            : Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(color: Colors.lightBlue[800]),
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
        ),
      ),
      drawer: const NavigationDrawer(),
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
