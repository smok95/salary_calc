/// 4대 보험 계산
class MajorInsuranceCalculator {
  /// 계산기준일
  final DateTime baseDate;

  /// 건강보험료율
  double _taxRateHealth;

  MajorInsuranceCalculator({DateTime baseDate})
      : baseDate = baseDate ?? DateTime.now() {
    if (baseDate.year <= 2020) {
      // 2020년 기준 6.67% (근로자: 3.335%, 사업주: 3.335% 부담)
      _taxRateHealth = 0.0667;
    } else if (baseDate.year >= 2021) {
      // 2021년 기준 6.86% (근로자: 3.43%, 사업주: 3.44% 부담)
      _taxRateHealth = 0.0686;
    }
  }

  /// 국민연금 보험료 계산
  ///
  /// 소득월액을 [income]에 입력한다.
  /// 근로자 부담액만 확인하려면 [onlyWorker]값을 true로 설정한다.
  /// 작성기준 : 2020년
  int calcNationalPension(int income, {bool onlyWorker = false}) {
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
  List calcHealthInsurancePremium(int income, {bool onlyWorker = false}) {
    if (income <= 0) return [0, 0];

    /// 건강보험료
    int healthCost = (income * _taxRateHealth).toInt();

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
  int calcEmploymentInsurancePremium(int income,
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

  String helpText(String name) {
    String text = '';
    switch (name) {
      case 'health-care':
        final percent = _taxRateHealth * 100;
        text =
            '${baseDate.year}년 기준 건강보험료 ${percent.toStringAsFixed(2)}%\n(근로자와 사업주 각각 ${(percent / 2).toStringAsFixed(2)}% 부담)';
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
