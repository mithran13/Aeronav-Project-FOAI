class StepClimbWaypoint {
  final String waypoint;
  final int flightLevel;
  final double distanceAlongRouteKm;
  final String rationale;

  StepClimbWaypoint({
    required this.waypoint,
    required this.flightLevel,
    required this.distanceAlongRouteKm,
    required this.rationale,
  });
}

class EcoRouteResult {
  final String aircraftModel;
  final String originIata;
  final String destinationIata;
  final double distanceKm;

  // Fuel Metrics
  final double standardFuelKg;
  final double ecoFuelKg;
  final double fuelSavedKg;
  final double fuelSavedGal;
  final double fuelSavingsPercent;

  // Environmental & Cost Metrics
  final double co2SavedMetricTons;
  final double costSavingsUsd;

  // Flight Profile Metrics
  final double costIndex; // CI (0 - 100)
  final double cruisingMach; // e.g. M0.82
  final double averageWindComponentKts; // Positive = Tailwind, Negative = Headwind
  final double timeDifferenceMinutes; // Negative = faster, Positive = slower
  final List<StepClimbWaypoint> stepClimbs;
  final double greenScore; // 0 - 100
  final String greenRating; // A+, A, B, etc.
  final String summary;

  EcoRouteResult({
    required this.aircraftModel,
    required this.originIata,
    required this.destinationIata,
    required this.distanceKm,
    required this.standardFuelKg,
    required this.ecoFuelKg,
    required this.fuelSavedKg,
    required this.fuelSavedGal,
    required this.fuelSavingsPercent,
    required this.co2SavedMetricTons,
    required this.costSavingsUsd,
    required this.costIndex,
    required this.cruisingMach,
    required this.averageWindComponentKts,
    required this.timeDifferenceMinutes,
    required this.stepClimbs,
    required this.greenScore,
    required this.greenRating,
    required this.summary,
  });
}
