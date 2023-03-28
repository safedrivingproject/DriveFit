import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '/home/home_page.dart';
import '/home/database_service.dart';
import '../global_variables.dart' as globals;

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  DatabaseService databaseService = DatabaseService();
  final _rotXController = TextEditingController();
  final _rotYController = TextEditingController();
  final _carVelocityController = TextEditingController();
  final _additionalDelayController = TextEditingController();
  final _statesController = MaterialStatesController();
  bool? enableGeolocation,
      stationaryAlertsDisabled,
      showCameraPreview,
      useHighCameraResolution,
      showDebug,
      hasCalibrated;
  bool isInvalid = true;
  double? neutralRotX = 5, neutralRotY = -25;
  int? rotXDelay = 10, rotYDelay = 25, additionalDelay = 20;
  double? carVelocityThresholdMS = 8.3, carVelocityThresholdKMH = 30.0;
  List<String> drowsyAlarmValue = ["asset", "audio/car_horn_high.mp3"];
  List<String> inattentiveAlarmValue = ["asset", "audio/double_beep.mp3"];
  double _doubleValue = 1.0;
  int _intValue = 10;
  double _speedValue = 0.0;

  Future<void> _loadDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        enableGeolocation = (prefs.getBool('enableGeolocation') ?? true);
        stationaryAlertsDisabled =
            (prefs.getBool('stationaryAlertsDisabled') ?? false);
        additionalDelay = (prefs.getInt('additionalDelay') ?? 20);
        showCameraPreview = (prefs.getBool('showCameraPreview') ?? true);
        useHighCameraResolution =
            (prefs.getBool('useHighCameraResolution') ?? false);
        showDebug = (prefs.getBool('showDebug') ?? false);
        hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
        neutralRotX = (prefs.getDouble('neutralRotX') ?? 5.0);
        neutralRotY = (prefs.getDouble('neutralRotY') ?? -25.0);
        rotXDelay = (prefs.getInt('rotXDelay') ?? 10);
        rotYDelay = (prefs.getInt('rotYDelay') ?? 25);
        carVelocityThresholdMS =
            (prefs.getDouble('carVelocityThreshold') ?? 8.3);
        drowsyAlarmValue = (prefs.getStringList('drowsyAlarm') ??
            ["asset", "audio/car_horn_high.mp3"]);
        inattentiveAlarmValue = (prefs.getStringList('inattentiveAlarm') ??
            ["asset", "audio/double_beep.mp3"]);
      });
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setBool(key, value);
      });
    }
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setInt(key, value);
      });
    }
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setDouble(key, value);
      });
    }
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        prefs.setStringList(key, value);
      });
    }
  }

  Future<void> _clearSPData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultSettings();
    _rotXController.addListener(() {
      onFieldChanged(_rotXController, true, false);
    });
    _rotYController.addListener(() {
      onFieldChanged(_rotYController, true, false);
    });
    _carVelocityController.addListener(() {
      onFieldChanged(_carVelocityController, false, true);
    });
    _additionalDelayController.addListener(() {
      onFieldChanged(_additionalDelayController, true, false);
    });
  }

  void onFieldChanged(
      TextEditingController controller, bool convertDelay, bool convertSpeed) {
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
            _doubleValue = double.tryParse(controller.text) ?? 30.0;
            _speedValue = (_doubleValue / 3.6);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _rotXController.dispose();
    _rotYController.dispose();
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
                Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (context) {
                  return const HomePage(title: globals.appName);
                }));
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
                      _saveBool('enableGeolocation', value);
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
                      _saveBool('stationaryAlertsDisabled', value);
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
                                isInvalid = true;
                              } else {
                                isInvalid = false;
                              }
                              return isInvalid ? 'Invalid value.' : null;
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
                                showSnackBar(context, "Setting unchanged.");
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
                                if (mounted) {
                                  setState(() {
                                    additionalDelay = _intValue;
                                    _saveInt('additionalDelay',
                                        additionalDelay ?? _intValue);
                                  });
                                }
                                showSnackBar(context, "Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Done"),
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
                    "See yourself in the driving page. Turn off if you think it's distracting."),
                leading: const Icon(Icons.visibility_outlined),
                initialValue: showCameraPreview,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      showCameraPreview = value;
                      _saveBool('showCameraPreview', value);
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
                      _saveBool('useHighCameraResolution', value);
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
                                isInvalid = true;
                              } else {
                                isInvalid = false;
                              }
                              return isInvalid ? 'Invalid value.' : null;
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
                                showSnackBar(context, "Setting unchanged.");
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
                                if (mounted) {
                                  setState(() {
                                    rotXDelay = _intValue;
                                    _saveInt(
                                        'rotXDelay', rotXDelay ?? _intValue);
                                  });
                                }
                                showSnackBar(context, "Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Done"),
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
                                isInvalid = true;
                              } else {
                                isInvalid = false;
                              }
                              return isInvalid ? 'Invalid value.' : null;
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
                                showSnackBar(context, "Setting unchanged.");
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
                                if (mounted) {
                                  setState(() {
                                    rotYDelay = _intValue;
                                    _saveInt(
                                        'rotYDelay', rotYDelay ?? _intValue);
                                  });
                                }
                                showSnackBar(context, "Setting updated.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Done"),
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
                                isInvalid = true;
                              } else {
                                isInvalid = false;
                              }
                              return isInvalid ? 'Invalid value.' : null;
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
                                showSnackBar(context, "Setting unchanged.");
                                Navigator.of(context).pop();
                              },
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: !isInvalid
                                  ? () {
                                      if (mounted) {
                                        setState(() {
                                          carVelocityThresholdMS = _speedValue;
                                          carVelocityThresholdKMH =
                                              _doubleValue;
                                          _saveDouble(
                                              'carVelocityThreshold',
                                              carVelocityThresholdMS ??
                                                  _speedValue);
                                        });
                                      }
                                      showSnackBar(context, "Setting updated.");
                                      Navigator.of(context).pop();
                                    }
                                  : null,
                              child: const Text("Done"),
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
                                _saveStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar(context, "Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Low-pitched car horn"),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/car_horn_low.mp3"
                                ];
                                _saveStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar(context, "Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Beeps"),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/double_beep.mp3"
                                ];
                                _saveStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar(context, "Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Choose from files"),
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(type: FileType.audio);
                                if (result != null) {
                                  drowsyAlarmValue = [
                                    "file",
                                    result.files.first.path!
                                  ];
                                  _saveStringList(
                                      'drowsyAlarm', drowsyAlarmValue);
                                  // ignore: use_build_context_synchronously
                                  showSnackBar(context, "Alarm updated.");
                                } else {
                                  // ignore: use_build_context_synchronously
                                  showSnackBar(context, "Alarm unchanged.");
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
                                _saveStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar(context, "Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Low-pitched car horn"),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/car_horn_low.mp3"
                                ];
                                _saveStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar(context, "Alarm updated.");
                              },
                            ),
                            SimpleDialogOption(
                              child: const Text("Beeps"),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/double_beep.mp3"
                                ];
                                _saveStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar(context, "Alarm updated.");
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
                                  _saveStringList('inattentiveAlarm',
                                      inattentiveAlarmValue);
                                  // ignore: use_build_context_synchronously
                                  showSnackBar(context, "Alarm updated.");
                                } else {
                                  // ignore: use_build_context_synchronously
                                  showSnackBar(context, "Alarm unchanged.");
                                }
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
            ],
          ),
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Developer"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Show debug info"),
                leading: const Icon(Icons.bug_report_outlined),
                initialValue: showDebug,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      showDebug = value;
                      _saveBool('showDebug', value);
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
                                if (mounted) {
                                  setState(() {
                                    _clearSPData();
                                    _loadDefaultSettings();
                                    databaseService.deleteData();
                                  });
                                }
                                Navigator.of(context).pop();
                              },
                              child: const Text("Reset"),
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

  void showSnackBar(BuildContext context, String text) {
    var snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
