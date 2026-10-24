import '../models/gnss_telemetry.dart';

enum GnssScenario {
  normalClean,
  electronicJamming,
  gpsSpoofingAttack,
  spaceWeatherScintillation,
}

class GnssAnomalyDetector {
  /// Evaluates GNSS telemetry and triggers anomaly alerts & failover.
  static GnssTelemetry evaluateTelemetry({
    required GnssScenario scenario,
    required double baseLat,
    required double baseLon,
  }) {
    switch (scenario) {
      case GnssScenario.normalClean:
        return _generateNormalClean(baseLat, baseLon);
      case GnssScenario.electronicJamming:
        return _generateJamming(baseLat, baseLon);
      case GnssScenario.gpsSpoofingAttack:
        return _generateSpoofing(baseLat, baseLon);
      case GnssScenario.spaceWeatherScintillation:
        return _generateSpaceWeather(baseLat, baseLon);
    }
  }

  static GnssTelemetry _generateNormalClean(double lat, double lon) {
    final sats = [
      const SatelliteSignal(prn: 4, constellation: 'GPS', elevationDeg: 62.0, azimuthDeg: 140.0, carrierToNoiseDbHz: 45.2, pseudorangeResidualMeters: 1.2, isLocked: true),
      const SatelliteSignal(prn: 9, constellation: 'GPS', elevationDeg: 78.0, azimuthDeg: 210.0, carrierToNoiseDbHz: 47.8, pseudorangeResidualMeters: -0.8, isLocked: true),
      const SatelliteSignal(prn: 14, constellation: 'GPS', elevationDeg: 35.0, azimuthDeg: 045.0, carrierToNoiseDbHz: 42.1, pseudorangeResidualMeters: 2.1, isLocked: true),
      const SatelliteSignal(prn: 18, constellation: 'Galileo', elevationDeg: 54.0, azimuthDeg: 310.0, carrierToNoiseDbHz: 46.5, pseudorangeResidualMeters: -1.1, isLocked: true),
      const SatelliteSignal(prn: 22, constellation: 'Galileo', elevationDeg: 28.0, azimuthDeg: 180.0, carrierToNoiseDbHz: 39.8, pseudorangeResidualMeters: 3.4, isLocked: true),
      const SatelliteSignal(prn: 27, constellation: 'GLONASS', elevationDeg: 48.0, azimuthDeg: 095.0, carrierToNoiseDbHz: 43.4, pseudorangeResidualMeters: 0.5, isLocked: true),
      const SatelliteSignal(prn: 31, constellation: 'GPS', elevationDeg: 18.0, azimuthDeg: 270.0, carrierToNoiseDbHz: 36.2, pseudorangeResidualMeters: -2.4, isLocked: true),
    ];

    return GnssTelemetry(
      satellitesInView: 14,
      satellitesLocked: 7,
      averageCn0DbHz: 43.0,
      hdop: 0.9,
      vdop: 1.2,
      clockDriftNsPerSec: 1.2,
      pseudorangeJumpMeters: 1.4,
      raimStatus: RaimStatus.integrityOk,
      primarySource: NavPrimarySource.gnssPrimary,
      reportedLat: lat,
      reportedLon: lon,
      trueInsLat: lat,
      trueInsLon: lon,
      spoofingOffsetKm: 0.0,
      alertMessage: 'ALL SENSORS NORMAL. RAIM INTEGRITY VERIFIED. GNSS-1/2 LOCKED.',
      isFailoverActive: false,
      satellites: sats,
    );
  }

  static GnssTelemetry _generateJamming(double lat, double lon) {
    final sats = [
      const SatelliteSignal(prn: 4, constellation: 'GPS', elevationDeg: 62.0, azimuthDeg: 140.0, carrierToNoiseDbHz: 22.1, pseudorangeResidualMeters: 18.4, isLocked: false),
      const SatelliteSignal(prn: 9, constellation: 'GPS', elevationDeg: 78.0, azimuthDeg: 210.0, carrierToNoiseDbHz: 24.3, pseudorangeResidualMeters: 26.2, isLocked: false),
      const SatelliteSignal(prn: 14, constellation: 'GPS', elevationDeg: 35.0, azimuthDeg: 045.0, carrierToNoiseDbHz: 19.5, pseudorangeResidualMeters: 45.1, isLocked: false),
      const SatelliteSignal(prn: 18, constellation: 'Galileo', elevationDeg: 54.0, azimuthDeg: 310.0, carrierToNoiseDbHz: 26.0, pseudorangeResidualMeters: 14.8, isLocked: false),
    ];

    return GnssTelemetry(
      satellitesInView: 12,
      satellitesLocked: 0,
      averageCn0DbHz: 22.9,
      hdop: 8.5,
      vdop: 12.0,
      clockDriftNsPerSec: 18.5,
      pseudorangeJumpMeters: 38.0,
      raimStatus: RaimStatus.jammingDetected,
      primarySource: NavPrimarySource.insDeadReckoning,
      reportedLat: lat,
      reportedLon: lon,
      trueInsLat: lat,
      trueInsLon: lon,
      spoofingOffsetKm: 0.0,
      alertMessage: 'WARNING: HIGH-POWER RF JAMMING DETECTED ON L1/L5. GNSS PRIMARY LOST. AUTOMATIC FAILOVER TO TRIPLE-INS DEAD RECKONING.',
      isFailoverActive: true,
      satellites: sats,
    );
  }

  static GnssTelemetry _generateSpoofing(double lat, double lon) {
    // False spoofed position displaced by ~68 km (simulating false airport target)
    final spoofedLat = lat + 0.42;
    final spoofedLon = lon + 0.55;

    final sats = [
      // Spoofed signals with unnaturally identical high power (synthesized fake transmitter)
      const SatelliteSignal(prn: 4, constellation: 'GPS', elevationDeg: 62.0, azimuthDeg: 140.0, carrierToNoiseDbHz: 53.8, pseudorangeResidualMeters: 340.0, isLocked: true),
      const SatelliteSignal(prn: 9, constellation: 'GPS', elevationDeg: 78.0, azimuthDeg: 210.0, carrierToNoiseDbHz: 54.1, pseudorangeResidualMeters: 338.0, isLocked: true),
      const SatelliteSignal(prn: 14, constellation: 'GPS', elevationDeg: 35.0, azimuthDeg: 045.0, carrierToNoiseDbHz: 53.9, pseudorangeResidualMeters: 344.0, isLocked: true),
      const SatelliteSignal(prn: 18, constellation: 'GPS', elevationDeg: 54.0, azimuthDeg: 310.0, carrierToNoiseDbHz: 54.0, pseudorangeResidualMeters: 335.0, isLocked: true),
    ];

    return GnssTelemetry(
      satellitesInView: 8,
      satellitesLocked: 4,
      averageCn0DbHz: 53.9,
      hdop: 1.1,
      vdop: 1.3,
      clockDriftNsPerSec: 88.4, // Massive clock drift anomaly typical of ground spoofers
      pseudorangeJumpMeters: 339.0, // Massive spatial discrepancy
      raimStatus: RaimStatus.spoofingAlert,
      primarySource: NavPrimarySource.insDeadReckoning,
      reportedLat: spoofedLat,
      reportedLon: spoofedLon,
      trueInsLat: lat,
      trueInsLon: lon,
      spoofingOffsetKm: 68.4,
      alertMessage: 'CRITICAL EICAS ALERT: GPS SPOOFING ATTACK DETECTED! PSEUDORANGE RESIDUAL > 300M. INS POSITION DISAGREES BY 68.4 KM. REJECTING GNSS DATA.',
      isFailoverActive: true,
      satellites: sats,
    );
  }

  static GnssTelemetry _generateSpaceWeather(double lat, double lon) {
    final sats = [
      const SatelliteSignal(prn: 4, constellation: 'GPS', elevationDeg: 62.0, azimuthDeg: 140.0, carrierToNoiseDbHz: 34.2, pseudorangeResidualMeters: 14.2, isLocked: true),
      const SatelliteSignal(prn: 9, constellation: 'GPS', elevationDeg: 78.0, azimuthDeg: 210.0, carrierToNoiseDbHz: 35.1, pseudorangeResidualMeters: -12.8, isLocked: true),
      const SatelliteSignal(prn: 14, constellation: 'GPS', elevationDeg: 35.0, azimuthDeg: 045.0, carrierToNoiseDbHz: 31.8, pseudorangeResidualMeters: 18.5, isLocked: true),
      const SatelliteSignal(prn: 18, constellation: 'Galileo', elevationDeg: 54.0, azimuthDeg: 310.0, carrierToNoiseDbHz: 33.4, pseudorangeResidualMeters: -16.4, isLocked: true),
    ];

    return GnssTelemetry(
      satellitesInView: 9,
      satellitesLocked: 4,
      averageCn0DbHz: 33.6,
      hdop: 2.8,
      vdop: 3.9,
      clockDriftNsPerSec: 8.4,
      pseudorangeJumpMeters: 15.0,
      raimStatus: RaimStatus.degradedAccuracy,
      primarySource: NavPrimarySource.gnssPrimary,
      reportedLat: lat + 0.012,
      reportedLon: lon + 0.015,
      trueInsLat: lat,
      trueInsLon: lon,
      spoofingOffsetKm: 1.8,
      alertMessage: 'CAUTION: IONOSPHERIC SCINTILLATION. SIGNAL ATTENUATION & INCREASED HDOP (2.8). RAIM DEGRADED BUT ACCEPTABLE.',
      isFailoverActive: false,
      satellites: sats,
    );
  }
}
