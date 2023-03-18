import 'dart:async';
import 'dart:core';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';

import 'camera_view.dart';
import '/home/home_page.dart';
import 'driving_logic.dart';
import '/global_variables.dart' as globals;

class DrivingView extends StatefulWidget {
  const DrivingView({
    Key? key,
    required this.calibrationMode,
    required this.accelerometerOn,
  }) : super(key: key);

  final bool calibrationMode;
  final bool accelerometerOn;

  @override
  State<DrivingView> createState() => _DrivingViewState();
}

class _DrivingViewState extends State<DrivingView> {
  int caliSeconds = 3;
  Timer? periodicDetectionTimer, periodicCalibrationTimer;
  bool cancelTimer = false;
  bool carMoving = false;

  CustomPaint? _customPaint;
  String? _text;

  double? rotX = globals.neutralRotX,
      rotY = globals.neutralRotY,
      rotZ = 0,
      leftEyeOpenProb = 1.0,
      rightEyeOpenProb = 1.0;
  double maxAccelThreshold = 1.0;
  List<Face> faces = [];

  bool startCalibration = false;

  List<double> accelData = List.filled(3, 0.0);
  double accelX = 0, accelY = 0, accelZ = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.calibrationMode == true)
          Column(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: const [
                        CalibrateInstruction(
                          bullet: "1.",
                          instruction: "Secure your phone in the phone holder",
                        ),
                        SizedBox(height: 5),
                        CalibrateInstruction(
                          bullet: "2.",
                          instruction:
                              "Make sure your head is visible in the camera preview",
                        ),
                        SizedBox(height: 5),
                        CalibrateInstruction(
                          bullet: "3.",
                          instruction:
                              "Look forward towards the road (just like when you are driving attentively)",
                        ),
                        SizedBox(height: 5),
                        CalibrateInstruction(
                          bullet: "4.",
                          instruction: "Press 'Calibrate' and wait 3 seconds",
                        ),
                      ],
                    ),
                  ),
                  if (startCalibration == true)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black.withOpacity(0.5),
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        caliSeconds < 1 ? "Complete!" : "$caliSeconds",
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: lightColorScheme.onPrimary,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16.0))),
                        backgroundColor: lightColorScheme.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        if (startCalibration == false) {
                          DrivingLogicState().calibrationTimer();
                        }
                      },
                      child: Text(
                        "Calibrate",
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: lightColorScheme.onPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          )
        else if (widget.calibrationMode == false)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    backgroundColor: lightColorScheme.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (context) {
                      return const HomePage(title: globals.appName);
                    }));
                  },
                  child: Text(
                    "Stop driving",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.onPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        Column(
          children: [
            if (MediaQuery.of(context).orientation == Orientation.portrait)
              Column(
                children: [
                  if (globals.showDebug == true)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          DataValueWidget(
                              text: "rotX", value: DrivingLogicState().rotX),
                          DataValueWidget(
                              text: "rotY", value: DrivingLogicState().rotY),
                          DataValueWidget(
                              text: "neutralRotX", value: globals.neutralRotX),
                          DataValueWidget(
                              text: "neutralRotY", value: globals.neutralRotY),
                          DataValueWidget(
                              text: "leftEyeOpenProb",
                              value: DrivingLogicState().leftEyeOpenProb),
                          DataValueWidget(
                              text: "rightEyeOpenProb",
                              value: DrivingLogicState().rightEyeOpenProb),
                          if (widget.accelerometerOn == true)
                            Column(
                              children: [
                                DataValueWidget(
                                    text: "carMoving",
                                    value:
                                        DrivingLogicState().carMoving ? 1 : 0),
                                DataValueWidget(
                                    text: "resultantAccel",
                                    value: globals.resultantAccel),
                                DataValueWidget(
                                    text: "accelX",
                                    value: DrivingLogicState().accelX),
                                DataValueWidget(
                                    text: "accelY",
                                    value: DrivingLogicState().accelY),
                                DataValueWidget(
                                    text: "accelZ",
                                    value: DrivingLogicState().accelZ),
                              ],
                            )
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class CalibrateInstruction extends StatelessWidget {
  const CalibrateInstruction({
    super.key,
    required this.bullet,
    required this.instruction,
  });

  final String bullet;
  final String instruction;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            bullet,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: lightColorScheme.onPrimary),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 10,
          child: Text(
            instruction,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: lightColorScheme.onPrimary),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class DataValueWidget extends StatelessWidget {
  const DataValueWidget({
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
            Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: lightColorScheme.onPrimary)),
            Text(value.toString(),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: lightColorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}
