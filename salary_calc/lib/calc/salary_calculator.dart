import 'package:flutter_jk/flutter_jk.dart';

import 'major_insurance_calculator.dart';

class SalaryCalculator {
  /// 계산기준일
  final DateTime baseDate;

  SalaryCalculator({DateTime? baseDate})
      : this.baseDate = baseDate ?? DateTime.now() {
    _majorInsuranceCalc = MajorInsuranceCalculator(baseDate: this.baseDate);
  }

  /// [income]은 전체 급여액
  /// [income]값이 월급이면 [inAnnual]값을 false로 설정하고
  /// 연봉이면 퇴직금 포함여부를 [includeServerancePay]값에 설정한다.
  /// true면 퇴직금포함, false면 퇴직금별도임.
  /// 비과세액은 [nontaxable]에 값을 설정한다. 기본값은 10만원
  /// 부양가족은 본인포함 인원수를 [dependents]에 지정하고
  /// 20세 이하 자녀가 있는 경우 [youngDependents]에 지정한다.
  /// 소득세 납부세율은 [incomeTaxRate]에 설정
  SalarySummary calc(int income,
      {bool isAnnual = true,
      bool includeSeverancePay = false,
      int nontaxable = 100000,
      int dependents = 1,
      int youngDependents = 0,
      double incomeTaxRate = 1.0}) {
    /// 연봉(단순 참고용)
    int annualSalary = 0;

    /// 세전 월급
    int grossSalary = 0;
    if (isAnnual) {
      // 퇴직금포함이면 1년을 13개월로
      final monthCount = includeSeverancePay ? 13.0 : 12.0;
      grossSalary = (income / monthCount).round();
      annualSalary = income;
    } else {
      grossSalary = income;
      annualSalary = grossSalary * 12;
    }

    /// 비과세액보다 월소득액이 작은 경우 그냥 0으로 설정하고 진행한다.
    /// exception를 발생시키는 것 보다는 그냥 모두 0값으로 리턴하는게 편하다고 판단했음.
    /*if (grossSalary < nontaxable) {
      throw FormatException('비과세액이 월소득액보다 큽니다.');
    }*/

    if (grossSalary < nontaxable) nontaxable = grossSalary;

    // 과세금액 (비과세 금액 제외)
    int taxableIncome = grossSalary - nontaxable;

    // 공제액 계산

    final incomeTaxCalc = IncomeTaxCalc(baseDate: baseDate);

    // 소득세
    final incomeTax = incomeTaxCalc.calc(
        taxableIncome, dependents + youngDependents,
        taxRate: incomeTaxRate);

    // 지방소득세
    final localIncomeTax = incomeTaxCalc.calcLocalIncomeTax(incomeTax);

    // 국민연금 (근로자 부담액만)
    final nationalPension = _majorInsuranceCalc
        .calcNationalPension(taxableIncome, onlyWorker: true);

    /// 건강보험료/장기요양보험료 (근로자 부담액만)
    final healthCarePremiums = _majorInsuranceCalc
        .calcHealthInsurancePremium(taxableIncome, onlyWorker: true);

    final employmentInsurancePremium = _majorInsuranceCalc
        .calcEmploymentInsurancePremium(taxableIncome, onlyWorker: true);
    return SalarySummary(grossSalary, incomeTax, localIncomeTax, this.baseDate,
        nontaxable: nontaxable,
        nationalPension: nationalPension,
        healthInsurancePremium: healthCarePremiums[0],
        longTermCareInsurancePremium: healthCarePremiums[1],
        employmentInsurancePremium: employmentInsurancePremium,
        annualGrossSalary: annualSalary);
  }

  /// 도움말
  ///
  String helpText(String name) {
    String text = '';
    switch (name) {
      case 'national-pension':
      case 'health-care':
      case 'long-term-care':
      case 'employment-insurance':
        text = _majorInsuranceCalc.helpText(name);
        break;
    }

    return text;
  }

  /// 4대보험 계산기
  late MajorInsuranceCalculator _majorInsuranceCalc;
}

/// 영단어는 https://www.philinlove.com/entry/difference-between-wage-salary-and-pay 참고함.
/// 월급 요약정보
class SalarySummary {
  /// 월급(세전)
  final int grossSalary;

  /// 연봉(세전)
  final int annualGrossSalary;

  /// 월급(세후)
  int get netSalary {
    int salary = grossSalary - totalDeduction;

    /// 계산결과값이 마이너스면 0을 리턴한다.
    return salary < 0 ? 0 : salary;
  }

  /// 전체 공제액
  int get totalDeduction {
    return incomeTax +
        localIncomeTax +
        nationalPension +
        healthInsurancePremium +
        longTermCareInsurancePremium +
        employmentInsurancePremium;
  }

  /// 근로소득세
  final incomeTax;

  /// 지방소득세
  final localIncomeTax;

  /// 국민연금
  final nationalPension;

  /// 건강보험료
  final healthInsurancePremium;

  /// 장기요양보험료
  final longTermCareInsurancePremium;

  /// 고용보험료
  final employmentInsurancePremium;

  /// 비과세액(기본: 10만원)
  final int nontaxable;

  /// 계산기준일
  final DateTime? baseDate;

  const SalarySummary(
      this.grossSalary, this.incomeTax, this.localIncomeTax, this.baseDate,
      {this.nontaxable = 100000,
      this.nationalPension = 0,
      this.healthInsurancePremium = 0,
      this.longTermCareInsurancePremium = 0,
      this.employmentInsurancePremium = 0,
      this.annualGrossSalary = 0});

  static const SalarySummary zero = SalarySummary(0, 0, 0, null);
}
