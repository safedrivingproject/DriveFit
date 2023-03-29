import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import '/theme/color_schemes.g.dart';
import '/settings/settings_page.dart';
import '../service/database_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: true);
  Color _appBarBgColor = Colors.transparent;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  bool get _isSliverAppBarExpanded {
    return _scrollController.hasClients &&
        _scrollController.offset > (180 - kToolbarHeight);
  }

  double _getTitleOpacity() {
    var opacity;
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
    var opacity;
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
    var opacity;
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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              28, 14, 28, 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 0, 0, 28),
                                      child: Text(
                                        'Drive Summary',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge
                                            ?.copyWith(
                                                height: 1,
                                                color: lightColorScheme
                                                    .onPrimary
                                                    .withOpacity(
                                                        _getLargeTitleOpacity())),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16, 16, 16, 8),
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
                                          ?.copyWith(
                                              color: lightColorScheme
                                                  .inverseSurface),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('11',
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayLarge),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(4, 0, 0, 12),
                                          child: Text('safe trips',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      color: lightColorScheme
                                                          .inverseSurface)),
                                        ),
                                        const SizedBox(width: 20),
                                        Text('23',
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayLarge),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(4, 0, 0, 12),
                                            child: Text(
                                                'potential accidents avoided',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: lightColorScheme
                                                            .inverseSurface)),
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
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              28, 0, 28, 14),
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  8, 14, 8, 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            12, 0, 0, 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Overall Avg. Score',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(0, 4, 0, 0),
                                              child: Text(
                                                '4.2/5',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displaySmall,
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0, 4, 0, 0),
                                              child: Icon(
                                                Icons.star_rounded,
                                                color: Color(0xFFF6C91A),
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
                                          const EdgeInsetsDirectional.fromSTEB(
                                              12, 0, 12, 0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Avg. Score (Last 7 days)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(0, 4, 0, 0),
                                                child: Text(
                                                  '4.8/5',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .displaySmall,
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 4, 0, 0),
                                                child: Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFFF6C91A),
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
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              28, 0, 28, 14),
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16, 16, 16, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 8, 0, 16),
                                    child: Text(
                                      'Trend of drowsy alerts',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  AspectRatio(
                                    aspectRatio: 1.2,
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 16, 16, 16),
                                      child: LineChart(drowsyCountData()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              28, 0, 28, 14),
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
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16, 16, 16, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 8, 0, 16),
                                    child: Text(
                                      'Trend of inattentive alerts',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  AspectRatio(
                                    aspectRatio: 1.2,
                                    child: Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0, 16, 16, 16),
                                      child: LineChart(inattentiveCountData()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SessionsList(),
                      ],
                    ), // Data Column
                  ),
                ],
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
        horizontalInterval: getMaxY(getRecentDrowsyData())! > 25 ? 5 : 1,
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
      maxX: 14,
      minY: 0,
      maxY: (getMaxY(getRecentDrowsyData())! / 5).ceil() * 5,
      lineBarsData: [
        LineChartBarData(
          spots: getRecentDrowsyData(),
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

  List<FlSpot> getRecentDrowsyData() {
    var list = <FlSpot>[];
    for (double i = 0; i <= 14; i++) {
      list.add(FlSpot(i, 14 - i));
    }
    return list;
  }

  LineChartData inattentiveCountData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: getMaxY(getRecentInattentiveData())! > 25 ? 5 : 1,
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
      maxX: 14,
      minY: 0,
      maxY: (getMaxY(getRecentInattentiveData())! / 5).ceil() * 5,
      lineBarsData: [
        LineChartBarData(
          spots: getRecentInattentiveData(),
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

  List<FlSpot> getRecentInattentiveData() {
    var list = <FlSpot>[];
    for (double i = 0; i <= 14; i++) {
      list.add(FlSpot(i, i + 4));
    }
    return list;
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
    switch (value.toInt()) {
      case 0:
        text = const Text('Past', style: style);
        break;
      case 14:
        text = const Text('Recent', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

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
    switch (value.toInt()) {
      case 0:
        text = '0';
        break;
      case 5:
        text = '5';
        break;
      case 10:
        text = '10';
        break;
      case 15:
        text = '15';
        break;
      case 20:
        text = '20';
        break;
      case 25:
        text = '25';
        break;
      case 30:
        text = '30';
        break;
      case 35:
        text = '35';
        break;
      case 40:
        text = '40';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }
}

class SessionsList extends StatefulWidget {
  @override
  _SessionsListState createState() => _SessionsListState();
}

class _SessionsListState extends State<SessionsList> {
  List<SessionData> _sessions = [];

  @override
  void initState() {
    super.initState();
    _getRecentSessions();
  }

  Future<void> _getRecentSessions() async {
    DatabaseService databaseHelper = DatabaseService();
    List<SessionData> sessions = await databaseHelper.getRecentSessions();
    setState(() {
      _sessions = sessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _sessions.length,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        SessionData session = _sessions[index];
        return ListTile(
          title: Text('Session ${session.id}'),
          subtitle: Text('Start Time: ${session.startTime}'),
          trailing: Column(
            children: [
              Text('End Time: ${session.endTime}'),
              Text('Drowsy Alert Count: ${session.drowsyAlerts}'),
              Text('Inattentive Alert Count: ${session.inattentiveAlerts}'),
            ],
          ),
        );
      },
    );
  }
}
