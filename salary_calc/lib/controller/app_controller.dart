import 'package:money_formatter/money_formatter.dart';
import 'package:share/share.dart';

import '../calc/salary_calculator.dart';
import '../my_private_data.dart';

class AppController {
  static AppController _instance = AppController._internal();

  factory AppController() {
    return _instance;
  }

  static AppController get instance => AppController();

  AppController._internal();

  /// 계산결과 공유
  void shareCalcResult(SalarySummary data, int salary, bool isAnnualSalary,
      bool includeServerancePay) {
    var text =
        getCalcResultText(data, salary, isAnnualSalary, includeServerancePay);

    text += '\n\n\n연봉계산기\n${MyPrivateData.playStoreUrl}';

    Share.share(text);
  }

  String _toMoneyString(int value) {
    return MoneyFormatter(amount: value.toDouble())
        .output
        .withoutFractionDigits;
  }

  String getCalcResultText(SalarySummary data, int salary, bool isAnnualSalary,
      bool includeServerancePay) {
    var title = isAnnualSalary ? '연봉' : '월급';
    if (isAnnualSalary) {
      title +=
          '(퇴직금 ${includeServerancePay ? '포함' : '별도'}) : ${_toMoneyString(salary)}원';
    }
    return '''
$title

예상 소득액(월): ${_toMoneyString(data.grossSalary)}원

소득세: ${_toMoneyString(data.incomeTax)}원
지방소득세: ${_toMoneyString(data.localIncomeTax)}원
건강보험: ${_toMoneyString(data.healthInsurancePremium)}원
장기요양보험: ${_toMoneyString(data.longTermCareInsurancePremium)}원
고용보험: ${_toMoneyString(data.employmentInsurancePremium)}원
국민연금: ${_toMoneyString(data.nationalPension)}원

공제액 합계: ${_toMoneyString(data.totalDeduction)}원

예상 실수령액(월): ${_toMoneyString(data.netSalary)}원
년 환산금액: ${_toMoneyString(data.netSalary * 12)}원''';
  }
}
