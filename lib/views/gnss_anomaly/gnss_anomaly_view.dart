import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../algorithms/gnss_anomaly_detector.dart';
import '../../models/gnss_telemetry.dart';
import '../../services/auth_service.dart';
import '../../services/flight_tracker_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';


class GnssAnomalyView extends StatefulWidget {
  const GnssAnomalyView({super.key});

  @override
  State<GnssAnomalyView> createState() => _GnssAnomalyViewState();
}

class _GnssAnomalyViewState extends State<GnssAnomalyView> {
  GnssScenario _selectedScenario = GnssScenario.normalClean;
  late GnssTelemetry _telemetry;
  String? _lastTrackedFlightId;

  @override
  void initState() {
    super.initState();
    _evaluateScenario(GnssScenario.normalClean);
  }

  void _evaluateScenario(GnssScenario scenario) {
    final tracker = Provider.of<FlightTrackerService>(context, listen: false);
    final activeFlight = tracker.activeFlight;

    final result = GnssAnomalyDetector.evaluateTelemetry(
      scenario: scenario,
      baseLat: activeFlight.currentLat,
      baseLon: activeFlight.currentLon,
    );

    setState(() {
      _selectedScenario = scenario;
      _telemetry = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final trackerService = Provider.of<FlightTrackerService>(context);
    final activeFlight = trackerService.activeFlight;
    final isDark = authService.currentUser.nightMode;
    final screenWidth = MediaQuery.of(context).size.width;

    // Reactively update GNSS telemetry when the active route changes
    if (_lastTrackedFlightId != activeFlight.id) {
      _lastTrackedFlightId = activeFlight.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _evaluateScenario(_selectedScenario);
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 800 ? 28 : 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Banner
          _buildHeaderBanner(isDark),

          const SizedBox(height: 24),

          // 2. Scenario Simulator Controls
          _buildScenarioControls(isDark),

          const SizedBox(height: 24),

          // 3. EICAS Master Warning & Failover Annunciator
          _buildEicasAnnunciator(isDark),

          const SizedBox(height: 24),

          // 4. Live Sensor Metrics & Spatial Divergence
          _buildSensorMetrics(isDark),

          const SizedBox(height: 24),

          // 5. Satellite Signal Table
          _buildSatelliteTable(isDark),

          const SizedBox(height: 36),

          // 6. "How It Works" Foundations of AI Notes
          _buildTheorySection(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.9)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.spaceNavy,
              border: Border.all(color: Colors.orangeAccent, width: 1.5),
            ),
            child: const Icon(
              Icons.satellite_alt_rounded,
              color: Colors.orangeAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛰️ GNSS ANOMALY & SPOOFING DETECTOR',
                  style: AppTypography.hudMetric.copyWith(
                    color: Colors.orangeAccent,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Signal Integrity Monitoring (RAIM) • GPS Jamming & Spoofing Defense • INS Dead-Reckoning Failover',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioControls(bool isDark) {
    return Consumer<FlightTrackerService>(
      builder: (context, tracker, _) {
        final active = tracker.activeFlight;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.85) : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global Multi-Tab Route Synchronization Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt, color: AppColors.skyBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ACTIVE CORRIDOR SYNC: Monitoring GNSS telemetry for ${active.flightNumber} (${active.origin.city} [${active.origin.iata}] ➔ ${active.destination.city} [${active.destination.iata}]) synchronized from AI Route Planner & Map.',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                'TEST REAL-TIME GNSS THREAT SCENARIOS:',
                style: AppTypography.hudLabel.copyWith(fontSize: 11, color: AppColors.skyBlue),
              ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildScenarioButton(
                GnssScenario.normalClean,
                '🟢 Normal Operation',
                'Healthy constellation & RAIM OK',
                Colors.greenAccent,
              ),
              _buildScenarioButton(
                GnssScenario.electronicJamming,
                '🔴 GPS RF Jamming',
                'Signal attenuation < 25 dB-Hz',
                Colors.redAccent,
              ),
              _buildScenarioButton(
                GnssScenario.gpsSpoofingAttack,
                '⚠️ GPS Spoofing Attack',
                'False position & clock drift anomaly',
                Colors.orangeAccent,
              ),
              _buildScenarioButton(
                GnssScenario.spaceWeatherScintillation,
                '🟡 Ionospheric Scintillation',
                'Space weather signal degradation',
                Colors.amberAccent,
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildScenarioButton(
    GnssScenario scenario,
    String title,
    String subtitle,
    Color accentColor,
  ) {
    final isSelected = _selectedScenario == scenario;
    return GestureDetector(
      onTap: () => _evaluateScenario(scenario),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : AppColors.spaceNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEicasAnnunciator(bool isDark) {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (_telemetry.raimStatus) {
      case RaimStatus.integrityOk:
        statusColor = Colors.greenAccent;
        statusTitle = 'RAIM INTEGRITY: NORMAL (GNSS-1/2 PRIMARY)';
        statusIcon = Icons.check_circle_outline;
        break;
      case RaimStatus.degradedAccuracy:
        statusColor = Colors.amberAccent;
        statusTitle = 'CAUTION: GNSS ACCURACY DEGRADED';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case RaimStatus.jammingDetected:
        statusColor = Colors.redAccent;
        statusTitle = 'WARNING: GPS RF JAMMING DETECTED';
        statusIcon = Icons.portable_wifi_off;
        break;
      case RaimStatus.spoofingAlert:
        statusColor = Colors.orangeAccent;
        statusTitle = 'CRITICAL EICAS: GPS SPOOFING ATTACK DETECTED!';
        statusIcon = Icons.security_update_warning_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _telemetry.isFailoverActive
                      ? Colors.redAccent.withValues(alpha: 0.25)
                      : Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _telemetry.isFailoverActive ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                child: Text(
                  _telemetry.isFailoverActive ? 'FAILOVER ENGAGED' : 'SYSTEM HEALTHY',
                  style: TextStyle(
                    color: _telemetry.isFailoverActive ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _telemetry.alertMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
          if (_telemetry.isFailoverActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cockpitDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_calls_rounded, color: AppColors.electricAmber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Active Primary Nav: TRIPLE-INS INERTIAL REFERENCE + VOR/DME DEAD-RECKONING',
                    style: const TextStyle(
                      color: AppColors.electricAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorMetrics(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.85) : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVIONICS GNSS INTEGRITY TELEMETRY:',
            style: AppTypography.hudLabel.copyWith(fontSize: 11, color: AppColors.skyBlue),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              _buildMetricTile(
                'AVG CARRIER/NOISE (C/N0)',
                '${_telemetry.averageCn0DbHz.toStringAsFixed(1)} dB-Hz',
                Icons.network_check,
                _telemetry.averageCn0DbHz < 28.0 ? Colors.redAccent : Colors.cyanAccent,
                isDark,
              ),
              _buildMetricTile(
                'PSEUDORANGE RESIDUAL',
                '${_telemetry.pseudorangeJumpMeters.toStringAsFixed(1)} m',
                Icons.straighten,
                _telemetry.pseudorangeJumpMeters > 50.0 ? Colors.redAccent : AppColors.electricAmber,
                isDark,
              ),
              _buildMetricTile(
                'CLOCK DRIFT RATE',
                '${_telemetry.clockDriftNsPerSec.toStringAsFixed(1)} ns/s',
                Icons.access_time,
                _telemetry.clockDriftNsPerSec > 25.0 ? Colors.orangeAccent : Colors.purpleAccent,
                isDark,
              ),
              _buildMetricTile(
                'DILUTION OF PRECISION (HDOP)',
                _telemetry.hdop.toStringAsFixed(1),
                Icons.filter_center_focus,
                _telemetry.hdop > 3.0 ? Colors.amberAccent : Colors.greenAccent,
                isDark,
              ),
              _buildMetricTile(
                'SPOOFING DISCREPANCY',
                '${_telemetry.spoofingOffsetKm.toStringAsFixed(1)} km',
                Icons.navigation_outlined,
                _telemetry.spoofingOffsetKm > 5.0 ? Colors.redAccent : Colors.greenAccent,
                isDark,
              ),
              _buildMetricTile(
                'SATELLITES LOCKED',
                '${_telemetry.satellitesLocked} of ${_telemetry.satellitesInView}',
                Icons.radar,
                _telemetry.satellitesLocked == 0 ? Colors.redAccent : Colors.cyanAccent,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String val, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              Text(
                val,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteTable(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.85) : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRACKED CONSTELLATION SATELLITE SIGNALS:',
            style: AppTypography.hudLabel.copyWith(fontSize: 11, color: AppColors.skyBlue),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _telemetry.satellites.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final sat = _telemetry.satellites[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Text(
                      'PRN ${sat.prn.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(sat.constellation, style: const TextStyle(color: AppColors.skyBlue, fontSize: 10)),
                    ),
                    const Spacer(),
                    Text('Elev: ${sat.elevationDeg.toInt()}°', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(width: 12),
                    Text('Azim: ${sat.azimuthDeg.toInt()}°', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (sat.carrierToNoiseDbHz / 60.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  sat.carrierToNoiseDbHz < 28.0 ? Colors.redAccent : Colors.cyanAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${sat.carrierToNoiseDbHz.toInt()} dB',
                            style: TextStyle(
                              color: sat.carrierToNoiseDbHz < 28.0 ? Colors.redAccent : Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTheorySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.85) : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.orangeAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                'HOW GNSS ANOMALY DETECTION WORKS (FOUNDATIONS OF AI)',
                style: AppTypography.hudMetric.copyWith(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTheoryCard(
            '📡 1. Carrier-to-Noise Ratio (C/N0) & Jamming Detection',
            'Broadband RF jamming swamps weak satellite signals arriving from orbit (-160 dBW). '
                'When C/N0 falls below the operational tracking threshold (28 dB-Hz across multiple channels), '
                'the AI classifies the event as intentional Jamming rather than multipath noise.',
            isDark,
          ),
          const SizedBox(height: 10),
          _buildTheoryCard(
            '🕵️ 2. Spoofing Attack Detection (Pseudorange Residuals & Clock Jumps)',
            'Ground-based GPS spoofers generate fake constellation signals to hijack aircraft position. '
                'However, spoofers lack atomic synchronization, creating clock bias acceleration (>45 ns/s). '
                'Additionally, the aircraft\'s Inertial Reference System (INS) cross-checks velocity vectors: '
                'if GPS shows position jumps inconsistent with physical acceleration, the spoofed signal is rejected.',
            isDark,
          ),
          const SizedBox(height: 10),
          _buildTheoryCard(
            '🔄 3. Autonomous Failover to Inertial Dead Reckoning',
            'When RAIM detects loss of integrity or spoofing, the flight guidance system seamlessly decouples '
                'from GNSS and engages triple-IRS (laser ring gyroscopes) and VOR/DME radio multi-lateration, '
                'guaranteeing zero navigation disruption for the cockpit crew.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTheoryCard(String title, String body, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.lightText,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
