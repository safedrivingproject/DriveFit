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
    liveFaceList = [];
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

  double neutralRotX = 5,
      neutralRotY = -25,
      //
      rotXOffset = 15,
      rotYLeftOffset = 20,
      rotYRightOffset = 10,
      eyeProbThreshold = 0.3;
  //
  List<Face> faces = [];
  double? rotX = 5, rotY = -25, leftEyeOpenProb = 1.0, rightEyeOpenProb = 1.0;
  //
  int hasFaceCounter = 0;
  int eyeCounter = 0;
  int rotXCounter = 0;
  int rotYCounter = 0;
  List<Map<String, double>> liveFaceList = [];
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

  void insertLiveFaceList() {}

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
    if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
      if (leftEyeOpenProb! < eyeProbThreshold &&
          rightEyeOpenProb! < eyeProbThreshold) {
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
    if (rotX != null &&
        rotY != null &&
        leftEyeOpenProb != null &&
        rightEyeOpenProb != null) {
      if (rotX! > (neutralRotX - rotXOffset) &&
          rotY! > (neutralRotY - rotYRightOffset) &&
          rotY! < (neutralRotY + rotYLeftOffset) &&
          leftEyeOpenProb! > eyeProbThreshold &&
          rightEyeOpenProb! > eyeProbThreshold) {
        reminderCount = 0;
        reminderType = "None";
        hasReminded = false;
        isReminding = false;
      }
    }
  }

  void checkHeadDown(int delay) {
    if (rotX! < (neutralRotX - rotXOffset)) {
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
    if (rotY! > (neutralRotY + rotYLeftOffset) ||
        rotY! < (neutralRotY - rotYRightOffset)) {
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
