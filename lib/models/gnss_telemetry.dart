enum RaimStatus {
  integrityOk,
  degradedAccuracy,
  jammingDetected,
  spoofingAlert,
}

enum NavPrimarySource {
  gnssPrimary,
  insDeadReckoning,
  vorDmeMultiLateration,
}

class SatelliteSignal {
  final int prn; // Satellite ID
  final String constellation; // GPS, Galileo, GLONASS, BeiDou
  final double elevationDeg;
  final double azimuthDeg;
  final double carrierToNoiseDbHz; // C/N0 (30 - 50 dB-Hz is healthy)
  final double pseudorangeResidualMeters;
  final bool isLocked;

  const SatelliteSignal({
    required this.prn,
    required this.constellation,
    required this.elevationDeg,
    required this.azimuthDeg,
    required this.carrierToNoiseDbHz,
    required this.pseudorangeResidualMeters,
    required this.isLocked,
  });
}

class GnssTelemetry {
  final int satellitesInView;
  final int satellitesLocked;
  final double averageCn0DbHz;
  final double hdop; // Horizontal Dilution of Precision
  final double vdop; // Vertical Dilution of Precision
  final double clockDriftNsPerSec;
  final double pseudorangeJumpMeters;
  final RaimStatus raimStatus;
  final NavPrimarySource primarySource;

  // Spatial Divergence (GPS Reported vs Triple-INS True Coordinates)
  final double reportedLat;
  final double reportedLon;
  final double trueInsLat;
  final double trueInsLon;
  final double spoofingOffsetKm;

  final String alertMessage;
  final bool isFailoverActive;
  final List<SatelliteSignal> satellites;

  const GnssTelemetry({
    required this.satellitesInView,
    required this.satellitesLocked,
    required this.averageCn0DbHz,
    required this.hdop,
    required this.vdop,
    required this.clockDriftNsPerSec,
    required this.pseudorangeJumpMeters,
    required this.raimStatus,
    required this.primarySource,
    required this.reportedLat,
    required this.reportedLon,
    required this.trueInsLat,
    required this.trueInsLon,
    required this.spoofingOffsetKm,
    required this.alertMessage,
    required this.isFailoverActive,
    required this.satellites,
  });
}
