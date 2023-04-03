import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

import '/theme/color_schemes.g.dart';
import '/theme/custom_color.g.dart';
import '/settings/settings_page.dart';
import '../service/database_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseService databaseService = DatabaseService();
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: true);
  double _scrollOffset = 0.0;
  bool isAtEndOfPage = false;

  List<SessionData> driveSessionsList = [];
  int rowCount = 0, totalAlerts = 0;
  double overallAvgScore = 0.0, recentAvgScore = 0.0;

  bool _isloading = true, _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset = _scrollController.offset;
      if (_scrollController.position.atEdge) {
        isAtEndOfPage = _scrollController.position.pixels != 0;
      }
      if (mounted) {
        setState(() {});
      }
      print(isAtEndOfPage);
    });
    if (!_isInitialized) {
      _loadData();
    }
    _isInitialized = true;

    getSessionData();
  }

  Future _loadData() async {
    await getSessionData();
    if (mounted) {
      setState(() {
        _isloading = false;
      });
    }
  }

  Future<void> getSessionData() async {
    driveSessionsList.clear();
    driveSessionsList = await databaseService.getAllSessions();
    rowCount = databaseService.getRowCount(driveSessionsList);
    totalAlerts = databaseService.getDrowsyAlertCount(driveSessionsList) +
        databaseService.getInattentiveAlertCount(driveSessionsList);
    overallAvgScore = databaseService.getOverallAverageScore(driveSessionsList);
    recentAvgScore =
        databaseService.getRecentAverageScore(driveSessionsList, 7);
    if (mounted) {
      setState(() {});
    }
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
    if (_isloading) {
      return ListView.separated(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: lightColorScheme.background),
            child: SkeletonLoader(
              builder: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 14, 0, 14),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.03,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: lightColorScheme.background),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.03,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: lightColorScheme.background),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const SizedBox(height: 28);
        },
      );
    } else {
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
                borderRadius: BorderRadius.circular(8),
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
                    'So far, you\'ve had',
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
                        child: Text('safe trips',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: lightColorScheme.inverseSurface)),
                      ),
                      const SizedBox(width: 20),
                      Text(totalAlerts.toString(),
                          style: Theme.of(context).textTheme.displayLarge),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(4, 0, 0, 12),
                          child: Text('reminders',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: lightColorScheme.inverseSurface)),
                        ),
                      ),
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
                borderRadius: BorderRadius.circular(8),
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
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avg. Score \n(Overall)',
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
                              'Avg. Score \n(Last 7 sessions)',
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 16),
                      child: Text(
                        'Trend of drowsy alerts',
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
                                    "No sessions yet :/\nStart driving to begin a session now :)",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 16),
                      child: Text(
                        'Trend of inattentive alerts',
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
                                    "No sessions yet :/\nStart driving to begin a session now :)",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              title: Text('Drive Summary',
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
                    Flexible(
                      child: Text(
                        'Drive Summary',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                height: 1,
                                color: lightColorScheme.onPrimary
                                    .withOpacity(_getLargeTitleOpacity())),
                        textAlign: TextAlign.center,
                      ),
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
            'Past driving sessions',
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
            'No. of alerts / session',
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
    for (int i = 0; i < sessionsDrowsyListInt.length; i++) {
      flSpotlist.add(FlSpot(
          ((driveSessionsList.length > 14
                  ? 13.0
                  : driveSessionsList.length.toDouble()) -
              i -
              1),
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
            'Past driving sessions',
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
            'No. of alerts / session',
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
    for (int i = 0; i < sessionsInattentiveListInt.length; i++) {
      flSpotlist.add(FlSpot(
          ((driveSessionsList.length > 14
                  ? 13.0
                  : driveSessionsList.length.toDouble()) -
              i -
              1),
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
    if (value.toInt() == 0) {
      text = const Text('Past', style: style);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: text,
      );
    }
    if (value.toInt() ==
        (driveSessionsList.length > 14 ? 13 : driveSessionsList.length - 1)) {
      text = const Text('Recent', style: style);
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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: lightColorScheme.background,
              width: 1,
            ),
          ),
          child: Text("Previous Sessions:",
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (widget.sessionsList.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.builder(
              itemCount: widget.sessionsList.length,
              shrinkWrap: true,
              physics: widget.isAtEndOfPage
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                SessionData session = widget.sessionsList[index];
                return Card(
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
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              '${Duration(seconds: session.duration).inMinutes}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0, 0, 0, 2),
                              child: Text(
                                ' min ',
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
                                ' seconds ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SessionDetailsModule(
                              icon: const Icon(Icons.info_outline_rounded),
                              label: "Drowsy:",
                              value: session.drowsyAlertCount,
                              trailing:
                                  " time${session.drowsyAlertCount == 1 ? "" : "s"}",
                            ),
                            const SizedBox(width: 10),
                            SessionDetailsModule(
                              icon: const Icon(
                                  Icons.notifications_paused_outlined),
                              label: "Inattentive:",
                              value: session.inattentiveAlertCount,
                              trailing:
                                  " time${session.inattentiveAlertCount == 1 ? "" : "s"}",
                            ),
                            const SizedBox(width: 10),
                            SessionDetailsModule(
                              icon: Icon(
                                Icons.star_rounded,
                                color: sourceXanthous,
                                size: 24,
                              ),
                              label: "Score:",
                              value: session.score,
                              trailing: "",
                            ),
                          ],
                        ),
                      ],
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
                "No sessions yet :/",
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
      children: [
        icon,
        const SizedBox(width: 10),
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
                  child: Text(trailing,
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
