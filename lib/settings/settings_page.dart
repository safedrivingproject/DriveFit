import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:file_picker/file_picker.dart';

import '/home/home_page.dart';
import '../service/database_service.dart';
import '../service/shared_preferences_service.dart';
import '../global_variables.dart' as globals;

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService databaseService = DatabaseService();
  final _rotXController = TextEditingController();
  final _rotYController = TextEditingController();
  final _carVelocityController = TextEditingController();
  final _additionalDelayController = TextEditingController();
  final _restReminderController = TextEditingController();
  final _speedingVelocityController = TextEditingController();
  final _statesController = MaterialStatesController();
  bool? enableGeolocation,
      stationaryAlertsDisabled,
      showCameraPreview,
      useHighCameraResolution,
      showDebug,
      hasCalibrated;
  bool isInvalid = false;
  double? neutralRotX = 5, neutralRotY = -25;
  int? rotXDelay = 10, rotYDelay = 25, additionalDelay = 20;
  double? carVelocityThresholdMS = 8.33, carVelocityThresholdKMH = 30.0;
  double? speedingVelocityThresholdMS = 18.0,
      speedingVelocityThresholdKMH = 65.0;
  int? restReminderTime = 3600;
  List<String> drowsyAlarmValue = ["asset", "audio/car_horn_high.mp3"];
  List<String> inattentiveAlarmValue = ["asset", "audio/double_beep.mp3"];
  double _doubleValue = 1.0;
  int _intValue = 10;
  double _speedValue = 0.0;

  void _loadDefaultSettings() {
    if (mounted) {
      setState(() {
        enableGeolocation =
            SharedPreferencesService.getBool('enableGeolocation', true);
        stationaryAlertsDisabled =
            SharedPreferencesService.getBool('stationaryAlertsDisabled', false);
        additionalDelay =
            SharedPreferencesService.getInt('additionalDelay', 20);
        showCameraPreview =
            SharedPreferencesService.getBool('showCameraPreview', false);
        useHighCameraResolution =
            SharedPreferencesService.getBool('useHighCameraResolution', false);
        showDebug = SharedPreferencesService.getBool('showDebug', false);
        hasCalibrated =
            SharedPreferencesService.getBool('hasCalibrated', false);
        neutralRotX = SharedPreferencesService.getDouble('neutralRotX', 5.0);
        neutralRotY = SharedPreferencesService.getDouble('neutralRotY', -25.0);
        rotXDelay = SharedPreferencesService.getInt('rotXDelay', 10);
        rotYDelay = SharedPreferencesService.getInt('rotYDelay', 25);
        carVelocityThresholdMS =
            SharedPreferencesService.getDouble('carVelocityThreshold', 8.33);
        carVelocityThresholdKMH =
            (carVelocityThresholdMS! * 3.6).roundToDouble();
        drowsyAlarmValue = SharedPreferencesService.getStringList(
            'drowsyAlarm', ["asset", "audio/car_horn_high.mp3"]);
        inattentiveAlarmValue = SharedPreferencesService.getStringList(
            'inattentiveAlarm', ["asset", "audio/double_beep.mp3"]);
        restReminderTime =
            SharedPreferencesService.getInt('restReminderTime', 3600);
        speedingVelocityThresholdMS = SharedPreferencesService.getDouble(
            'speedingVelocityThreshold', 18.0);
        speedingVelocityThresholdKMH =
            (speedingVelocityThresholdMS! * 3.6).roundToDouble();
      });
    }
  }

  void _clearSPData() {
    SharedPreferencesService.clear();
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultSettings();
    _rotXController.addListener(() {
      onFieldChanged(_rotXController, true, false, false);
    });
    _rotYController.addListener(() {
      onFieldChanged(_rotYController, true, false, false);
    });
    _carVelocityController.addListener(() {
      onFieldChanged(_carVelocityController, false, true, false);
    });
    _additionalDelayController.addListener(() {
      onFieldChanged(_additionalDelayController, true, false, false);
    });
    _restReminderController.addListener(() {
      onFieldChanged(_restReminderController, false, false, true);
    });
    _speedingVelocityController.addListener(() {
      onFieldChanged(_speedingVelocityController, false, true, false);
    });
  }

  void onFieldChanged(TextEditingController controller, bool convertDelay,
      bool convertSpeed, bool convertSeconds) {
    if (mounted) {
      setState(() {
        if (controller.text.isEmpty ||
            RegExp(r'^\d*(?:\.\d*){2,}$').hasMatch(controller.text)) {
          isInvalid = true;
        } else {
          isInvalid = false;
        }
      });
    }
    if (isInvalid) {
      _statesController.update(MaterialState.disabled, true);
    } else if (!isInvalid) {
      _statesController.update(MaterialState.disabled, false);
      if (convertDelay) {
        if (mounted) {
          setState(() {
            _doubleValue = double.tryParse(controller.text) ?? 1.0;
            _intValue = (_doubleValue * 10).round();
          });
        }
      } else if (convertSpeed) {
        if (mounted) {
          setState(() {
            _doubleValue = (double.tryParse(controller.text) ?? 30.0);
            _speedValue = (_doubleValue / 3.6);
          });
        }
      } else if (convertSeconds) {
        if (mounted) {
          setState(() {
            _doubleValue = double.tryParse(controller.text) ?? 60.0;
            _intValue = (_doubleValue * 60).round();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _rotXController.dispose();
    _rotYController.dispose();
    _carVelocityController.dispose();
    _additionalDelayController.dispose();
    _restReminderController.dispose();
    _speedingVelocityController.dispose();
    _statesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushReplacement(PageRouteBuilder(
                    pageBuilder: (BuildContext context,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation) =>
                        const HomePage(title: globals.appName, index: 0),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0)
                            .chain(CurveTween(curve: Curves.easeInOutExpo))
                            .animate(animation),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                    reverseTransitionDuration:
                        const Duration(milliseconds: 500)));
              },
            )),
        body: SettingsList(sections: [
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Geolocation"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Enable Geolocation"),
                description:
                    const Text("Enables DriveFit to detect if car is moving."),
                leading: const Icon(Icons.place_outlined),
                initialValue: enableGeolocation,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      enableGeolocation = value;
                      SharedPreferencesService.setBool(
                          'enableGeolocation', value);
                    });
                  }
                },
              ),
              SettingsTile.switchTile(
                enabled: enableGeolocation == true,
                title: const Text("Disable alerts when car is not moving"),
                description:
                    const Text("Note: Alerts for closed eyes persist."),
                leading: const Icon(Icons.notifications_off_outlined),
                initialValue: stationaryAlertsDisabled,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      stationaryAlertsDisabled = value;
                      SharedPreferencesService.setBool(
                          'stationaryAlertsDisabled', value);
                    });
                  }
                },
              ),
              SettingsTile.navigation(
                  enabled: enableGeolocation == true
                      ? stationaryAlertsDisabled == false
                          ? true
                          : false
                      : false,
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Choose Additional Delay when car is stationary",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("${(additionalDelay! * 0.1).toStringAsFixed(1)} s"),
                    ],
                  ),
                  description: const Text(
                      "The additional delay before alerts are issued when car is stationary."),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit value'),
                          content: TextFormField(
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.always,
                            controller: _additionalDelayController,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            validator: (String? value) {
                              if (value == null ||
                                  RegExp(r'^\d*(?:\.\d*){2,}$')
                                      .hasMatch(value)) {
                                return 'Invalid value.';
                              } else {
                                return null;
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Delay (in seconds)',
                                hintText: 'e.g. 1.0'),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("Invalid value.");
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    additionalDelay = _intValue;
                                    SharedPreferencesService.setInt(
                                        'additionalDelay', _intValue);
                                  });
                                }
                                showSnackBar("Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ],
          ),
          SettingsSection(
            title: const Text("Driving"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Show camera preview when driving"),
                description: const Text(
                    "Whether you can see yourself in the driving page."),
                leading: const Icon(Icons.visibility_outlined),
                initialValue: showCameraPreview,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      showCameraPreview = value;
                      SharedPreferencesService.setBool(
                          'showCameraPreview', value);
                    });
                  }
                },
              ),
              SettingsTile.switchTile(
                title: const Text("Use High Camera Resolution"),
                description:
                    const Text("Not required, only impacts performance."),
                leading: const Icon(Icons.camera_enhance_outlined),
                initialValue: useHighCameraResolution,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      useHighCameraResolution = value;
                      SharedPreferencesService.setBool(
                          'useHighCameraResolution', value);
                    });
                  }
                },
              ),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Choose Vertical Head Movement Alert Sensitivity",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("${(rotXDelay! * 0.1).toStringAsFixed(1)} s"),
                    ],
                  ),
                  description: const Text(
                      "The delay between head tilted up/down and issuing alert."),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit value'),
                          content: TextFormField(
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.always,
                            controller: _rotXController,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            validator: (String? value) {
                              if (value == null ||
                                  RegExp(r'^\d*(?:\.\d*){2,}$')
                                      .hasMatch(value)) {
                                return 'Invalid value.';
                              } else {
                                return null;
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Delay (in seconds)',
                                hintText: 'e.g. 1.0'),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("Invalid value.");
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    rotXDelay = _intValue;
                                    SharedPreferencesService.setInt(
                                        'rotXDelay', _intValue);
                                  });
                                }
                                showSnackBar("Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text(
                            "Choose Horizontal Head Movement Alert Sensitivity"),
                      ),
                      const SizedBox(width: 10),
                      Text("${(rotYDelay! * 0.1).toStringAsFixed(1)} s")
                    ],
                  ),
                  description: const Text(
                      "The delay between head rotated left/right and issuing alert."),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit value'),
                          content: TextFormField(
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.always,
                            controller: _rotYController,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            validator: (String? value) {
                              if (value == null ||
                                  RegExp(r'^\d*(?:\.\d*){2,}$')
                                      .hasMatch(value)) {
                                return 'Invalid value.';
                              } else {
                                return null;
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Delay (in seconds)',
                                hintText: 'e.g. 2.5'),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("Invalid value.");
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    rotYDelay = _intValue;
                                    SharedPreferencesService.setInt(
                                        'rotYDelay', _intValue);
                                  });
                                }
                                showSnackBar("Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Choose Car Velocity Threshold",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "${(carVelocityThresholdKMH!).toStringAsFixed(1)} km/h"),
                    ],
                  ),
                  description:
                      const Text("The required speed for normal alerts."),
                  leading: const Icon(Icons.speed_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit value'),
                          content: TextFormField(
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.always,
                            controller: _carVelocityController,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            validator: (String? value) {
                              if (value == null ||
                                  RegExp(r'^\d*(?:\.\d*){2,}$')
                                      .hasMatch(value)) {
                                return 'Invalid value.';
                              } else {
                                return null;
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Threshold (in km/h)',
                                hintText: 'e.g. 30.0'),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("Invalid value.");
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    carVelocityThresholdMS = _speedValue;
                                    carVelocityThresholdKMH = _doubleValue;
                                    SharedPreferencesService.setDouble(
                                        'carVelocityThreshold', _speedValue);
                                  });
                                }
                                showSnackBar("Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                title: const Text(
                  "Select Drowsy Alert Alarm",
                ),
                leading: const Icon(Icons.edit_notifications_outlined),
                description:
                    const Text("Pick the desired sound for drowsy alarm."),
                onPressed: (context) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: const Text("Select Alarm"),
                          children: [
                            SimpleDialogOption(
                              child: const Text("High-pitched car horn"),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/car_horn_high.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Low-pitched car horn"),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/car_horn_low.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Double Beep"),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/double_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Soft Beep"),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/soft_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Choose sound from files"),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(type: FileType.audio);
                                if (result != null) {
                                  drowsyAlarmValue = [
                                    "file",
                                    result.files.first.path!
                                  ];
                                  SharedPreferencesService.setStringList(
                                      'drowsyAlarm', drowsyAlarmValue);
                                  showSnackBar("Alarm updated.");
                                } else {
                                  showSnackBar("Alarm unchanged.");
                                }
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
              SettingsTile.navigation(
                title: const Text(
                  "Select Inattentive Alert Alarm",
                ),
                leading: const Icon(Icons.edit_notifications_outlined),
                description:
                    const Text("Pick the desired sound for inattentive alarm."),
                onPressed: (context) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: const Text("Select Alarm"),
                          children: [
                            SimpleDialogOption(
                              child: const Text("High-pitched car horn"),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/car_horn_high.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Low-pitched car horn"),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/car_horn_low.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Double Beep"),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/double_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Soft Beep"),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/soft_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Choose from files"),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(type: FileType.audio);
                                if (result != null) {
                                  inattentiveAlarmValue = [
                                    "file",
                                    result.files.first.path!
                                  ];
                                  SharedPreferencesService.setStringList(
                                      'inattentiveAlarm',
                                      inattentiveAlarmValue);
                                  showSnackBar("Alarm updated.");
                                } else {
                                  showSnackBar("Alarm unchanged.");
                                }
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Long-duration Drive Resting Reminder Frequency",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "${(restReminderTime! / 60).toStringAsFixed(1)} min${restReminderTime == 1 ? "" : "s"}"),
                    ],
                  ),
                  description: const Text(
                      "The frequency of reminders to take a break from driving."),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit value'),
                          content: TextFormField(
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.always,
                            controller: _restReminderController,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            validator: (String? value) {
                              if (value == null ||
                                  RegExp(r'^\d*(?:\.\d*){2,}$')
                                      .hasMatch(value)) {
                                return 'Invalid value.';
                              } else {
                                return null;
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Frequency (in minutes)',
                                hintText: 'e.g. 60'),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("Invalid value.");
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    restReminderTime = _intValue;
                                    SharedPreferencesService.setInt(
                                        'restReminderTime', _intValue);
                                  });
                                }
                                showSnackBar("Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Choose Speeding Velocity Threshold",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "${(speedingVelocityThresholdKMH!).toStringAsFixed(1)} km/h"),
                    ],
                  ),
                  description: const Text(
                      "The required speed to trigger speeding reminders in bad weather."),
                  leading: const Icon(Icons.speed_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Edit value'),
                          content: TextFormField(
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.always,
                            controller: _speedingVelocityController,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false, decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9.]"))
                            ],
                            validator: (String? value) {
                              if (value == null ||
                                  RegExp(r'^\d*(?:\.\d*){2,}$')
                                      .hasMatch(value)) {
                                return 'Invalid value.';
                              } else {
                                return null;
                              }
                            },
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Threshold (in km/h)',
                                hintText: 'e.g. 65.0'),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("Invalid value.");
                                  Navigator.of(context).pop();
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    speedingVelocityThresholdMS = _speedValue;
                                    speedingVelocityThresholdKMH = _doubleValue;
                                    SharedPreferencesService.setDouble(
                                        'speedingVelocityThreshold',
                                        _speedValue);
                                  });
                                }
                                showSnackBar("Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ],
          ),
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Developer"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Enable Debug"),
                leading: const Icon(Icons.bug_report_outlined),
                initialValue: showDebug,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      showDebug = value;
                      SharedPreferencesService.setBool('showDebug', value);
                    });
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text("Data"),
            tiles: [
              SettingsTile.navigation(
                title: const Text("Clear Data"),
                leading: const Icon(Icons.info_outline_rounded),
                onPressed: (context) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Are you sure?"),
                          content: const Text(
                              "All user preferences and drive data will be reset. Calibration would be required again."),
                          actions: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                _clearSPData();
                                _loadDefaultSettings();
                                databaseService.deleteAllDataLocal();
                                if (globals.hasSignedIn) {
                                  databaseService.deleteAllDataFirebase();
                                }
                                if (mounted) setState(() {});
                                showSnackBar("Data Cleared!");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Clear"),
                            ),
                          ],
                        );
                      });
                },
              ),
            ],
          ),
        ]));
  }

  void showSnackBar(String text) {
    var snackBar = SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 1),
    );
    globals.snackbarKey.currentState?.showSnackBar(snackBar);
  }
}

enum AudioType {
  asset,
  file,
}

class AudioValue {
  AudioType type;
  String path;

  AudioValue({
    required this.type,
    required this.path,
  });
}

class SelectAlarmPage extends StatefulWidget {
  const SelectAlarmPage({super.key});

  @override
  State<SelectAlarmPage> createState() => _SelectAlarmPageState();
}

class _SelectAlarmPageState extends State<SelectAlarmPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
