import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../driving_mode/drive_session_summary.dart';
import '/theme/color_schemes.g.dart';
import '/theme/custom_color.g.dart';
import '../service/database_service.dart';

import 'package:localization/localization.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.sessionsList,
  });
  final List<SessionData> sessionsList;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseService databaseService = DatabaseService();
  bool isAtEndOfPage = false;

  List<SessionData> driveSessionsList = [];
  int rowCount = 0, totalAlerts = 0;
  double overallAvgScore = 0.0, recentAvgScore = 0.0;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      getSessionData();
      if (mounted) setState(() {});
    }
    _isInitialized = true;
  }

  void getSessionData() {
    driveSessionsList = widget.sessionsList;
    rowCount = databaseService.getRowCount(driveSessionsList);
    totalAlerts = databaseService.getDrowsyAlertCount(driveSessionsList) +
        databaseService.getInattentiveAlertCount(driveSessionsList);
    overallAvgScore = databaseService.getOverallAverageScore(driveSessionsList);
    recentAvgScore =
        databaseService.getRecentAverageScore(driveSessionsList, 7);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _body() {
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "so-far-you've-had".i18n(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: lightColorScheme.inverseSurface),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rowCount.toString(),
                        style: Theme.of(context).textTheme.displayLarge),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(4, 0, 0, 12),
                      child: Text(
                        "safe-trips".i18n(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: lightColorScheme.inverseSurface),
                        maxLines: 1,
                        
                      ),
                    ),
                    const Spacer(),
                    Text(totalAlerts.toString(),
                        style: Theme.of(context).textTheme.displayLarge),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(4, 0, 0, 12),
                      child: Text(
                        "reminders".i18n(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: lightColorScheme.inverseSurface),
                        maxLines: 1,
                        
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: lightColorScheme.onSecondary,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x35000000),
                  offset: Offset(0, 1),
                )
              ],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: lightColorScheme.onPrimary,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 14, 8, 14),
              child: Row(
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
                          "avg-score-overall".i18n(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 4, 0, 0),
                              child: Text(
                                '${overallAvgScore.toStringAsFixed(1)}/5',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 4, 0, 0),
                              child: Icon(
                                Icons.star_rounded,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "avg-score-last-7-sessions".i18n(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 4, 0, 0),
                                child: Text(
                                  '${recentAvgScore.toStringAsFixed(1)}/5',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 4, 0, 0),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: sourceXanthous,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: lightColorScheme.onSecondary,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x35000000),
                  offset: Offset(0, 1),
                )
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 16),
                    child: Text(
                      "trend-of-drowsy-alerts".i18n(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 16, 16, 16),
                      child: driveSessionsList.isNotEmpty
                          ? LineChart(drowsyCountData())
                          : SizedBox(
                              height: 75,
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                child: Text(
                                  "no-sessions-yet".i18n(),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: lightColorScheme.onSecondary,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x35000000),
                  offset: Offset(0, 1),
                )
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 16),
                    child: Text(
                      "trend-of-inattentive-alerts".i18n(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 16, 16, 16),
                      child: driveSessionsList.isNotEmpty
                          ? LineChart(inattentiveCountData())
                          : SizedBox(
                              height: 75,
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                child: Text(
                                  "no-sessions-yet".i18n(),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SessionsList(
          sessionsList: driveSessionsList,
          isAtEndOfPage: isAtEndOfPage,
        ),
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
            "drive-summary".i18n(),
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(height: 1, color: lightColorScheme.onPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          _body(),
        ],
      ), // Data Column
    );
  }

  LineChartData drowsyCountData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: getMaxY(getRecentDrowsyFlList())! > 25 ? 5 : 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: lightColorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: lightColorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(
            "past-driving-sessions".i18n(),
            style: TextStyle(
              fontSize: 12,
              color: lightColorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          axisNameSize: 30,
          axisNameWidget: Text(
            "no-of-alerts-per-session".i18n(),
            style: TextStyle(
              fontSize: 12,
              color: lightColorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border:
            Border.all(color: lightColorScheme.onBackground.withOpacity(0.2)),
      ),
      minX: 0,
      maxX: driveSessionsList.length > 14
          ? 13.0
          : driveSessionsList.length.toDouble() - 1,
      minY: 0,
      maxY: (getMaxY(getRecentDrowsyFlList())! / 5).ceil() * 5,
      lineBarsData: [
        LineChartBarData(
          spots: getRecentDrowsyFlList(),
          isCurved: false,
          color: lightColorScheme.primary,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
          ),
        ),
      ],
      lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: lightColorScheme.secondaryContainer)),
    );
  }

  List<FlSpot> getRecentDrowsyFlList() {
    var flSpotlist = <FlSpot>[];
    var sessionsDrowsyListInt = driveSessionsList
        .map((sessionData) => sessionData.drowsyAlertCount)
        .toList();
    var sessionsDrowsyListDouble =
        sessionsDrowsyListInt.map((count) => count.toDouble()).toList();
    for (int i = 0;
        i <
            (sessionsDrowsyListInt.length > 14
                ? 14
                : sessionsDrowsyListInt.length);
        i++) {
      flSpotlist.add(FlSpot(
          ((driveSessionsList.length > 14
                  ? 13.0
                  : driveSessionsList.length.toDouble() - 1) -
              i),
          sessionsDrowsyListDouble[i]));
    }
    return flSpotlist;
  }

  LineChartData inattentiveCountData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: getMaxY(getRecentInattentiveFlList())! > 25 ? 5 : 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: lightColorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: lightColorScheme.outline.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(
            "past-driving-sessions".i18n(),
            style: TextStyle(
              fontSize: 12,
              color: lightColorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          axisNameSize: 30,
          axisNameWidget: Text(
            "no-of-alerts-per-session".i18n(),
            style: TextStyle(
              fontSize: 12,
              color: lightColorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border:
            Border.all(color: lightColorScheme.onBackground.withOpacity(0.2)),
      ),
      minX: 0,
      maxX: driveSessionsList.length > 14
          ? 13.0
          : driveSessionsList.length.toDouble() - 1,
      minY: 0,
      maxY: (getMaxY(getRecentInattentiveFlList())! / 5).ceil() * 5,
      lineBarsData: [
        LineChartBarData(
          spots: getRecentInattentiveFlList(),
          isCurved: false,
          color: lightColorScheme.primary,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
          ),
        ),
      ],
      lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: lightColorScheme.secondaryContainer)),
    );
  }

  List<FlSpot> getRecentInattentiveFlList() {
    var flSpotlist = <FlSpot>[];
    var sessionsInattentiveListInt = driveSessionsList
        .map((sessionData) => sessionData.inattentiveAlertCount)
        .toList();
    var sessionsInattentiveListDouble =
        sessionsInattentiveListInt.map((count) => count.toDouble()).toList();
    for (int i = 0;
        i <
            (sessionsInattentiveListInt.length > 14
                ? 14
                : sessionsInattentiveListInt.length);
        i++) {
      flSpotlist.add(FlSpot(
          ((driveSessionsList.length > 14
                  ? 13.0
                  : driveSessionsList.length.toDouble() - 1) -
              i),
          sessionsInattentiveListDouble[i]));
    }
    return flSpotlist;
  }

  double? getMaxY(List<FlSpot> getList) {
    double? value = getList.fold(
        0,
        (previousValue, element) =>
            element.y > previousValue! ? element.y.toDouble() : previousValue);
    return value;
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    if (value.toInt() ==
        (driveSessionsList.length > 14 ? 13 : driveSessionsList.length - 1)) {
      text = Text("recent".i18n(), style: style);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: text,
      );
    } else if (value.toInt() == 0) {
      text = Text("past".i18n(), style: style);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: text,
      );
    }

    text = const Text('', style: style);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value.toInt() % 5 == 0) {
      text = value.toStringAsFixed(0);
      return Text(text, style: style, textAlign: TextAlign.left);
    } else {
      return Container();
    }
  }
}

class SessionsList extends StatefulWidget {
  final List<SessionData> sessionsList;
  final bool isAtEndOfPage;
  const SessionsList({
    super.key,
    required this.sessionsList,
    required this.isAtEndOfPage,
  });

  @override
  SessionsListState createState() => SessionsListState();
}

class SessionsListState extends State<SessionsList> {
  DateFormat noMillis = DateFormat("yyyy-MM-dd HH:mm:ss");
  DateFormat noSeconds = DateFormat("yyyy-MM-dd HH:mm");
  DateFormat noYearsSeconds = DateFormat("MM-dd HH:mm");

  String formatTime(DateFormat format, String time) {
    return format.format(DateTime.parse(time));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 16),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("previous-sessions".i18n(),
                  style: Theme.of(context).textTheme.titleMedium),
              Text("click-for-more-details".i18n(),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (widget.sessionsList.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.58,
                minHeight: 0.0),
            child: ListView.builder(
              itemCount: widget.sessionsList.length,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                SessionData session = widget.sessionsList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => DriveSessionSummary(
                              session: session,
                              isValidSession: true,
                              fromHistoryPage: true,
                              sessionIndex: index,
                            ))));
                  },
                  child: Card(
                    margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${formatTime(DateFormat.yMMMd(), session.startTime)} ${formatTime(DateFormat.jm(), session.startTime)} - ${formatTime(DateFormat.jm(), session.endTime)}",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${Duration(seconds: session.duration).inMinutes}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 0, 2),
                                child: Text(
                                  ' m ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${Duration(seconds: session.duration).inSeconds - (Duration(seconds: session.duration).inMinutes * 60)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 0, 2),
                                child: Text(
                                  ' s ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                session.distance >= 0
                                    ? (session.distance / 1000)
                                        .toStringAsFixed(2)
                                    : "N/A",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 0, 2),
                                child: Text(
                                  ' km ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "score".i18n(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${session.score}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    4, 0, 0, 0),
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                  child: ListView.builder(
                                    itemCount: session.score,
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return Icon(
                                        Icons.star_rounded,
                                        color: sourceXanthous,
                                        size: 24,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: SessionDetailsModule(
                                  icon: const Icon(Icons.info_outline_rounded),
                                  label: "drowsy".i18n(),
                                  value: session.drowsyAlertCount,
                                  trailing: locale == const Locale('zh', 'HK')
                                      ? "times".i18n([''])
                                      : (session.drowsyAlertCount == 1
                                          ? "times".i18n([''])
                                          : "times".i18n(['s'])),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: SessionDetailsModule(
                                  icon: const Icon(
                                      Icons.notifications_paused_outlined),
                                  label: "inattentive".i18n(),
                                  value: session.inattentiveAlertCount,
                                  trailing: locale == const Locale('zh', 'HK')
                                      ? "times".i18n()
                                      : (session.inattentiveAlertCount == 1
                                          ? "times".i18n([''])
                                          : "times".i18n(['s'])),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: SessionDetailsModule(
                                  icon: const Icon(Icons.speed),
                                  label: "speeding".i18n(),
                                  value: session.speedingCount,
                                  trailing: locale == const Locale('zh', 'HK')
                                      ? "times".i18n()
                                      : (session.speedingCount == 1
                                          ? "times".i18n([''])
                                          : "times".i18n(['s'])),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
            child: SizedBox(
              height: 75,
              width: MediaQuery.of(context).size.width,
              child: Text(
                "no-sessions-yet".i18n(),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class SessionDetailsModule extends StatelessWidget {
  const SessionDetailsModule({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
  });

  final Icon icon;
  final String label;
  final dynamic value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        icon,
        Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 0, 0),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(value.toString(),
                    style: Theme.of(context).textTheme.titleMedium),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                  child: Text(" $trailing",
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
