import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'driving_view.dart';
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
            style: Theme.of(context).textTheme.displaySmall,
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
                  setState(() {
                    globals.useAccelerometer = value;
                  });
                },
              ),
            ],
          )
        ]));
  }
}
