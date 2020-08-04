import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:get/get.dart';
import 'package:salary_calc/deduction_guide_listview.dart';
import 'package:salary_calc/my_admob.dart';
import 'package:salary_calc/salary_calculator.dart';

import 'my_private_data.dart';

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

  @override
  Widget build(BuildContext context) {
    final adBanner = MyAdmob.createAdmobBanner2();

    return Scaffold(
      body: SafeArea(
          child: ListView(
        padding: EdgeInsets.all(10),
        children: [
          _buildTitlebar(),
          // 예상 소득액(월)
          _buildGrossSalary(),
          // 공제액 세부내역
          _buildDeductionDetails(),
          ExpandablePanel(
            header: Text(''),
            expanded: SizedBox(
                height: 230,
                width: double.infinity,
                child: DeductionGuidePanel()),
          ),
          // 예상 실수령액(월)
          _buildNetSalary(),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          // Admob 배너광고
          SizedBox(
            height: adBanner.adSize.height.toDouble(),
            child: MyPrivateData.hideAd ? null : adBanner,
          )
        ],
      )),
      bottomNavigationBar: FlatButton(
          child: Text('닫기'),
          onPressed: () {
            Get.back();
          }),
    );
  }

  String _toMoneyString(int value) {
    return FlutterMoneyFormatter(amount: value.toDouble())
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
      String suffix,
      Widget labelPrefix,
      Widget labelSuffix}) {
    if (suffix == null) suffix = '';
    final style = TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize);
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
      String suffix = ' 원',
      Widget labelPrefix,
      Widget labelSuffix}) {
    return _buildLabelText(label, _toMoneyString(money),
        suffix: suffix,
        labelFontSize: labelFontSize,
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
    return _roundedBox(
        _buildLabelMoneyText('예상 실수령액(월)', data.netSalary, fontSize: 23));
  }

  Widget _buildDeductionDetails() {
    List<Widget> children = List<Widget>();

    children.add(_buildLabelMoneyText('소득세', data.incomeTax));
    children.add(_buildLabelMoneyText('지방소득세', data.localIncomeTax));
    children.add(_buildLabelMoneyText('건강보험', data.healthInsurancePremium));
    children
        .add(_buildLabelMoneyText('장기요양보험', data.longTermCareInsurancePremium));
    children.add(_buildLabelMoneyText('고용보험', data.employmentInsurancePremium));

    children.add(_buildLabelMoneyText('국민연금', data.nationalPension));
    children.add(Divider(color: Colors.black45, thickness: 0.5));
    children.add(_buildLabelMoneyText('공제액 합계', data.totalDeduction));

    return _roundedBox(Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children));
  }
}
