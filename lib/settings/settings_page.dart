import 'package:drive_fit/service/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../service/navigation.dart';
import '/home/home_page.dart';
import '../service/database_service.dart';
import '../service/shared_preferences_service.dart';
import '../global_variables.dart' as globals;
import '/main.dart';

import 'package:localization/localization.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService databaseService = DatabaseService();
  final WeatherService weatherService = WeatherService();
  final _rotXController = TextEditingController();
  final _rotYController = TextEditingController();
  final _carVelocityController = TextEditingController();
  final _additionalDelayController = TextEditingController();
  final _restReminderController = TextEditingController();
  final _speedingVelocityController = TextEditingController();
  final _statesController = MaterialStatesController();
  bool? enableGeolocation,
      globalSpeedingReminders,
      stationaryAlertsDisabled,
      showCameraPreview,
      useHighCameraResolution,
      showDebug,
      hasCalibrated;
  bool isInvalid = false;
  double? neutralRotX = 5, neutralRotY = -25;
  int? rotXDelay = 15, rotYDelay = 25, additionalDelay = 50;
  double? carVelocityThresholdMS = 4.16, carVelocityThresholdKMH = 15.0;
  double? speedingVelocityThresholdMS = 16.6,
      speedingVelocityThresholdKMH = 60.0;
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
        globalSpeedingReminders =
            SharedPreferencesService.getBool('globalSpeedingReminders', false);
        stationaryAlertsDisabled =
            SharedPreferencesService.getBool('stationaryAlertsDisabled', false);
        additionalDelay =
            SharedPreferencesService.getInt('additionalDelay', 50);
        showCameraPreview =
            SharedPreferencesService.getBool('showCameraPreview', false);
        useHighCameraResolution =
            SharedPreferencesService.getBool('useHighCameraResolution', false);
        showDebug = SharedPreferencesService.getBool('showDebug', false);
        hasCalibrated =
            SharedPreferencesService.getBool('hasCalibrated', false);
        neutralRotX = SharedPreferencesService.getDouble('neutralRotX', 5.0);
        neutralRotY = SharedPreferencesService.getDouble('neutralRotY', -25.0);
        rotXDelay = SharedPreferencesService.getInt('rotXDelay', 15);
        rotYDelay = SharedPreferencesService.getInt('rotYDelay', 25);
        carVelocityThresholdMS =
            SharedPreferencesService.getDouble('carVelocityThreshold', 4.16);
        carVelocityThresholdKMH =
            (carVelocityThresholdMS! * 3.6).roundToDouble();
        drowsyAlarmValue = SharedPreferencesService.getStringList(
            'drowsyAlarm', ["asset", "audio/car_horn_high.mp3"]);
        inattentiveAlarmValue = SharedPreferencesService.getStringList(
            'inattentiveAlarm', ["asset", "audio/double_beep.mp3"]);
        restReminderTime =
            SharedPreferencesService.getInt('restReminderTime', 3600);
        speedingVelocityThresholdMS = SharedPreferencesService.getDouble(
            'speedingVelocityThreshold', 16.6);
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
    final locale = Localizations.localeOf(context);

    return Scaffold(
        appBar: AppBar(
            title: Text(
              "settings".i18n(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                FadeNavigator.pushReplacement(
                    context,
                    const HomePage(index: 0),
                    FadeNavigator.opacityTweenSequence,
                    Colors.transparent,
                    const Duration(milliseconds: 500));
              },
            )),
        body: SettingsList(sections: [
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: Text("geolocation".i18n()),
            tiles: [
              SettingsTile.switchTile(
                title: Text("enable-geolocation".i18n()),
                description: Text("enable-geolocation-description".i18n()),
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
                title: Text("disable-alerts-when-car-not-moving".i18n()),
                description: Text(
                    "disable-alerts-when-car-not-moving-description".i18n()),
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
                      Expanded(
                        child: Text(
                          "additional-delay".i18n(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("${(additionalDelay! * 0.1).toStringAsFixed(1)} s"),
                    ],
                  ),
                  description: Text("additional-delay-description".i18n()),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("edit-value".i18n()),
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
                                return "invalid-value".i18n();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "delay-in-seconds".i18n(),
                                hintText: "eg-value".i18n(['1.0'])),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("setting-unchanged".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("invalid-value".i18n());
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
                                showSnackBar("setting-updated".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("save".i18n()),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.switchTile(
                enabled: enableGeolocation == true,
                title: Text("always-enable-speeding-alerts".i18n()),
                description:
                    Text("always-enable-speeding-alerts-description".i18n()),
                leading: const Icon(Icons.notification_important_outlined),
                initialValue: globalSpeedingReminders,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      globalSpeedingReminders = value;
                      SharedPreferencesService.setBool(
                          'globalSpeedingReminders', value);
                    });
                  }
                },
              ),
              SettingsTile.navigation(
                  enabled: enableGeolocation == true,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "speeding-velocity-threshold".i18n(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "${(speedingVelocityThresholdKMH!).toStringAsFixed(1)} km/h"),
                    ],
                  ),
                  description:
                      Text("speeding-velocity-threshold-description".i18n()),
                  leading: const Icon(Icons.speed_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("edit-value".i18n()),
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
                                return "invalid-value".i18n();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "threshold-in-kmh".i18n(),
                                hintText: "eg-value".i18n(['65.0'])),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("setting-unchanged".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("invalid-value".i18n());
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
                                showSnackBar("setting-updated".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("save".i18n()),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ],
          ),
          SettingsSection(
            title: Text("driving".i18n()),
            tiles: [
              SettingsTile.switchTile(
                title: Text("show-camera-preview".i18n()),
                description: Text("show-camera-preview-description".i18n()),
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
                title: Text("use-high-resolution".i18n()),
                description: Text("use-high-resolution-description".i18n()),
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
                      Expanded(
                        child: Text(
                          "drowsy-alert-sensitivity".i18n(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("${(rotXDelay! * 0.1).toStringAsFixed(1)} s"),
                    ],
                  ),
                  description:
                      Text("drowsy-alert-sensitivity-description".i18n()),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("edit-value".i18n()),
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
                                return "invalid-value".i18n();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "delay-in-seconds".i18n(),
                                hintText: "eg-value".i18n(['1.0'])),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("setting-unchanged".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("invalid-value".i18n());
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
                                showSnackBar("setting-updated".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("save".i18n()),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text("inattentive-alert-sensitivity".i18n()),
                      ),
                      const SizedBox(width: 10),
                      Text("${(rotYDelay! * 0.1).toStringAsFixed(1)} s")
                    ],
                  ),
                  description:
                      Text("inattentive-alert-sensitivity-description".i18n()),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("edit-value".i18n()),
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
                                return "invalid-value".i18n();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "delay-in-seconds".i18n(),
                                hintText: "eg-value".i18n(['2.5'])),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("setting-unchanged".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("invalid-value".i18n());
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
                                showSnackBar("setting-updated".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("save".i18n()),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "required-speed-for-alerts".i18n(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "${(carVelocityThresholdKMH!).toStringAsFixed(1)} km/h"),
                    ],
                  ),
                  description:
                      Text("required-speed-for-alerts-description".i18n()),
                  leading: const Icon(Icons.speed_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("edit-value".i18n()),
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
                                return "invalid-value".i18n();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "threshold-in-kmh".i18n(),
                                hintText: "eg-value".i18n(['30.0'])),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("setting-unchanged".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("invalid-value".i18n());
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
                                showSnackBar("setting-updated".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("save".i18n()),
                            ),
                          ],
                        );
                      },
                    );
                  }),
              SettingsTile.navigation(
                title: Text(
                  "drowsy-alert-sound".i18n(),
                ),
                leading: const Icon(Icons.edit_notifications_outlined),
                description: Text("drowsy-alert-sound-description".i18n()),
                onPressed: (context) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text("select-alarm".i18n()),
                          children: [
                            SimpleDialogOption(
                              child: Text("high-car-horn".i18n()),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/car_horn_high.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("low-car-horn".i18n()),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/car_horn_low.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("double-beep".i18n()),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/double_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("soft-beep".i18n()),
                              onPressed: () {
                                drowsyAlarmValue = [
                                  "asset",
                                  "audio/soft_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'drowsyAlarm', drowsyAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("choose-from-files".i18n()),
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
                                  showSnackBar("alarm-updated".i18n());
                                } else {
                                  showSnackBar("alarm-unchanged".i18n());
                                }
                              },
                            ),
                          ],
                        );
                      });
                },
              ),
              SettingsTile.navigation(
                title: Text(
                  "inattentive-alert-sound".i18n(),
                ),
                leading: const Icon(Icons.edit_notifications_outlined),
                description: Text("inattentive-alert-sound-description".i18n()),
                onPressed: (context) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text("select-alarm".i18n()),
                          children: [
                            SimpleDialogOption(
                              child: Text("high-car-horn".i18n()),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/car_horn_high.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("low-car-horn".i18n()),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/car_horn_low.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("double-beep".i18n()),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/double_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("soft-beep".i18n()),
                              onPressed: () {
                                inattentiveAlarmValue = [
                                  "asset",
                                  "audio/soft_beep.mp3"
                                ];
                                SharedPreferencesService.setStringList(
                                    'inattentiveAlarm', inattentiveAlarmValue);
                                Navigator.of(context).pop();
                                showSnackBar("alarm-updated".i18n());
                              },
                            ),
                            SimpleDialogOption(
                              child: Text("choose-from-files".i18n()),
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
                                  showSnackBar("alarm-updated".i18n());
                                } else {
                                  showSnackBar("alarm-unchanged".i18n());
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
                      Expanded(
                        child: Text(
                          "resting-reminder-frequency".i18n(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          "${(restReminderTime! / 60).toStringAsFixed(1)} min${restReminderTime == 1 ? "" : "s"}"),
                    ],
                  ),
                  description:
                      Text("resting-reminder-frequency-description".i18n()),
                  leading: const Icon(Icons.timer_outlined),
                  onPressed: (context) async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("edit-value".i18n()),
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
                                return "invalid-value".i18n();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: "frequency-in-mins".i18n(),
                                hintText: "eg-value".i18n(['60'])),
                          ),
                          actions: <Widget>[
                            TextButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                showSnackBar("setting-unchanged".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
                            ),
                            FilledButton(
                              style: TextButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              statesController: _statesController,
                              onPressed: () {
                                if (isInvalid) {
                                  showSnackBar("invalid-value".i18n());
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
                                showSnackBar("setting-updated".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("save".i18n()),
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
            title: Text("developer".i18n()),
            tiles: [
              SettingsTile.switchTile(
                title: Text("enable-debug".i18n()),
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
            title: Text("data".i18n()),
            tiles: [
              SettingsTile.navigation(
                title: Text("clear-data".i18n()),
                leading: const Icon(Icons.info_outline_rounded),
                onPressed: (context) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("are-you-sure".i18n()),
                          content: Text("delete-data-description".i18n()),
                          actions: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.labelLarge),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("cancel".i18n()),
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
                                showSnackBar("data-deleted".i18n());
                                Navigator.of(context).pop();
                              },
                              child: Text("delete".i18n()),
                            ),
                          ],
                        );
                      });
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text("language".i18n()),
            tiles: [
              SettingsTile(
                title: locale == const Locale('zh', 'HK')
                    ? Text("switch-to-english".i18n())
                    : Text("switch-to-chinese".i18n()),
                onPressed: (context) {
                  final myApp = context.findAncestorStateOfType<MyAppState>()!;
                  if (locale == const Locale('zh', 'HK')) {
                    myApp.changeLocale(const Locale('en', 'US'));
                    SharedPreferencesService.setString('language', "en_US");
                  } else {
                    myApp.changeLocale(const Locale('zh', 'HK'));
                    SharedPreferencesService.setString('language', "zh_HK");
                  }
                  SharedPreferencesService.setBool('needUpdateLanguage', true);
                },
              )
            ],
          )
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
