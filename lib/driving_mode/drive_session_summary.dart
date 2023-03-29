import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import '/service/database_service.dart';

class DriveSessionSummary extends StatefulWidget {
  const DriveSessionSummary({super.key, required this.session});

  final SessionData session;

  @override
  State<DriveSessionSummary> createState() => _DriveSessionSummaryState();
}

class _DriveSessionSummaryState extends State<DriveSessionSummary> {
  @override
  Widget build(BuildContext context) {
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
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  '${widget.session.score} / 5',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF6C91A),
                                  size: 24,
                                ),
                              ],
                            ),
                          ]),
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
                                '${widget.session.drowsyAlerts}',
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
                                '${widget.session.inattentiveAlerts}',
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
