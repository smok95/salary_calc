import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:settings_ui/settings_ui.dart';

import 'my_local.dart';

typedef SettingChangeCallback = void Function(String name, dynamic value);

class SettingsPage extends StatelessWidget {
  final SettingChangeCallback? onSettingChange;

  SettingsPage({this.onSettingChange});

  void _fireChange(final String name, dynamic value) {
    if (onSettingChange != null) {
      onSettingChange!(name, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final translator = MyLocal.of(context);

    final lo = translator != null ? translator.text : (value) => value;

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
                  title: Text(lo('rate review')),
                  onPressed: (context) {
                    _fireChange('rate review', null);
                  }),
              SettingsTile(
                  leading: Icon(Icons.share),
                  title: Text(lo('share app')),
                  onPressed: (context) {
                    _fireChange('share app', null);
                  }),
              SettingsTile(
                  leading: Icon(Icons.apps),
                  title: Text(lo('more apps')),
                  onPressed: (context) {
                    _fireChange('more apps', null);
                  }),
              SettingsTile(
                leading: Icon(Icons.info_outline),
                title: Text(lo('app info')),
                onPressed: (context) async {
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
