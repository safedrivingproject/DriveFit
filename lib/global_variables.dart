library globals;

import 'package:flutter/material.dart';

const appName = 'Drive Fit';

double faceCenterX = 0.5, faceCenterY = 0.5;
double neutralAccelX = 0.0, neutralAccelY = 9.8, neutralAccelZ = 0.0;
double resultantAccel = 0;

bool hasCalibrated = false;
bool useAccelerometer = false;
bool enableGeolocation = true;
bool showDebug = false;
bool showCameraPreview = false;
bool useHighCameraResolution = false;
List<String> drowsyAlarmValue = ["asset", "audio/car_horn_high.mp3"];
List<String> inattentiveAlarmValue = ["asset", "audio/double_beep.mp3"];

bool inCalibrationMode = false;

bool hasSignedIn = false;

GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();
