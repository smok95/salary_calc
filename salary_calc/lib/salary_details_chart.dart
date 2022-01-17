import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:salary_calc/calc/salary_calculator.dart';

import 'indicator.dart';

class SalaryDetailsChart extends StatefulWidget {
  final SalarySummary data;

  SalaryDetailsChart(this.data, {Key? key}) : super(key: key);

  @override
  _SalaryDetailsChartState createState() => _SalaryDetailsChartState();
}

class SalaryChartData {
  final Color color;
  final String title;
  final double percentage;

  SalaryChartData(this.percentage, this.title, this.color);
}

class _SalaryDetailsChartState extends State<SalaryDetailsChart> {
  List<SalaryChartData> _items = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    _items.clear();

    const colorIndex = 300;

    /// 소득세+지방소득세
    final incomeTax =
        ((data.incomeTax + data.localIncomeTax) / data.grossSalary) * 100;

    _items.add(SalaryChartData(incomeTax, '소득세 ${doubleToString(incomeTax)}%',
        Colors.deepOrange[colorIndex]!));

    /// 건강보험 + 장기요양보험 + 고용보험
    final insurances = ((data.healthInsurancePremium +
                data.longTermCareInsurancePremium +
                data.employmentInsurancePremium) /
            data.grossSalary) *
        100;
    _items.add(SalaryChartData(insurances, '보험료 ${doubleToString(insurances)}%',
        Colors.yellow[colorIndex]!));

    /// 국민연금
    final pension = (data.nationalPension / data.grossSalary) * 100;
    _items.add(SalaryChartData(
        pension, '국민연금 ${doubleToString(pension)}%', Colors.blue[colorIndex]!));

    /// 공제액 합계
    /*final deduction = (data.totalDeduction / data.grossSalary) * 100;
    _items.add(SalaryChartData(deduction, '공제액', Colors.blue[200]));
    */

    /// 예상 실수령액(월)
    final netSalary = (data.netSalary / data.grossSalary) * 100;
    _items.add(SalaryChartData(netSalary, '실수령액 ${doubleToString(netSalary)}%',
        Colors.lightGreen[colorIndex]!));

    return Card(
      margin: EdgeInsets.all(0),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          Flexible(
            flex: 7,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                    pieTouchData: PieTouchData(enabled: false),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    sections: _createPieChartSections()),
              ),
            ),
          ),
          Flexible(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildIndicators(),
            ),
          ),
        ],
      ),
    );
  }

  String doubleToString(double value, {int fractionDigits = 1}) {
    return value.toStringAsFixed(
        value.truncateToDouble() == value ? 0 : fractionDigits);
  }

  PieChartSectionData _createPieChartSectionData(
      final double value, final Color color) {
    return PieChartSectionData(
        color: color,
        value: value,
        showTitle: false,
        titleStyle:
            TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
  }

  List<Widget> _buildIndicators() {
    List<Widget> indicators = [];

    for (var item in _items) {
      indicators.add(Indicator(color: item.color, text: item.title, size: 13));
      indicators.add(SizedBox(height: 4));
    }
    return indicators;
  }

  List<PieChartSectionData> _createPieChartSections() {
    List<PieChartSectionData> sections = [];

    for (var item in _items) {
      sections.add(_createPieChartSectionData(item.percentage, item.color));
    }

    return sections;
  }
}
