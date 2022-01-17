import 'package:flutter/material.dart';
import 'package:flutter_jk/flutter_jk.dart';
import 'package:salary_calc/calc/salary_calculator.dart';

class DeductionGuidePanel extends StatelessWidget {
  /// 계산기준일
  final DateTime? baseDate;
  DeductionGuidePanel(this.baseDate);

  @override
  Widget build(BuildContext context) {
    /// 계산기준 연도
    final calculator = IncomeTaxCalc(baseDate: baseDate);
    final salaryCalc = SalaryCalculator(baseDate: baseDate);

    return ListView(
      children: [
        // 기준 소득월액
        _buildListTile(
            '기준 소득월액', '한달 기준 소득액에서 비과세액을 뺀 금액으로, 기준 소득월액이 곧 과세금액에 해당합니다.'),
        _buildListTile(
            '비과세액',
            '월급여에서 세금공제를 하지 않는 금액으로 월10만원 이하의 식대, 출산/보육수당, 국외근로소득, 생산직근로자의 연장,야간,휴일근로 수당 등' +
                ' 소득세법에서 정한 기준에 따라 과세대상에서 제외됩니다.\n본 계산기는 월 식대10만원을 기본으로 설정하였으며, 본인의 비과세액을 아는 경우에는 비과세액을 변경하여 계산하실 수 있습니다.'),
        // 소득세
        _buildListTile('근로소득세', calculator.helpText('income-tax')),
        // 지방소득세
        _buildListTile('지방소득세', calculator.helpText('local-income-tax')),
        // 건강보험
        _buildListTile('건강보험', salaryCalc.helpText('health-care')),
        // 장기요양보험
        _buildListTile('장기요양보험', salaryCalc.helpText('long-term-care')),
        // 고용보험
        _buildListTile('고용보험', salaryCalc.helpText('employment-insurance')),
        // 국민연금
        _buildListTile('국민연금', salaryCalc.helpText('national-pension')),
      ],
    );
  }

  ListTile _buildListTile(final String title, final String subtitle) {
    return ListTile(title: Text(title), subtitle: Text(subtitle));
  }
}
