library globals;

const appName = 'Drive Smart';
double faceCenterX = 0.5, faceCenterY = 0.5;
double neutralRotX = 5, neutralRotY = -25;
double neutralAccelX = 0.0, neutralAccelY = 9.8, neutralAccelZ = 0.0;
double resultantAccel = 0;
bool hasCalibrated = false;
bool useAccelerometer = false;
bool inCalibrationMode = true;
bool showDebug = false;
bool showCameraPreview = true;
bool useHighCameraResolution = false;
var alarmAudioPath = "audio/car_horn_high.mp3";
