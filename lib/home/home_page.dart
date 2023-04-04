import 'package:flutter/material.dart';
import 'package:bottom_bar_page_transition/bottom_bar_page_transition.dart';

import '/service/database_service.dart';
import 'drive_page.dart';
import 'history_page.dart';
import 'achievements_page.dart';

class HomePage extends StatefulWidget {
  final String? title;
  final int? index;
  const HomePage({super.key, this.title, this.index});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService databaseService = DatabaseService();
  int selectedPageIndex = 1;
  List<SessionData> driveSessionsList = [];

  @override
  void initState() {
    super.initState();
    selectedPageIndex = widget.index ?? 0;
    getSessionData();
  }

  Future<void> getSessionData() async {
    driveSessionsList = await databaseService.getAllSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(milliseconds: 500),
        selectedIndex: selectedPageIndex,
        onDestinationSelected: (int index) {
          if (mounted) {
            setState(() {
            selectedPageIndex = index;
          });
          }
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
      body: BottomBarPageTransition(
        builder: (context, index) => _getBody(index),
        currentIndex: selectedPageIndex,
        totalLength: 3,
        transitionType: TransitionType.fade,
        transitionDuration: const Duration(milliseconds: 500),
        transitionCurve: Curves.easeInOutExpo,
      ),
    );
  }

  Widget _getBody(int index) {
    if (index == 0) {
      return DrivePage(
        sessionsList: driveSessionsList,
      );
    } else if (index == 1) {
      return HistoryPage(
        sessionsList: driveSessionsList,
      );
    } else if (index == 2) {
      return AchievementsPage(
        sessionsList: driveSessionsList,
      );
    }
    return Center(
        child: Text(
      "Error: Unknown route",
      style: Theme.of(context).textTheme.headlineLarge,
    ));
  }
}
