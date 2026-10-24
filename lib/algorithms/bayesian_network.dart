import '../models/delay_risk_result.dart';

/// Bayesian Network Engine for Flight Delay Risk Assessment.
/// Models a Directed Acyclic Graph (DAG) with Conditional Probability Tables (CPTs).
class BayesianFlightDelayNetwork {
  // Evidence Value Lists
  static const List<String> weatherOptions = [
    'Clear / VFR',
    'Low Visibility / Fog',
    'High Crosswinds',
    'Severe Thunderstorm',
  ];

  static const List<String> trafficOptions = [
    'Low Congestion',
    'Moderate Congestion',
    'High Congestion (Peak Hours)',
  ];

  static const List<String> maintenanceOptions = [
    'Inspection Passed (Clean)',
    'Minor Defect (MEL Item)',
    'Major Service Needed',
  ];

  static const List<String> inboundOptions = [
    'On-Time Arrival',
    'Minor Inbound Delay (<30m)',
    'Severe Inbound Delay (>60m)',
  ];

  /// Computes exact posterior delay probability P(Delay | Weather, Traffic, Maintenance, Inbound)
  /// and calculates predicted time offset (early arrival / on-time / delayed duration in minutes).
  static DelayRiskResult calculateDelayRisk({
    required String weather,
    required String traffic,
    required String maintenance,
    required String inbound,
  }) {
    // 1. Calculate Individual Risk Weights & Time Deltas from Evidence Factors
    double wRisk = 0.0;
    double weatherTimeDelta = 0.0;
    String weatherImpactNote = '';

    if (weather == 'Clear / VFR') {
      wRisk = 0.0;
      weatherTimeDelta = -12.0; // Early arrival advantage due to calm upper air and direct visual approaches
      weatherImpactNote =
          'Optimal VFR meteorological conditions, calm upper atmosphere, and direct visual approaches expedite cruise and descent profiles, saving ~10-15 minutes.';
    } else if (weather == 'Low Visibility / Fog') {
      wRisk = 0.25;
      weatherTimeDelta = 22.0;
      weatherImpactNote =
          'Low visibility requires CAT III Instrument Landing System (ILS) spacing (separation increased from 3 NM to 6 NM) and slow taxi turnoffs, adding ~20-25 minutes.';
    } else if (weather == 'High Crosswinds') {
      wRisk = 0.40;
      weatherTimeDelta = 38.0;
      weatherImpactNote =
          'Severe crosswinds limit active runway capacity and trigger radar vectoring around terminal airspace, adding ~35-45 minutes.';
    } else if (weather == 'Severe Thunderstorm') {
      wRisk = 0.85;
      weatherTimeDelta = 75.0;
      weatherImpactNote =
          'Convective storm cells require active airspace detours (100-250 NM) and airborne holding patterns, delaying arrival by ~60-90 minutes.';
    }

    double tRisk = 0.0;
    double trafficTimeDelta = 0.0;
    if (traffic == 'Low Congestion') {
      tRisk = 0.0;
      trafficTimeDelta = -3.0; // Continuous descent approach without holding
    } else if (traffic == 'Moderate Congestion') {
      tRisk = 0.20;
      trafficTimeDelta = 14.0;
    } else if (traffic == 'High Congestion (Peak Hours)') {
      tRisk = 0.55;
      trafficTimeDelta = 32.0;
    }

    double mRisk = 0.0;
    double maintenanceTimeDelta = 0.0;
    if (maintenance == 'Inspection Passed (Clean)') {
      mRisk = 0.0;
      maintenanceTimeDelta = 0.0;
    } else if (maintenance == 'Minor Defect (MEL Item)') {
      mRisk = 0.35;
      maintenanceTimeDelta = 18.0;
    } else if (maintenance == 'Major Service Needed') {
      mRisk = 0.90;
      maintenanceTimeDelta = 70.0;
    }

    double iRisk = 0.0;
    double inboundTimeDelta = 0.0;
    if (inbound == 'On-Time Arrival') {
      iRisk = 0.0;
      inboundTimeDelta = 0.0;
    } else if (inbound == 'Minor Inbound Delay (<30m)') {
      iRisk = 0.40;
      inboundTimeDelta = 24.0;
    } else if (inbound == 'Severe Inbound Delay (>60m)') {
      iRisk = 0.85;
      inboundTimeDelta = 72.0;
    }

    // 2. Bayesian Noisy-OR Factor Integration Model for Joint Conditional Distribution
    // P(No Delay) = (1 - wRisk) * (1 - tRisk) * (1 - mRisk) * (1 - iRisk)
    final double pNoDelay =
        ((1.0 - wRisk) * (1.0 - tRisk) * (1.0 - mRisk) * (1.0 - iRisk))
            .clamp(0.02, 0.95);

    // Complementary Total Delay Probability P(Delay) = 1 - P(No Delay)
    final double pTotalDelay = 1.0 - pNoDelay;

    // Distribute total delay into Moderate (15-60m) vs Severe (>60m) based on severity factors
    final double severityScore =
        (wRisk * 1.2 + mRisk * 1.5 + iRisk * 1.1 + tRisk * 0.8) / 4.6;

    double pSevereDelay = pTotalDelay * severityScore.clamp(0.15, 0.85);
    double pModerateDelay = pTotalDelay - pSevereDelay;

    // Normalize probabilities to sum to exactly 1.0
    final double totalSum = pNoDelay + pModerateDelay + pSevereDelay;
    final double normNoDelay = pNoDelay / totalSum;
    final double normModerate = pModerateDelay / totalSum;
    final double normSevere = pSevereDelay / totalSum;

    // Overall Weighted Risk Score Percentage (0% - 100%)
    final double overallScore =
        (normModerate * 45.0 + normSevere * 100.0).clamp(0.0, 100.0);

    // Determine Risk Level Tier
    DelayRiskLevel riskLevel;
    if (overallScore < 25.0) {
      riskLevel = DelayRiskLevel.low;
    } else if (overallScore < 50.0) {
      riskLevel = DelayRiskLevel.moderate;
    } else if (overallScore < 75.0) {
      riskLevel = DelayRiskLevel.high;
    } else {
      riskLevel = DelayRiskLevel.critical;
    }

    // Identify Primary Risk Driver Factor
    String primaryDriver = 'Optimal Operational Conditions';
    double maxWeight = 0.0;
    if (wRisk > maxWeight) {
      maxWeight = wRisk;
      primaryDriver = 'Adverse Weather ($weather)';
    }
    if (tRisk > maxWeight) {
      maxWeight = tRisk;
      primaryDriver = 'Air Traffic Congestion ($traffic)';
    }
    if (mRisk > maxWeight) {
      maxWeight = mRisk;
      primaryDriver = 'Aircraft Technical Inspection ($maintenance)';
    }
    if (iRisk > maxWeight) {
      maxWeight = iRisk;
      primaryDriver = 'Inbound Turnaround Delay ($inbound)';
    }

    // 3. Compute Predicted Time Offset (Early, On-Time, or Delay Duration in Minutes)
    final double netEvidenceMinutes =
        weatherTimeDelta + trafficTimeDelta + maintenanceTimeDelta + inboundTimeDelta;

    // Expected value according to Bayesian posterior probability distribution
    final double expectedPosteriorMinutes =
        (normNoDelay * (weather == 'Clear / VFR' ? -10.0 : 2.0)) +
        (normModerate * 32.0) +
        (normSevere * 82.0);

    // Blended estimate (45% evidence sum + 55% Bayesian expected value)
    int predictedMinutesOffset =
        ((netEvidenceMinutes * 0.45) + (expectedPosteriorMinutes * 0.55)).round();

    // Determine Predicted Arrival Status, Offset Range, and Description
    PredictedArrivalStatus predictedStatus;
    String statusBadgeText;
    String offsetRange;
    String arrivalStatusDescription;

    if (predictedMinutesOffset <= -4) {
      predictedStatus = PredictedArrivalStatus.early;
      statusBadgeText = 'EARLY ARRIVAL EXPECTED';
      final int minEarly = (predictedMinutesOffset - 3).abs();
      final int maxEarly = (predictedMinutesOffset + 3).abs();
      final int lowBound = minEarly < maxEarly ? minEarly : maxEarly;
      final int highBound = minEarly > maxEarly ? minEarly : maxEarly;
      offsetRange = '-$lowBound to -$highBound mins (Early)';
      arrivalStatusDescription =
          'Flight is tracking ahead of schedule. Favorable meteorological conditions (Clear / VFR) and direct air traffic routing allow an estimated ${predictedMinutesOffset.abs()} minutes EARLY touchdown.';
    } else if (predictedMinutesOffset <= 10) {
      predictedStatus = PredictedArrivalStatus.onTime;
      statusBadgeText = 'ON-TIME ARRIVAL';
      offsetRange = 'On-Time (±3 mins)';
      arrivalStatusDescription =
          'Flight schedule is maintained. Routine operational buffers absorb all minor variations, ensuring ON-TIME touchdown.';
    } else if (predictedMinutesOffset <= 30) {
      predictedStatus = PredictedArrivalStatus.minorDelay;
      statusBadgeText = 'MINOR DELAY (+${predictedMinutesOffset}M)';
      offsetRange = '+${predictedMinutesOffset - 5} to +${predictedMinutesOffset + 6} mins Delay';
      arrivalStatusDescription =
          'Minor delay predicted (~$predictedMinutesOffset mins). Mild headwinds or terminal sequencing may cause slight gate hold.';
    } else if (predictedMinutesOffset <= 60) {
      predictedStatus = PredictedArrivalStatus.moderateDelay;
      statusBadgeText = 'MODERATE DELAY (+${predictedMinutesOffset}M)';
      offsetRange = '+${predictedMinutesOffset - 8} to +${predictedMinutesOffset + 10} mins Delay';
      arrivalStatusDescription =
          'Moderate delay anticipated (~$predictedMinutesOffset mins) driven primarily by $primaryDriver. Gate arrival adjustment advised.';
    } else {
      predictedStatus = PredictedArrivalStatus.severeDelay;
      statusBadgeText = 'SEVERE DELAY (+${predictedMinutesOffset}M)';
      offsetRange = '+${predictedMinutesOffset - 15} to +${predictedMinutesOffset + 20} mins Delay';
      arrivalStatusDescription =
          'Significant disruption probable (~$predictedMinutesOffset mins / ${(predictedMinutesOffset / 60).toStringAsFixed(1)} hrs) due to $primaryDriver. Flight rerouting or slot swapping advised.';
    }

    // Generate Mitigation Recommendation
    String rec = 'Flight expected on schedule or early. Standard boarding and cruise procedures.';
    if (predictedStatus == PredictedArrivalStatus.early) {
      rec = 'Flight operating ahead of schedule. Coordinate with destination airport for early gate availability.';
    } else if (riskLevel == DelayRiskLevel.moderate) {
      rec = 'Monitor departure slot. Minor buffer built into ground turnaround.';
    } else if (riskLevel == DelayRiskLevel.high) {
      rec = 'High likelihood of gate delay (~$predictedMinutesOffset mins). Recommend notifying passengers & rerouting active airspace.';
    } else if (riskLevel == DelayRiskLevel.critical) {
      rec = 'Critical delay probable (~$predictedMinutesOffset mins). Consider aircraft swap, slot rescheduling, or issuing passenger travel advisories.';
    }

    return DelayRiskResult(
      noDelayProb: normNoDelay,
      moderateDelayProb: normModerate,
      severeDelayProb: normSevere,
      overallRiskScore: overallScore,
      riskLevel: riskLevel,
      weatherCondition: weather,
      trafficCongestion: traffic,
      maintenanceStatus: maintenance,
      inboundStatus: inbound,
      primaryRiskDriver: primaryDriver,
      recommendation: rec,
      predictedMinutesOffset: predictedMinutesOffset,
      offsetRange: offsetRange,
      predictedStatus: predictedStatus,
      statusBadgeText: statusBadgeText,
      weatherImpactNote: weatherImpactNote,
      arrivalStatusDescription: arrivalStatusDescription,
    );
  }
}
