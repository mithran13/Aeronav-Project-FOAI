import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../algorithms/eco_route_ai.dart';
import '../../models/airport_node.dart';
import '../../models/eco_route_result.dart';
import '../../services/ai_graph_service.dart';
import '../../services/auth_service.dart';
import '../../services/flight_tracker_service.dart';
import '../../services/global_airport_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/hover_animated_widgets.dart';

class EcoRouteAiView extends StatefulWidget {
  const EcoRouteAiView({super.key});

  @override
  State<EcoRouteAiView> createState() => _EcoRouteAiViewState();
}

class _EcoRouteAiViewState extends State<EcoRouteAiView> {
  late Map<String, AirportNode> _graph;
  late List<AirportNode> _airportList;

  String _selectedFromIata = 'MAA'; // Chennai
  String _selectedToIata = 'LHR'; // London
  String _selectedAircraft = 'Boeing 787-9 Dreamliner';

  EcoRouteResult? _result;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _graph = AiGraphService.getFlightGraph();
    _airportList = _graph.values.toList()
      ..sort((a, b) => a.city.compareTo(b.city));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tracker = Provider.of<FlightTrackerService>(context, listen: false);
        _selectedFromIata = tracker.selectedOriginIata;
        _selectedToIata = tracker.selectedDestinationIata;
        _calculateEcoRoute();
      }
    });
  }

  void _onFromChanged(String? val) {
    if (val != null && val != _selectedFromIata) {
      setState(() => _selectedFromIata = val);
      final tracker = Provider.of<FlightTrackerService>(context, listen: false);
      tracker.setGlobalPlannedRoute(
        fromIata: _selectedFromIata,
        toIata: _selectedToIata,
      );
      _calculateEcoRoute();
    }
  }

  void _onToChanged(String? val) {
    if (val != null && val != _selectedToIata) {
      setState(() => _selectedToIata = val);
      final tracker = Provider.of<FlightTrackerService>(context, listen: false);
      tracker.setGlobalPlannedRoute(
        fromIata: _selectedFromIata,
        toIata: _selectedToIata,
      );
      _calculateEcoRoute();
    }
  }

  void _calculateEcoRoute() {
    setState(() => _isCalculating = true);

    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;

      var origin = _graph[_selectedFromIata];
      var destination = _graph[_selectedToIata];

      if (origin == null || destination == null) {
        final oInfo = GlobalAirportService.findByIata(_selectedFromIata);
        final dInfo = GlobalAirportService.findByIata(_selectedToIata);
        origin ??= AirportNode(
          iata: oInfo.iata,
          icao: oInfo.icao,
          name: oInfo.name,
          city: oInfo.city,
          country: oInfo.country,
          latitude: oInfo.latitude,
          longitude: oInfo.longitude,
        );
        destination ??= AirportNode(
          iata: dInfo.iata,
          icao: dInfo.icao,
          name: dInfo.name,
          city: dInfo.city,
          country: dInfo.country,
          latitude: dInfo.latitude,
          longitude: dInfo.longitude,
        );
      }

      final res = EcoRouteAi.calculateEcoTrajectory(
        origin: origin,
        destination: destination,
        aircraftModel: _selectedAircraft,
      );

      setState(() {
        _result = res;
        _isCalculating = false;
      });
    });
  }

  void _swapAirports() {
    setState(() {
      final temp = _selectedFromIata;
      _selectedFromIata = _selectedToIata;
      _selectedToIata = temp;
    });
    final tracker = Provider.of<FlightTrackerService>(context, listen: false);
    tracker.setGlobalPlannedRoute(
      fromIata: _selectedFromIata,
      toIata: _selectedToIata,
    );
    _calculateEcoRoute();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final trackerService = Provider.of<FlightTrackerService>(context);
    final isDark = authService.currentUser.nightMode;
    final screenWidth = MediaQuery.of(context).size.width;

    // Reactively synchronize with active corridor if updated elsewhere
    if (trackerService.selectedOriginIata != _selectedFromIata ||
        trackerService.selectedDestinationIata != _selectedToIata) {
      _selectedFromIata = trackerService.selectedOriginIata;
      _selectedToIata = trackerService.selectedDestinationIata;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _calculateEcoRoute();
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

          // 2. Aircraft & Route Controls
          _buildControlForm(isDark),

          const SizedBox(height: 28),

          // 3. Results Section
          if (_isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            )
          else if (_result != null)
            _buildResultsSection(_result!, isDark),

          const SizedBox(height: 36),

          // 4. "How It Works" Foundations of AI Section
          _buildTheorySection(isDark),
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
          color: Colors.greenAccent.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.15),
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
              border: Border.all(color: Colors.greenAccent, width: 1.5),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.greenAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌿 ECO-ROUTE AI: GREEN FLIGHT OPTIMIZER',
                  style: AppTypography.hudMetric.copyWith(
                    color: Colors.greenAccent,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fuel Burn Minimization • Step-Climb Scheduling • Jet Stream Wind Vectoring',
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

  // --- Controls ---
  Widget _buildControlForm(bool isDark) {
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
          // Global Multi-Tab Route Synchronization Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ACTIVE CORRIDOR SYNC: Tracking $_selectedFromIata ➔ $_selectedToIata (Synchronized with AI Route Planner, World Map & Delay Risk).',
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
            'SELECT FLIGHT PAIR & AIRCRAFT MODEL:',
            style: AppTypography.hudLabel.copyWith(
              fontSize: 11,
              color: AppColors.skyBlue,
            ),
          ),
          const SizedBox(height: 16),

          // Airport Selectors
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      children: [
                        _buildAirportDropdown(
                          'FROM AIRPORT',
                          _selectedFromIata,
                          _onFromChanged,
                          isDark,
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.swap_vert, color: Colors.greenAccent),
                          onPressed: _swapAirports,
                        ),
                        const SizedBox(height: 10),
                        _buildAirportDropdown(
                          'TO AIRPORT',
                          _selectedToIata,
                          _onToChanged,
                          isDark,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildAirportDropdown(
                            'FROM AIRPORT',
                            _selectedFromIata,
                            _onFromChanged,
                            isDark,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz, color: Colors.greenAccent),
                            onPressed: _swapAirports,
                          ),
                        ),
                        Expanded(
                          child: _buildAirportDropdown(
                            'TO AIRPORT',
                            _selectedToIata,
                            _onToChanged,
                            isDark,
                          ),
                        ),
                      ],
                    );
            },
          ),

          const SizedBox(height: 18),

          // Aircraft Model Selector
          Text(
            'Aircraft Type & Aerodynamic Profile:',
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
            children: EcoRouteAi.aircraftProfiles.keys.map((model) {
              final isSelected = model == _selectedAircraft;
              return ChoiceChip(
                label: Text(model),
                selected: isSelected,
                selectedColor: Colors.greenAccent,
                backgroundColor: AppColors.spaceNavy,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.greenAccent : AppColors.borderSubtle,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedAircraft = model);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          HoverAnimatedButton(
            onPressed: _calculateEcoRoute,
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.energy_savings_leaf, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'OPTIMIZE GREEN ECO-TRAJECTORY',
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

  Widget _buildAirportDropdown(String label, String selectedIata,
      ValueChanged<String?> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.hudLabel.copyWith(fontSize: 10)),
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
              value: selectedIata,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.cockpitDark : AppColors.lightCard,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
              onChanged: onChanged,
              items: _airportList.map((airport) {
                return DropdownMenuItem<String>(
                  value: airport.iata,
                  child: Text(
                    '${airport.iata} — ${airport.city} (${airport.country})',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightText,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // --- Results Section ---
  Widget _buildResultsSection(EcoRouteResult res, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score & Summary Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cockpitDark.withValues(alpha: 0.9)
                : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Text(
                          'GRADE ${res.greenRating}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Green Score: ${res.greenScore.toStringAsFixed(1)} / 100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${res.fuelSavingsPercent.toStringAsFixed(1)}% Fuel Saved',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                res.summary,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // KPI Metrics Row
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildMetricCard(
                    'JET-A FUEL SAVED',
                    '${res.fuelSavedKg.toStringAsFixed(0)} kg (${res.fuelSavedGal.toStringAsFixed(0)} gal)',
                    Icons.local_gas_station,
                    Colors.greenAccent,
                    isDark,
                  ),
                  _buildMetricCard(
                    'CO₂ REDUCTION',
                    '-${res.co2SavedMetricTons.toStringAsFixed(1)} metric tons',
                    Icons.cloud_off,
                    Colors.cyanAccent,
                    isDark,
                  ),
                  _buildMetricCard(
                    'NET OPERATING SAVINGS',
                    '\$${res.costSavingsUsd.toStringAsFixed(0)} USD',
                    Icons.attach_money,
                    AppColors.electricAmber,
                    isDark,
                  ),
                  _buildMetricCard(
                    'JET STREAM WIND EFFECT',
                 res.averageWindComponentKts >= 0 ? '+${res.averageWindComponentKts.toStringAsFixed(0)} kt (Tailwind)' : '${res.averageWindComponentKts.toStringAsFixed(0)} kt (Headwind)',
                    Icons.air,
                    Colors.purpleAccent,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Step-Climb Altitude Schedule
        Text(
          'OPTIMAL VERTICAL STEP-CLIMB FLIGHT PROFILE:',
          style: AppTypography.hudLabel.copyWith(fontSize: 11, color: AppColors.skyBlue),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: res.stepClimbs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final step = res.stepClimbs[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Text(
                      'FL${step.flightLevel}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${step.waypoint} • ${(step.flightLevel * 100).toStringAsFixed(0)} ft (${(step.flightLevel * 30.48).toStringAsFixed(0)} m)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          step.rationale,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
    );
  }

  Widget _buildMetricCard(
      String title, String val, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              Text(
                val,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Theory Notes ---
  Widget _buildTheorySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.85)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.greenAccent, size: 22),
              const SizedBox(width: 10),
              Text(
                'HOW ECO-ROUTE AI WORKS (FOUNDATIONS OF AI)',
                style: AppTypography.hudMetric.copyWith(
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTheoryCard(
            '💨 1. Jet Stream & Upper-Level Wind Vector Optimization',
            'Wind vectors at 30,000-40,000 ft (FL300-FL400) can exceed 150 kts. Eco-Route AI uses vector calculus '
                'to ride tailwind cores eastbound and deviate laterally around core headwinds westbound, '
                'maximizing ground speed while operating at lower thrust.',
            isDark,
          ),
          const SizedBox(height: 10),
          _buildTheoryCard(
            '📈 2. Dynamic Step-Climb Altitude Scheduling',
            'Aircraft cannot cruise at high altitudes initially when heavy with fuel. As fuel burns off (saving ~40% gross weight), '
                'the optimal aerodynamic altitude rises. Eco-Route AI calculates step-climb waypoints (e.g. FL330 -> FL370 -> FL410) '
                'to keep the aircraft continuously in the lowest drag/burn envelope.',
            isDark,
          ),
          const SizedBox(height: 10),
          _buildTheoryCard(
            '⚖️ 3. Cost Index (CI) & Speed Optimization',
            'Cost Index balances fuel costs against flight crew/operational time costs: CI = Time Cost / Fuel Cost. '
                'Eco-Route AI computes the lowest total trip cost Mach number (e.g., M0.82 vs M0.85), saving thousands of dollars per long-haul flight.',
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
              color: Colors.greenAccent,
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
