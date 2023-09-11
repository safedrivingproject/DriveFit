import 'package:drive_fit/home/home_page.dart';
import 'package:drive_fit/service/navigation.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/service/database_service.dart';
import '/service/ranking_service.dart';
import '/home/new_rank_screen.dart';
import '/global_variables.dart' as globals;

import '/theme/custom_color.g.dart';

import 'package:localization/localization.dart';

class DriveSessionSummary extends StatefulWidget {
  const DriveSessionSummary(
      {super.key,
      required this.session,
      required this.isValidSession,
      required this.fromHistoryPage,
      required this.sessionIndex});

  final SessionData session;
  final bool isValidSession;
  final bool fromHistoryPage;
  final int sessionIndex;

  @override
  State<DriveSessionSummary> createState() => _DriveSessionSummaryState();
}

class _DriveSessionSummaryState extends State<DriveSessionSummary> {
  final RankingService rankingService = RankingService();
  final DatabaseService databaseService = DatabaseService();

  DateFormat onlyHMS = DateFormat("HH:mm:ss");

  String formatTime(DateFormat format, String time) {
    return format.format(DateTime.tryParse(time) ?? DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    widget.session.drowsyAlertTimestampsList =
        widget.session.drowsyAlertTimestamps.split(", ");
    widget.session.inattentiveAlertTimestampsList =
        widget.session.inattentiveAlertTimestamps.split(", ");
    widget.session.speedingTimestampsList =
        widget.session.speedingTimestamps.split(", ");
  }

  void showSnackBar(String text) {
    var snackBar = SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 1),
    );
    globals.snackbarKey.currentState?.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    final starCount =
        ((widget.session.score / (widget.session.duration / 60).ceil()) * 5)
            .round();

    return WillPopScope(
      onWillPop: () async {
        if (widget.fromHistoryPage) {
          return true;
        }
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          leading: widget.fromHistoryPage
              ? IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          actions: [
            if (widget.fromHistoryPage)
              IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("are-you-sure".i18n()),
                          content: Text("delete-session-description".i18n()),
                          actions: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                databaseService
                                    .deleteSessionLocal(widget.session);
                                if (globals.hasSignedIn) {
                                  databaseService
                                      .deleteSessionFirebase(widget.session);
                                }
                                rankingService.removeSessionScore(
                                    widget.session.score, widget.sessionIndex);
                                if (mounted) setState(() {});
                                showSnackBar("data-deleted".i18n());
                                goToHome();
                              },
                              child: Text("delete".i18n()),
                            ),
                          ],
                        );
                      });
                },
                icon: const Icon(Icons.delete),
              ),
          ],
        ),
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
                    "session-summary".i18n(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
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
              SizedBox(
                height: widget.isValidSession
                    ? MediaQuery.of(context).size.height * 0.7
                    : MediaQuery.of(context).size.height * 0.6,
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(28, 14, 28, 14),
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.fast),
                  children: [
                    Card(
                      color: lightColorScheme.onPrimary,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(16.0))),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text("your-score".i18n(),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(width: 10),
                            Text(
                              '${widget.session.score}',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Spacer(),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.05,
                              child: ListView.builder(
                                itemCount: starCount < 0 ? 0 : starCount,
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
                          borderRadius:
                              BorderRadius.all(Radius.circular(16.0))),
                      child: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("you-drove-for".i18n(),
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            "${Duration(seconds: widget.session.duration).inMinutes}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall,
                                      ),
                                      TextSpan(
                                        text: " m ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      TextSpan(
                                        text:
                                            "${Duration(seconds: widget.session.duration).inSeconds - (Duration(seconds: widget.session.duration).inMinutes * 60)}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall,
                                      ),
                                      TextSpan(
                                        text: " s ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("with-a-distance-of".i18n(),
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                const SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: widget.session.distance >= 0
                                            ? (widget.session.distance / 1000)
                                                .toStringAsFixed(2)
                                            : "N/A",
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall,
                                      ),
                                      TextSpan(
                                        text: widget.session.distance >= 0
                                            ? " km "
                                            : "",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
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
                          borderRadius:
                              BorderRadius.all(Radius.circular(16.0))),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("you-were-found-drowsy-for".i18n(),
                                style: Theme.of(context).textTheme.titleSmall),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${widget.session.drowsyAlertCount} ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
                                  ),
                                  TextSpan(
                                    text: locale == const Locale('zh', 'HK')
                                        ? "times".i18n([''])
                                        : (widget.session.drowsyAlertCount == 1
                                            ? "times".i18n([''])
                                            : "times".i18n(['s'])),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.session.drowsyAlertTimestamps.isNotEmpty)
                              ListView.builder(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8, 4, 0, 8),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget
                                    .session.drowsyAlertTimestampsList.length,
                                itemBuilder: (context, index) {
                                  String drowsyTimestamp = widget
                                      .session.drowsyAlertTimestampsList[index];
                                  if (index == 0) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "timestamps".i18n(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(formatTime(
                                            onlyHMS, drowsyTimestamp)),
                                      ],
                                    );
                                  } else {
                                    return Text(
                                        formatTime(onlyHMS, drowsyTimestamp));
                                  }
                                },
                              ),
                            Text("inattentive-for".i18n(),
                                style: Theme.of(context).textTheme.titleSmall),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        "${widget.session.inattentiveAlertCount} ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
                                  ),
                                  TextSpan(
                                    text: locale == const Locale('zh', 'HK')
                                        ? "times".i18n([''])
                                        : (widget.session
                                                    .inattentiveAlertCount ==
                                                1
                                            ? "times".i18n([''])
                                            : "times".i18n(['s'])),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            if (widget
                                .session.inattentiveAlertTimestamps.isNotEmpty)
                              ListView.builder(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8, 4, 0, 8),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.session
                                    .inattentiveAlertTimestampsList.length,
                                itemBuilder: (context, index) {
                                  String inattentiveTimestamp = widget.session
                                      .inattentiveAlertTimestampsList[index];
                                  if (index == 0) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "timestamps".i18n(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(formatTime(
                                            onlyHMS, inattentiveTimestamp)),
                                      ],
                                    );
                                  } else {
                                    return Text(formatTime(
                                        onlyHMS, inattentiveTimestamp));
                                  }
                                },
                              ),
                            Text("and-speeding-for".i18n(),
                                style: Theme.of(context).textTheme.titleSmall),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${widget.session.speedingCount} ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
                                  ),
                                  TextSpan(
                                    text: locale == const Locale('zh', 'HK')
                                        ? "times".i18n([''])
                                        : (widget.session.speedingCount == 1
                                            ? "times".i18n([''])
                                            : "times".i18n(['s'])),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            if (widget.session.speedingTimestamps.isNotEmpty)
                              ListView.builder(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8, 4, 0, 8),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget
                                    .session.speedingTimestampsList.length,
                                itemBuilder: (context, index) {
                                  String speedingTimestamp = widget
                                      .session.speedingTimestampsList[index];
                                  if (index == 0) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "timestamps".i18n(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(formatTime(
                                            onlyHMS, speedingTimestamp)),
                                      ],
                                    );
                                  } else {
                                    return Text(
                                        formatTime(onlyHMS, speedingTimestamp));
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
                          "journey-too-short".i18n(),
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
                padding: const EdgeInsets.all(12.0),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    backgroundColor: lightColorScheme.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    var hasNewRank = checkForNewRank();
                    if (hasNewRank) {
                      goToNewRankPage();
                    } else {
                      goToHome();
                    }
                  },
                  child: Text(
                    "ok".i18n(),
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
    if (rankingService.currentRankIndex > rankingService.previousRankIndex) {
      return true;
    }
    return false;
  }

  void goToHome() {
    FadeNavigator.pushReplacement(
        context,
        const HomePage(index: 1),
        FadeNavigator.opacityTweenSequence,
        lightColorScheme.primary,
        const Duration(milliseconds: 500));
  }

  void goToNewRankPage() {
    FadeNavigator.pushReplacement(
        context,
        NewRankScreen(rankIndex: rankingService.currentRankIndex),
        FadeNavigator.opacityTweenSequence,
        lightColorScheme.primary,
        const Duration(milliseconds: 500));
  }
}
