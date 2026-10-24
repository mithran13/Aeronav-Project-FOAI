import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../algorithms/bayesian_network.dart';
import '../../models/delay_risk_result.dart';
import '../../models/flight_item.dart';
import '../../services/auth_service.dart';
import '../../services/flight_tracker_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/hover_animated_widgets.dart';

class AiDelayAnalyzerView extends StatefulWidget {
  const AiDelayAnalyzerView({super.key});

  @override
  State<AiDelayAnalyzerView> createState() => _AiDelayAnalyzerViewState();
}

class _AiDelayAnalyzerViewState extends State<AiDelayAnalyzerView> {
  String _selectedFlightId = 'FLIGHT-UA101';

  String _selectedWeather = BayesianFlightDelayNetwork.weatherOptions[0];
  String _selectedTraffic = BayesianFlightDelayNetwork.trafficOptions[0];
  String _selectedMaintenance = BayesianFlightDelayNetwork.maintenanceOptions[0];
  String _selectedInbound = BayesianFlightDelayNetwork.inboundOptions[0];

  DelayRiskResult? _result;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculateRisk();
  }

  void _calculateRisk() {
    setState(() => _isCalculating = true);

    Future.delayed(const Duration(milliseconds: 120), () {
      final res = BayesianFlightDelayNetwork.calculateDelayRisk(
        weather: _selectedWeather,
        traffic: _selectedTraffic,
        maintenance: _selectedMaintenance,
        inbound: _selectedInbound,
      );

      setState(() {
        _result = res;
        _isCalculating = false;
      });
    });
  }

  void _onFlightSelected(PassengerFlightItem flight, {bool syncGlobal = true}) {
    setState(() {
      _selectedFlightId = flight.id;

      // Auto-set initial evidence from flight properties
      if (flight.isDelayed) {
        _selectedInbound = BayesianFlightDelayNetwork.inboundOptions[1]; // Minor delay
        _selectedTraffic = BayesianFlightDelayNetwork.trafficOptions[1]; // Moderate congestion
      } else {
        _selectedInbound = BayesianFlightDelayNetwork.inboundOptions[0];
        _selectedTraffic = BayesianFlightDelayNetwork.trafficOptions[0];
      }

      final cond = flight.destination.weatherCondition?.toLowerCase() ?? '';
      if (cond.contains('rain') || cond.contains('storm')) {
        _selectedWeather = BayesianFlightDelayNetwork.weatherOptions[3];
      } else {
        _selectedWeather = BayesianFlightDelayNetwork.weatherOptions[0];
      }
    });

    if (syncGlobal) {
      final tracker = Provider.of<FlightTrackerService>(context, listen: false);
      tracker.selectFlight(flight);
    }

    _calculateRisk();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final trackerService = Provider.of<FlightTrackerService>(context);
    final isDark = authService.currentUser.nightMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final allFlights = trackerService.allFlights;

    // Reactively synchronize active flight with global route tracker
    final globalActiveFlight = trackerService.activeFlight;
    if (_selectedFlightId != globalActiveFlight.id) {
      _selectedFlightId = globalActiveFlight.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onFlightSelected(globalActiveFlight, syncGlobal: false);
      });
    }

    final selectedFlight = allFlights.firstWhere(
      (f) => f.id == _selectedFlightId,
      orElse: () => allFlights.isNotEmpty ? allFlights.first : trackerService.activeFlight,
    );

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

          // 2. Flight & Evidence Form Controls
          _buildEvidenceControlForm(allFlights, isDark),

          const SizedBox(height: 28),

          // 3. Results Diagnostics Section
          if (_isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.electricAmber),
              ),
            )
          else if (_result != null)
            _buildResultsSection(_result!, selectedFlight, isDark),

          const SizedBox(height: 36),

          // 4. "How It Works" Foundations of AI Section
          _buildVivaExplanationSection(isDark),
        ],
      ),
    );
  }

  // --- Header Banner ---
  Widget _buildHeaderBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.9)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.electricAmber.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricAmber.withValues(alpha: 0.15),
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
              border: Border.all(color: AppColors.electricAmber, width: 1.5),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: AppColors.electricAmber,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 FLIGHT DELAY RISK ANALYZER',
                  style: AppTypography.hudMetric.copyWith(
                    color: AppColors.electricAmber,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foundations of Artificial Intelligence • Bayesian Probabilistic Network (DAG)',
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

  // --- Evidence Form Controls ---
  Widget _buildEvidenceControlForm(
      List<PassengerFlightItem> allFlights, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.85)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIGURE FLIGHT EVIDENCE & ENVIRONMENTAL CONDITIONS:',
            style: AppTypography.hudLabel.copyWith(
              fontSize: 11,
              color: AppColors.skyBlue,
            ),
          ),
          const SizedBox(height: 14),

          // Active Corridor Synchronization Banner
          Consumer<FlightTrackerService>(
            builder: (context, tracker, _) {
              final active = tracker.activeFlight;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.electricAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.electricAmber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt, color: AppColors.electricAmber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ACTIVE CORRIDOR SYNC: Analyzing flight ${active.flightNumber} (${active.origin.city} [${active.origin.iata}] ➔ ${active.destination.city} [${active.destination.iata}]) synchronized from AI Route Planner & Map.',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.lightText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Active Flight Quick Pick Chips
          Text(
            'Select Active Flight to Analyze:',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allFlights.map((flight) {
              final isSelected = flight.id == _selectedFlightId;
              return ChoiceChip(
                label: Text('${flight.flightNumber} (${flight.origin.iata} ➔ ${flight.destination.iata})'),
                selected: isSelected,
                selectedColor: AppColors.electricAmber,
                backgroundColor: AppColors.spaceNavy,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.electricAmber : AppColors.borderSubtle,
                ),
                onSelected: (selected) {
                  if (selected) _onFlightSelected(flight);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Evidence Variable Dropdowns Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildEvidenceDropdown(
                                '🌤️ Weather Forecast (W)',
                                _selectedWeather,
                                BayesianFlightDelayNetwork.weatherOptions,
                                (val) => setState(() => _selectedWeather = val!),
                                isDark,
                              ),
                              const SizedBox(height: 14),
                              _buildEvidenceDropdown(
                                '✈️ Air Traffic Congestion (T)',
                                _selectedTraffic,
                                BayesianFlightDelayNetwork.trafficOptions,
                                (val) => setState(() => _selectedTraffic = val!),
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildEvidenceDropdown(
                                '🔧 Aircraft Maintenance Status (M)',
                                _selectedMaintenance,
                                BayesianFlightDelayNetwork.maintenanceOptions,
                                (val) => setState(() => _selectedMaintenance = val!),
                                isDark,
                              ),
                              const SizedBox(height: 14),
                              _buildEvidenceDropdown(
                                '🔄 Inbound Turnaround Delay (I)',
                                _selectedInbound,
                                BayesianFlightDelayNetwork.inboundOptions,
                                (val) => setState(() => _selectedInbound = val!),
                                isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildEvidenceDropdown(
                          '🌤️ Weather Forecast (W)',
                          _selectedWeather,
                          BayesianFlightDelayNetwork.weatherOptions,
                          (val) => setState(() => _selectedWeather = val!),
                          isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildEvidenceDropdown(
                          '✈️ Air Traffic Congestion (T)',
                          _selectedTraffic,
                          BayesianFlightDelayNetwork.trafficOptions,
                          (val) => setState(() => _selectedTraffic = val!),
                          isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildEvidenceDropdown(
                          '🔧 Aircraft Maintenance Status (M)',
                          _selectedMaintenance,
                          BayesianFlightDelayNetwork.maintenanceOptions,
                          (val) => setState(() => _selectedMaintenance = val!),
                          isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildEvidenceDropdown(
                          '🔄 Inbound Turnaround Delay (I)',
                          _selectedInbound,
                          BayesianFlightDelayNetwork.inboundOptions,
                          (val) => setState(() => _selectedInbound = val!),
                          isDark,
                        ),
                      ],
                    );
            },
          ),

          const SizedBox(height: 22),

          // Calculate Action Button
          HoverAnimatedButton(
            onPressed: _calculateRisk,
            color: AppColors.electricAmber,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CALCULATE DELAY RISK (BAYESIAN INFERENCE)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceDropdown(String label, String value, List<String> options,
      ValueChanged<String?> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.cockpitDark : AppColors.lightCard,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.electricAmber),
              onChanged: onChanged,
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightText,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // --- Results & Diagnostic Output ---
  Widget _buildResultsSection(DelayRiskResult res, PassengerFlightItem flight, bool isDark) {
    Color riskColor;
    switch (res.riskLevel) {
      case DelayRiskLevel.low:
        riskColor = Colors.greenAccent;
        break;
      case DelayRiskLevel.moderate:
        riskColor = Colors.amberAccent;
        break;
      case DelayRiskLevel.high:
        riskColor = Colors.orangeAccent;
        break;
      case DelayRiskLevel.critical:
        riskColor = Colors.redAccent;
        break;
    }

    Color timingColor;
    IconData timingIcon;
    if (res.isEarly) {
      timingColor = const Color(0xFF00E676); // Vibrant emerald green
      timingIcon = Icons.flight_land_rounded;
    } else if (res.isOnTime) {
      timingColor = AppColors.skyBlue;
      timingIcon = Icons.check_circle_outline_rounded;
    } else {
      timingColor = res.predictedStatus == PredictedArrivalStatus.severeDelay
          ? Colors.redAccent
          : Colors.orangeAccent;
      timingIcon = Icons.alarm_rounded;
    }

    final scheduledArrival = flight.destination.time;
    final projectedArrival = res.calculateAdjustedArrival(scheduledArrival);
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.92)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timingColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: timingColor.withValues(alpha: 0.18),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP SPOTLIGHT: Predicted Schedule Offset Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  timingColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  timingColor.withValues(alpha: isDark ? 0.05 : 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: timingColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(timingIcon, color: timingColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'PREDICTED SCHEDULE IMPACT',
                          style: AppTypography.hudLabel.copyWith(
                            fontSize: 11,
                            color: timingColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: timingColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: timingColor),
                      ),
                      child: Text(
                        res.statusBadgeText,
                        style: TextStyle(
                          color: timingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Big Time Offset Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      res.isEarly
                          ? '-${res.predictedMinutesOffset.abs()} MINS'
                          : (res.isOnTime
                              ? 'ON TIME'
                              : (res.predictedMinutesOffset >= 60
                                  ? '+${res.predictedMinutesOffset ~/ 60}h ${res.predictedMinutesOffset % 60}m'
                                  : '+${res.predictedMinutesOffset} MINS')),
                      style: TextStyle(
                        color: timingColor,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.isEarly
                                ? 'TOUCHDOWN AHEAD OF SCHEDULE'
                                : (res.isOnTime
                                    ? 'TOUCHDOWN EXACTLY ON TIMETABLE'
                                    : 'ESTIMATED FLIGHT DELAY DURATION'),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.lightText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estimated Window: ${res.offsetRange}',
                            style: TextStyle(
                              color: timingColor.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text(
                  res.arrivalStatusDescription,
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.lightText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Scheduled ETA vs. Projected Touchdown Comparison Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.spaceNavy.withValues(alpha: 0.8) : AppColors.lightBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                // Scheduled Gate Arrival
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCHEDULED ARRIVAL',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: isDark ? Colors.white60 : Colors.black54),
                          const SizedBox(width: 5),
                          Text(
                            '${timeFormat.format(scheduledArrival)} Local',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.lightText,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${flight.destination.iata} (${flight.destination.city})',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Transition Badge / Arrow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: timingColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: timingColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        res.formattedOffset.toUpperCase(),
                        style: TextStyle(
                          color: timingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: timingColor, size: 14),
                    ],
                  ),
                ),

                // Projected Adjusted Touchdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PROJECTED TOUCHDOWN',
                        style: TextStyle(
                          color: timingColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.flight_land, size: 16, color: timingColor),
                          const SizedBox(width: 5),
                          Text(
                            '${timeFormat.format(projectedArrival)} Local',
                            style: TextStyle(
                              color: timingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        res.isEarly
                            ? '(${res.predictedMinutesOffset.abs()}m Ahead of Schedule)'
                            : (res.isOnTime
                                ? '(Exact Target Window)'
                                : '(+${res.predictedMinutesOffset}m Late Arrival)'),
                        style: TextStyle(
                          color: timingColor.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Meteorological Schedule Impact Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.spaceNavy.withValues(alpha: 0.6) : AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.electricAmber.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.wb_sunny_outlined, color: AppColors.electricAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'METEOROLOGICAL SCHEDULE FACTOR (${res.weatherCondition}):',
                        style: const TextStyle(
                          color: AppColors.electricAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        res.weatherImpactNote,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.lightText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),

          // 4. Bayesian Posterior Probability Distribution
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POSTERIOR DELAY RISK SCORE (BAYESIAN INFERENCE)',
                style: AppTypography.hudLabel.copyWith(
                  fontSize: 11,
                  color: AppColors.skyBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor),
                ),
                child: Text(
                  res.riskLevelName.toUpperCase(),
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Percentage Score Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${res.overallRiskScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: riskColor,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Calculated Probability of Operational Delay P(Delay | Weather, Traffic, Tech, Inbound)',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Posterior Distribution Progress Bars
          Text(
            'POSTERIOR PROBABILITY DISTRIBUTION P(D | E):',
            style: AppTypography.hudLabel.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 10),

          _buildProbBar(
              'No Delay / Early Touchdown (<15m)', res.noDelayProb, Colors.greenAccent, isDark),
          const SizedBox(height: 8),
          _buildProbBar('Moderate Delay (15-60m)', res.moderateDelayProb,
              Colors.amberAccent, isDark),
          const SizedBox(height: 8),
          _buildProbBar('Severe Delay (>60m)', res.severeDelayProb,
              Colors.redAccent, isDark),

          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 14),

          // Diagnostic Drivers & Recommendation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.electricAmber, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Schedule Risk Driver:',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.primaryRiskDriver,
                      style: const TextStyle(
                        color: AppColors.electricAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Recommended Operational Action:',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.recommendation,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondary : AppColors.lightText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbBar(
      String label, double prob, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontSize: 12)),
            Text('${(prob * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: prob,
            minHeight: 8,
            backgroundColor: isDark ? AppColors.spaceNavy : AppColors.lightBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // --- "How It Works" Section (Foundations of AI Viva Notes) ---
  Widget _buildVivaExplanationSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.85)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.electricAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: AppColors.electricAmber, size: 22),
              const SizedBox(width: 10),
              Text(
                'HOW IT WORKS — BAYESIAN NETWORKS (FOUNDATIONS OF AI)',
                style: AppTypography.hudMetric.copyWith(
                  color: AppColors.electricAmber,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTheoryCard(
            '🌐 1. Directed Acyclic Graph (DAG) Topology',
            'A Bayesian Network is a Probabilistic Graphical Model representing random variables as nodes '
                'and conditional dependencies as directed edges. Here, Weather (W), Traffic (T), Maintenance (M), and Inbound (I) '
                'act as parent evidence nodes pointing directly to the Delay Risk target node (D).',
            isDark,
          ),
          const SizedBox(height: 10),

          _buildTheoryCard(
            '📊 2. Conditional Probability Tables (CPTs)',
            'Each variable node stores a Conditional Probability Table quantifying the likelihood of outcomes '
                'given all combinations of parent states: P(Delay | Weather, Traffic, Maintenance, Inbound).',
            isDark,
          ),
          const SizedBox(height: 10),

          _buildTheoryCard(
            '🧮 3. Exact Bayesian Inference & Noisy-OR Factorization',
            'Using Bayes\' Theorem and Noisy-OR probability integration, the network computes the exact posterior probability distribution '
                'P(D = k | E) = P(D = k, E) / P(E). This updates beliefs dynamically as new weather or operational evidence is provided.',
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
              color: AppColors.skyBlue,
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
