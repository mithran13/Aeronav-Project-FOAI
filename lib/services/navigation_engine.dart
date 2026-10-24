import 'dart:async';
import 'package:flutter/material.dart';
import '../models/flight_plan.dart';

class NavigationEngine extends ChangeNotifier {
  FlightPlan _activePlan;
  final List<FlightPlan> _premadePlans = [];

  // Simulator State
  bool _isSimulating = false;
  double _simSpeedMultiplier = 1.0; // 1x, 2x, 5x, 10x
  double _simProgress = 0.0; // 0.0 to 1.0 along entire flight route
  Timer? _simTimer;

  // Live Simulated Flight Dynamics
  double _currentLat = 0.0;
  double _currentLon = 0.0;
  double _currentAltitude = 0.0;
  double _currentAirspeed = 0.0;
  double _currentHeading = 0.0;
  double _currentPitch = 0.0;
  double _currentRoll = 0.0;
  double _currentVsi = 0.0;
  int _activeWaypointIndex = 0;

  FlightPlan get activePlan => _activePlan;
  List<FlightPlan> get premadePlans => List.unmodifiable(_premadePlans);
  bool get isSimulating => _isSimulating;
  double get simSpeedMultiplier => _simSpeedMultiplier;
  double get simProgress => _simProgress;

  double get currentLat => _currentLat;
  double get currentLon => _currentLon;
  double get currentAltitude => _currentAltitude;
  double get currentAirspeed => _currentAirspeed;
  double get currentHeading => _currentHeading;
  double get currentPitch => _currentPitch;
  double get currentRoll => _currentRoll;
  double get currentVsi => _currentVsi;
  int get activeWaypointIndex => _activeWaypointIndex;

  NavigationEngine()
      : _activePlan = _createDefaultJfkBosPlan() {
    _initPremadePlans();
    _updateSimPosition();
  }

  static FlightPlan _createDefaultJfkBosPlan() {
    return FlightPlan(
      id: 'FP-JFK-BOS',
      flightNumber: 'AAL452',
      origin: Waypoint(
        id: 'KJFK',
        identifier: 'KJFK',
        name: 'John F. Kennedy Intl',
        latitude: 40.6413,
        longitude: -73.7781,
        altitudeFeet: 13.0,
        type: 'AIRPORT',
      ),
      destination: Waypoint(
        id: 'KBOS',
        identifier: 'KBOS',
        name: 'Boston Logan Intl',
        latitude: 42.3656,
        longitude: -71.0096,
        altitudeFeet: 19.0,
        type: 'AIRPORT',
      ),
      waypoints: [
        Waypoint(
          id: 'MERIT',
          identifier: 'MERIT',
          name: 'MERIT VOR FIX',
          latitude: 41.1542,
          longitude: -72.8801,
          altitudeFeet: 33000.0,
          type: 'FIX',
        ),
        Waypoint(
          id: 'ORW',
          identifier: 'ORW',
          name: 'Norwich VOR',
          latitude: 41.5558,
          longitude: -71.9997,
          altitudeFeet: 33000.0,
          type: 'VOR',
        ),
        Waypoint(
          id: 'WOONS',
          identifier: 'WOONS',
          name: 'WOONS WPT',
          latitude: 42.0125,
          longitude: -71.4583,
          altitudeFeet: 24000.0,
          type: 'WAYPOINT',
        ),
      ],
      aircraft: AircraftSpecs.presets[0], // Boeing 737-800
      cruiseAltitudeFeet: 33000.0,
      scheduledDeparture: DateTime.now(),
      remarks: 'Standard IFR Route Airway V16',
    );
  }

  void _initPremadePlans() {
    _premadePlans.addAll([
      _activePlan,
      FlightPlan(
        id: 'FP-LAX-SFO',
        flightNumber: 'DLH882',
        origin: Waypoint(
          id: 'KLAX',
          identifier: 'KLAX',
          name: 'Los Angeles Intl',
          latitude: 33.9416,
          longitude: -118.4085,
          altitudeFeet: 125.0,
          type: 'AIRPORT',
        ),
        destination: Waypoint(
          id: 'KSFO',
          identifier: 'KSFO',
          name: 'San Francisco Intl',
          latitude: 37.6188,
          longitude: -122.3750,
          altitudeFeet: 13.0,
          type: 'AIRPORT',
        ),
        waypoints: [
          Waypoint(
            id: 'BSR',
            identifier: 'BSR',
            name: 'Big Sur VOR',
            latitude: 36.1814,
            longitude: -121.6419,
            altitudeFeet: 35000.0,
            type: 'VOR',
          ),
          Waypoint(
            id: 'SERFR',
            identifier: 'SERFR',
            name: 'SERFR Arrival Fix',
            latitude: 37.0500,
            longitude: -121.9000,
            altitudeFeet: 16000.0,
            type: 'FIX',
          ),
        ],
        aircraft: AircraftSpecs.presets[1],
        cruiseAltitudeFeet: 35000.0,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 1)),
      ),
      FlightPlan(
        id: 'FP-MIA-MCO',
        flightNumber: 'GEX991',
        origin: Waypoint(
          id: 'KMIA',
          identifier: 'KMIA',
          name: 'Miami Intl',
          latitude: 25.7959,
          longitude: -80.2906,
          altitudeFeet: 8.0,
          type: 'AIRPORT',
        ),
        destination: Waypoint(
          id: 'KMCO',
          identifier: 'KMCO',
          name: 'Orlando Intl',
          latitude: 28.4294,
          longitude: -81.3089,
          altitudeFeet: 96.0,
          type: 'AIRPORT',
        ),
        waypoints: [
          Waypoint(
            id: 'TRV',
            identifier: 'TRV',
            name: 'Treasure VOR',
            latitude: 27.3400,
            longitude: -80.4800,
            altitudeFeet: 28000.0,
            type: 'VOR',
          ),
        ],
        aircraft: AircraftSpecs.presets[2],
        cruiseAltitudeFeet: 28000.0,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 3)),
      ),
    ]);
  }

  void setActivePlan(FlightPlan plan) {
    _activePlan = plan;
    _simProgress = 0.0;
    _updateSimPosition();
    notifyListeners();
  }

  void updatePlanDetails({
    String? flightNumber,
    AircraftSpecs? aircraft,
    double? cruiseAltitude,
    List<Waypoint>? waypoints,
  }) {
    _activePlan = FlightPlan(
      id: _activePlan.id,
      flightNumber: flightNumber ?? _activePlan.flightNumber,
      origin: _activePlan.origin,
      destination: _activePlan.destination,
      alternate: _activePlan.alternate,
      waypoints: waypoints ?? _activePlan.waypoints,
      aircraft: aircraft ?? _activePlan.aircraft,
      cruiseAltitudeFeet: cruiseAltitude ?? _activePlan.cruiseAltitudeFeet,
      scheduledDeparture: _activePlan.scheduledDeparture,
      remarks: _activePlan.remarks,
    );
    _updateSimPosition();
    notifyListeners();
  }

  void addWaypointToPlan(Waypoint wp) {
    List<Waypoint> newWps = List.from(_activePlan.waypoints)..add(wp);
    updatePlanDetails(waypoints: newWps);
  }

  void removeWaypointFromPlan(int index) {
    List<Waypoint> newWps = List.from(_activePlan.waypoints);
    if (index >= 0 && index < newWps.length) {
      newWps.removeAt(index);
      updatePlanDetails(waypoints: newWps);
    }
  }

  void toggleSimulation() {
    _isSimulating = !_isSimulating;
    if (_isSimulating) {
      _startSimLoop();
    } else {
      _simTimer?.cancel();
    }
    notifyListeners();
  }

  void setSimSpeed(double speed) {
    _simSpeedMultiplier = speed;
    notifyListeners();
  }

  void setSimProgress(double progress) {
    _simProgress = progress.clamp(0.0, 1.0);
    _updateSimPosition();
    notifyListeners();
  }

  void resetSimulation() {
    _simProgress = 0.0;
    _updateSimPosition();
    notifyListeners();
  }

  void _startSimLoop() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _simProgress += 0.001 * _simSpeedMultiplier;
      if (_simProgress >= 1.0) {
        _simProgress = 1.0;
        _isSimulating = false;
        _simTimer?.cancel();
      }
      _updateSimPosition();
      notifyListeners();
    });
  }

  void _updateSimPosition() {
    final route = _activePlan.fullRouteWaypoints;
    if (route.length < 2) return;

    int totalSegments = route.length - 1;
    double segmentProgress = _simProgress * totalSegments;
    int currentSegIndex = segmentProgress.floor().clamp(0, totalSegments - 1);
    double segFraction = segmentProgress - currentSegIndex;

    Waypoint w1 = route[currentSegIndex];
    Waypoint w2 = route[(currentSegIndex + 1).clamp(0, route.length - 1)];

    _activeWaypointIndex = currentSegIndex + 1;

    // Lat/Lon linear interpolation
    _currentLat = w1.latitude + (w2.latitude - w1.latitude) * segFraction;
    _currentLon = w1.longitude + (w2.longitude - w1.longitude) * segFraction;

    // Heading calculation between w1 and w2
    _currentHeading = FlightPlan.calculateBearing(
      w1.latitude,
      w1.longitude,
      w2.latitude,
      w2.longitude,
    );

    // Altitude profile (Climb -> Cruise -> Descent)
    double maxAlt = _activePlan.cruiseAltitudeFeet;
    if (_simProgress < 0.2) {
      _currentAltitude = ( _simProgress / 0.2 ) * maxAlt;
      _currentPitch = 6.0;
      _currentVsi = 1800.0;
    } else if (_simProgress < 0.8) {
      _currentAltitude = maxAlt;
      _currentPitch = 0.5;
      _currentVsi = 0.0;
    } else {
      _currentAltitude = maxAlt * (1.0 - (_simProgress - 0.8) / 0.2);
      _currentPitch = -3.5;
      _currentVsi = -1500.0;
    }

    // Airspeed dynamics
    double targetSpeed = _activePlan.aircraft.cruiseSpeedKnots;
    if (_simProgress < 0.1 || _simProgress > 0.9) {
      _currentAirspeed = targetSpeed * 0.55;
    } else {
      _currentAirspeed = targetSpeed;
    }

    _currentRoll = (_simProgress * 100 % 8 < 2 && _simProgress > 0.2 && _simProgress < 0.8) ? 14.0 : 0.0;
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }
}
