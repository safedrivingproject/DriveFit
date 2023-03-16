import 'package:flutter/material.dart';
import '/settings_page.dart';
import '/theme/color_schemes.g.dart';
import 'drive_page.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    setState(() {});
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          color: lightColorScheme.background,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsPage(title: "Settings")));
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(milliseconds: 500),
        selectedIndex: selectedPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            selectedPageIndex = index;
          });
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
      body: [
        const DrivePage(),
        const HistoryPage(),
        const AchievementsPage(),
      ][selectedPageIndex],
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
