import 'dart:math';

import 'package:drive_fit/home/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:geolocator/geolocator.dart';

import '/service/shared_preferences_service.dart';
import '/service/geolocation_service.dart';
import '/service/database_service.dart';
import '/service/ranking_service.dart';
import '/service/weather_service.dart';
import '/settings/settings_page.dart';
import 'drive_page.dart';
import 'history_page.dart';
import 'achievements_page.dart';
import '/global_variables.dart' as globals;
import 'tips.dart';

class HomePage extends StatefulWidget {
  final String? title;
  final int? index;
  const HomePage({super.key, this.title, this.index});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final DatabaseService databaseService = DatabaseService();
  final GeolocationService geolocationService = GeolocationService();
  final RankingService rankingService = RankingService();
  final WeatherService weatherService = WeatherService();
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: false);

  double _scrollOffset = 0.0;
  bool isAtEndOfPage = false;
  int selectedPageIndex = 0;

  List<SessionData> driveSessionsList = [];

  int totalAlertCount = 0,
      totalDrowsyAlertCount = 0,
      totalInattentiveAlertCount = 0;
  int latestAlertCount = 0,
      latestDrowsyAlertCount = 0,
      latestInattentiveAlertCount = 0;
  String tipType = "Generic";
  String oldTipType = "Generic";
  int tipsIndex = 0;

  DateTime currentDate = DateTime.now();
  String tipExpirationDay =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .toString();

  bool hasNewSession = true;

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  var opacityTweenSequence = <TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: ConstantTween<double>(0.0),
      weight: 80.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutExpo)),
      weight: 20.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    initHomePage();
  }

  Future<void> initHomePage() async {
    await checkPermissions();
    globals.hasSignedIn = FirebaseAuth.instance.currentUser != null;
    databaseService.updateUserProfile();
    if (globals.hasSignedIn) databaseService.saveUserDataToFirebase();
    selectedPageIndex = 0;
    _loadSettings();
    getWeather();
    getSessionData();
    rankingService.getScores();
    rankingService.getRank();
    _animationController.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(() {
      _scrollOffset = _scrollController.offset;
      if (_scrollController.position.atEdge) {
        isAtEndOfPage = _scrollController.position.pixels != 0;
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  void showRequestPermissionsDialog(String permissionType) {
    showDialog(
        context: context,
        builder: (BuildContext context) => RequestPermissionDialog(
              type: permissionType,
            ));
  }

  Future<void> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    String permissionType = "";

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      permissionType = "Services";
      geolocationService.hasPermission = false;
      showRequestPermissionsDialog(permissionType);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permissionType = "Permissions";
        geolocationService.hasPermission = false;
        showRequestPermissionsDialog(permissionType);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      permissionType = "Permissions";
      geolocationService.hasPermission = false;
      showRequestPermissionsDialog(permissionType);
      return;
    }

    geolocationService.hasPermission = true;
  }

  void _loadSettings() {
    tipsIndex = SharedPreferencesService.getInt('tipsIndex', 0);
    tipType = SharedPreferencesService.getString('tipType', "Generic");
    databaseService.drivingTip = getTip(tipType, tipsIndex);
    hasNewSession = databaseService.needSessionDataUpdate;
    currentDate = DateTime.now();
    tipExpirationDay = SharedPreferencesService.getString(
        'tipExpirationDay',
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .toString());
    weatherService.weatherExpirationHour = SharedPreferencesService.getString(
        'weatherExpirationHour',
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
                DateTime.now().hour)
            .toString());
    weatherService.currentWeatherConditionCode =
        SharedPreferencesService.getInt('currentWeatherConditionCode', -1);
    weatherService.currentWeatherMain =
        SharedPreferencesService.getString('currentWeatherMain', "Oops...");
    weatherService.currentWeatherDescription =
        SharedPreferencesService.getString(
            'currentWeatherDescription', "No weather information yet :(");
    weatherService.currentWeatherIconURL =
        SharedPreferencesService.getString('currentWeatherIconURL', "");
  }

  Future<void> getWeather() async {
    if (weatherService.currentWeatherConditionCode != null &&
        weatherService.currentWeatherConditionCode != -1) {
      if (currentDate
          .isBefore(DateTime.parse(weatherService.weatherExpirationHour))) {
        return;
      }
    }
    weatherService.position = await geolocationService.getCurrentPosition();
    await weatherService.getCurrentWeather();
    weatherService.extractWeatherConditionCode();
    weatherService.extractWeatherDescription();
    if (currentDate
            .isAfter(DateTime.parse(weatherService.weatherExpirationHour)) ||
        currentDate.isAtSameMomentAs(
            DateTime.parse(weatherService.weatherExpirationHour))) {
      weatherService.weatherExpirationHour =
          DateTime.parse(weatherService.weatherExpirationHour)
              .add(const Duration(hours: 1))
              .toString();
      SharedPreferencesService.setString(
          'weatherExpirationHour', weatherService.weatherExpirationHour);
    }
    if (mounted) setState(() {});
  }

  Future<void> getSessionData() async {
    driveSessionsList = await databaseService.getAllSessions();

    totalDrowsyAlertCount =
        databaseService.getDrowsyAlertCount(driveSessionsList);
    totalInattentiveAlertCount =
        databaseService.getInattentiveAlertCount(driveSessionsList);
    totalAlertCount = totalDrowsyAlertCount + totalInattentiveAlertCount;
    if (driveSessionsList.isNotEmpty) {
      latestDrowsyAlertCount = driveSessionsList[0].drowsyAlertCount;
      latestInattentiveAlertCount = driveSessionsList[0].inattentiveAlertCount;
      latestAlertCount = latestDrowsyAlertCount + latestInattentiveAlertCount;
    }
    getTipData();
    goToPage(widget.index);
  }

  void getTipData() {
    if (!hasNewSession) {
      if (currentDate.isBefore(DateTime.parse(tipExpirationDay))) {
        oldTipType = tipType;
        tipType = getTipType();
        SharedPreferencesService.setString('tipType', tipType);
        if (oldTipType != tipType) {
          generateNewTipIndex();
          SharedPreferencesService.setInt('tipsIndex', tipsIndex);
        }
        databaseService.drivingTip = getTip(tipType, tipsIndex);
        return;
      }
    }
    tipType = getTipType();
    SharedPreferencesService.setString('tipType', tipType);
    generateNewTipIndex();
    SharedPreferencesService.setInt('tipsIndex', tipsIndex);
    databaseService.drivingTip = getTip(tipType, tipsIndex);
    hasNewSession = false;
    if (currentDate.isAfter(DateTime.parse(tipExpirationDay)) ||
        currentDate.isAtSameMomentAs(DateTime.parse(tipExpirationDay))) {
      tipExpirationDay = DateTime.parse(tipExpirationDay)
          .add(const Duration(days: 1))
          .toString();
      SharedPreferencesService.setString('tipExpirationDay', tipExpirationDay);
    }
  }

  void generateNewTipIndex() {
    if (tipType == "Drowsy") {
      tipsIndex = Random().nextInt(drowsyTipsList.length);
    } else if (tipType == "Inattentive") {
      tipsIndex = Random().nextInt(inattentiveTipsList.length);
    } else {
      tipsIndex = Random().nextInt(genericTipsList.length);
    }
  }

  String getTipType() {
    if (latestAlertCount > 2) {
      if ((latestDrowsyAlertCount - latestInattentiveAlertCount) > 2) {
        return "Drowsy";
      } else if (latestInattentiveAlertCount - latestDrowsyAlertCount > 2) {
        return "Inattentive";
      }
    }
    return "Generic";
  }

  String getTip(String tipType, int index) {
    if (tipType == "Drowsy") {
      return drowsyTipsList[index];
    } else if (tipType == "Inattentive") {
      return inattentiveTipsList[index];
    }
    return genericTipsList[index];
  }

  Future<void> goToPage(int? index) async {
    await Future.delayed(const Duration(milliseconds: 100));
    selectedPageIndex = widget.index ?? 0;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _getTitleOpacity() {
    double opacity;
    var threshold = 150 - kToolbarHeight;
    if (_scrollOffset > (threshold + 50)) {
      return 1.0;
    } else if (_scrollOffset > threshold) {
      opacity = (_scrollOffset - threshold) / 50;
    } else {
      return 0.0;
    }
    return opacity;
  }

  double _getAppBarOpacity() {
    double opacity;
    var threshold = 150 - kToolbarHeight;
    if (_scrollOffset > (threshold + 50)) {
      return 1.0;
    } else if (_scrollOffset > threshold) {
      opacity = (_scrollOffset - threshold) / 50;
    } else {
      return 0.0;
    }
    return opacity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(milliseconds: 500),
        selectedIndex: selectedPageIndex,
        onDestinationSelected: (int index) async {
          if (mounted) {
            setState(() {
              selectedPageIndex = index;
            });
          }
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutExpo);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.directions_car_outlined),
            icon: Icon(Icons.directions_car_outlined),
            label: 'Drive',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.bookmarks_outlined),
            icon: Icon(Icons.bookmarks_outlined),
            label: 'History',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.star_border_rounded),
            icon: Icon(Icons.star_border_rounded),
            label: 'Achievements',
          ),
        ],
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Container(
      color: lightColorScheme.background,
      child: Stack(
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
            shrinkWrap: true,
            physics: _getScrollPhysics(selectedPageIndex),
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.settings),
                  color: lightColorScheme.background,
                  onPressed: () {
                    Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (BuildContext context,
                                Animation<double> animation,
                                Animation<double> secondaryAnimation) =>
                            const SettingsPage(title: "Settings"),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .chain(CurveTween(curve: Curves.easeInOutExpo))
                                .animate(animation),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                        reverseTransitionDuration:
                            const Duration(milliseconds: 500)));
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.account_circle),
                    color: lightColorScheme.background,
                    onPressed: () {
                      if (globals.hasSignedIn) {
                        Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (BuildContext context,
                                    Animation<double> animation,
                                    Animation<double> secondaryAnimation) =>
                                ProfileScreen(
                                  appBar: AppBar(
                                    title: Text(
                                      "Your Profile",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    centerTitle: true,
                                  ),
                                  actions: [
                                    SignedOutAction((context) {
                                      globals.hasSignedIn = false;
                                      databaseService.updateUserProfile();
                                      showSnackBar("Signed out!");
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage()));
                                    })
                                  ],
                                  actionCodeSettings: ActionCodeSettings(
                                      url:
                                          "https://drivefituser.page.link/home"),
                                ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: Tween<double>(begin: 0.0, end: 1.0)
                                    .chain(
                                        CurveTween(curve: Curves.easeInOutExpo))
                                    .animate(animation),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 500)));
                      } else {
                        Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (BuildContext context,
                                    Animation<double> animation,
                                    Animation<double> secondaryAnimation) =>
                                LoginPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: Tween<double>(begin: 0.0, end: 1.0)
                                    .chain(
                                        CurveTween(curve: Curves.easeInOutExpo))
                                    .animate(animation),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 500)));
                      }
                    },
                  ),
                ],
                title: Text(_getAppBarTitle(selectedPageIndex),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: lightColorScheme.onPrimary
                            .withOpacity(_getTitleOpacity()))),
                centerTitle: true,
                pinned: true,
                snap: false,
                floating: false,
                toolbarHeight: kToolbarHeight + 1.25,
                backgroundColor:
                    lightColorScheme.primary.withOpacity(_getAppBarOpacity()),
                scrolledUnderElevation: 4,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              SliverToBoxAdapter(
                child: _getAnimation(),
              )
            ],
          ),
        ],
      ),
    );
  }

  void showSnackBar(String text) {
    var snackBar =
        SnackBar(content: Text(text), duration: const Duration(seconds: 2));
    globals.snackbarKey.currentState?.showSnackBar(snackBar);
  }

  Widget _getAnimation() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOutExpo))
              .animate(animation),
          child: child,
        );
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: _getPage(selectedPageIndex),
    );
  }

  ScrollPhysics _getScrollPhysics(int index) {
    if (index == 0) {
      return const NeverScrollableScrollPhysics();
    }
    if (index == 1) {
      return const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast);
    }
    if (index == 2) {
      return const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast);
    }
    return const NeverScrollableScrollPhysics();
  }

  String _getAppBarTitle(int index) {
    if (index == 0) return "";
    if (index == 1) return "Drive Summary";
    if (index == 2) return "Achievements";
    return "";
  }

  Widget _getPage(int index) {
    if (index == 0) {
      return DrivePage(
        sessionsList: driveSessionsList,
        key: const ValueKey<int>(0),
      );
    } else if (index == 1) {
      return HistoryPage(
        sessionsList: driveSessionsList,
        key: const ValueKey<int>(1),
      );
    } else if (index == 2) {
      return AchievementsPage(
        sessionsList: driveSessionsList,
        key: const ValueKey<int>(2),
      );
    }
    return Center(
        child: Text(
      "Error: Unknown route",
      style: Theme.of(context).textTheme.headlineLarge,
    ));
  }
}
