import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';

import 'face_detector_painter.dart';
import 'coordinates_translator.dart';
import 'global_variables.dart' as globals;

class AccelerometerView extends StatefulWidget {
  const AccelerometerView({
    Key? key,
  }) : super(key: key);

  @override
  State<AccelerometerView> createState() => _AccelerometerViewState();
}

class _AccelerometerViewState extends State<AccelerometerView> {
  bool _accelAvailable = false;
  List<double> _accelData = List.filled(3, 0.0);
  StreamSubscription? _accelSubscription;
  double? accelX, accelY, accelZ;

  @override
  void initState() {
    super.initState();
    _initAccelerometer();
  }

  @override
  void dispose() {
    _stopAccelerometer();
    super.dispose();
  }

  void _initAccelerometer() async {
    await SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result) {
      setState(() {
        _accelAvailable = result;
      });
      _startAccelerometer();
    });
  }

  Future<void> _startAccelerometer() async {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: Sensors.SENSOR_DELAY_GAME,
      );
      _accelSubscription = stream.listen((sensorEvent) {
        setState(() {
          _accelData = sensorEvent.data;
          accelX = _accelData[0];
          accelY = _accelData[1];
          accelZ = _accelData[2];
        });
      });
    }
  }

  void _stopAccelerometer() {
    if (_accelSubscription == null) return;
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (MediaQuery.of(context).orientation == Orientation.portrait)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AccelValueWidget(text: "accelX", value: accelX),
                AccelValueWidget(text: "accelY", value: accelY),
                AccelValueWidget(text: "accelZ", value: accelZ),
              ],
            ),
          ),
      ],
    );
  }
}

class AccelValueWidget extends StatelessWidget {
  const AccelValueWidget({
    Key? key,
    required this.text,
    required this.value,
  }) : super(key: key);

  final String text;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 50,
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: Theme.of(context).textTheme.displaySmall),
            Text(value.toString(),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
