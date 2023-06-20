import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  static final FaceDetectionService _instance =
      FaceDetectionService._internal();

  factory FaceDetectionService() => _instance;

  /// *******************************************
  /// *******************************************
  /// INITIALIZATION
  /// *******************************************
  /// *******************************************
  FaceDetectionService._internal() {
    neutralRotX = 0;
    neutralRotY = -25;
    //
    rotXOffset = 15;
    rotYLeftOffset = 25;
    rotYRightOffset = 20;
    eyeProbThreshold = 0.5;
    //
    faces = [];
    //
    rotX = 5;
    rotY = -25;
    leftEyeOpenProb = 1.0;
    rightEyeOpenProb = 1.0;
    //
    hasFaceCounter = 0;
    eyeCounter = 0;
    rotXCounter = 0;
    rotYCounter = 0;
    //
    rotXDelay = 10;
    rotYDelay = 25;
    additionalDelay = 20;
    //
    reminderCount = 0;
    reminderType = "None";
    hasReminded = false;
    isReminding = false;
    //
    hasFace = false;
  }

  double neutralRotX = 0,
      neutralRotY = -25,
      //
      rotXOffset = 15,
      rotYLeftOffset = 20,
      rotYRightOffset = 10,
      eyeProbThreshold = 0.5;
  //
  List<Face> faces = [];
  double? rotX = 0, rotY = -25, leftEyeOpenProb = 1.0, rightEyeOpenProb = 1.0;
  double? filteredRotX = 0,
      filteredRotY = -25,
      filteredLeftEyeOpenProb = 1.0,
      filteredRightEyeOpenProb = 1.0;
  //
  int hasFaceCounter = 0;
  int eyeCounter = 0;
  int rotXCounter = 0;
  int rotYCounter = 0;
  double? previousFilteredRotX = 0;
  double? previousFilteredRotY = -25;
  double? previousFilteredLeftEyeOpenProb = 1.0;
  double? previousFilteredRightEyeOpenProb = 1.0;
  double timeConstant = 0.5;
  //
  int rotXDelay = 10, rotYDelay = 25;
  int additionalDelay = 20;
  //
  int reminderCount = 0;
  String reminderType = "None";
  bool hasReminded = false;
  bool isReminding = false;
  //
  bool hasFace = false;

  /// *******************************************
  /// *******************************************
  /// FUNCTIONS
  /// *******************************************
  /// *******************************************

  void clearPreviousFilteredFace() {
    previousFilteredRotX = neutralRotX;
    previousFilteredRotY = neutralRotY;
    previousFilteredLeftEyeOpenProb = 1.0;
    previousFilteredRightEyeOpenProb = 1.0;
  }

  void runLowPassFilter() {
    filteredRotX = timeConstant * (previousFilteredRotX ?? 0) +
        (1.0 - timeConstant) * (rotX ?? 0);
    filteredRotY = timeConstant * (previousFilteredRotY ?? -25) +
        (1.0 - timeConstant) * (rotY ?? -25);
    filteredLeftEyeOpenProb =
        timeConstant * (previousFilteredLeftEyeOpenProb ?? 1.0) +
            (1.0 - timeConstant) * (leftEyeOpenProb ?? 1.0);
    filteredRightEyeOpenProb =
        timeConstant * (previousFilteredRightEyeOpenProb ?? 1.0) +
            (1.0 - timeConstant) * (rightEyeOpenProb ?? 1.0);
  }

  void updatePreviousFilteredFace() {
    previousFilteredRotX = filteredRotX;
    previousFilteredRotY = filteredRotY;
    previousFilteredLeftEyeOpenProb = filteredLeftEyeOpenProb;
    previousFilteredRightEyeOpenProb = filteredRightEyeOpenProb;
  }

  void checkHasFace() {
    if (faces.isEmpty) {
      hasFaceCounter++;
    } else {
      hasFaceCounter = 0;
      hasFace = true;
    }
    if (hasFaceCounter > 50) {
      hasFace = false;
    }
  }

  void checkEyesClosed() {
    if (filteredLeftEyeOpenProb != null && filteredRightEyeOpenProb != null) {
      if (filteredLeftEyeOpenProb! < eyeProbThreshold &&
          filteredRightEyeOpenProb! < eyeProbThreshold) {
        eyeCounter++;
      } else {
        eyeCounter = 0;
      }
      if (eyeCounter > 10) {
        reminderType = "Drowsy";
        isReminding = true;
        reminderCount++;
        eyeCounter = 0;
      }
    }
  }

  void checkNormalPosition() {
    if (filteredRotX != null &&
        filteredRotY != null &&
        filteredLeftEyeOpenProb != null &&
        filteredRightEyeOpenProb != null) {
      if (filteredRotX! > (neutralRotX - rotXOffset) &&
          filteredRotY! > (neutralRotY - rotYRightOffset) &&
          filteredRotY! < (neutralRotY + rotYLeftOffset) &&
          filteredLeftEyeOpenProb! > eyeProbThreshold &&
          filteredRightEyeOpenProb! > eyeProbThreshold) {
        reminderCount = 0;
        reminderType = "None";
        hasReminded = false;
        isReminding = false;
      }
    }
  }

  void checkHeadDown(int delay) {
    if (filteredRotX! < (neutralRotX - rotXOffset)) {
      rotXCounter++;
    } else {
      rotXCounter = 0;
    }
    if (rotXCounter > delay) {
      reminderType = "Drowsy";
      isReminding = true;
      reminderCount++;
      rotXCounter = 0;
    }
  }

  void checkHeadLeftRight(int delay) {
    if (filteredRotY! > (neutralRotY + rotYLeftOffset) ||
        filteredRotY! < (neutralRotY - rotYRightOffset)) {
      rotYCounter++;
    } else {
      rotYCounter = 0;
    }
    if (rotYCounter > delay) {
      reminderType = "Inattentive";
      isReminding = true;
      reminderCount++;
      rotYCounter = 0;
    }
  }
}
