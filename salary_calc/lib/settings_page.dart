import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:settings_ui/settings_ui.dart';

import 'my_local.dart';

typedef DarkModeCallback = void Function(bool darkMode);
typedef SettingChangeCallback = void Function(String name, dynamic value);

class SettingsPage extends StatelessWidget {
  final DarkModeCallback onToggleDarkMode;
  final SettingChangeCallback onSettingChange;

  SettingsPage({this.onToggleDarkMode, this.onSettingChange});

  void _fireChange(final String name, dynamic value) {
    if (onSettingChange != null) {
      onSettingChange(name, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lo = MyLocal.of(context).text;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lo('settings'),
        ),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            //title: 'Section',
            tiles: [
              SettingsTile(
                  leading: Icon(Icons.rate_review),
                  title: lo('rate review'),
                  onTap: () {
                    _fireChange('rate review', null);
                  }),
              SettingsTile(
                  leading: Icon(Icons.share),
                  title: lo('share app'),
                  onTap: () {
                    _fireChange('share app', null);
                  }),
              SettingsTile(
                  leading: Icon(Icons.apps),
                  title: lo('more apps'),
                  onTap: () {
                    _fireChange('more apps', null);
                  }),
              SettingsTile(
                leading: Icon(Icons.info_outline),
                title: lo('app info'),
                onTap: () async {
                  PackageInfo packageInfo = await PackageInfo.fromPlatform();
                  showAboutDialog(
                      context: context,
                      applicationName: packageInfo.appName,
                      applicationVersion: packageInfo.version);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
