import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyLocal {
  MyLocal(this.locale);
  final Locale locale;

  static MyLocal? of(BuildContext context) {
    return Localizations.of<MyLocal>(context, MyLocal);
  }

  static Map<String, Map<String, String>> _values = {
    'en': {
      'title': 'Salary Calcurator',
      'screenshot': 'Screenshot',
      'reset': 'Reset',
      'minimum': 'MIN',
      'maximum': 'MAX',
      'average': 'AVG',
      'screenshot saved': 'Screenshot saved',
      'open': 'OPEN',
      'error': 'Error',
      'permission denied': 'Permission denied',
      'please allow permission':
          'Necessary permissions are denied. Please allow in Settings.',
      'settings': 'Settings',
      'open settings': 'OPEN SETTINGS',
      'dark mode': 'Dark Mode',
      'share app': 'Share App',
      'rate review': 'Rate 5 stars',
      'more apps': 'More apps',
      'app info': 'About this app',
    },
    'ko': {
      'title': '연봉계산기',
      'screenshot': '화면캡쳐',
      'reset': '초기화',
      'minimum': '최소',
      'maximum': '최대',
      'average': '평균',
      'screenshot saved': '화면캡쳐 성공',
      'open': '열기',
      'error': '오류',
      'permission denied': '권한 없음',
      'please allow permission': '권한이 없어 해당 기능을 사용할 수 없습니다. 앱 설정에서 권한을 허용해주세요.',
      'settings': '설정',
      'open settings': '설정 열기',
      'dark mode': '다크 모드',
      'share app': '앱 공유하기',
      'rate review': '별점주기',
      'more apps': '다른 앱 보기',
      'app info': '앱 정보',
    },
  };

  String text(String name) {
    var langMap = _values[locale.languageCode];
    if (langMap == null) {
      return name;
    }

    var msg = langMap[name];
    if (msg == null) return name;
    return msg;
  }
}

class MyLocalDelegate extends LocalizationsDelegate<MyLocal> {
  const MyLocalDelegate();

  @override
  bool isSupported(Locale locale) => [
        'ko',
        'en',
      ].contains(locale.languageCode);

  @override
  Future<MyLocal> load(Locale locale) {
    // Returunig a SynchronousFuture here because an async "load" operation
    // isn't needed to produce an instance of MyLocal.
    return SynchronousFuture<MyLocal>(MyLocal(locale));
  }

  @override
  bool shouldReload(MyLocalDelegate old) => false;
}
