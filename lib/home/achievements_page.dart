import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:skeleton_loader/skeleton_loader.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:drive_fit/theme/custom_color.g.dart';

import '../settings/settings_page.dart';
import '/service/database_service.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({
    super.key,
    required this.sessionsList,
  });
  final List<SessionData> sessionsList;

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final DatabaseService databaseService = DatabaseService();
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: true);
  double _scrollOffset = 0.0;

  List<SessionData> driveSessionsList = [];
  int totalScore = 0;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset = _scrollController.offset;
      if (mounted) {
        setState(() {});
      }
    });
    if (!_isInitialized) {
      getSessionData();
      if (mounted) setState(() {});
    }
    _isInitialized = true;
  }

  void getSessionData() {
    driveSessionsList = widget.sessionsList;
    totalScore = databaseService.getTotalScore(driveSessionsList);
  }

  @override
  void dispose() {
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

  double _getLargeTitleOpacity() {
    double opacity;
    var threshold = 100 - kToolbarHeight;
    if (_scrollOffset > (threshold + 50)) {
      return 0.0;
    } else if (_scrollOffset > threshold) {
      opacity = 1 - ((_scrollOffset - threshold) / 50);
    } else {
      return 1.0;
    }
    return opacity;
  }

  Widget _body() {
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: lightColorScheme.background,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x35000000),
                offset: Offset(0, 1),
              )
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: lightColorScheme.background,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 7, 0, 14),
                child: Text(
                  'Your rank is:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: lightColorScheme.primary),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
                child: Stack(
                  alignment: const AlignmentDirectional(0, 1),
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.width * 0.6,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.network(
                            'https://picsum.photos/seed/501/600',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.08,
                      decoration: const BoxDecoration(),
                      alignment: const AlignmentDirectional(0, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://picsum.photos/seed/501/600',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://picsum.photos/seed/501/600',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.38,
                            height: 50,
                            decoration: const BoxDecoration(),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://picsum.photos/seed/501/600',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.05,
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    'https://picsum.photos/seed/501/600',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Ferrari',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: lightColorScheme.primary),
              ),
              Text(
                '8 more points to the next level',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: lightColorScheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast),
            slivers: [
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.settings),
                  color: lightColorScheme.background,
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            const SettingsPage(title: "Settings")));
                  },
                ),
                title: Text('Achievements',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        'Achievements',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                height: 1,
                                color: lightColorScheme.onPrimary
                                    .withOpacity(_getLargeTitleOpacity())),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 28),
                      _body(),
                    ],
                  ), // Data Column
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
