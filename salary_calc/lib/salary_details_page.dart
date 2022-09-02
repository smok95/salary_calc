import 'package:expandable/expandable.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:money_formatter/money_formatter.dart';
import 'package:salary_calc/deduction_guide_listview.dart';
import 'package:salary_calc/my_admob.dart';
import 'package:salary_calc/calc/salary_calculator.dart';

import 'my_private_data.dart';
import 'salary_details_chart.dart';

class SalaryDetailsPage extends StatelessWidget {
  final SalarySummary data;

  /// 연봉 또는 월급
  final int salary;

  /// 연봉/월급 구분 true면 연봉
  final bool isAnnualSalary;

  /// 연봉인 경우 퇴직금 포함여부
  final bool includeServerancePay;

  SalaryDetailsPage(this.salary, this.isAnnualSalary, this.data,
      {this.includeServerancePay = false});

  final _adBanner = MyAdmob.createAdmobBanner2();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: ListView(
        padding: EdgeInsets.all(10),
        children: [
          _buildTitlebar(),
          // 예상 소득액(월)
          _buildGrossSalary(),
          // 공제액 세부내역
          FlipCard(
              front: _buildDeductionDetails(), back: SalaryDetailsChart(data)),

          // 예상 실수령액(월)
          _buildNetSalary(),

          _buildControlBar(),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          // Admob 배너광고
          if (!MyPrivateData.hideAd) _adBanner
        ],
      )),
      bottomNavigationBar: TextButton(
          child: Text('닫기'),
          onPressed: () {
            Get.back();
          }),
    );
  }

  String _toMoneyString(int value) {
    return MoneyFormatter(amount: value.toDouble())
        .output
        .withoutFractionDigits;
  }

  Widget _buildTitlebar() {
    String text = isAnnualSalary ? '연봉' : '월급';
    if (isAnnualSalary) {
      text += '(퇴직금 ${includeServerancePay ? '포함' : '별도'})';
    }

    return _roundedBox(
        _buildLabelMoneyText(text, salary, suffix: '원 기준', labelFontSize: 16),
        color: Colors.transparent);
  }

  Widget _buildLabelText(String label, String value,
      {double labelFontSize = 16,
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.bold,
      String? suffix,
      Widget? labelPrefix,
      Widget? labelSuffix}) {
    if (suffix == null) suffix = '';
    final style = TextStyle(fontWeight: fontWeight, fontSize: fontSize);
    final labelStyle =
        TextStyle(fontWeight: FontWeight.normal, fontSize: labelFontSize);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelPrefix != null ? labelPrefix : SizedBox.shrink(),
        Text(label, style: labelStyle),
        labelSuffix != null ? labelSuffix : SizedBox.shrink(),
        Spacer(),
        Text('$value$suffix', style: style)
      ],
    );
  }

  Widget _buildLabelMoneyText(String label, int money,
      {double labelFontSize = 16,
      double fontSize = 16,
      FontWeight fontWeight = FontWeight.bold,
      String suffix = ' 원',
      Widget? labelPrefix,
      Widget? labelSuffix}) {
    return _buildLabelText(label, _toMoneyString(money),
        suffix: suffix,
        labelFontSize: labelFontSize,
        fontWeight: fontWeight,
        fontSize: fontSize,
        labelPrefix: labelPrefix,
        labelSuffix: labelSuffix);
  }

  Widget _roundedBox(Widget child, {Color color = Colors.amberAccent}) {
    final paddingValue = 10.0;
    final radius = Radius.circular(5);
    return Container(
        padding: EdgeInsets.all(paddingValue),
        margin: EdgeInsets.only(bottom: 3),
        width: double.infinity,
        decoration:
            BoxDecoration(borderRadius: BorderRadius.all(radius), color: color),
        child: child);
  }

  // 예상 소득액(월)
  Widget _buildGrossSalary() {
    return _roundedBox(_buildLabelMoneyText('예상 소득액(월)', data.grossSalary));
  }

  // 예상 실수령액(월)
  Widget _buildNetSalary() {
    return _roundedBox(Column(
      children: [
        _buildLabelMoneyText('예상 실수령액(월)', data.netSalary,
            labelFontSize: 13, fontSize: 20),
        _buildLabelMoneyText('년 환산금액', data.netSalary * 12,
            labelFontSize: 13, fontSize: 13, fontWeight: FontWeight.normal)
      ],
    ));
  }

  Widget _buildDeductionDetails() {
    List<Widget> children = [];

    final fontWeight = FontWeight.normal;
    children.add(
        _buildLabelMoneyText('소득세', data.incomeTax, fontWeight: fontWeight));
    children.add(_buildLabelMoneyText('지방소득세', data.localIncomeTax,
        fontWeight: fontWeight));
    children.add(_buildLabelMoneyText('건강보험', data.healthInsurancePremium,
        fontWeight: fontWeight));
    children.add(_buildLabelMoneyText(
        '장기요양보험', data.longTermCareInsurancePremium,
        fontWeight: fontWeight));
    children.add(_buildLabelMoneyText('고용보험', data.employmentInsurancePremium,
        fontWeight: fontWeight));

    children.add(_buildLabelMoneyText('국민연금', data.nationalPension,
        fontWeight: fontWeight));
    children.add(Divider(color: Colors.black45, thickness: 1));
    children.add(_buildLabelMoneyText(
      '  공제액 합계',
      data.totalDeduction,
      labelPrefix: FaIcon(FontAwesomeIcons.chartPie, size: 18),
    ));

    return _roundedBox(Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children));
  }

  void _openDetailInfo() {
    Get.dialog(Card(
      child: DeductionGuidePanel(this.data.baseDate),
      margin: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
    ));
  }

  Widget _buildControlBar() {
    return Row(
      children: [
        TextButton(onPressed: () => _openDetailInfo(), child: Text('계산기준')),
        TextButton(onPressed: null, child: Text('공유하기')),
      ],
    );
  }
}
