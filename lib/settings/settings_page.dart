import 'package:drive_fit/home/home_page.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:drive_fit/unused/camera_logic.dart';
import 'package:flutter/material.dart';
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
  bool? enableGeolocation,
      showCameraPreview,
      useHighCameraResolution,
      showDebug,
      hasCalibrated;
  double? neutralRotX = 5, neutralRotY = -25;
  int? rotXDelay = 10, rotYDelay = 25;

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
                title: const Text(
                    "Choose Vertical Head Movement Alert Sensitivity"),
                description: Text(
                    "The delay between head tilted down and issuing alert. (${rotXDelay! * 0.1} s)"),
                leading: const Icon(Icons.timer_outlined),
                onPressed: (context) async {
                  switch (await showDialog<RotXDelayValue>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          title: const Text('Select assignment'),
                          children: <Widget>[
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, RotXDelayValue.short);
                              },
                              child: const Text('Short (0.5 s)'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, RotXDelayValue.normal);
                              },
                              child: const Text('Normal (1.0 s)'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, RotXDelayValue.long);
                              },
                              child: const Text('Long (2.0 s)'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, RotXDelayValue.veryLong);
                              },
                              child: const Text('Very Long (3.0 s)'),
                            ),
                          ],
                        );
                      })) {
                    case RotXDelayValue.short:
                      rotXDelay = 5;
                      _saveInt('rotXDelay', rotXDelay ?? 5);
                      const snackBar =
                          SnackBar(content: Text("Setting updated."));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      break;
                    case RotXDelayValue.normal:
                      rotXDelay = 10;
                      _saveInt('rotXDelay', rotXDelay ?? 10);
                      const snackBar =
                          SnackBar(content: Text("Setting updated."));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      break;
                    case RotXDelayValue.long:
                      rotXDelay = 20;
                      _saveInt('rotXDelay', rotXDelay ?? 20);
                      const snackBar =
                          SnackBar(content: Text("Setting updated."));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      break;
                    case RotXDelayValue.veryLong:
                      rotXDelay = 30;
                      _saveInt('rotXDelay', rotXDelay ?? 30);
                      const snackBar =
                          SnackBar(content: Text("Setting updated."));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      break;
                    case null:
                      rotXDelay = 10;
                      const snackBar =
                          SnackBar(content: Text("Setting unchanged."));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      break;
                  }
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
}

enum RotXDelayValue {
  short(5),
  normal(10),
  long(20),
  veryLong(30);

  final int value;
  const RotXDelayValue(this.value);
}

enum RotYDelayValue {
  short(15),
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
