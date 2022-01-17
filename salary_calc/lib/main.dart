import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:salary_calc/salary_table.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'my_admob.dart';
import 'settings_page.dart';
import 'my_local.dart';
import 'salary_calc_page.dart';
import 'my_private_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// AdMob 초기화
  MyAdmob.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Prevent device orientation changes.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return GetMaterialApp(
      onGenerateTitle: (BuildContext context) {
        var translate = MyLocal.of(context);
        return translate != null ? translate.text('title') : '연봉계산기';
      },
      localizationsDelegates: [
        const MyLocalDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko', ''),
        const Locale('en', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final adBanner = _buildAdBanner();
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Column(
          children: [
            Expanded(
              child: SalaryCalcPage(
                onOpenSettings: () {
                  Get.to(SettingsPage(
                    onSettingChange: (name, value) async {
                      if (name == 'share app') {
                        Share.share(MyPrivateData.playStoreUrl);
                      } else if (name == 'rate review') {
                        final playstoreUrl = MyPrivateData.playStoreUrl;
                        if (await canLaunch(playstoreUrl)) {
                          await launch(playstoreUrl);
                        }
                      } else if (name == 'more apps') {
                        final devPage =
                            MyPrivateData.googlePlayDeveloperPageUrl;
                        if (await canLaunch(devPage)) {
                          await launch(devPage);
                        }
                      }
                    },
                  ));
                },
                onOpenSalaryTable: () {
                  print('연봉 실수령액표 화면을 오픈합니다.');
                  Get.to(SalaryTable(
                    adBanner: adBanner,
                  ));
                },
              ),
            ),
            adBanner
          ],
        )));
  }

  /// 광고영역
  Widget _buildAdBanner() {
    return MyPrivateData.hideAd
        ? SizedBox.shrink()
        : MyAdmob.createAdmobBanner(adSize: AdmobBannerSize.BANNER);
  }
}
