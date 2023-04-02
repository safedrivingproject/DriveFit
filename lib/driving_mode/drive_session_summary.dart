import 'package:drive_fit/home/home_page.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/service/database_service.dart';

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
                                      (widget.session.distance / 1000)
                                          .toStringAsFixed(2),
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
                    Navigator.of(context).pop();
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
}
