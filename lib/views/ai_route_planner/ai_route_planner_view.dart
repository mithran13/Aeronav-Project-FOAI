import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../algorithms/a_star.dart';
import '../../algorithms/dls.dart';
import '../../algorithms/uniform_cost_search.dart';
import '../../algorithms/weather_aware_routing.dart';
import '../../models/airport_node.dart';
import '../../models/route_result.dart';
import '../../services/ai_graph_service.dart';
import '../../services/auth_service.dart';
import '../../services/flight_tracker_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/hover_animated_widgets.dart';

enum AiAlgorithmMode { dls, ucs, aStar, compareAll }

class AiRoutePlannerView extends StatefulWidget {
  final Function(RouteResult route) onViewOnMap;

  const AiRoutePlannerView({super.key, required this.onViewOnMap});

  @override
  State<AiRoutePlannerView> createState() => _AiRoutePlannerViewState();
}

class _AiRoutePlannerViewState extends State<AiRoutePlannerView> {
  late Map<String, AirportNode> _graph;
  late List<AirportNode> _airportList;

  String _selectedFromIata = 'MAA'; // Default Chennai
  String _selectedToIata = 'JFK'; // Default New York

  AiAlgorithmMode _selectedAlgorithm = AiAlgorithmMode.aStar;
  int _dlsDepthLimit = 3;

  RouteResult? _singleResult;
  List<RouteResult>? _comparisonResults;
  WeatherAwareRouteResult? _weatherResult;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _graph = AiGraphService.getFlightGraph();
    _airportList = _graph.values.toList()
      ..sort((a, b) => a.city.compareTo(b.city));

    // Execute initial search on load with synchronized global state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tracker = Provider.of<FlightTrackerService>(context, listen: false);
        if (_graph.containsKey(tracker.selectedOriginIata)) {
          _selectedFromIata = tracker.selectedOriginIata;
        }
        if (_graph.containsKey(tracker.selectedDestinationIata)) {
          _selectedToIata = tracker.selectedDestinationIata;
        }
        _runRoutePlanner();
      }
    });
  }

  void _onOriginChanged(String? val) {
    if (val != null && val != _selectedFromIata) {
      setState(() => _selectedFromIata = val);
      final tracker = Provider.of<FlightTrackerService>(context, listen: false);
      tracker.setGlobalPlannedRoute(
        fromIata: _selectedFromIata,
        toIata: _selectedToIata,
      );
      _runRoutePlanner();
    }
  }

  void _onDestinationChanged(String? val) {
    if (val != null && val != _selectedToIata) {
      setState(() => _selectedToIata = val);
      final tracker = Provider.of<FlightTrackerService>(context, listen: false);
      tracker.setGlobalPlannedRoute(
        fromIata: _selectedFromIata,
        toIata: _selectedToIata,
      );
      _runRoutePlanner();
    }
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
    _runRoutePlanner();
  }

  void _runRoutePlanner() {
    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      if (_selectedAlgorithm == AiAlgorithmMode.compareAll) {
        final dlsRes = DepthLimitedSearch.findRoute(
          graph: _graph,
          startIata: _selectedFromIata,
          goalIata: _selectedToIata,
          depthLimit: _dlsDepthLimit,
        );

        final ucsRes = UniformCostSearch.findRoute(
          graph: _graph,
          startIata: _selectedFromIata,
          goalIata: _selectedToIata,
        );

        final aStarRes = AStarSearch.findRoute(
          graph: _graph,
          startIata: _selectedFromIata,
          goalIata: _selectedToIata,
        );

        final wxRes = WeatherAwareRouting.calculateRoute(baseRoute: aStarRes);

        setState(() {
          _comparisonResults = [dlsRes, ucsRes, aStarRes];
          _singleResult = aStarRes; // Default active map route
          _weatherResult = wxRes;
          _isSearching = false;
        });

        // Publish synchronized active route to global tracker service
        final tracker = Provider.of<FlightTrackerService>(context, listen: false);
        tracker.setGlobalPlannedRoute(
          fromIata: _selectedFromIata,
          toIata: _selectedToIata,
          aiRoute: aStarRes,
        );
      } else {
        RouteResult result;
        switch (_selectedAlgorithm) {
          case AiAlgorithmMode.dls:
            result = DepthLimitedSearch.findRoute(
              graph: _graph,
              startIata: _selectedFromIata,
              goalIata: _selectedToIata,
              depthLimit: _dlsDepthLimit,
            );
            break;
          case AiAlgorithmMode.ucs:
            result = UniformCostSearch.findRoute(
              graph: _graph,
              startIata: _selectedFromIata,
              goalIata: _selectedToIata,
            );
            break;
          case AiAlgorithmMode.aStar:
            result = AStarSearch.findRoute(
              graph: _graph,
              startIata: _selectedFromIata,
              goalIata: _selectedToIata,
            );
            break;
          default:
            result = AStarSearch.findRoute(
              graph: _graph,
              startIata: _selectedFromIata,
              goalIata: _selectedToIata,
            );
        }

        final wxRes = WeatherAwareRouting.calculateRoute(baseRoute: result);

        setState(() {
          _singleResult = result;
          _weatherResult = wxRes;
          _comparisonResults = null;
          _isSearching = false;
        });

        // Publish synchronized active route to global tracker service
        final tracker = Provider.of<FlightTrackerService>(context, listen: false);
        tracker.setGlobalPlannedRoute(
          fromIata: _selectedFromIata,
          toIata: _selectedToIata,
          aiRoute: result,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = authService.currentUser.nightMode;
    final screenWidth = MediaQuery.of(context).size.width;

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

          // 2. Control Panel Form (From, To, Algorithm Selector, DLS Limit)
          _buildPlannerControlPanel(isDark),

          const SizedBox(height: 28),

          // 3. Results Section
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.electricBlue),
              ),
            )
          else if (_selectedAlgorithm == AiAlgorithmMode.compareAll &&
              _comparisonResults != null)
            _buildComparisonResultsSection(isDark)
          else if (_singleResult != null)
            _buildSingleResultSection(_singleResult!, isDark),

          const SizedBox(height: 36),

          // 4. "How It Works" Foundations of AI Section
          _buildTheoryExplanationSection(isDark),
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
          color: AppColors.electricBlue.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withValues(alpha: 0.15),
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
              Icons.psychology_rounded,
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
                  '🧠 AI ROUTE PLANNER',
                  style: AppTypography.hudMetric.copyWith(
                    color: AppColors.electricBlue,
                    fontSize: 20,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foundations of Artificial Intelligence • Graph Search Algorithms (DLS, UCS, A*)',
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

  // --- Control Panel Form ---
  Widget _buildPlannerControlPanel(bool isDark) {
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
              color: AppColors.radarGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.radarGreen.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt, color: AppColors.radarGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ACTIVE CORRIDOR SYNC: Any route selected here is automatically tracked across World Map, Eco-Route AI, Delay Risk, and GNSS systems.',
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

          // Airport Selectors Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return isNarrow
                  ? Column(
                      children: [
                        _buildAirportDropdown(
                          'FROM AIRPORT',
                          _selectedFromIata,
                          _onOriginChanged,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          icon: const Icon(Icons.swap_vert,
                              color: AppColors.electricAmber),
                          onPressed: _swapAirports,
                        ),
                        const SizedBox(height: 12),
                        _buildAirportDropdown(
                          'TO AIRPORT',
                          _selectedToIata,
                          _onDestinationChanged,
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
                            _onOriginChanged,
                            isDark,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz,
                                color: AppColors.electricAmber),
                            onPressed: _swapAirports,
                          ),
                        ),
                        Expanded(
                          child: _buildAirportDropdown(
                            'TO AIRPORT',
                            _selectedToIata,
                            _onDestinationChanged,
                            isDark,
                          ),
                        ),
                      ],
                    );
            },
          ),

          const SizedBox(height: 20),

          // Algorithm Mode Selector
          Text(
            'SELECT AI SEARCH ALGORITHM:',
            style: AppTypography.hudLabel.copyWith(
              fontSize: 11,
              color: AppColors.skyBlue,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildAlgoChip(AiAlgorithmMode.dls, '1. Depth-Limited (DLS)'),
              _buildAlgoChip(AiAlgorithmMode.ucs, '2. Uniform Cost (UCS)'),
              _buildAlgoChip(AiAlgorithmMode.aStar, '3. A* Search (Heuristic)'),
              _buildAlgoChip(AiAlgorithmMode.compareAll, '⚡ Compare All Side-by-Side'),
            ],
          ),

          // Depth Limit Slider if DLS is active
          if (_selectedAlgorithm == AiAlgorithmMode.dls ||
              _selectedAlgorithm == AiAlgorithmMode.compareAll) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'DLS Max Depth Limit (L): ',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_dlsDepthLimit hops',
                  style: const TextStyle(
                    color: AppColors.electricAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _dlsDepthLimit.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              activeColor: AppColors.electricAmber,
              label: 'Limit: $_dlsDepthLimit',
              onChanged: (val) {
                setState(() => _dlsDepthLimit = val.toInt());
              },
            ),
          ],

          const SizedBox(height: 20),

          // Submit Action Button
          HoverAnimatedButton(
            onPressed: _runRoutePlanner,
            color: AppColors.electricBlue,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'FIND ROUTE WITH AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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
        Text(
          label,
          style: AppTypography.hudLabel.copyWith(fontSize: 10),
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
              value: selectedIata,
              isExpanded: true,
              dropdownColor:
                  isDark ? AppColors.cockpitDark : AppColors.lightCard,
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.electricBlue),
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

  Widget _buildAlgoChip(AiAlgorithmMode mode, String label) {
    final isSelected = _selectedAlgorithm == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.electricBlue,
      backgroundColor: AppColors.spaceNavy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.electricBlue : AppColors.borderSubtle,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedAlgorithm = mode);
        }
      },
    );
  }

  // --- Single Result Display Section ---
  Widget _buildSingleResultSection(RouteResult res, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result Summary Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cockpitDark.withValues(alpha: 0.9)
                : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: res.isSuccess
                  ? AppColors.electricBlue
                  : AppColors.electricAmber,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.electricBlue),
                    ),
                    child: Text(
                      res.algorithmName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: res.isSuccess
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      res.isSuccess ? '✓ ROUTE FOUND' : '✗ NO ROUTE',
                      style: TextStyle(
                        color: res.isSuccess ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                res.statusMessage,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Metrics Grid
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildMetricTile(
                    'TOTAL DISTANCE',
                    '${res.totalDistanceKm.toStringAsFixed(1)} km',
                    Icons.straighten,
                    AppColors.electricAmber,
                    isDark,
                  ),
                  _buildMetricTile(
                    'NODES EXPLORED',
                    '${res.nodesExplored} nodes',
                    Icons.account_tree,
                    AppColors.electricBlue,
                    isDark,
                  ),
                  _buildMetricTile(
                    'EXECUTION TIME',
                    '${res.executionTimeMs.toStringAsFixed(3)} ms',
                    Icons.timer,
                    AppColors.skyBlue,
                    isDark,
                  ),
                  _buildMetricTile(
                    'TOTAL HOPS',
                    '${res.totalHops} flight legs',
                    Icons.connecting_airports,
                    Colors.purpleAccent,
                    isDark,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (res.isSuccess)
                Align(
                  alignment: Alignment.centerRight,
                  child: HoverAnimatedButton(
                    onPressed: () => widget.onViewOnMap(res),
                    color: AppColors.electricAmber,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, color: Colors.black, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'VIEW ON MAP',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Route Hops Detail Cards
        if (res.isSuccess && res.legs.isNotEmpty) ...[
          Text(
            'FLIGHT ROUTE PATH LEGS:',
            style: AppTypography.hudLabel.copyWith(
              fontSize: 11,
              color: AppColors.skyBlue,
            ),
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: res.legs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final leg = res.legs[index];
              final fromNode = res.path[index];
              final toNode = res.path[index + 1];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.electricBlue,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${fromNode.iata} (${fromNode.city})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward,
                                    size: 14, color: AppColors.electricAmber),
                              ),
                              Text(
                                '${toNode.iata} (${toNode.city})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Flight: ${leg.flightNumber} (${leg.airline}) • Distance: ${leg.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
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

        const SizedBox(height: 20),

        if (_weatherResult != null)
          _buildWeatherAwareCard(_weatherResult!, isDark),
      ],
    );
  }

  // --- Side-by-Side Comparison Results Section ---
  Widget _buildComparisonResultsSection(bool isDark) {
    final dls = _comparisonResults![0];
    final ucs = _comparisonResults![1];
    final aStar = _comparisonResults![2];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ SIDE-BY-SIDE ALGORITHM COMPARISON',
          style: AppTypography.hudMetric.copyWith(
            color: AppColors.electricAmber,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildComparisonCard(dls, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildComparisonCard(ucs, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildComparisonCard(aStar, isDark)),
                    ],
                  )
                : Column(
                    children: [
                      _buildComparisonCard(dls, isDark),
                      const SizedBox(height: 12),
                      _buildComparisonCard(ucs, isDark),
                      const SizedBox(height: 12),
                      _buildComparisonCard(aStar, isDark),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildComparisonCard(RouteResult res, bool isDark) {
    final bool isBest = res.algorithmName.contains('A*');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.9)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBest ? AppColors.electricAmber : AppColors.borderSubtle,
          width: isBest ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  res.algorithmName,
                  style: TextStyle(
                    color: isBest ? AppColors.electricAmber : AppColors.electricBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isBest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.electricAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OPTIMAL',
                    style: TextStyle(
                      color: AppColors.electricAmber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          _buildStatRow('Status', res.isSuccess ? 'Success' : 'Failed',
              res.isSuccess ? Colors.greenAccent : Colors.redAccent),
          _buildStatRow(
              'Total Distance',
              res.isSuccess
                  ? '${res.totalDistanceKm.toStringAsFixed(1)} km'
                  : 'N/A',
              Colors.white),
          _buildStatRow('Nodes Explored', '${res.nodesExplored}', AppColors.skyBlue),
          _buildStatRow('Time Elapsed',
              '${res.executionTimeMs.toStringAsFixed(3)} ms', Colors.amberAccent),
          _buildStatRow('Total Hops', '${res.totalHops}', Colors.purpleAccent),

          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 6),

          Text(
            'Path: ${res.isSuccess ? res.hopSummary : 'No path found'}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),

          const SizedBox(height: 12),

          if (res.isSuccess)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onViewOnMap(res),
                icon: const Icon(Icons.map, size: 14),
                label: const Text('VIEW ON MAP', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text(val,
              style: TextStyle(
                  color: valColor, fontWeight: FontWeight.bold, fontSize: 12)),
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
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 9)),
              Text(
                val,
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- "How It Works" Section (Foundations of AI Viva Notes) ---
  Widget _buildTheoryExplanationSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cockpitDark.withValues(alpha: 0.85)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.skyBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: AppColors.skyBlue, size: 22),
              const SizedBox(width: 10),
              Text(
                'HOW IT WORKS — FOUNDATIONS OF AI CONCEPTS',
                style: AppTypography.hudMetric.copyWith(
                  color: AppColors.skyBlue,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTheoryCard(
            '🔍 1. Depth-Limited Search (DLS)',
            'An UNINFORMED graph search algorithm that explores paths up to a fixed depth limit L. '
                'Avoids infinite loops in cyclic graphs. Neither complete (if solution lies beyond L) nor optimal, '
                'with Time Complexity O(b^L) and Space Complexity O(b * L).',
            isDark,
          ),
          const SizedBox(height: 10),

          _buildTheoryCard(
            '⚖️ 2. Uniform Cost Search (UCS)',
            'An UNINFORMED graph search algorithm (equivalent to Dijkstra) that expands the node with the lowest cumulative path cost g(n). '
                'Guarantees the optimal shortest path for non-negative edge costs. Time/Space Complexity: O(b^(1 + C*/ε)).',
            isDark,
          ),
          const SizedBox(height: 10),

          _buildTheoryCard(
            '🎯 3. A* Search (Informed Heuristic)',
            'An INFORMED graph search algorithm using evaluation function f(n) = g(n) + h(n), where g(n) is actual path cost '
                'and h(n) is the Haversine straight-line distance heuristic to the target goal airport. '
                'Because Haversine distance is admissible (h(n) ≤ h*(n)), A* guarantees an optimal solution while exploring fewer nodes.',
            isDark,
          ),
          const SizedBox(height: 10),

          _buildTheoryCard(
            '⛈️ 4. Dynamic Weather-Aware Routing (Convective Avoidance)',
            'FAA and ICAO standards mandate that commercial aircraft maintain a minimum 20 NM lateral clearance '
                'around severe convective storm cells (reflectivity > 45 dBZ) to prevent structural damage from hail and extreme updrafts. '
                'The Weather-Aware routing engine samples route segments, detects hazard buffer intersections, and dynamically synthesizes '
                'tangent tactical deviation waypoints to navigate clear of severe convective activity.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAwareCard(WeatherAwareRouteResult wx, bool isDark) {
    final hasAvoidance = wx.hasAvoidance;
    final accentColor = hasAvoidance ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.9) : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
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
                  Icon(
                    hasAvoidance ? Icons.thunderstorm_rounded : Icons.check_circle_outline,
                    color: accentColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'WEATHER-AWARE DYNAMIC REROUTING',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${wx.safetyScorePercent.toStringAsFixed(1)}% SAFETY SCORE',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            wx.statusSummary,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightText,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          if (wx.detectedHazards.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Severe Weather Cells in Corridor:',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: wx.detectedHazards.map((h) {
                return Chip(
                  avatar: const Icon(Icons.flash_on, size: 14, color: Colors.orangeAccent),
                  label: Text('${h.hazard.name} (${h.hazard.severityDbz.toInt()} dBZ)'),
                  backgroundColor: AppColors.spaceNavy,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  side: const BorderSide(color: AppColors.borderSubtle),
                );
              }).toList(),
            ),
          ],

          if (hasAvoidance) ...[
            const SizedBox(height: 14),
            Text(
              'Generated Tactical Deviation Waypoints (30 NM Clearance):',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: wx.detourWaypoints.map((w) {
                return Chip(
                  avatar: const Icon(Icons.alt_route_rounded, size: 14, color: Colors.cyanAccent),
                  label: Text('${w.name} • ${w.clearanceKm.toStringAsFixed(0)} km safe buffer'),
                  backgroundColor: AppColors.spaceNavy,
                  labelStyle: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  side: const BorderSide(color: Colors.cyanAccent),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final weatherRoute = RouteResult(
                    algorithmName: '${wx.baseRoute.algorithmName} (Weather Avoidance)',
                    isSuccess: true,
                    path: wx.optimizedPath,
                    legs: [],
                    totalDistanceKm: wx.weatherAwareDistanceKm,
                    nodesExplored: wx.baseRoute.nodesExplored,
                    executionTimeMs: wx.baseRoute.executionTimeMs,
                    statusMessage: 'Weather-avoidance flight route bypassing ${wx.detourWaypoints.length} convective storm cells.',
                  );
                  widget.onViewOnMap(weatherRoute);
                },
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text('VIEW WEATHER-AVOIDANCE ROUTE ON MAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
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
              color: AppColors.electricAmber,
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
