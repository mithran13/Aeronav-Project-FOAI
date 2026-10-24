import 'package:flutter_test/flutter_test.dart';
import 'package:aero_nav/algorithms/bayesian_network.dart';
import 'package:aero_nav/models/delay_risk_result.dart';

void main() {
  group('BayesianFlightDelayNetwork Tests', () {
    test('Optimal conditions with Clear / VFR weather produce Early Arrival', () {
      final res = BayesianFlightDelayNetwork.calculateDelayRisk(
        weather: 'Clear / VFR',
        traffic: 'Low Congestion',
        maintenance: 'Inspection Passed (Clean)',
        inbound: 'On-Time Arrival',
      );

      // Must be classified as early arrival
      expect(res.isEarly, isTrue);
      expect(res.isOnTime, isFalse);
      expect(res.isDelayed, isFalse);
      expect(res.predictedMinutesOffset, lessThan(0));
      expect(res.predictedStatus, equals(PredictedArrivalStatus.early));
      expect(res.statusBadgeText, contains('EARLY'));
      expect(res.weatherImpactNote, contains('VFR'));
      expect(res.offsetRange, contains('Early'));

      // Test adjusted arrival time calculation
      final scheduled = DateTime(2026, 10, 17, 14, 30);
      final adjusted = res.calculateAdjustedArrival(scheduled);
      expect(adjusted.isBefore(scheduled), isTrue);
      expect(adjusted.difference(scheduled).inMinutes, equals(res.predictedMinutesOffset));
    });

    test('Severe Thunderstorm produces Severe Delay', () {
      final res = BayesianFlightDelayNetwork.calculateDelayRisk(
        weather: 'Severe Thunderstorm',
        traffic: 'High Congestion (Peak Hours)',
        maintenance: 'Major Service Needed',
        inbound: 'Severe Inbound Delay (>60m)',
      );

      expect(res.isDelayed, isTrue);
      expect(res.isEarly, isFalse);
      expect(res.predictedMinutesOffset, greaterThan(60));
      expect(res.riskLevel, equals(DelayRiskLevel.critical));
      expect(res.predictedStatus, equals(PredictedArrivalStatus.severeDelay));
      expect(res.statusBadgeText, contains('SEVERE DELAY'));
      expect(res.weatherImpactNote, contains('Convective'));

      final scheduled = DateTime(2026, 10, 17, 14, 30);
      final adjusted = res.calculateAdjustedArrival(scheduled);
      expect(adjusted.isAfter(scheduled), isTrue);
    });

    test('Moderate Congestion with Clear weather produces On-Time Arrival', () {
      final res = BayesianFlightDelayNetwork.calculateDelayRisk(
        weather: 'Clear / VFR',
        traffic: 'Moderate Congestion',
        maintenance: 'Inspection Passed (Clean)',
        inbound: 'On-Time Arrival',
      );

      expect(res.predictedMinutesOffset, inInclusiveRange(-5, 12));
      expect(res.offsetRange.isNotEmpty, isTrue);
    });
  });
}
