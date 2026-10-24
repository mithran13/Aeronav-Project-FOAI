import 'dart:async';
import 'package:flutter/material.dart';
import '../models/flight_item.dart';
import '../models/route_result.dart';
import 'global_airport_service.dart';

class FlightTrackerService extends ChangeNotifier {
  final List<PassengerFlightItem> _flights = [];
  PassengerFlightItem? _activeFlight;
  RouteResult? _activeAiRoute;
  String _searchQuery = '';
  bool _showAircraftPopup = true;

  String _selectedOriginIata = 'MAA';
  String _selectedDestinationIata = 'JFK';

  bool _isSimulating = true;
  Timer? _tickerTimer;
  int _lastUpdatedSecondsAgo = 2;

  List<PassengerFlightItem> get allFlights => List.unmodifiable(_flights);
  PassengerFlightItem get activeFlight => _activeFlight ?? _flights.first;
  RouteResult? get activeAiRoute => _activeAiRoute;
  String get searchQuery => _searchQuery;
  bool get isSimulating => _isSimulating;
  bool get showAircraftPopup => _showAircraftPopup;
  int get lastUpdatedSecondsAgo => _lastUpdatedSecondsAgo;

  String get selectedOriginIata => _selectedOriginIata;
  String get selectedDestinationIata => _selectedDestinationIata;

  void setActiveAiRoute(RouteResult? route) {
    _activeAiRoute = route;
    notifyListeners();
  }

  void clearActiveAiRoute() {
    _activeAiRoute = null;
    notifyListeners();
  }

  FlightTrackerService() {
    _initSampleFlights();
    _startTicker();
  }

  void toggleAircraftPopup() {
    _showAircraftPopup = !_showAircraftPopup;
    notifyListeners();
  }

  void _initSampleFlights() {
    _flights.addAll([
      // UA 101: Chennai (MAA) -> Tokyo (HND) as requested
      PassengerFlightItem(
        id: 'FLIGHT-UA101',
        flightNumber: 'UA 101',
        airlineName: 'United Airlines',
        airlineCode: 'UA',
        origin: AirportInfo(
          iata: 'MAA',
          icao: 'VOMM',
          name: 'Chennai International Airport',
          city: 'Chennai',
          country: 'India',
          latitude: 12.9941,
          longitude: 80.1709,
          terminal: 'Terminal 2',
          gate: 'Gate 14',
          time: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        destination: AirportInfo(
          iata: 'HND',
          icao: 'RJTT',
          name: 'Tokyo Haneda Airport',
          city: 'Tokyo',
          country: 'Japan',
          latitude: 35.5494,
          longitude: 139.7798,
          terminal: 'Terminal 3',
          gate: 'Gate 112',
          time: DateTime.now().add(const Duration(hours: 5, minutes: 15)),
          baggageClaim: 'Carousel 4',
          weatherTemp: '24°C',
          weatherCondition: 'Sunny',
        ),
        aircraftModel: 'Boeing 787-9 Dreamliner',
        tailNumber: 'N101UA',
        statusText: 'In the Air • On Time',
        progress: 0.48,
        windSpeedKts: 16.0,
        windDirection: 'ENE',
        cloudCeiling: 'Clear Sky @ FL370',
        turbulenceRisk: 'Smooth Air',
        alerts: [
          FlightAlert(
            id: 'UA-1',
            title: 'On Time Departure',
            message: 'UA 101 departed Chennai (MAA) Terminal 2 Gate 14 on schedule.',
            category: 'Departure',
            timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          FlightAlert(
            id: 'UA-2',
            title: 'Tokyo Arrival Gate Assigned',
            message: 'Assigned Terminal 3 Gate 112 at Tokyo Haneda (HND).',
            category: 'Gate',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),

      // AA 452: New York (JFK) -> London (LHR)
      PassengerFlightItem(
        id: 'FLIGHT-AA452',
        flightNumber: 'AA 452',
        airlineName: 'American Airlines',
        airlineCode: 'AA',
        origin: AirportInfo(
          iata: 'JFK',
          icao: 'KJFK',
          name: 'John F. Kennedy Intl',
          city: 'New York',
          country: 'United States',
          latitude: 40.6413,
          longitude: -73.7781,
          terminal: 'Terminal 8',
          gate: 'B22',
          time: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        destination: AirportInfo(
          iata: 'LHR',
          icao: 'EGLL',
          name: 'London Heathrow Airport',
          city: 'London',
          country: 'United Kingdom',
          latitude: 51.4700,
          longitude: -0.4543,
          terminal: 'Terminal 5',
          gate: 'A14',
          time: DateTime.now().add(const Duration(hours: 3, minutes: 20)),
          baggageClaim: 'Carousel 4',
          weatherTemp: '18°C',
          weatherCondition: 'Partly Cloudy',
        ),
        aircraftModel: 'Boeing 777-300ER',
        tailNumber: 'N737AA',
        statusText: 'In the Air • On Time',
        progress: 0.52,
        windSpeedKts: 18.0,
        windDirection: 'WSW',
        cloudCeiling: 'Scattered @ 9,000 ft',
        turbulenceRisk: 'Light Turbulence',
        alerts: [],
      ),

      // EK 201: Dubai (DXB) -> New York (JFK)
      PassengerFlightItem(
        id: 'FLIGHT-EK201',
        flightNumber: 'EK 201',
        airlineName: 'Emirates',
        airlineCode: 'EK',
        origin: AirportInfo(
          iata: 'DXB',
          icao: 'OMDB',
          name: 'Dubai Intl Airport',
          city: 'Dubai',
          country: 'United Arab Emirates',
          latitude: 25.2532,
          longitude: 55.3657,
          terminal: 'Terminal 3',
          gate: 'C19',
          time: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        destination: AirportInfo(
          iata: 'JFK',
          icao: 'KJFK',
          name: 'John F. Kennedy Intl',
          city: 'New York',
          country: 'United States',
          latitude: 40.6413,
          longitude: -73.7781,
          terminal: 'Terminal 4',
          gate: 'B30',
          time: DateTime.now().add(const Duration(hours: 6, minutes: 10)),
          baggageClaim: 'Carousel 7',
          weatherTemp: '22°C',
          weatherCondition: 'Clear Sky',
        ),
        aircraftModel: 'Airbus A380-800',
        tailNumber: 'A6-EOA',
        statusText: 'In the Air • Delayed +20m',
        isDelayed: true,
        delayMinutes: 20,
        progress: 0.65,
        windSpeedKts: 20.0,
        windDirection: 'ENE',
        cloudCeiling: 'Few Clouds @ 12,000 ft',
        turbulenceRisk: 'Light Turbulence',
        alerts: [],
      ),
    ]);

    _activeFlight = _flights.first; // UA 101 as default flight
  }

  List<PassengerFlightItem> get filteredFlights {
    if (_searchQuery.isEmpty) return _flights;
    String q = _searchQuery.toLowerCase().trim();
    return _flights.where((f) {
      return f.flightNumber.toLowerCase().contains(q) ||
          f.airlineName.toLowerCase().contains(q) ||
          f.tailNumber.toLowerCase().contains(q) ||
          f.aircraftModel.toLowerCase().contains(q) ||
          f.origin.city.toLowerCase().contains(q) ||
          f.origin.iata.toLowerCase().contains(q) ||
          f.destination.city.toLowerCase().contains(q) ||
          f.destination.iata.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectFlight(PassengerFlightItem flight) {
    _activeFlight = flight;
    _selectedOriginIata = flight.origin.iata;
    _selectedDestinationIata = flight.destination.iata;
    _showAircraftPopup = true;
    notifyListeners();
  }

  /// Sets the globally tracked route across AI Route Planner, World Map, Eco-Route, GNSS, and Delay Risk
  void setGlobalPlannedRoute({
    required String fromIata,
    required String toIata,
    RouteResult? aiRoute,
  }) {
    _selectedOriginIata = fromIata.toUpperCase();
    _selectedDestinationIata = toIata.toUpperCase();
    if (aiRoute != null) {
      _activeAiRoute = aiRoute;
    }

    // Check if an existing flight in the list connects this route
    PassengerFlightItem? matchingFlight;
    for (var f in _flights) {
      if (f.origin.iata.toUpperCase() == _selectedOriginIata &&
          f.destination.iata.toUpperCase() == _selectedDestinationIata) {
        matchingFlight = f;
        break;
      }
    }

    if (matchingFlight != null) {
      _activeFlight = matchingFlight;
    } else {
      final originInfo = GlobalAirportService.findByIata(_selectedOriginIata);
      final destInfo = GlobalAirportService.findByIata(_selectedDestinationIata);
      final distKm = GlobalAirportService.calculateDistanceKm(originInfo, destInfo);
      final flightHours = (distKm / 850.0).clamp(1.0, 18.0);

      String airline = 'AeroNav Global';
      String code = 'AN';
      String flightNo = 'AN ${100 + (_selectedDestinationIata.hashCode.abs() % 899)}';
      String model = distKm > 4000 ? 'Boeing 787-9 Dreamliner' : 'Airbus A321neo';
      String tail = 'N$code${100 + (_selectedOriginIata.hashCode.abs() % 899)}';

      final now = DateTime.now();
      final depTime = now.subtract(Duration(minutes: (flightHours * 30).round()));
      final arrTime = now.add(Duration(minutes: (flightHours * 30).round()));

      final dynamicFlight = PassengerFlightItem(
        id: 'ROUTE-$_selectedOriginIata-$_selectedDestinationIata',
        flightNumber: flightNo,
        airlineName: airline,
        airlineCode: code,
        origin: AirportInfo(
          iata: originInfo.iata,
          icao: originInfo.icao,
          name: originInfo.name,
          city: originInfo.city,
          country: originInfo.country,
          latitude: originInfo.latitude,
          longitude: originInfo.longitude,
          terminal: originInfo.terminal,
          gate: originInfo.gate,
          time: depTime,
        ),
        destination: AirportInfo(
          iata: destInfo.iata,
          icao: destInfo.icao,
          name: destInfo.name,
          city: destInfo.city,
          country: destInfo.country,
          latitude: destInfo.latitude,
          longitude: destInfo.longitude,
          terminal: destInfo.terminal,
          gate: destInfo.gate,
          time: arrTime,
          baggageClaim: 'Carousel ${(destInfo.iata.hashCode.abs() % 8) + 1}',
          weatherTemp: destInfo.weatherTemp ?? '22°C',
          weatherCondition: destInfo.weatherCondition ?? 'Clear Sky',
        ),
        aircraftModel: model,
        tailNumber: tail,
        statusText: 'In the Air • Tracking Active Route',
        progress: 0.45,
        windSpeedKts: 16.0,
        windDirection: 'WSW',
        cloudCeiling: 'Scattered @ FL360',
        turbulenceRisk: 'Smooth Air',
        alerts: [
          FlightAlert(
            id: 'ALERT-ROUTE-1',
            title: 'Active Corridor Synchronized',
            message: 'Airborne flight path between ${originInfo.city} (${originInfo.iata}) and ${destInfo.city} (${destInfo.iata}) synchronized across all modules.',
            category: 'Navigation',
            timestamp: now,
          ),
        ],
      );

      _flights.removeWhere((f) => f.id == dynamicFlight.id);
      _flights.insert(0, dynamicFlight);
      _activeFlight = dynamicFlight;
    }

    _showAircraftPopup = true;
    notifyListeners();
  }

  void toggleSimulation() {
    _isSimulating = !_isSimulating;
    if (_isSimulating) {
      _startTicker();
    } else {
      _tickerTimer?.cancel();
    }
    notifyListeners();
  }

  void setFlightProgress(double progress) {
    if (_activeFlight != null) {
      _activeFlight!.progress = progress.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _lastUpdatedSecondsAgo = (timer.tick % 5) + 1;

      if (_activeFlight != null && _isSimulating) {
        _activeFlight!.progress += 0.0004;
        if (_activeFlight!.progress >= 1.0) {
          _activeFlight!.progress = 1.0;
        }
      }
      notifyListeners();
    });
  }

  void addCustomTrip(PassengerFlightItem trip) {
    _flights.insert(0, trip);
    _activeFlight = trip;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}
