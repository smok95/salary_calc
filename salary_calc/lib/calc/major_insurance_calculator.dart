/// 4대 보험 계산
class MajorInsuranceCalculator {
  /// 계산기준일
  final DateTime baseDate;

  /// 건강보험료율
  late double _taxRateHealthCare;

  /// 장기요양보험요율
  late double _taxRateLongTermCare;

  /// 국민연금요율
  late double _taxRateNationalPension;

  /// 고용보험요율
  late double _taxRateEmploymentInsurance;

  MajorInsuranceCalculator({DateTime? baseDate})
      : this.baseDate = baseDate ?? DateTime.now() {
    final year = this.baseDate.year;
    if (year <= 2020) {
      // 2020년 기준
      // 6.67% (근로자: 3.335%, 사업주: 3.335% 부담)
      _taxRateHealthCare = 0.0667;
      // 10.25%
      _taxRateLongTermCare = 0.1025;
      // 9% (근로자: 4.5%, 사업주: 4.5%)
      _taxRateNationalPension = 0.09;
      // 1.6% (각각 50%)
      _taxRateEmploymentInsurance = 0.016;
    } else if (year >= 2021) {
      // 2021년 기준
      // 6.86% (근로자: 3.43%, 사업주: 3.44% 부담)
      _taxRateHealthCare = 0.0686;
      // 11.52%
      _taxRateLongTermCare = 0.1152;
      // 9% (근로자: 4.5%, 사업주: 4.5%)
      _taxRateNationalPension = 0.09;
      // 1.6% (각각 50%)
      _taxRateEmploymentInsurance = 0.016;
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
    int nationalPension = (income * _taxRateNationalPension).toInt();

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
    int healthCost = (income * _taxRateHealthCare).toInt();

    if (onlyWorker) healthCost ~/= 2;

    /// 원단위 절사
    healthCost = (healthCost ~/ 10) * 10;

    /// 장기요양보험 건강보험료의 _taxRateLongTermCare% (근로자와 사업주 각각 50% 부담)
    int careCost = (healthCost * _taxRateLongTermCare).toInt();

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

    final double each = _taxRateEmploymentInsurance / 2;

    int cost = (income * each).toInt();

    if (!onlyWorker) {
      double additionalTaxRate = 0.0025;

      if (employeeCount >= 150 && employeeCount < 1000) {
        additionalTaxRate = 0.0065;
      } else if (employeeCount >= 1000) {
        additionalTaxRate = 0.0085;
      }

      if (prioritySupportedCompany) additionalTaxRate = 0.0045;
      if (government) additionalTaxRate = 0.0085;

      cost += (income * (each + additionalTaxRate)).toInt();
    }

    return (cost ~/ 10) * 10;
  }

  String doubleToString(double v, int fractionDigits) {
    var s = v.toStringAsFixed(fractionDigits);
    if (s.isEmpty) return s;

    if (fractionDigits >= 1) {
      for (var i = 0; i < fractionDigits; i++) {
        if (s.endsWith('0')) {
          s = s.substring(0, s.length - 1);
        } else {
          break;
        }
      }

      if (s.endsWith('.')) {
        s = s.substring(0, s.length - 1);
      }
    }
    return s;
  }

  String helpText(String name) {
    String text = '';
    final year = baseDate.year;
    var percent = 0.0;
    switch (name) {
      case 'national-pension':
        percent = _taxRateNationalPension * 100;
        final each = doubleToString(percent / 2, 1);
        text =
            '$year년을 기준으로 월 소득액에서 비과세액을 제외한 금액의 ${doubleToString(percent, 1)}%를 공제합니다. (회사 $each%, 본인 $each% 각각 부담)\n' +
                '월 최저액 32만원, 최대액 503만원으로 소득이 최저액에 못미치거나, 최대액을 초과하는 경우에는 ' +
                '최저액 또는 최대액을 기준으로 계산됩니다.';
        break;
      case 'health-care':
        percent = _taxRateHealthCare * 100;
        text =
            '$year년 기준 건강보험료 ${doubleToString(percent, 2)}%\n(근로자와 사업주 각각 ${doubleToString(percent / 2, 2)}% 부담)';
        break;
      case 'long-term-care':
        percent = _taxRateLongTermCare * 100;
        text =
            '$year년 기준 건강보험료의 ${doubleToString(percent, 2)}%\n(근로자와 사업주 각각 ${doubleToString(percent / 2, 3)}% 부담)';
        break;
      case 'employment-insurance':
        percent = _taxRateEmploymentInsurance * 100;
        final each = doubleToString(percent / 2, 1);
        text =
            '$year년 기준 ${doubleToString(percent, 1)}%\n(근로자와 사업주 각각 $each% 부담)';
        break;
    }

    return text;
  }
}
