import 'dart:math';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jk/flutter_jk.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:get/get.dart';
import 'package:salary_calc/random_message.dart';
import 'package:salary_calc/salary_details_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

import 'check_label.dart';
import 'money_masked_text_controller.dart';
import 'num_pad.dart';
import 'salary_calculator.dart';

class SalaryCalcPage extends StatefulWidget {
  /// 환경설정 오픈 이벤트
  /// 화면에서 설정버튼 클릭시 발생
  final VoidCallback onOpenSettings;

  /// 연봉실수령액 표 보기 이벤트
  final VoidCallback onOpenSalaryTable;

  SalaryCalcPage({Key key, this.onOpenSettings, this.onOpenSalaryTable})
      : super(key: key);

  @override
  _SalaryCalcState createState() => _SalaryCalcState();
}

class _SalaryCalcState extends State<SalaryCalcPage> {
  @override
  void initState() {
    super.initState();
    _emoticon = RandomMessage.emoticon;
    _nontaxableTextController = _TextFieldController(Key('nontaxable'),
        initialValue: _data.nontaxable.toDouble());
    _nontaxableFocusNode.addListener(() {
      print('_nontaxableFocusNode.hasFocus=${_nontaxableFocusNode.hasFocus}');
      setState(() {});
    });
    _salaryTextController.addListener(_textControlListener);
    _nontaxableTextController.addListener(_textControlListener);
  }

  @override
  void dispose() {
    _nontaxableFocusNode.dispose();
    _nontaxableTextController.dispose();
    _salaryTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelText = this._isAnnualSalary ? '연봉' : '월급';
    final keyboardHeight = 180.0;

    String moneyString = _data.salary >= 10000
        ? '$labelText ${KrUtils.numberToManwon(_data.salary)}'
        : '';

    return Padding(
        padding: EdgeInsets.only(left: 5, top: 5, right: 5, bottom: 5),
        child: Column(
          children: [
            // 연봉/월급 및 퇴직금 옵션
            _salaryOptions(),
            // 소득액 입력필드
            _buildSalaryInput(labelText),

            // 부양가족(본인포함)
            _buildDependantsInput(),
            // 20세 이하 자녀
            _buildYoungDependants(),
            // 비과세액 입력필드
            _buildNontaxableInput(),
            // 계산결과
            _buildResultView(labelText),
            _buildEasyMoneyButtons(negative: !_plusMode),
            _buildNumPad(keyboardHeight),
          ],
        ));
  }

  /// 급여액 입력란
  Widget _buildSalaryInput(final String labelText) {
    String moneyString =
        _data.salary > 0 ? KrUtils.numberToManwon(_data.salary) : '';

    final fillColor = _salaryFieldHasFocus ? _fillColor : Colors.white;
    return TextField(
      readOnly: true,
      showCursor: true,
      autofocus: true,
      controller: _salaryTextController,
      decoration: InputDecoration(
          isDense: true,
          labelText: '$labelText $moneyString',
          suffixText: '원',
          labelStyle: Theme.of(context)
              .textTheme
              .subtitle1, // TextStyle(fontSize: 20.0, fontWeight: FontWeight.normal),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding:
              EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 5),
          hintText: labelText,
          border: UnderlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.all(_radius)),
          filled: true,
          fillColor: fillColor),
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
      keyboardType:
          TextInputType.numberWithOptions(signed: true, decimal: false),
      onChanged: (value) {
        _data.salary = _salaryTextController.numberValue.toInt();
        _calc();
      },
    );
  }

  Widget _buildNontaxableInput() {
    final labelText = '비과세액';
    final fillColor = _salaryFieldHasFocus ? Colors.transparent : _fillColor;
    return TextField(
      readOnly: true,
      showCursor: true,
      controller: _nontaxableTextController,
      focusNode: _nontaxableFocusNode,
      decoration: InputDecoration(
        isDense: true,
        suffixText: '원',
        prefixText: labelText,
        labelStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: labelText,
        border: UnderlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(_radius)),
        filled: true,
        fillColor: fillColor,
      ),
      textAlign: TextAlign.right,
      //style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
      keyboardType:
          TextInputType.numberWithOptions(signed: true, decimal: false),
      onChanged: (value) {
        _data.nontaxable = _nontaxableTextController.numberValue.toInt();
        _calc();
      },
    );
  }

  bool get _salaryFieldHasFocus {
    return !(_nontaxableFocusNode?.hasFocus ?? false);
  }

  /// 현재 포커스를 가진 TextController 리턴
  /// 확인이 안되는 경우 _salaryTextController기본값
  _TextFieldController get _activeTextFieldController {
    return _salaryFieldHasFocus
        ? _salaryTextController
        : _nontaxableTextController;
  }

  /// 숫자패드
  Widget _buildNumPad(final double height) {
    return NumPad(
        height: height,
        onPressed: (value) {
          _vibrate();
          _activeTextFieldController.insertInt(value);
        },
        onBackspace: () {
          _vibrate();
          _activeTextFieldController.removeNumber();
        },
        onClear: () {
          _vibrate();
          _clearAll();
        });
  }

  /// 계산결과 뷰
  Widget _buildResultView(final String labelText) {
    // 입력값이 없으면 안내화면을 표시한다.
    final showHelp = _data.salary <= 0;

    String message = "${labelText}을 입력해 보세요!";

    if (!_showHelpText && _showCheerUpMessage) {
      _showCheerUpMessage = false;
      message = RandomMessage.cheerUpMessage;
    }

    /// 2% 확률로 응원메시지 다시 표시
    if (!_showCheerUpMessage) {
      final randomValue = Random.secure().nextInt(100);
      _showCheerUpMessage = randomValue <= 2;
    }

    List<Widget> children = List<Widget>();
    double paddingValue = 10;
    if (showHelp) {
      paddingValue = 0;

      children.add(Expanded(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_emoticon, style: TextStyle(fontSize: 40)),
          VerticalDivider(
            color: Colors.transparent,
          ),
          Shimmer.fromColors(
            child: Text(message,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
            baseColor: Colors.black,
            highlightColor: Colors.transparent,
            period: Duration(seconds: 2),
            loop: 3,
            enabled: _showHelpText,
          )
        ],
      )));

      var linkText;
      if (widget.onOpenSalaryTable != null) {
        linkText = FlatButton(
            onPressed: widget.onOpenSalaryTable,
            child: Text(
              '실수령액 표 보기',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black54,
              ),
            ));
      } else {
        linkText = SizedBox.shrink();
      }

      children.add(Row(
        children: [
          Expanded(
              child: Align(alignment: Alignment.centerLeft, child: linkText)),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: widget.onOpenSettings,
          )
        ],
      ));
    } else {
      final grossSalary = _toMoneyString(_data.result.grossSalary);
      final totalDeduction = _toMoneyString(_data.result.totalDeduction);
      final netSalary = _toMoneyString(_data.result.netSalary);
      Widget createResultRow(String label, String value,
          {double labelFontSize = 14, double fontSize = 16}) {
        final style =
            TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize);
        final labelStyle =
            TextStyle(fontWeight: FontWeight.normal, fontSize: labelFontSize);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: labelStyle),
            Text('$value 원', style: style)
          ],
        );
      }

      children.add(createResultRow('예상 소득액(월)', grossSalary));
      children.add(createResultRow('공제액 합계', totalDeduction));

      if (_showHelpText) {
        children.add(Center(
            child: Shimmer.fromColors(
                child: Text('자세한 정보는 여기를 터치하세요'),
                //loop: 3,
                period: Duration(seconds: 5),
                baseColor: Colors.black,
                highlightColor: Colors.transparent)));
      } else {
        children.add(Divider(color: Colors.black45, thickness: 0.5));
      }
      children.add(createResultRow('예상 실수령액(월)', netSalary, fontSize: 23));
    }

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(paddingValue),
        width: double.infinity,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(_radius), color: Colors.amberAccent),
        child: InkWell(
            onTap: _showDetails,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: children)),
      ),
    );
  }

  void _showDetails() {
    if (_data.salary <= 0) return;

    /// 한번 터치를 하면 사용방법을 인지했기 때문에 더 이상 안내 메시지를 표시하지 않는다.
    if (_showHelpText) _showHelpText = false;

    //print('세부정보를 표시하겠습니다.');
    Get.to(
        SalaryDetailsPage(
          _data.salary,
          _isAnnualSalary,
          _data.result,
          includeServerancePay: _includeSeverancePay,
        ),
        transition: Transition.noTransition);
  }

  /// 전체 초기화
  void _clearAll() {
    if (_data.salary > 0) _emoticon = RandomMessage.emoticon;

    _data.clear();
    _plusMode = true;
    _salaryTextController.updateValue(_data.salary.toDouble());
    _nontaxableTextController.updateValue(_data.nontaxable.toDouble());
    _calc();
  }

  /// 진동
  void _vibrate() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 3);
    }
  }

  Widget _salaryOptions() {
    final isSelected = [_isAnnualSalary, !_isAnnualSalary];
    final disableColor = Colors.grey[400];

    final List<Widget> children = List<Widget>();

    // 연봉/월급 구분 토글버튼
    children.add(ToggleButtons(
      renderBorder: false,
      fillColor: Colors.transparent,
      color: disableColor,
      selectedColor: Colors.black,
      children: [
        CheckLabel('연봉', _isAnnualSalary),
        CheckLabel('월급', !_isAnnualSalary)
      ],
      isSelected: isSelected,
      onPressed: (index) {
        setState(() {
          _isAnnualSalary = index == 0;
          _calc();
        });
      },
    ));

    // 연봉일때 퇴직금 포함여부 토글버튼
    if (_isAnnualSalary) {
      children.add(Spacer());
      children.add(Text('퇴직금   '));
      children.add(ToggleButtons(
        renderBorder: false,
        fillColor: Colors.transparent,
        color: disableColor,
        selectedColor: Colors.black,
        children: [
          CheckLabel('포함', _includeSeverancePay),
          CheckLabel('별도', !_includeSeverancePay)
        ],
        isSelected: [_includeSeverancePay, !_includeSeverancePay],
        onPressed: (index) {
          setState(() {
            _includeSeverancePay = index == 0;
            _calc();
          });
        },
      ));
    }

    return Padding(
        padding: EdgeInsets.only(left: 10.0, right: 10.0),
        child: Row(
          children: children,
          mainAxisAlignment: MainAxisAlignment.start,
        ));
  }

  String _toMoneyString(int value) {
    return FlutterMoneyFormatter(amount: value.toDouble())
        .output
        .withoutFractionDigits;
  }

  /// 실수령액 계산
  void _calc() {
    _data.result = SalaryCalculator.calc(_data.salary,
        nontaxable: _data.nontaxable,
        isAnnual: _isAnnualSalary,
        includeSeverancePay: _includeSeverancePay,
        dependents: _data.dependants,
        youngDependents: _data.youngDependants);

    setState(() {});
  }

  void _textControlListener() {
    final controller = _activeTextFieldController;
    final value = controller.numberValue.toInt();

    if (controller == _nontaxableTextController) {
      /// 비과세액이 지금과 같으면 리턴
      if (value == _data.nontaxable) return;
      _data.nontaxable = value;
    } else {
      /// 소득액이 지금과 같으면 리턴
      if (value == _data.salary) return;
      _data.salary = value;
    }

    _calc();
  }

  Widget _buildEasyMoneyButton(int unit) {
    final absValue = unit.abs();
    final text = '${absValue}만';
    final iconData = unit < 0 ? Icons.remove : Icons.add;

    final size = 15.0;
    return InkWell(
      borderRadius: BorderRadius.all(_radius),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
        child: Row(
          children: [
            Icon(iconData, size: size),
            Text(text, style: TextStyle(fontSize: size))
          ],
        ),
      ),
      onTap: () {
        _vibrate();

        var value = _activeTextFieldController.numberValue + unit * 10000;
        if (value <= 0) {
          value = 0;

          // 마이너스 입력모드면 강제로 플러스 모드로 변경
          if (!_plusMode) {
            setState(() {
              _plusMode = true;
            });
          }
        }

        if (value > _maximumSalary) {
          _showFlushbar(
              '최대 ${KrUtils.numberToManwon(_maximumSalary)} 까지만 계산 가능합니다.');
          return;
        }

        print('_nontaxableFocusNode.hasFocus=${_nontaxableFocusNode.hasFocus}');
        _activeTextFieldController.updateValue(value.toDouble());

        if (_nontaxableFocusNode.hasFocus) {
          _data.nontaxable = value.toInt();
        } else {
          _data.salary = value.toInt();
        }
        _calc();
      },
    );
  }

  /// 급여액 입력 편의 버튼
  Widget _buildEasyMoneyButtons({bool negative = false}) {
    return Container(
      padding: EdgeInsets.only(top: 10.0, bottom: 1.0),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _fillColor, width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(
                Icons.exposure,
                color: Colors.grey[700],
              ),
              onPressed: () {
                setState(() {
                  _plusMode = !_plusMode;
                });
              }),
          _buildEasyMoneyButton(negative ? -1000 : 1000),
          _buildEasyMoneyButton(negative ? -100 : 100),
          _buildEasyMoneyButton(negative ? -10 : 10),
          _buildEasyMoneyButton(negative ? -1 : 1),
        ],
      ),
    );
  }

  Widget _buildNumberStepper(
      final String label, int value, void Function(int) onChanged,
      {int minimum = 1, int maximum = 999}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        NumStepper(
            width: 130.0,
            minimum: minimum,
            maximum: maximum,
            rightSymbol: ' 명',
            textStyle: TextStyle(fontSize: 15),
            value: value,
            onChanged: onChanged)
      ],
    );
  }

  /// 부양가족수 설정 컨트롤
  Widget _buildDependantsInput() {
    return _buildNumberStepper('부양가족 수(본인포함) ', _data.dependants, (value) {
      _vibrate();

      if (value <= _data.youngDependants) {
        _showFlushbar('부양가족의 수는 자녀 수보다 많아야 합니다.');
        value += 1;
      }

      _data.dependants = value;
      _calc();
    });
  }

  /// 20세 이하 자녀 설정 컨트롤
  Widget _buildYoungDependants() {
    return _buildNumberStepper('20세 이하 자녀 수 ', _data.youngDependants, (value) {
      _vibrate();

      if (value >= _data.dependants) {
        _showFlushbar('자녀의 수는 부양가족 수보다 적어야 합니다.');
        value = _data.dependants - 1;
      }

      _data.youngDependants = value;
      _calc();
    }, minimum: 0);
  }

  /// Flushbar 표시
  void _showFlushbar(final String message) {
    /// 표시중인 Flushbar 닫기
    if (_flushbar?.isShowing() ?? false) {
      _flushbar.dismiss();
    }

    _flushbar = Flushbar(
      message: message,
      icon: Icon(
        Icons.info_outline,
        color: Colors.redAccent,
      ),
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
    );

    _flushbar.show(context);
  }

  _TextFieldController _salaryTextController =
      _TextFieldController(Key('salary'));
  _TextFieldController _nontaxableTextController;
  FocusNode _nontaxableFocusNode = FocusNode();

  /// 연봉/월급 구분, true면 연봉
  bool _isAnnualSalary = true;

  /// 퇴직금포함 여부, true면 포함
  bool _includeSeverancePay = false;

  SalaryCalcData _data = SalaryCalcData();

  bool _plusMode = true;
  String _emoticon;
  bool _showCheerUpMessage = true;

  /// 최대 계산 가능 금액 (9999억..., )
  /// 제한금액은 [money_masked_text_controller]의 제한 자리수 기준으로 정했음.
  final _maximumSalary = 999999999999;

  final Radius _radius = Radius.circular(5.0);
  Color _fillColor = Colors.grey[200];
  Flushbar _flushbar;

  /// 상세정보 사용방법 안내메시지 표시여부
  bool _showHelpText = true;
}

/// 연봉계산기용 TextEditingController
class _TextFieldController extends MoneyMaskedTextController {
  _TextFieldController(this.key, {double initialValue = 0.0})
      : super(
            initialValue: initialValue,
            decimalSeparator: '',
            precision: 0,
            thousandSeparator: ',');

  final Key key;
}

/// 연봉계산에 필요한 정보
class SalaryCalcData {
  /// 현재 입력된 연봉 또는 월급값
  int salary = 0;

  /// 비과세액
  int nontaxable = 100000;

  /// 부양가족(본인포함)
  int dependants = 1;

  /// 20세 이하 자녀수
  int youngDependants = 0;

  /// 소득세 납부 선택세율
  double incomeTaxRate = 1.0;

  /// 최종 계산 결과 요약정보
  SalarySummary result = SalarySummary.zero;

  void clear() {
    salary = 0;
    nontaxable = 100000;
    dependants = 1;
    youngDependants = 0;
    incomeTaxRate = 1.0;
    result = SalarySummary.zero;
  }
}
