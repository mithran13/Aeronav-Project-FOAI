import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/country_info.dart';
import '../../models/flight_item.dart';
import '../../services/atc_radio_service.dart';
import '../../services/auth_service.dart';
import '../../services/country_airspace_service.dart';
import '../../services/flight_tracker_service.dart';
import '../../services/global_airport_service.dart';
import '../../services/live_flight_api_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/hover_animated_widgets.dart';
import 'flutter_map_widget.dart';

enum MapDisplayMode { flightradarDark, streetView, mapboxHybridSatellite }

enum SelectedPopupType { plane, airport, route, none }

class WorldMapView extends StatefulWidget {
  const WorldMapView({super.key});

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  final MapController _mapController = MapController();

  MapDisplayMode _mapMode = MapDisplayMode.flightradarDark; // Default: Dark Radar View
  bool _isFullscreen = false;
  bool _isLoadingLiveApi = false;
  bool _isFlightPanelCollapsed = false;
  bool _showWeatherRadar = true;

  // Contextual Selection Details Popup State
  SelectedPopupType _popupType = SelectedPopupType.plane;
  AirportInfo? _selectedAirport;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  List<dynamic> _searchResults = [];
  bool _showSearchResults = false;
  String? _lastTrackedFlightId;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Smoothly animate camera using flutter_map MapController
  void _animateCameraTo(double lat, double lon, {double zoom = 4.5}) {
    _mapController.move(LatLng(lat, lon), zoom);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  void _centerOnActiveFlight() {
    final tracker = Provider.of<FlightTrackerService>(context, listen: false);
    final activeFlight = tracker.activeFlight;
    _animateCameraTo(activeFlight.currentLat, activeFlight.currentLon, zoom: 4.5);
    setState(() {
      _popupType = SelectedPopupType.plane;
    });
  }

  void _handleSearchInput(String query, List<PassengerFlightItem> allFlights) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
        return;
      }

      final q = query.toLowerCase().trim();
      final List<dynamic> results = [];

      // 1. Search Flights
      for (var f in allFlights) {
        if (f.flightNumber.toLowerCase().contains(q) ||
            f.airlineName.toLowerCase().contains(q) ||
            f.origin.city.toLowerCase().contains(q) ||
            f.origin.iata.toLowerCase().contains(q) ||
            f.destination.city.toLowerCase().contains(q) ||
            f.destination.iata.toLowerCase().contains(q)) {
          results.add(f);
        }
      }

      // 2. Search Airports
      final airports = GlobalAirportService.searchAirports(q);
      for (var a in airports) {
        if (!results.contains(a)) results.add(a);
      }

      // 3. Search Country Airspaces
      final country = CountryAirspaceService.findCountry(q);
      if (country != null && !results.contains(country)) {
        results.add(country);
      }

      setState(() {
        _searchResults = results;
        _showSearchResults = true;
      });
    });
  }

  void _selectSearchResult(dynamic item, FlightTrackerService tracker) {
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });

    if (item is PassengerFlightItem) {
      tracker.selectFlight(item);
      _animateCameraTo(item.currentLat, item.currentLon, zoom: 5.0);
      setState(() => _popupType = SelectedPopupType.plane);
    } else if (item is AirportInfo) {
      setState(() {
        _selectedAirport = item;
        _popupType = SelectedPopupType.airport;
      });
      _animateCameraTo(item.latitude, item.longitude, zoom: 6.0);
    } else if (item is CountryInfo) {
      _animateCameraTo(item.centerLat, item.centerLon, zoom: item.zoomLevel);
    }
  }

  void _syncRealLiveFlights() async {
    setState(() => _isLoadingLiveApi = true);
    final tracker = Provider.of<FlightTrackerService>(context, listen: false);

    final liveList = await LiveFlightApiEngine.fetchRealLiveFlights();

    if (mounted) {
      setState(() => _isLoadingLiveApi = false);
      if (liveList.isNotEmpty) {
        for (var flight in liveList) {
          tracker.addCustomTrip(flight);
        }
        _centerOnActiveFlight();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.cockpitDark,
            content: Text(
              'Synced ${liveList.length} Live ADS-B flights to World Radar Tracker!',
              style: AppTypography.hudLabel.copyWith(color: AppColors.skyBlue),
            ),
          ),
        );
      }
    }
  }

  FlutterMapStyleMode _getStyleMode(MapDisplayMode mode) {
    switch (mode) {
      case MapDisplayMode.flightradarDark:
        return FlutterMapStyleMode.darkCockpit;
      case MapDisplayMode.streetView:
        return FlutterMapStyleMode.streetView;
      case MapDisplayMode.mapboxHybridSatellite:
        return FlutterMapStyleMode.satellite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final trackerService = Provider.of<FlightTrackerService>(context);
    final activeFlight = trackerService.activeFlight;
    final isDark = authService.currentUser.nightMode;

    // Automatically re-center camera on active flight when route or flight changes
    if (_lastTrackedFlightId != activeFlight.id) {
      _lastTrackedFlightId = activeFlight.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animateCameraTo(activeFlight.currentLat, activeFlight.currentLon, zoom: 4.5);
        }
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.spaceNavy : AppColors.lightBg,
      body: Stack(
        children: [
          // ==================================================
          // 1. FULL-SCREEN FLUTTER MAP VECTOR MAP ENGINE (HERO)
          // ==================================================
          Positioned.fill(
            child: FlutterWorldMapWidget(
              activeFlight: activeFlight,
              allFlights: trackerService.allFlights,
              activeAiRoute: trackerService.activeAiRoute,
              styleMode: _getStyleMode(_mapMode),
              mapController: _mapController,
              showWeatherRadar: _showWeatherRadar,
              onSelectFlight: (flight) {
                trackerService.selectFlight(flight);
                setState(() {
                  _popupType = SelectedPopupType.plane;
                });
              },
              onSelectAirport: (airport) {
                setState(() {
                  _selectedAirport = airport;
                  _popupType = SelectedPopupType.airport;
                });
              },
            ),
          ),

          // AI Route Active Overlay Banner (if AI route is selected)
          if (trackerService.activeAiRoute != null &&
              trackerService.activeAiRoute!.isSuccess)
            Positioned(
              top: 70,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cockpitDark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.cyanAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology, color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI ROUTE: ${trackerService.activeAiRoute!.algorithmName}',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Path: ${trackerService.activeAiRoute!.hopSummary} (${trackerService.activeAiRoute!.totalDistanceKm.toStringAsFixed(0)} km)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => trackerService.clearActiveAiRoute(),
                      child: const Icon(Icons.close,
                          color: AppColors.textMuted, size: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ==================================================
          // 2. COMPACT FLOATING FLIGHT STATUS PANEL (TOP-LEFT)
          // ==================================================
          if (!_isFullscreen)
            Positioned(
              top: 16,
              left: 16,
              child: _buildTopFlightStatusPanel(activeFlight, isDark),
            ),

          // ==================================================
          // 3. MAP SEARCH OVERLAY (TOP-CENTER)
          // ==================================================
          if (!_isFullscreen)
            Positioned(
              top: 16,
              left: 360,
              right: 315,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search TextField Box
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (q) => _handleSearchInput(q, trackerService.allFlights),
                      style: TextStyle(color: isDark ? Colors.white : AppColors.lightText, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search flight (UA101, AA452), airport (MAA, HND, JFK), city or country...',
                        hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: AppColors.electricBlue, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _handleSearchInput('', trackerService.allFlights);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),

                  // Search Results Dropdown Overlay Card
                  if (_showSearchResults && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cockpitDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.electricBlue),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, i) => const Divider(height: 1, color: AppColors.borderSubtle),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          if (item is PassengerFlightItem) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.flight, color: AppColors.electricAmber, size: 18),
                              title: Text('✈ ${item.flightNumber} — ${item.airlineName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${item.origin.city} (${item.origin.iata}) ➔ ${item.destination.city} (${item.destination.iata})', style: const TextStyle(fontSize: 11)),
                              onTap: () => _selectSearchResult(item, trackerService),
                            );
                          } else if (item is AirportInfo) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, color: AppColors.electricBlue, size: 18),
                              title: Text('${item.city} (${item.iata}) — ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${item.country} • ${item.formattedTerminalGate}', style: const TextStyle(fontSize: 11)),
                              onTap: () => _selectSearchResult(item, trackerService),
                            );
                          } else if (item is CountryInfo) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.public, color: AppColors.skyBlue, size: 18),
                              title: Text('${item.name} (${item.code})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: const Text('Country Airspace Tracking', style: TextStyle(fontSize: 11)),
                              onTap: () => _selectSearchResult(item, trackerService),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                ],
              ),
            ),

          // ==================================================
          // 4. LIVE SIMULATED ATC RADIO CHATTER & WAVEFORM HUD (TOP-RIGHT)
          // ==================================================
          if (!_isFullscreen)
            Positioned(
              top: 16,
              right: 16,
              child: _buildAtcRadioHudPanel(isDark),
            ),

          // ==================================================
          // 4. CONTEXTUAL POPUP DETAILS CARDS (AIRCRAFT & AIRPORT)
          // ==================================================
          if (_popupType == SelectedPopupType.plane)
            Positioned(
              bottom: 24,
              left: 24,
              child: _buildAircraftDetailsCard(activeFlight, isDark, trackerService),
            ),

          if (_popupType == SelectedPopupType.airport && _selectedAirport != null)
            Positioned(
              bottom: 24,
              left: 24,
              child: _buildAirportDetailsCard(_selectedAirport!, isDark),
            ),

          // ==================================================
          // 5. COMPACT VERTICAL MAP CONTROL STACK (BOTTOM-RIGHT)
          // ==================================================
          Positioned(
            bottom: 24,
            right: 20,
            child: HoverAnimatedCard(
              glowColor: AppColors.electricAmber,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In Button
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.electricBlue),
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),

                  // Zoom Out Button
                  IconButton(
                    icon: const Icon(Icons.remove, color: AppColors.electricBlue),
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),

                  // Locate / Center Active Flight
                  IconButton(
                    icon: const Icon(Icons.my_location, color: AppColors.electricAmber),
                    tooltip: 'Follow Active Flight',
                    onPressed: _centerOnActiveFlight,
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),

                  // Map Style Switcher Cycle Button
                  IconButton(
                    icon: const Icon(Icons.layers, color: AppColors.skyBlue),
                    tooltip: 'Cycle Map Style (Dark Cockpit / OpenStreetMap / Satellite)',
                    onPressed: () {
                      setState(() {
                        if (_mapMode == MapDisplayMode.flightradarDark) {
                          _mapMode = MapDisplayMode.streetView;
                        } else if (_mapMode == MapDisplayMode.streetView) {
                          _mapMode = MapDisplayMode.mapboxHybridSatellite;
                        } else {
                          _mapMode = MapDisplayMode.flightradarDark;
                        }
                      });
                    },
                  ),
                  // Weather Radar Layer Toggle
                  IconButton(
                    icon: Icon(
                      Icons.thunderstorm,
                      color: _showWeatherRadar ? Colors.yellowAccent : AppColors.textMuted,
                    ),
                    tooltip: _showWeatherRadar ? 'Hide Convective Weather Radar Layer' : 'Show Convective Weather Radar Layer',
                    onPressed: () {
                      setState(() => _showWeatherRadar = !_showWeatherRadar);
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),

                  // Fullscreen Toggle Button
                  IconButton(
                    icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                    tooltip: 'Toggle Fullscreen',
                    onPressed: () {
                      setState(() => _isFullscreen = !_isFullscreen);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  // Top Floating Compact Flight Status Panel
  Widget _buildTopFlightStatusPanel(PassengerFlightItem flight, bool isDark) {
    bool isDemo = !flight.id.startsWith('LIVE-');

    if (_isFlightPanelCollapsed) {
      return InkWell(
        onTap: () => setState(() => _isFlightPanelCollapsed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.electricBlue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.airplanemode_active, color: AppColors.electricAmber, size: 16),
              const SizedBox(width: 8),
              Text(
                '✈ ${flight.flightNumber} • ${flight.origin.iata} ➔ ${flight.destination.iata}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.unfold_more, size: 14, color: AppColors.electricBlue),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _isLoadingLiveApi ? null : _syncRealLiveFlights,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDemo ? Colors.grey.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDemo ? Colors.grey : Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingLiveApi)
                        const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                      else
                        Text(
                          isDemo ? 'DEMO FLIGHT' : '● LIVE',
                          style: TextStyle(
                            color: isDemo ? Colors.grey : Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${flight.flightNumber} • ${flight.airlineName}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.lightText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isFlightPanelCollapsed = true),
                child: const Icon(Icons.remove, size: 18, color: AppColors.electricBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${flight.origin.city} (${flight.origin.iata})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Icon(Icons.arrow_forward, color: AppColors.electricBlue, size: 14),
              Text('${flight.destination.city} (${flight.destination.iata})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${flight.currentAltitudeFeet.toInt()} ft', style: const TextStyle(fontSize: 11, color: AppColors.electricAmber, fontWeight: FontWeight.bold)),
              Text('${flight.currentSpeedMph.toInt()} kts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text('ETA ${flight.timeRemainingFormatted}', style: const TextStyle(fontSize: 11, color: AppColors.skyBlue, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // Aircraft Contextual Details Card
  Widget _buildAircraftDetailsCard(PassengerFlightItem flight, bool isDark, FlightTrackerService trackerService) {
    bool isDemo = !flight.id.startsWith('LIVE-');

    return Container(
      width: 360,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.electricAmber),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.electricAmber, shape: BoxShape.circle),
                child: const Icon(Icons.flight_takeoff, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('✈ ${flight.flightNumber}', style: AppTypography.h3.copyWith(color: AppColors.electricAmber, fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          isDemo ? 'DEMO' : '● LIVE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDemo ? Colors.grey : Colors.greenAccent),
                        ),
                      ],
                    ),
                    Text('${flight.airlineName} • ${flight.aircraftModel}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _popupType = SelectedPopupType.none),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${flight.origin.city} (${flight.origin.iata})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(flight.origin.formattedTerminalGate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const Icon(Icons.flight_land, color: AppColors.electricBlue),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${flight.destination.city} (${flight.destination.iata})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(flight.destination.formattedTerminalGate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Flight Data Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  const Text('ALTITUDE', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text('${flight.currentAltitudeFeet.toInt()} ft', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
                Column(children: [
                  const Text('SPEED', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text('${flight.currentSpeedMph.toInt()} kts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
                Column(children: [
                  const Text('HEADING', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text('${flight.currentHeading.toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
                Column(children: [
                  const Text('REMAINING', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text(flight.timeRemainingFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.electricAmber)),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    trackerService.selectFlight(flight);
                    _animateCameraTo(flight.currentLat, flight.currentLon, zoom: 5.5);
                  },
                  icon: const Icon(Icons.my_location, size: 16, color: Colors.white),
                  label: const Text('FOLLOW FLIGHT ON MAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Airport Contextual Details Card
  Widget _buildAirportDetailsCard(AirportInfo airport, bool isDark) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cockpitDark : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.electricBlue),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.electricBlue, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${airport.city} (${airport.iata})', style: AppTypography.h3.copyWith(color: AppColors.electricBlue, fontSize: 16)),
                    Text(airport.name, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _popupType = SelectedPopupType.none),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ICAO Code: ${airport.icao}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text('Country: ${airport.country}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(airport.formattedTerminalGate, style: const TextStyle(fontSize: 12, color: AppColors.electricAmber, fontWeight: FontWeight.bold)),

          const SizedBox(height: 14),

          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _animateCameraTo(airport.latitude, airport.longitude, zoom: 6.5);
                  },
                  icon: const Icon(Icons.center_focus_strong, size: 16, color: Colors.white),
                  label: const Text('CENTER AIRPORT ON MAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final tracker = Provider.of<FlightTrackerService>(context, listen: false);
                    tracker.setGlobalPlannedRoute(
                      fromIata: tracker.selectedOriginIata,
                      toIata: airport.iata,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.cockpitDark,
                        content: Text(
                          'Destination set to ${airport.city} (${airport.iata})! Synchronized across AI Route, Eco-Route & Delay Risk.',
                          style: const TextStyle(color: AppColors.radarGreen),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation, size: 16, color: Colors.black),
                  label: const Text('SET AS DESTINATION (SYNC ALL TABS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricAmber,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ATC Radio VHF Live Chatter & Waveform Equalizer HUD Panel
  Widget _buildAtcRadioHudPanel(bool isDark) {
    return Consumer<AtcRadioService>(
      builder: (context, atcRadio, _) {
        final isOn = atcRadio.isRadioOn;

        return Container(
          width: 285,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cockpitDark.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOn ? AppColors.electricAmber : AppColors.electricBlue.withValues(alpha: 0.4),
              width: isOn ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isOn ? AppColors.electricAmber.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isOn ? Icons.graphic_eq : Icons.radio,
                    color: isOn ? AppColors.electricAmber : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOn ? 'VHF CHATTER — ${atcRadio.currentChannel.frequency}' : 'ATC VHF RADIO',
                      style: AppTypography.hudLabel.copyWith(
                        color: isOn ? AppColors.electricAmber : (isDark ? Colors.white : AppColors.lightText),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Channel Selector Dropdown Popup Button
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.tune, size: 16, color: AppColors.skyBlue),
                    tooltip: 'Select ATC Channel Frequency',
                    onSelected: (idx) => atcRadio.selectChannel(idx),
                    itemBuilder: (context) {
                      return List.generate(AtcRadioService.availableChannels.length, (index) {
                        final ch = AtcRadioService.availableChannels[index];
                        return PopupMenuItem<int>(
                          value: index,
                          child: Row(
                            children: [
                              Text(ch.frequency, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.electricAmber)),
                              const SizedBox(width: 8),
                              Text('${ch.name} (${ch.location})', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      });
                    },
                  ),

                  // Power Toggle Button
                  InkWell(
                    onTap: () => atcRadio.toggleRadio(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOn ? AppColors.electricAmber : AppColors.spaceNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: isOn ? Colors.black : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (isOn) ...[
                const SizedBox(height: 8),
                // Live Waveform Equalizer Animated Bars
                ValueListenableBuilder<List<double>>(
                  valueListenable: atcRadio.waveformNotifier,
                  builder: (context, levels, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: levels.map((lvl) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 4,
                          height: 18 * lvl,
                          decoration: BoxDecoration(
                            color: AppColors.electricAmber,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 6),
                // ATC Transmission Marquee Text
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.spaceNavy.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    atcRadio.currentTransmission,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.skyBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
