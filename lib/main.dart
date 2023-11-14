import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:localization/localization.dart';

import 'home/home_page.dart';
import 'notifications/notification_controller.dart';
import '/service/shared_preferences_service.dart';
import 'global_variables.dart' as globals;

import 'theme/color_schemes.g.dart';
import 'theme/custom_color.g.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseUIAuth.configureProviders([
    EmailLinkAuthProvider(
      actionCodeSettings: ActionCodeSettings(
        url: "https://drivefituser.page.link/home",
        androidPackageName: "com.example.drive_fit",
        handleCodeInApp: true,
        androidMinimumVersion: '5',
      ),
    ),
    EmailAuthProvider(),
  ]);
  imageCache.clear();
  await NotificationController.initializeLocalNotifications();
  cameras = await availableCameras();
  await SharedPreferencesService.init();
  runApp(const MyApp());
}

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
          const ForegroundTaskOptions(interval: 5000, autoRunOnBoot: false));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale? _locale;

  changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    _initForegroundTask();
    FlutterForegroundTask.setOnLockScreenVisibility(true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    LocalJsonLocalization.delegate.directories = ['lib/i18n'];

    final textTheme = Theme.of(context).textTheme;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        CustomColors lightCustomColors = lightCustomColorsOriginal;

        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightColorScheme;
          lightCustomColors = lightCustomColorsOriginal.harmonized(lightScheme);
        } else {
          lightScheme = lightColorScheme;
        }

        return MaterialApp(
            locale: _locale,
            localeResolutionCallback: (locale, supportedLocales) {
              if (supportedLocales.contains(locale)) {
                return locale;
              }

              if (locale?.languageCode == 'en') {
                return const Locale('en', 'US');
              }
              return const Locale('zh', 'HK');
            },
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              LocalJsonLocalization.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'HK'),
              Locale('en', 'US'),
            ],
            navigatorKey: MyApp.navigatorKey,
            scaffoldMessengerKey: globals.snackbarKey,
            title: globals.appName,
            debugShowCheckedModeBanner: false,
            home: const HomePage(),
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
