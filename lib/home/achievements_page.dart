import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:drive_fit/service/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:skeleton_loader/skeleton_loader.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:drive_fit/theme/custom_color.g.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'rank_list.dart';
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

class _AchievementsPageState extends State<AchievementsPage>
    with TickerProviderStateMixin {
  final DatabaseService databaseService = DatabaseService();
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: true);
  double _scrollOffset = 0.0;

  List<SessionData> driveSessionsList = [];
  int totalScore = 0;
  int rankScore = 0;
  int scoreStreak = 0;

  bool _isInitialized = false;

  int rankIndex = 0;
  String rankName = "Toyota";

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
      getRank();
      calcScoreStreak();
      if (mounted) setState(() {});
    }
    _isInitialized = true;
  }

  void getSessionData() {
    driveSessionsList = widget.sessionsList;
    scoreStreak = SharedPreferencesService.getInt('scoreStreak', 0);
    totalScore = databaseService.getTotalScore(driveSessionsList);
  }

  void getRank() {
    rankScore = totalScore + scoreStreak;
    rankIndex = rankList
        .lastIndexWhere((element) => rankScore >= element["requiredScore"]);
    rankName = rankList[rankIndex]["name"];
  }

  Future<void> calcScoreStreak() async {
    if (driveSessionsList.isEmpty) {
      scoreStreak = 0;
      return;
    }
    scoreStreak = 0;
    for (var session in driveSessionsList) {
      if (session.score == 5) {
        scoreStreak++;
      } else {
        break;
      }
    }
    SharedPreferencesService.setInt('scoreStreak', scoreStreak);
  }

  String _getRequiredScoreForNextRank() {
    if (rankIndex == rankList.length - 1) {
      return "Great job! You are at the highest rank!";
    }
    var requiredScore = rankList[rankIndex + 1]["requiredScore"] - rankScore;
    return "$requiredScore more point${requiredScore == 1 ? "" : "s"} to the next rank!";
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

  Widget _getPreviousCarImages() {
    if (rankIndex > 1) {
      String previousRankName1 = rankList[rankIndex - 1]["name"];
      String previousRankName2 = rankList[rankIndex - 2]["name"];
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.05,
              height: MediaQuery.of(context).size.width * 0.05,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image(
                image: AssetImage("./assets/cars/$previousRankName2.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.05,
              height: MediaQuery.of(context).size.width * 0.05,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image(
                image: AssetImage("./assets/cars/$previousRankName1.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    } else if (rankIndex > 0) {
      String previousRankName = rankList[rankIndex - 1]["name"];
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.05,
          height: MediaQuery.of(context).size.width * 0.05,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Image(
            image: AssetImage("./assets/cars/$previousRankName.png"),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(height: MediaQuery.of(context).size.width * 0.05),
    );
  }

  Widget _getFollowingCarImages() {
    if (rankIndex < rankList.length - 2) {
      String followingRankName1 = rankList[rankIndex + 1]["name"];
      String followingRankName2 = rankList[rankIndex + 2]["name"];
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.05,
              height: MediaQuery.of(context).size.width * 0.05,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image(
                image: AssetImage("./assets/cars/$followingRankName1.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.05,
              height: MediaQuery.of(context).size.width * 0.05,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image(
                image: AssetImage("./assets/cars/$followingRankName2.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    } else if (rankIndex < rankList.length - 1) {
      String followingRankName = rankList[rankIndex + 1]["name"];
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.05,
          height: MediaQuery.of(context).size.width * 0.05,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Image(
            image: AssetImage("./assets/cars/$followingRankName.png"),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(height: MediaQuery.of(context).size.width * 0.05),
    );
  }

  double getRankProgress() {
    if (rankIndex < rankList.length - 1) {
      var difference = rankList[rankIndex + 1]["requiredScore"] -
          rankList[rankIndex]["requiredScore"];
      return (rankScore - rankList[rankIndex]["requiredScore"]) / difference;
    }
    return 1.0;
  }

  Widget _body() {
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: lightColorScheme.background,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x35000000),
                offset: Offset(0, 1),
              )
            ],
            borderRadius: BorderRadius.circular(16),
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
                  'Your rank:',
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
                    CircularPercentIndicator(
                      animation: true,
                      animationDuration: 2000,
                      animateFromLastPercent: true,
                      curve: Curves.easeInOutQuint,
                      circularStrokeCap: CircularStrokeCap.round,
                      radius: MediaQuery.of(context).size.width * 0.3,
                      lineWidth: 20.0,
                      percent: getRankProgress(),
                      center: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image(
                          image: AssetImage("./assets/cars/$rankName.png"),
                          fit: BoxFit.cover,
                          isAntiAlias: true,
                        ),
                      ),
                      progressColor: sourceXanthous,
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
                          _getPreviousCarImages(),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 50,
                            decoration: const BoxDecoration(),
                          ),
                          _getFollowingCarImages(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AutoSizeText(
                rankName,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: lightColorScheme.primary),
                maxLines: 1,
              ),
              Text(
                _getRequiredScoreForNextRank(),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: lightColorScheme.primary),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: lightColorScheme.background,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x35000000),
                offset: Offset(0, 1),
              )
            ],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lightColorScheme.background,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your score streak:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 4, 0, 0),
                              child: Text(
                                '$scoreStreak',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 8, 0, 0),
                              child: Icon(
                                Icons.local_fire_department,
                                color: sourceXanthous,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                      child: Text(
                        'FYI: Your score streak is the number of consecutive sessions in which you got max points.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            'Achievements',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                height: 1,
                color: lightColorScheme.onPrimary
                    .withOpacity(_getLargeTitleOpacity())),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          _body(),
        ],
      ), // Data Column
    );
  }
}
