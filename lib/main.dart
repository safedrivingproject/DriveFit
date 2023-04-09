import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'home/home_page.dart';
import 'notifications/notification_controller.dart';
import '/service/shared_preferences_service.dart';
import 'global_variables.dart' as globals;

import 'theme/color_schemes.g.dart';
import 'theme/custom_color.g.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  imageCache.clear();
  await NotificationController.initializeLocalNotifications();
  cameras = await availableCameras();
  await SharedPreferencesService.init();
  runApp(const MyApp());
}

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // You can use the getData function to get the stored data.
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can use the clearAllData function to clear all the stored data.
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    print('onButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp("/resume-route");
    _sendPort?.send('onNotificationPressed');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _initForegroundTask() {
    FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'drivefit_foreground_service',
            channelName: 'DriveFit Foreground Service',
            channelDescription: 'Notification channel for foreground services.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            iconData: const NotificationIconData(
              resType: ResourceType.drawable,
              resPrefix: ResourcePrefix.ic,
              name: 'bg_service_small',
            )),
        iosNotificationOptions:
            const IOSNotificationOptions(showNotification: false),
        foregroundTaskOptions:
            const ForegroundTaskOptions(interval: 5000, autoRunOnBoot: true));
  }

  Future<void> _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.restartService();
    } else {
      FlutterForegroundTask.startService(
        notificationTitle: 'Going to drive?',
        notificationText: 'Tap to start DriveFit!',
      );
    }
  }

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    _initForegroundTask();
    _startForegroundTask();
    FlutterForegroundTask.setOnLockScreenVisibility(true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightColorScheme;
          lightCustomColors = lightCustomColors.harmonized(lightScheme);

          darkScheme = darkColorScheme;
          darkCustomColors = darkCustomColors.harmonized(darkScheme);
        } else {
          lightScheme = lightColorScheme;
          darkScheme = darkColorScheme;
        }

        return MaterialApp(
            navigatorKey: MyApp.navigatorKey,
            scaffoldMessengerKey: globals.snackbarKey,
            title: globals.appName,
            debugShowCheckedModeBanner: false,
            home: const HomePage(title: globals.appName),
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: lightScheme,
              extensions: [lightCustomColors],
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
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: lightColorScheme.onBackground),
                titleMedium: GoogleFonts.outfit(
                    textStyle: textTheme.titleMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: lightColorScheme.onBackground),
                titleSmall: GoogleFonts.outfit(
                    textStyle: textTheme.titleSmall,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
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
            ));
      },
    );
  }
}
