import 'dart:math';
import '../models/airport_node.dart';
import '../models/eco_route_result.dart';
import 'haversine.dart';

class AircraftAeroProfile {
  final String model;
  final double baseBurnKgPerKm;
  final double optimalMach;
  final double standardMach;
  final int maxCeilingFl;

  const AircraftAeroProfile({
    required this.model,
    required this.baseBurnKgPerKm,
    required this.optimalMach,
    required this.standardMach,
    required this.maxCeilingFl,
  });
}

class EcoRouteAi {
  static const Map<String, AircraftAeroProfile> aircraftProfiles = {
    'Boeing 787-9 Dreamliner': AircraftAeroProfile(
      model: 'Boeing 787-9 Dreamliner',
      baseBurnKgPerKm: 5.4,
      optimalMach: 0.82,
      standardMach: 0.85,
      maxCeilingFl: 430,
    ),
    'Airbus A350-900': AircraftAeroProfile(
      model: 'Airbus A350-900',
      baseBurnKgPerKm: 5.6,
      optimalMach: 0.82,
      standardMach: 0.85,
      maxCeilingFl: 430,
    ),
    'Boeing 777-300ER': AircraftAeroProfile(
      model: 'Boeing 777-300ER',
      baseBurnKgPerKm: 7.8,
      optimalMach: 0.83,
      standardMach: 0.86,
      maxCeilingFl: 410,
    ),
    'Airbus A320neo': AircraftAeroProfile(
      model: 'Airbus A320neo',
      baseBurnKgPerKm: 2.7,
      optimalMach: 0.77,
      standardMach: 0.79,
      maxCeilingFl: 390,
    ),
  };

  /// Computes green eco-optimized trajectory vs standard flight profile.
  static EcoRouteResult calculateEcoTrajectory({
    required AirportNode origin,
    required AirportNode destination,
    String aircraftModel = 'Boeing 787-9 Dreamliner',
  }) {
    final profile = aircraftProfiles[aircraftModel] ?? aircraftProfiles.values.first;

    final distanceKm = HaversineCalculator.distanceKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Estimate realistic upper-level wind component based on latitude and direction (West-to-East Jet Stream)
    final dLon = destination.longitude - origin.longitude;
    final avgLat = (origin.latitude + destination.latitude) / 2;
    final isEastbound = dLon > 0;
    
    // Sub-tropical/Polar jet stream between 25°N and 60°N
    double tailwindComponentKts = 0.0;
    if (avgLat.abs() >= 20.0 && avgLat.abs() <= 65.0) {
      tailwindComponentKts = isEastbound ? 55.0 + min(45.0, avgLat.abs() * 0.8) : -45.0 - min(40.0, avgLat.abs() * 0.7);
    } else {
      tailwindComponentKts = isEastbound ? 18.0 : -15.0;
    }

    // 1. Standard Flight Profile (Constant FL330 / FL350, High Cost Index CI 80, Standard High Mach)
    final double standardBurnRate = profile.baseBurnKgPerKm * 1.08;
    final double standardFuelKg = distanceKm * standardBurnRate;

    // 2. Eco-Route AI Optimization (Continuous Descent / Step Climb FL330 -> FL370 -> FL410, CI 22, Wind-Optimized Speed)
    // Step climb reduces burn by ~6.5%, optimal Mach reduces by ~4.5%, tailwind routing adds ~3-8% efficiency
    double windEfficiencyFactor = tailwindComponentKts > 0 
        ? 1.0 - (tailwindComponentKts / 800.0) 
        : 1.0 + ((-tailwindComponentKts) / 1200.0);

    final double ecoBurnRate = profile.baseBurnKgPerKm * 0.89 * windEfficiencyFactor;
    final double ecoFuelKg = distanceKm * ecoBurnRate;

    final double fuelSavedKg = max(0.0, standardFuelKg - ecoFuelKg);
    // Jet-A density ~ 0.804 kg/liter -> 1 US Gal = 3.04 kg
    final double fuelSavedGal = fuelSavedKg / 3.04;
    final double fuelSavingsPercent = (fuelSavedKg / standardFuelKg) * 100.0;

    // CO2 emission factor: 3.16 kg CO2 per kg Jet-A
    final double co2SavedMetricTons = (fuelSavedKg * 3.16) / 1000.0;

    // Jet-A Global Average Price ~$2.85 per US gallon
    final double costSavingsUsd = fuelSavedGal * 2.85;

    // Time difference: flying slightly slower (lower Mach) vs tailwind assistance
    final double stdTimeMins = (distanceKm / (profile.standardMach * 1060.0)) * 60.0;
    final double ecoGroundSpeed = (profile.optimalMach * 1060.0) + (tailwindComponentKts * 1.852);
    final double ecoTimeMins = (distanceKm / ecoGroundSpeed) * 60.0;
    final double timeDiffMins = ecoTimeMins - stdTimeMins;

    // Step Climb Schedule
    final List<StepClimbWaypoint> stepClimbs = [
      StepClimbWaypoint(
        waypoint: 'TOC (Top of Climb)',
        flightLevel: 330,
        distanceAlongRouteKm: min(220.0, distanceKm * 0.1),
        rationale: 'Initial heavy gross weight cruising altitude.',
      ),
      if (distanceKm > 1500.0)
        StepClimbWaypoint(
          waypoint: 'STEP-1 (Fuel Burnoff)',
          flightLevel: 370,
          distanceAlongRouteKm: distanceKm * 0.45,
          rationale: 'Aircraft weight reduced by ${(standardFuelKg * 0.4 / 1000).toStringAsFixed(1)} tons. Air density optimal at FL370.',
        ),
      if (distanceKm > 4000.0 && profile.maxCeilingFl >= 410)
        StepClimbWaypoint(
          waypoint: 'STEP-2 (Final Cruise)',
          flightLevel: 410,
          distanceAlongRouteKm: distanceKm * 0.78,
          rationale: 'Minimum atmospheric drag at FL410 before Top of Descent (TOD).',
        ),
    ];

    double greenScore = (85.0 + fuelSavingsPercent * 1.1).clamp(70.0, 99.5);
    String rating = 'A+';
    if (greenScore < 85.0) rating = 'A';
    if (greenScore < 78.0) rating = 'B+';

    final summary = 'Optimized trajectory saves ${fuelSavedKg.toStringAsFixed(0)} kg of Jet-A '
        '(${co2SavedMetricTons.toStringAsFixed(1)} metric tons CO₂). '
        'Net airline operating savings of \$${costSavingsUsd.toStringAsFixed(0)} with '
        '${timeDiffMins < 0 ? '${timeDiffMins.abs().toStringAsFixed(1)}m faster arrival' : '+${timeDiffMins.toStringAsFixed(1)}m flight time'}.';

    return EcoRouteResult(
      aircraftModel: profile.model,
      originIata: origin.iata,
      destinationIata: destination.iata,
      distanceKm: distanceKm,
      standardFuelKg: standardFuelKg,
      ecoFuelKg: ecoFuelKg,
      fuelSavedKg: fuelSavedKg,
      fuelSavedGal: fuelSavedGal,
      fuelSavingsPercent: fuelSavingsPercent,
      co2SavedMetricTons: co2SavedMetricTons,
      costSavingsUsd: costSavingsUsd,
      costIndex: 22.0,
      cruisingMach: profile.optimalMach,
      averageWindComponentKts: tailwindComponentKts,
      timeDifferenceMinutes: timeDiffMins,
      stepClimbs: stepClimbs,
      greenScore: greenScore,
      greenRating: rating,
      summary: summary,
    );
  }
}
