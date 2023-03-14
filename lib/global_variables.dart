library globals;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/color_schemes.g.dart';

const appName = 'Drive Fit';
double faceCenterX = 0.5, faceCenterY = 0.5;
double neutralRotX = 5, neutralRotY = -25;
double neutralAccelX = 0.0, neutralAccelY = 9.8, neutralAccelZ = 0.0;
double rotXOffset = 15,
    rotYLeftOffset = 25,
    rotYRightOffset = 15,
    eyeProbThreshold = 0.3;
double resultantAccel = 0;
bool hasCalibrated = false;
bool useAccelerometer = false;
bool inCalibrationMode = true;
bool showDebug = false;
bool showCameraPreview = true;
bool useHighCameraResolution = false;
var alarmAudioPath = "audio/car_horn_high.mp3";

TextTheme appTextTheme = TextTheme(
  displayLarge: GoogleFonts.outfit(
      textStyle: appTextTheme.displayLarge,
      fontWeight: FontWeight.w700,
      fontSize: 60,
      color: lightColorScheme.onBackground),
  displayMedium: GoogleFonts.outfit(
      textStyle: appTextTheme.displayMedium,
      fontWeight: FontWeight.w600,
      fontSize: 45,
      color: lightColorScheme.onBackground),
  displaySmall: GoogleFonts.outfit(
      textStyle: appTextTheme.displaySmall,
      fontWeight: FontWeight.w600,
      fontSize: 35,
      color: lightColorScheme.onBackground),
  headlineLarge: GoogleFonts.outfit(
      textStyle: appTextTheme.headlineLarge,
      fontWeight: FontWeight.w500,
      fontSize: 32,
      color: lightColorScheme.onBackground),
  headlineMedium: GoogleFonts.outfit(
      textStyle: appTextTheme.headlineMedium,
      fontWeight: FontWeight.w500,
      fontSize: 28,
      color: lightColorScheme.onBackground),
  headlineSmall: GoogleFonts.outfit(
      textStyle: appTextTheme.headlineSmall,
      fontWeight: FontWeight.w500,
      fontSize: 24,
      color: lightColorScheme.onBackground),
  titleLarge: GoogleFonts.outfit(
      textStyle: appTextTheme.titleLarge,
      fontWeight: FontWeight.w400,
      fontSize: 22,
      color: lightColorScheme.onBackground),
  titleMedium: GoogleFonts.outfit(
      textStyle: appTextTheme.titleMedium,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: lightColorScheme.onBackground),
  titleSmall: GoogleFonts.outfit(
      textStyle: appTextTheme.titleSmall,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: lightColorScheme.onBackground),
  bodyLarge: GoogleFonts.interTight(
      textStyle: appTextTheme.bodyLarge,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: lightColorScheme.onBackground),
  bodyMedium: GoogleFonts.interTight(
      textStyle: appTextTheme.bodyMedium,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: lightColorScheme.onBackground),
  bodySmall: GoogleFonts.interTight(
      textStyle: appTextTheme.bodySmall,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: lightColorScheme.onBackground),
  labelLarge: GoogleFonts.inter(
      textStyle: appTextTheme.labelLarge,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: lightColorScheme.onBackground),
  labelMedium: GoogleFonts.inter(
      textStyle: appTextTheme.labelMedium,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: lightColorScheme.onBackground),
  labelSmall: GoogleFonts.inter(
      textStyle: appTextTheme.labelSmall,
      fontWeight: FontWeight.w600,
      fontSize: 11,
      color: lightColorScheme.onBackground),
);
