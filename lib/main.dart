import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home/home_page.dart';
import 'notifications/notification_controller.dart';
import 'global_variables.dart' as globals;

import 'theme/color_schemes.g.dart';
import 'theme/custom_color.g.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        title: globals.appName,
        debugShowCheckedModeBanner: false,
        home: const HomePage(title: globals.appName),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: lightColorScheme,
          textTheme: TextTheme(
            displayLarge: GoogleFonts.outfit(
                textStyle: textTheme.displayLarge,
                fontWeight: FontWeight.w700,
                fontSize: 60,
                color: lightColorScheme.onBackground),
            displayMedium: GoogleFonts.outfit(
                textStyle: textTheme.displayMedium,
                fontWeight: FontWeight.w700,
                fontSize: 45,
                color: lightColorScheme.onBackground),
            displaySmall: GoogleFonts.outfit(
                textStyle: textTheme.displaySmall,
                fontWeight: FontWeight.w700,
                fontSize: 35,
                color: lightColorScheme.onBackground),
            headlineLarge: GoogleFonts.interTight(
                textStyle: textTheme.headlineLarge,
                fontWeight: FontWeight.w600,
                fontSize: 32,
                color: lightColorScheme.onBackground),
            headlineMedium: GoogleFonts.interTight(
                textStyle: textTheme.headlineMedium,
                fontWeight: FontWeight.w600,
                fontSize: 28,
                color: lightColorScheme.onBackground),
            headlineSmall: GoogleFonts.interTight(
                textStyle: textTheme.headlineSmall,
                fontWeight: FontWeight.w600,
                fontSize: 24,
                color: lightColorScheme.onBackground),
            titleLarge: GoogleFonts.outfit(
                textStyle: textTheme.titleLarge,
                fontWeight: FontWeight.w400,
                fontSize: 22,
                color: lightColorScheme.onBackground),
            titleMedium: GoogleFonts.outfit(
                textStyle: textTheme.titleMedium,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: lightColorScheme.onBackground),
            titleSmall: GoogleFonts.outfit(
                textStyle: textTheme.titleSmall,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: lightColorScheme.onBackground),
            bodyLarge: GoogleFonts.interTight(
                textStyle: textTheme.bodyLarge,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: lightColorScheme.onBackground),
            bodyMedium: GoogleFonts.interTight(
                textStyle: textTheme.bodyMedium,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: lightColorScheme.onBackground),
            bodySmall: GoogleFonts.interTight(
                textStyle: textTheme.bodySmall,
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: lightColorScheme.onBackground),
            labelLarge: GoogleFonts.inter(
                textStyle: textTheme.labelLarge,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: lightColorScheme.onBackground),
            labelMedium: GoogleFonts.inter(
                textStyle: textTheme.labelMedium,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: lightColorScheme.onBackground),
            labelSmall: GoogleFonts.inter(
                textStyle: textTheme.labelSmall,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: lightColorScheme.onBackground),
          ),
          // const TextTheme(
          //   bodyLarge: TextStyle(fontSize: 16.0, fontFamily: 'Inter'),
          //   bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Inter'),
          //   bodySmall: TextStyle(fontSize: 12.0, fontFamily: 'Inter'),
          //   displayLarge: TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold),
          //   displayMedium: TextStyle(fontSize: 35.0, fontWeight: FontWeight.bold),
          //   displaySmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          // ),
        ));
  }
}
