import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'home_page.dart';
import 'notification_controller.dart';
import 'notification_page.dart';
import 'global_variables.dart' as globals;

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationController.initializeLocalNotifications();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //static const String routeHome = '/', routeNotification = '/notification-page';

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    super.initState();
  }

  // List<Route<dynamic>> onGenerateInitialRoutes(String initialRouteName) {
  //  List<Route<dynamic>> pageStack = [];
  //  pageStack
  //      .add(MaterialPageRoute(builder: (_) => const Home(title: appName)));
  //  if (initialRouteName == routeNotification &&
  //      NotificationController.initialAction != null) {
  //    pageStack.add(MaterialPageRoute(
  //        builder: (_) => NotificationPage(
  //            receivedAction: NotificationController.initialAction!)));
  //  }
  //  return pageStack;
  //}

  //Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  //  switch (settings.name) {
  //    case routeHome:
  //      return MaterialPageRoute(builder: (_) => const Home(title: appName));

  //    case routeNotification:
  //      ReceivedAction receivedAction = settings.arguments as ReceivedAction;
  //      return MaterialPageRoute(
  //          builder: (_) => NotificationPage(receivedAction: receivedAction));
  //  }
  //  return null;
  //}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: globals.appName,
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: globals.appName),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue[800],
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
    );
  }
}
