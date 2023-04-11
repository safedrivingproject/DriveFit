import 'package:drive_fit/home/home_page.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/service/database_service.dart';
import '/service/ranking_service.dart';
import '/home/new_rank_screen.dart';

import '/theme/custom_color.g.dart';

class DriveSessionSummary extends StatefulWidget {
  const DriveSessionSummary(
      {super.key, required this.session, required this.isValidSession});

  final SessionData session;
  final bool isValidSession;

  @override
  State<DriveSessionSummary> createState() => _DriveSessionSummaryState();
}

class _DriveSessionSummaryState extends State<DriveSessionSummary> {
  final RankingService rankingService = RankingService();

  var opacityTweenSequence = <TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: ConstantTween<double>(0.0),
      weight: 50.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutExpo)),
      weight: 50.0,
    ),
  ];

  String formatTime(DateFormat format, String time) {
    return format.format(DateTime.tryParse(time) ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Container(
          color: lightColorScheme.surfaceVariant,
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
                width: MediaQuery.of(context).size.width,
                child: Align(
                  alignment: const AlignmentDirectional(0, 0),
                  child: Text(
                    'Drive Session Summary',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: lightColorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Align(
                      alignment: const AlignmentDirectional(0, 0),
                      child: Text(
                        formatTime(
                            DateFormat.yMMMd(), widget.session.startTime),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: lightColorScheme.primary),
                      ),
                    ),
                    Align(
                      alignment: const AlignmentDirectional(0, 0),
                      child: Text(
                        "${formatTime(DateFormat.jm(), widget.session.startTime)} - ${formatTime(DateFormat.jm(), widget.session.endTime)}",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: lightColorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 14),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Card(
                    color: lightColorScheme.onPrimary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Your score: ",
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(width: 10),
                          Text(
                            '${widget.session.score} / 5',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: ListView.builder(
                              itemCount: widget.session.score,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                return Icon(
                                  Icons.star_rounded,
                                  color: sourceXanthous,
                                  size: 24,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: lightColorScheme.onPrimary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("You drove for: ",
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.end,
                                  children: [
                                    Text(
                                      '${Duration(seconds: widget.session.duration).inMinutes}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 0, 0, 4),
                                      child: Text(
                                        ' min ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                    Text(
                                      '${Duration(seconds: widget.session.duration).inSeconds - (Duration(seconds: widget.session.duration).inMinutes * 60)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 0, 0, 4),
                                      child: Text(
                                        ' seconds ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("with a distance of: ",
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.end,
                                  children: [
                                    Text(
                                      widget.session.distance >= 0.01
                                          ? (widget.session.distance / 1000)
                                              .toStringAsFixed(2)
                                          : "N/A",
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 0, 0, 4),
                                      child: Text(
                                        ' km ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: lightColorScheme.onPrimary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("You were alerted of drowsiness for: ",
                              style: Theme.of(context).textTheme.titleMedium),
                          Row(
                            children: [
                              Text(
                                '${widget.session.drowsyAlertCount}',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              Text(
                                ' times',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          Text("and of inattentiveness for: ",
                              style: Theme.of(context).textTheme.titleMedium),
                          Row(
                            children: [
                              Text(
                                '${widget.session.inattentiveAlertCount}',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              Text(
                                ' times',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.isValidSession == false)
                Container(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 28),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    children: [
                      Align(
                        alignment: const AlignmentDirectional(0, 0),
                        child: Text(
                          "Journey is too short, session won't be counted.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: lightColorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    backgroundColor: lightColorScheme.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    var hasNewRank = checkForNewRank();
                    // if (showDebug) {
                    //   goToNewRankPage();
                    //   return;
                    // }
                    if (hasNewRank) {
                      goToNewRankPage();
                    } else {
                      goToHome();
                    }
                  },
                  child: Text(
                    "Return to home page",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.onPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool checkForNewRank() {
    rankingService.getRank();
    print(
        "${rankingService.previousRankIndex}, ${rankingService.currentRankIndex}");
    if (rankingService.currentRankIndex > rankingService.previousRankIndex) {
      return true;
    }
    return false;
  }

  void goToHome() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      barrierColor: lightColorScheme.primary,
      transitionDuration: const Duration(seconds: 1),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return const HomePage(index: 1);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity:
              TweenSequence<double>(opacityTweenSequence).animate(animation),
          child: child,
        );
      },
    ));
  }

  void goToNewRankPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        barrierColor: lightColorScheme.primary,
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return NewRankScreen(rankIndex: rankingService.currentRankIndex);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity:
                TweenSequence<double>(opacityTweenSequence).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
}
