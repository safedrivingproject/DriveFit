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
    neutralRotX = 5;
    neutralRotY = -25;
    //
    rotXOffset = 15;
    rotYLeftOffset = 25;
    rotYRightOffset = 20;
    eyeProbThreshold = 0.3;
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
    reminderCount = 0;
    reminderType = "None";
    //
    hasFace = false;
  }

  double neutralRotX = 5,
      neutralRotY = -25,
      //
      rotXOffset = 15,
      rotYLeftOffset = 25,
      rotYRightOffset = 20,
      eyeProbThreshold = 0.3;
  //
  List<Face> faces = [];
  double? rotX = 5,
      rotY = -25,
      leftEyeOpenProb = 1.0,
      rightEyeOpenProb = 1.0;
  //
  int hasFaceCounter = 0;
  int eyeCounter = 0;
  int rotXCounter = 0;
  int rotYCounter = 0;
  //
  int reminderCount = 0;
  String reminderType = "None";
  //
  bool hasFace = false;

  /// *******************************************
  /// *******************************************
  /// FUNCTIONS
  /// *******************************************
  /// *******************************************
  void checkHasFace() {
    if (faces.isEmpty) {
      hasFaceCounter++;
    } else {
      hasFaceCounter = 0;
      hasFace = true;
    }
    if (hasFaceCounter > 30) {
      hasFace = false;
    }
  }

  void checkEyesClosed() {
    if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
      if (leftEyeOpenProb! < eyeProbThreshold &&
          rightEyeOpenProb! < eyeProbThreshold) {
        eyeCounter++;
      } else {
        eyeCounter = 0;
      }
      if (reminderCount >= 3) {
        reminderType = "None";
        return;
      }
      if (eyeCounter > 10) {
        reminderType = "Drowsy";
        reminderCount++;
        eyeCounter = 0;
      }
    }
  }

  void checkNormalPosition() {
    if (rotX != null &&
        rotY != null &&
        leftEyeOpenProb != null &&
        rightEyeOpenProb != null) {
      if (rotX! > (neutralRotX - rotXOffset) &&
          rotX! < (neutralRotX + rotXOffset) &&
          rotY! > (neutralRotY - rotYRightOffset) &&
          rotY! < (neutralRotY + rotYLeftOffset) &&
          leftEyeOpenProb! > eyeProbThreshold &&
          rightEyeOpenProb! > eyeProbThreshold) {
        reminderCount = 0;
        reminderType = "None";
      }
    }
  }

  void checkHeadUpDown() {
    if (rotX! < (neutralRotX - rotXOffset) ||
        rotX! > (neutralRotX + rotXOffset)) {
      rotXCounter++;
    } else {
      rotXCounter = 0;
    }
    if (reminderCount >= 3) {
        reminderType = "None";
        return;
      }
    if (rotXCounter > 10) {
      reminderType = "Drowsy";
      reminderCount++;
      rotXCounter = 0;
    }
  }

  void checkHeadLeftRight() {
    if (rotY! > (neutralRotY + rotYLeftOffset) ||
        rotY! < (neutralRotY - rotYRightOffset)) {
      rotYCounter++;
    } else {
      rotYCounter = 0;
    }
    if (reminderCount >= 3) {
        reminderType = "None";
        return;
      }
    if (rotYCounter > 25) {
      reminderType = "Inattentive";
      reminderCount++;
      rotYCounter = 0;
    }
  }
}
