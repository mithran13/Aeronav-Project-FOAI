import 'dart:math';
import '../models/country_info.dart';
import '../models/flight_item.dart';
import 'global_airport_service.dart';

class AirspaceSearchResult {
  final CountryInfo country;
  final List<PassengerFlightItem> flightsInAirspace;
  final String trafficDensity;

  AirspaceSearchResult({
    required this.country,
    required this.flightsInAirspace,
    required this.trafficDensity,
  });
}

class CountryAirspaceService {
  // Find country matching query string (supports presets and any country in global airport database)
  static CountryInfo? findCountry(String query) {
    if (query.isEmpty) return null;
    String q = query.toLowerCase().trim();

    // 1. Check presets
    for (var c in CountryInfo.presets) {
      if (c.name.toLowerCase().contains(q) || c.code.toLowerCase() == q) {
        return c;
      }
    }

    // 2. Dynamic lookup from global airports database for any country in the world
    final matchingAirports = GlobalAirportService.globalAirports.where(
      (a) => a.country.toLowerCase().contains(q),
    ).toList();

    if (matchingAirports.isNotEmpty) {
      double minLat = 90.0, maxLat = -90.0;
      double minLon = 180.0, maxLon = -180.0;
      double sumLat = 0.0, sumLon = 0.0;

      for (var a in matchingAirports) {
        if (a.latitude < minLat) minLat = a.latitude;
        if (a.latitude > maxLat) maxLat = a.latitude;
        if (a.longitude < minLon) minLon = a.longitude;
        if (a.longitude > maxLon) maxLon = a.longitude;
        sumLat += a.latitude;
        sumLon += a.longitude;
      }

      double centerLat = sumLat / matchingAirports.length;
      double centerLon = sumLon / matchingAirports.length;
      String countryName = matchingAirports.first.country;
      String countryCode = countryName.substring(0, min(2, countryName.length)).toUpperCase();

      return CountryInfo(
        name: countryName,
        code: countryCode,
        centerLat: centerLat,
        centerLon: centerLon,
        zoomLevel: 2.0,
        minLat: minLat - 3.0,
        maxLat: maxLat + 3.0,
        minLon: minLon - 3.0,
        maxLon: maxLon + 3.0,
      );
    }

    return null;
  }

  // Calculate active flights over or near a specific country
  static AirspaceSearchResult analyzeAirspace(CountryInfo country, List<PassengerFlightItem> flights) {
    List<PassengerFlightItem> inAirspace = [];

    for (var f in flights) {
      double lat = f.currentLat;
      double lon = f.currentLon;

      // Check if plane's live coordinates fall inside country's bounding box
      bool insideLat = lat >= country.minLat && lat <= country.maxLat;
      bool insideLon = lon >= country.minLon && lon <= country.maxLon;

      // Also check if origin or destination matches country
      bool matchesAirport = f.origin.country.toLowerCase().contains(country.name.toLowerCase()) ||
          f.destination.country.toLowerCase().contains(country.name.toLowerCase());

      if ((insideLat && insideLon) || matchesAirport) {
        inAirspace.add(f);
      }
    }

    String density = 'Normal Airspace Volume';
    if (inAirspace.length >= 3) {
      density = 'High Airspace Density • Heavy Corridor Traffic';
    } else if (inAirspace.isNotEmpty) {
      density = 'Moderate Airspace Traffic';
    }

    return AirspaceSearchResult(
      country: country,
      flightsInAirspace: inAirspace,
      trafficDensity: density,
    );
  }
}
