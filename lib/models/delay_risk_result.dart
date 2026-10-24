enum DelayRiskLevel { low, moderate, high, critical }

enum PredictedArrivalStatus {
  early,         // Arriving ahead of schedule (< -3 min offset)
  onTime,        // Arriving on schedule (-3 to +10 mins)
  minorDelay,    // 11 to 30 mins
  moderateDelay, // 31 to 60 mins
  severeDelay,   // > 60 mins
}

class DelayRiskResult {
  final double noDelayProb; // P(No Delay <15m)
  final double moderateDelayProb; // P(Moderate Delay 15-60m)
  final double severeDelayProb; // P(Severe Delay >60m)
  final double overallRiskScore; // Combined weighted delay risk percentage (0% - 100%)
  final DelayRiskLevel riskLevel;

  // Evidence Inputs used for calculation
  final String weatherCondition;
  final String trafficCongestion;
  final String maintenanceStatus;
  final String inboundStatus;

  // Diagnostic Insights
  final String primaryRiskDriver;
  final String recommendation;

  // Delay & Arrival Time Prediction Features
  final int predictedMinutesOffset; // Negative = Early (e.g. -12), 0 = On Time, Positive = Delay (e.g. +35)
  final String offsetRange; // e.g. "-10 to -15 mins (Early)", "On-Time (±3 mins)", "+25 to +40 mins"
  final PredictedArrivalStatus predictedStatus;
  final String statusBadgeText; // e.g. "EARLY ARRIVAL EXPECTED", "ON-TIME ARRIVAL", "DELAY PREDICTED (+35M)"
  final String weatherImpactNote; // Breakdown of how the chosen weather affects schedule
  final String arrivalStatusDescription; // Summary explanation of arrival timing

  DelayRiskResult({
    required this.noDelayProb,
    required this.moderateDelayProb,
    required this.severeDelayProb,
    required this.overallRiskScore,
    required this.riskLevel,
    required this.weatherCondition,
    required this.trafficCongestion,
    required this.maintenanceStatus,
    required this.inboundStatus,
    required this.primaryRiskDriver,
    required this.recommendation,
    required this.predictedMinutesOffset,
    required this.offsetRange,
    required this.predictedStatus,
    required this.statusBadgeText,
    required this.weatherImpactNote,
    required this.arrivalStatusDescription,
  });

  String get riskLevelName {
    switch (riskLevel) {
      case DelayRiskLevel.low:
        return 'Low Risk (<25%)';
      case DelayRiskLevel.moderate:
        return 'Moderate Risk (25-50%)';
      case DelayRiskLevel.high:
        return 'High Risk (50-75%)';
      case DelayRiskLevel.critical:
        return 'Critical Delay Risk (>75%)';
    }
  }

  bool get isEarly => predictedStatus == PredictedArrivalStatus.early;
  bool get isOnTime => predictedStatus == PredictedArrivalStatus.onTime;
  bool get isDelayed =>
      predictedStatus == PredictedArrivalStatus.minorDelay ||
      predictedStatus == PredictedArrivalStatus.moderateDelay ||
      predictedStatus == PredictedArrivalStatus.severeDelay;

  String get formattedOffset {
    if (predictedMinutesOffset < 0) {
      return '${predictedMinutesOffset.abs()}m Early';
    } else if (predictedMinutesOffset == 0) {
      return 'On Time (0m)';
    } else {
      int h = predictedMinutesOffset ~/ 60;
      int m = predictedMinutesOffset % 60;
      if (h > 0) {
        return m > 0 ? '+$h h $m m' : '+$h h';
      }
      return '+$m m';
    }
  }

  DateTime calculateAdjustedArrival(DateTime scheduledArrival) {
    return scheduledArrival.add(Duration(minutes: predictedMinutesOffset));
  }
}
