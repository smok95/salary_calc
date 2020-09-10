import 'package:salary_calc/income_tax_table.dart';

/// 4대 보험 계산
class MajorInsuranceCalculator {
  /// 국민연금 보험료 계산
  ///
  /// 소득월액을 [income]에 입력한다.
  /// 근로자 부담액만 확인하려면 [onlyWorker]값을 true로 설정한다.
  /// 작성기준 : 2020년
  static int calcNationalPension(int income, {bool onlyWorker = false}) {
    if (income <= 0) return 0;

    // 1000원단위 절사
    income = (income ~/ 1000) * 1000;

    final minimum = 320000;
    final maximum = 5030000;

    /// 기준 소득월액 (최저 32만 최대 503만)
    if (income < minimum) income = minimum;
    if (income > maximum) income = maximum;

    /// 소득월액의 9%(근로자부담 4.5%, 사용자부담(회사): 4.5%)
    int nationalPension = (income * 0.09).toInt();

    if (onlyWorker) {
      nationalPension = nationalPension ~/ 2;
    }

    return nationalPension;
  }

  /// 건강보험료 및 장기요양보험료 계산
  ///
  /// 소득월액을 [income]에 입력한다.
  ///
  /// [건강보험료, 장기요양보험료] 형식으로 리턴된다.
  static List calcHealthInsurancePremium(int income,
      {bool onlyWorker = false}) {
    if (income <= 0) return [0, 0];

    /// 2020년 기준 건강보험료 6.67% (근로자: 3.335%, 사업주 : 3.335% 부담)
    int healthCost = (income * 0.0667).toInt();

    if (onlyWorker) healthCost ~/= 2;

    /// 원단위 절사
    healthCost = (healthCost ~/ 10) * 10;

    /// 2020기준  건강보험료의 10.25% (근로자와 사업주 각각 50% 부담)
    int careCost = (healthCost * 0.1025).toInt();

    /// 원단위 절사
    careCost = (careCost ~/ 10) * 10;

    return [healthCost, careCost];
  }

  /// 고용보험료 계산
  ///
  /// 소득월액을 [income]에 입력한다.
  /// 근로자수는 [employeeCount]에 입력한다.
  /// 우선지원대상기업인 경우 [prioritySupportedCompany]를 true로 설정한다.
  /// 정부,지방단체인 경우에는 [government]를 true로 설정한다.
  static int calcEmploymentInsurancePremium(int income,
      {int employeeCount = 0,
      bool prioritySupportedCompany = false,
      bool government = false,
      bool onlyWorker = false}) {
    /// 2020년 기준 1.6% (근로자 0.8% 사업주 0.8%)
    /// 여기에 추가로 기업 근로자수에 따라 사업주는 고용안전,직업능력개발사업 금액이 추가된다.
    /// 150인 미만 : +0.25%
    /// 150인 이상(우선지원대상기업): + 0.45%
    /// 150 ~ 1000인 미만 : +0.65%
    /// 1000인 이상 또는 정부,지방단체 : +0.85%

    int cost = (income * 0.008).toInt();

    if (!onlyWorker) {
      double additionalTaxRate = 0.0025;

      if (employeeCount >= 150 && employeeCount < 1000) {
        additionalTaxRate = 0.0065;
      } else if (employeeCount >= 1000) {
        additionalTaxRate = 0.0085;
      }

      if (prioritySupportedCompany) additionalTaxRate = 0.0045;
      if (government) additionalTaxRate = 0.0085;

      cost += (income * (0.008 + additionalTaxRate)).toInt();
    }

    return (cost ~/ 10) * 10;
  }
}

class SalaryCalculator {
  /// [income]은 전체 급여액
  /// [income]값이 월급이면 [inAnnual]값을 false로 설정하고
  /// 연봉이면 퇴직금 포함여부를 [includeServerancePay]값에 설정한다.
  /// true면 퇴직금포함, false면 퇴직금별도임.
  /// 비과세액은 [nontaxable]에 값을 설정한다. 기본값은 10만원
  /// 부양가족은 본인포함 인원수를 [dependents]에 지정하고
  /// 20세 이하 자녀가 있는 경우 [youngDependents]에 지정한다.
  /// 소득세 납부세율은 [incomeTaxRate]에 설정
  static SalarySummary calc(int income,
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

    // 소득세
    final incomeTax = IncomeTaxTable.calc(
        taxableIncome, dependents + youngDependents,
        taxRate: incomeTaxRate);

    // 지방소득세
    final localIncomeTax = IncomeTaxTable.calcLocalIncomeTax(incomeTax);

    // 국민연금 (근로자 부담액만)
    final nationalPension = MajorInsuranceCalculator.calcNationalPension(
        taxableIncome,
        onlyWorker: true);

    /// 건강보험료/장기요양보험료 (근로자 부담액만)
    final healthCarePremiums =
        MajorInsuranceCalculator.calcHealthInsurancePremium(taxableIncome,
            onlyWorker: true);

    final employmentInsurancePremium =
        MajorInsuranceCalculator.calcEmploymentInsurancePremium(taxableIncome,
            onlyWorker: true);
    return SalarySummary(grossSalary, incomeTax, localIncomeTax,
        nontaxable: nontaxable,
        nationalPension: nationalPension,
        healthInsurancePremium: healthCarePremiums[0],
        longTermCareInsurancePremium: healthCarePremiums[1],
        employmentInsurancePremium: employmentInsurancePremium,
        annualGrossSalary: annualSalary);
  }

  /// 도움말
  ///
  static String helpText(String name, int year) {
    String text = '';
    switch (name) {
      case 'national-pension':
        text =
            '2020년을 기준으로 월 소득액에서 비과세액을 제외한 금액의 9%를 공제합니다. (회사 4.5%, 본인 4.5% 각각 부담)\n' +
                '월 최저액 32만원, 최대액 503만원으로 소득이 최저액에 못미치거나, 최대액을 초과하는 경우에는 ' +
                '최저액 또는 최대액을 기준으로 계산됩니다.';
        break;
      case 'health-care':
        text = '2020년 기준 건강보험료 6.67%\n(근로자와 사업주 각각 3.335% 부담)';
        break;
      case 'long-term-care':
        text = '2020년 기준 건강보험료의 10.25%\n(근로자와 사업주 각각 5.125% 부담)';
        break;
      case 'employment-insurance':
        text = '2020년 기준 1.6%\n(근로자와 사업주 각각 0.8% 부담)';
        break;
    }

    return text;
  }
}

/// 영단어는 https://www.philinlove.com/entry/difference-between-wage-salary-and-pay 참고함.
/// 월급 요약정보
class SalarySummary {
  /// 월급(세전)
  final int grossSalary;

  /// 연봉(세전) nullable value
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

  const SalarySummary(this.grossSalary, this.incomeTax, this.localIncomeTax,
      {this.nontaxable = 100000,
      this.nationalPension = 0,
      this.healthInsurancePremium = 0,
      this.longTermCareInsurancePremium = 0,
      this.employmentInsurancePremium = 0,
      this.annualGrossSalary});

  static const SalarySummary zero = SalarySummary(0, 0, 0);
}
