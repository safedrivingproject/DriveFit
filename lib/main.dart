import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:workmanager/workmanager.dart';
import 'camera_logic.dart';

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'openCamera':
        initCamera();
        break;
      case 'closeCamera':
        stopLiveFeed();
        break;
    }
    return Future.value(true);
  });
}

List<CameraDescription> cameras = [];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appName = 'Face Detection from Google ML Kit';
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.lightBlue[800],
        fontFamily: 'Segoe UI',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              fontSize: 16.0, fontFamily: 'Arial', color: Colors.white),
          bodyMedium: TextStyle(
              fontSize: 14.0, fontFamily: 'Arial', color: Colors.white),
          bodySmall: TextStyle(
              fontSize: 12.0, fontFamily: 'Arial', color: Colors.white),
          displayLarge: TextStyle(
              fontSize: 50.0, fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium: TextStyle(
              fontSize: 35.0, fontWeight: FontWeight.bold, color: Colors.white),
          displaySmall: TextStyle(
              fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const Home(title: appName),
    );
  }
}

class Home extends StatelessWidget {
  final String title;
  const Home({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
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
                          'Smart Driving',
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
                      onPressed: () async {
                        await Workmanager().initialize(callbackDispatcher,
                            isInDebugMode: true);
                        await Workmanager().registerOneOffTask(
                            'openCamera', 'simpleTask',
                            constraints: Constraints(
                                networkType: NetworkType.not_required,
                                requiresBatteryNotLow: true));
                        //if (context.mounted) return;
                        //Navigator.push(
                        //    context,
                        //    MaterialPageRoute(
                        //        builder: (context) =>
                        //            const FaceDetectorView()));
                      },
                      child: Text(
                        "Start Face Detection",
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
                      onPressed: () async {
                        await Workmanager().initialize(callbackDispatcher,
                            isInDebugMode: true);
                        await Workmanager().registerOneOffTask(
                            'closeCamera', 'simpleTask',
                            constraints: Constraints(
                                networkType: NetworkType.not_required,
                                requiresBatteryNotLow: true));
                        //if (context.mounted) return;
                        //Navigator.push(
                        //    context,
                        //    MaterialPageRoute(
                        //        builder: (context) =>
                        //            const FaceDetectorView()));
                      },
                      child: Text(
                        "Stop Face Detection",
                        style: Theme.of(context).textTheme.displayMedium,
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
    );
  }
}
