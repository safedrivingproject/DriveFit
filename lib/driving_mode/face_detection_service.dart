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
    _neutralRotX = 5;
    _neutralRotY = -25;
    //
    _rotXOffset = 15;
    _rotYLeftOffset = 25;
    _rotYRightOffset = 20;
    _eyeProbThreshold = 0.3;
    //
    _faces = [];
    //
    _rotX = 5;
    _rotY = -25;
    _leftEyeOpenProb = 1.0;
    _rightEyeOpenProb = 1.0;
    //
    _hasFaceCounter = 0;
    _eyeCounter = 0;
    _rotXCounter = 0;
    _rotYCounter = 0;
    //
    _reminderCount = 0;
    _reminderType = "None";
    //
    _hasFace = false;
  }

  double _neutralRotX = 5,
      _neutralRotY = -25,
      //
      _rotXOffset = 15,
      _rotYLeftOffset = 25,
      _rotYRightOffset = 20,
      _eyeProbThreshold = 0.3;
  //
  List<Face> _faces = [];
  double? _rotX = 5,
      _rotY = -25,
      _leftEyeOpenProb = 1.0,
      _rightEyeOpenProb = 1.0;
  //
  int _hasFaceCounter = 0;
  int _eyeCounter = 0;
  int _rotXCounter = 0;
  int _rotYCounter = 0;
  //
  int _reminderCount = 0;
  String _reminderType = "None";
  //
  bool _hasFace = false;

  double get neutralRotX => _neutralRotX;
  double get neutralRotY => _neutralRotY;
  //
  double get rotXOffset => _rotXOffset;
  double get rotYLeftOffset => _rotYLeftOffset;
  double get rotYRightOffset => _rotYRightOffset;
  double get eyeProbThreshold => _eyeProbThreshold;
  //
  List<Face> get faces => _faces;
  //
  double? get rotX => _rotX;
  double? get rotY => _rotY;
  double? get leftEyeOpenProb => _leftEyeOpenProb;
  double? get rightEyeOpenProb => _rightEyeOpenProb;
  //
  int get hasFaceCounter => _hasFaceCounter;
  int get eyeCounter => _eyeCounter;
  int get rotXCounter => _rotXCounter;
  int get rotYCounter => _rotYCounter;
  //
  int get reminderCount => _reminderCount;
  String get reminderType => _reminderType;
  //
  bool get hasFace => _hasFace;

  set neutralRotX(double value) => _neutralRotX = value;
  set neutralRotY(double value) => _neutralRotY = value;
  //
  set rotXOffset(double value) => _rotXOffset = value;
  set rotYLeftOffset(double value) => _rotYLeftOffset = value;
  set rotYRightOffset(double value) => _rotYRightOffset = value;
  set eyeProbThreshold(double value) => _eyeProbThreshold = value;
  //
  set faces(List<Face> values) => _faces = values;
  //
  set rotX(double? value) => _rotX = value;
  set rotY(double? value) => _rotY = value;
  set leftEyeOpenProb(double? value) => _leftEyeOpenProb = value;
  set rightEyeOpenProb(double? value) => _rightEyeOpenProb = value;
  //
  set hasFaceCounter(int value) => _hasFaceCounter = value;
  set eyeCounter(int value) => _eyeCounter = value;
  set rotXCounter(int value) => _rotXCounter = value;
  set rotYCounter(int value) => _rotYCounter = value;
  //
  set reminderCount(int value) => _reminderCount = value;
  set reminderType(String value) => _reminderType;
  //
  set hasFace(bool value) => _hasFace = value;

  /// *******************************************
  /// *******************************************
  /// FUNCTIONS
  /// *******************************************
  /// *******************************************
  void checkHasFace() {
    if (faces.isEmpty) {
      _hasFaceCounter++;
    } else {
      _hasFaceCounter = 0;
      _hasFace = true;
    }
    if (_hasFaceCounter > 30) {
      _hasFace = false;
    }
  }

  void checkEyesClosed() {
    if (_leftEyeOpenProb != null && _rightEyeOpenProb != null) {
      if (_leftEyeOpenProb! < _eyeProbThreshold &&
          _rightEyeOpenProb! < _eyeProbThreshold) {
        _eyeCounter++;
      } else {
        _eyeCounter = 0;
      }
      if (_reminderCount >= 3) {
        _reminderType = "None";
        return;
      }
      if (_eyeCounter > 10) {
        _reminderType = "Drowsy";
        _reminderCount++;
        _eyeCounter = 0;
      }
    }
  }

  void checkNormalPosition() {
    if (_rotX != null &&
        _rotY != null &&
        _leftEyeOpenProb != null &&
        _rightEyeOpenProb != null) {
      if (_rotX! > (_neutralRotX - _rotXOffset) &&
          _rotX! < (_neutralRotX + _rotXOffset) &&
          _rotY! > (_neutralRotY - _rotYRightOffset) &&
          _rotY! < (_neutralRotY + _rotYLeftOffset) &&
          _leftEyeOpenProb! > _eyeProbThreshold &&
          _rightEyeOpenProb! > _eyeProbThreshold) {
        _reminderCount = 0;
        _reminderType = "None";
      }
    }
  }

  void checkHeadUpDown() {
    if (_rotX! < (_neutralRotX - _rotXOffset) ||
        _rotX! > (_neutralRotX + _rotXOffset)) {
      _rotXCounter++;
    } else {
      _rotXCounter = 0;
    }
    if (_reminderCount >= 3) {
        _reminderType = "None";
        return;
      }
    if (_rotXCounter > 10) {
      _reminderType = "Drowsy";
      _reminderCount++;
      _rotXCounter = 0;
    }
  }

  void checkHeadLeftRight() {
    if (_rotY! > (_neutralRotY + _rotYLeftOffset) ||
        _rotY! < (_neutralRotY - _rotYRightOffset)) {
      _rotYCounter++;
    } else {
      _rotYCounter = 0;
    }
    if (_reminderCount >= 3) {
        _reminderType = "None";
        return;
      }
    if (_rotYCounter > 25) {
      _reminderType = "Inattentive";
      _reminderCount++;
      _rotYCounter = 0;
    }
  }
}
