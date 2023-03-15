import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'global_variables.dart' as globals;

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({super.key, required this.title});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    setState(() {});
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          centerTitle: true,
        ),
        body: SettingsList(sections: [
          SettingsSection(
            margin: const EdgeInsetsDirectional.all(20),
            title: const Text("Accelerometer"),
            tiles: [
              SettingsTile.switchTile(
                title: const Text("Use accelerometer"),
                leading: const Icon(Icons.speed),
                initialValue: globals.useAccelerometer,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      globals.useAccelerometer = value;
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
                initialValue: globals.showCameraPreview,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      globals.showCameraPreview = value;
                    });
                  }
                },
              ),
              SettingsTile.switchTile(
                title: const Text("Use High Camera Resolution"),
                leading: const Icon(Icons.camera_rounded),
                initialValue: globals.useHighCameraResolution,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      globals.useHighCameraResolution = value;
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
                initialValue: globals.showDebug,
                onToggle: (value) {
                  if (mounted) {
                    setState(() {
                      globals.showDebug = value;
                    });
                  }
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
