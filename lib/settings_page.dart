import 'package:drive_fit/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_variables.dart' as globals;

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? useAccelerometer,
      showCameraPreview,
      useHighCameraResolution,
      showDebug,
      hasCalibrated;

  Future<void> _loadDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        useAccelerometer = (prefs.getBool('useAccelerometer') ?? false);
        showCameraPreview = (prefs.getBool('showCameraPreview') ?? true);
        useHighCameraResolution =
            (prefs.getBool('useHighCameraResolution') ?? false);
        showDebug = (prefs.getBool('showDebug') ?? false);
        hasCalibrated = (prefs.getBool('hasCalibrated') ?? false);
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
            title: const Text("Accelerometer"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Use accelerometer"),
                leading: const Icon(Icons.speed),
                initialValue: useAccelerometer,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      useAccelerometer = value;
                      _saveBool('useAccelerometer', value);
                    });
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Camera"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Show camera preview when driving"),
                leading: const Icon(Icons.visibility),
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
                leading: const Icon(Icons.camera_rounded),
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

class selectAlarmPage extends StatefulWidget {
  const selectAlarmPage({super.key});

  @override
  State<selectAlarmPage> createState() => _selectAlarmPageState();
}

class _selectAlarmPageState extends State<selectAlarmPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
