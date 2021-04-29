import 'dart:core';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jk/flutter_jk.dart';
import 'package:lazy_data_table/lazy_data_table.dart' as lz;
import 'package:money_formatter/money_formatter.dart';
import 'package:salary_calc/calc/salary_calculator.dart';

/// table_sticky_headers: ^1.1.2 수백줄 데이터 출력에도 성능이 좋지 못해
/// LazyDataTable로 교체함.
//import 'package:table_sticky_headers/table_sticky_headers.dart';

class SalaryTable extends StatefulWidget {
  final Widget adBanner;

  SalaryTable({this.adBanner});

  @override
  _SalaryTableState createState() => _SalaryTableState();
}

class _SalaryTableState extends State<SalaryTable> {
  @override
  void initState() {
    super.initState();

    _data = [];

    const millionWon = 1000000;
    final salaryCalc = SalaryCalculator();
    // 1000만원 ~ 3억까지 100만원 단위로
    int income = 10 * millionWon;
    while (income <= millionWon * 300) {
      _data.add(salaryCalc.calc(income));
      income += millionWon;
    }
  }

  String _toMoneyString(int value) {
    return MoneyFormatter(amount: value.toDouble())
        .output
        .withoutFractionDigits;
  }

  @override
  Widget build(BuildContext context) {
    /*    
    
    */
    final sw = Stopwatch()..start();
    final obj = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('연봉 실수령액 표'),
            IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  AwesomeDialog(
                      dialogType: DialogType.INFO,
                      context: context,
                      title: '계산 기준',
                      desc:
                          '가장 일반적인 조건을 적용하여 계산된 표입니다.\n부양가족(본인포함): 1명\n퇴직금 별도\n비과세액: 월10만원')
                    ..show();
                  //Get.snackbar('title', 'message');
                })
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.screen_rotation),
              onPressed: () {
                final modes =
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? [
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight
                          ]
                        : [
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown
                          ];
                SystemChrome.setPreferredOrientations(modes);
              })
        ],
      ),
      body: WillPopScope(
          child: SafeArea(
              child: Column(
            children: [
              Expanded(child: _buildLazyDataTable()),
              if (widget.adBanner != null) widget.adBanner
            ],
          )),
          onWillPop: () async {
            // Change orientation, if landscape mode
            if (MediaQuery.of(context).orientation == Orientation.landscape) {
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown
              ]);
            }

            return true;
          }),
    );

    sw.stop();

    print('eplased : ${sw.elapsedMilliseconds} msec');
    return obj;
  }

  final List<String> _columns = [
    '월급여액',
    '실수령액',
    '공제액계',
    '소득세',
    '지방소득세',
    '국민연금',
    '고용보험',
    '건강보험',
    '장기요양',
  ];

  /*
  Widget _buildDataTable() {
    SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
            child: DataTable(columns: [
          DataColumn(label: Text('연봉')),
          DataColumn(label: Text('실수령액')),
          DataColumn(label: Text('공제액계')),
          DataColumn(label: Text('국민연금')),
        ], rows: _generateRow())));
  }

  List<DataRow> _generateRow() {
    List<DataRow> rows = List<DataRow>();
    for (var item in _data) {
      DataRow row = DataRow(cells: [
        DataCell(Text(item.annualGrossSalary.toString())),
        DataCell(Text(item.netSalary.toString())),
        DataCell(Text(item.totalDeduction.toString())),
        DataCell(Text(item.nationalPension.toString()))
      ]);

      rows.add(row);
    }

    return rows;
  } */

  Widget _buildLazyDataTable() {
    final _centerText = (final String text, {bool bold = false}) {
      return Center(
          child: Text(
        text,
        textAlign: TextAlign.center,
        style:
            TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ));
    };

    const borderSide =
        BorderSide(color: Color.fromARGB(0xFF, 0xee, 0xee, 0xee));
    const border = Border(bottom: borderSide, right: borderSide);

    return lz.LazyDataTable(
        tableDimensions: lz.DataTableDimensions(
          cellHeight: 30,
          cellWidth: 95,
          columnHeaderHeight: 35,
          rowHeaderWidth: 80,
        ),
        tableTheme: lz.DataTableTheme(
          columnHeaderBorder: border,
          rowHeaderBorder: border,
          cellBorder: border,
          cornerBorder: border,
          columnHeaderColor: Colors.amber[200],
          rowHeaderColor: Colors.white,
          cellColor: Colors.white,
          cornerColor: Colors.amber[200],
        ),
        rows: _data.length,
        columns: _columns.length,
        columnHeaderBuilder: (i) => _centerText(_columns[i], bold: true),
        rowHeaderBuilder: (i) => Container(
            color: i % 2 == 0 ? Colors.white : Colors.grey[100],
            child: _centerText(
              KrUtils.numberToManwon(_data[i].annualGrossSalary, suffix: ''),
            )),
        dataCellBuilder: (row, col) {
          final data = _data[row];

          bool bold = false;
          int value = 0;
          switch (col) {
            case 0: // 월급여액
              value = data.grossSalary;
              break;
            case 1: //  실수령액
              bold = true;
              value = data.netSalary;
              break;
            case 2: // 공제액계

              value = data.totalDeduction;
              break;
            case 3: // 소득세
              value = data.incomeTax;
              break;
            case 4: // 지방소득세
              value = data.localIncomeTax;
              break;
            case 5: // 국민연금
              value = data.nationalPension;
              break;
            case 6: // 고용보험료
              value = data.employmentInsurancePremium;
              break;
            case 7: // 건강보험
              value = data.healthInsurancePremium;
              break;
            case 8: // 장기요양보험
              value = data.longTermCareInsurancePremium;
              break;

            default:
          }
          return Container(
              color: row % 2 == 0 ? Colors.white : Colors.grey[100],
              child: _centerText(_toMoneyString(value), bold: bold));
        },
        cornerWidget: Center(
            child: Text(
          "연봉",
          style: TextStyle(fontWeight: FontWeight.bold),
        )));
  }

  /*
  Widget _buildTableStickyHeaders() {
    return StickyHeadersTable(
        columnsLength: _columns.length,
        rowsLength: _data.length,
        columnsTitleBuilder: (i) => Text(_columns[i]),
        rowsTitleBuilder: (i) => Text(KrUtils.numberToManwon(
            _data[i].annualGrossSalary,
            withoutWon: true)),
        contentCellBuilder: (col, row) {
          final data = _data[row];

          int value = 0;
          switch (col) {
            case 0: //  실수령액
              value = data.netSalary;
              break;
            case 1: // 공제액계
              value = data.totalDeduction;
              break;
            case 2: // 소득세
              value = data.incomeTax;
              break;
            case 3: // 지방소득세
              value = data.localIncomeTax;
              break;
            case 4: // 국민연금
              value = data.nationalPension;
              break;
            case 5: // 고용보험료
              value = data.employmentInsurancePremium;
              break;
            case 6: // 건강보험
              value = data.healthInsurancePremium;
              break;
            case 7: // 장기요양보험
              value = data.longTermCareInsurancePremium;
              break;

            default:
          }
          return Text(_toMoneyString(value));
        },
        legendCell: Text('연봉'),
      );
  } */
  List<SalarySummary> _data;
}
