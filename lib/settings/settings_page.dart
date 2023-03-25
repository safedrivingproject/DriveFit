import 'package:drive_fit/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global_variables.dart' as globals;

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _rotXController = TextEditingController();
  final _rotYController = TextEditingController();
  final _carVelocityController = TextEditingController();
  final _statesController = MaterialStatesController();
  bool? enableGeolocation,
      showCameraPreview,
      useHighCameraResolution,
      showDebug,
      hasCalibrated;
  bool isInvalid = true;
  double? neutralRotX = 5, neutralRotY = -25;
  int? rotXDelay = 10, rotYDelay = 25;
  double? carVelocityThreshold = 5.0;
  double _double = 1.0;
  int _value = 10;

  Future<void> _loadDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        enableGeolocation = (prefs.getBool('enableGeolocation') ?? true);
        showCameraPreview = (prefs.getBool('showCameraPreview') ?? true);
        useHighCameraResolution =
            (prefs.getBool('useHighCameraResolution') ?? false);
        showDebug = (prefs.getBool('showDebug') ?? false);
        hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
        neutralRotX = (prefs.getDouble('neutralRotX') ?? 5.0);
        neutralRotY = (prefs.getDouble('neutralRotY') ?? -25.0);
        rotXDelay = (prefs.getInt('rotXDelay') ?? 10);
        rotYDelay = (prefs.getInt('rotYDelay') ?? 25);
        carVelocityThreshold = (prefs.getDouble('carVelocityThreshold') ?? 5.0);
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

  Future<bool> _readBool(String key, bool defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    bool boolValue = prefs.getBool(key) ?? defaultValue;
    return boolValue;
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
      onFieldChanged(_rotXController, true);
    });
    _rotYController.addListener(() {
      onFieldChanged(_rotYController, true);
    });
    _carVelocityController.addListener(() {
      onFieldChanged(_carVelocityController, false);
    });
  }

  void onFieldChanged(TextEditingController controller, bool convertDouble) {
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
      if (!convertDouble) {
        if (mounted) {
          setState(() {
            _double = double.tryParse(controller.text) ?? 5.0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _double = double.tryParse(controller.text) ?? 1.0;
            _value = (_double * 10).round();
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
                    const Text("Only issue alerts when the car is moving."),
                leading: const Icon(Icons.speed),
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
            ],
          ),
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
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
                  title: Text(
                      "Choose Vertical Head Movement Alert Sensitivity \n(${(rotXDelay! * 0.1).toStringAsFixed(1)} s)"),
                  description: const Text(
                      "The delay between head tilted down and issuing alert."),
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
                                    rotXDelay = _value;
                                    _saveInt('rotXDelay', rotXDelay ?? _value);
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
                  title: Text(
                      "Choose Horizontal Head Movement Alert Sensitivity \n(${(rotYDelay! * 0.1).toStringAsFixed(1)} s)"),
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
                                    rotYDelay = _value;
                                    _saveInt('rotYDelay', rotYDelay ?? _value);
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
                  title: Text(
                      "Choose Car Velocity Threshold \n(${(carVelocityThreshold!).toStringAsFixed(1)} m/s)"),
                  description: const Text(
                      "The required speed before alerts would be given."),
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
                                labelText: 'Threshold (in m/s)',
                                hintText: 'e.g. 5.0'),
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
                                          carVelocityThreshold = _double;
                                          _saveDouble('carVelocityThreshold',
                                              carVelocityThreshold ?? _double);
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

enum RotYDelayValue {
  short(10),
  normal(25),
  long(40),
  veryLong(55);

  final int value;
  const RotYDelayValue(this.value);
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
