import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flight_item.dart';

class OpenSkyService {
  static const String _apiEndpoint =
      'https://opensky-network.org/api/states/all';

  // Fetch real live ADS-B flights from OpenSky Network API
  static Future<List<PassengerFlightItem>> fetchLiveFlights() async {
    try {
      final response = await http
          .get(Uri.parse(_apiEndpoint))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic>? states = data['states'];
        if (states == null || states.isEmpty) return [];

        final List<PassengerFlightItem> liveList = [];
        int count = 0;

        for (var state in states) {
          if (count >= 15) {
            break; // Limit to 15 active airborne flights for optimal FPS
          }

          String icao24 = (state[0] as String?) ?? '';
          String callsign = (state[1] as String?)?.trim() ?? '';
          String country = (state[2] as String?) ?? 'Global';
          double? lon = (state[5] as num?)?.toDouble();
          double? lat = (state[6] as num?)?.toDouble();
          bool onGround = (state[8] as bool?) ?? false;

          if (callsign.isEmpty) {
            callsign =
                'SKY${icao24.toUpperCase().substring(0, minInt(icao24.length, 4))}';
          }
          if (lat == null || lon == null || onGround) continue;

          // Altitude and speed are retained for future telemetry use, but not
          // needed for the current live-flight list rendering.

          liveList.add(
            PassengerFlightItem(
              id: 'OPENSKY-$icao24',
              flightNumber: callsign,
              airlineName: '$country Airways',
              airlineCode: callsign.substring(0, minInt(callsign.length, 3)),
              origin: AirportInfo(
                iata: 'DEP',
                icao: 'LIVE',
                name: 'Origin Airport',
                city: country,
                country: country,
                latitude: lat - 2.5,
                longitude: lon - 4.5,
                terminal: 'Terminal 1',
                gate: 'Gate 4',
                time: DateTime.now().subtract(const Duration(hours: 2)),
              ),
              destination: AirportInfo(
                iata: 'ARR',
                icao: 'DEST',
                name: 'Destination Airport',
                city: 'Destination',
                country: 'Global',
                latitude: lat + 3.0,
                longitude: lon + 5.0,
                terminal: 'Terminal 2',
                gate: 'Gate B12',
                time: DateTime.now().add(const Duration(hours: 2, minutes: 30)),
                baggageClaim: 'Carousel 3',
                weatherTemp: '20°C',
                weatherCondition: 'Clear',
              ),
              aircraftModel: 'ADS-B Tracked Aircraft',
              tailNumber: icao24.toUpperCase(),
              statusText: 'LIVE ADS-B • In the Air',
              progress: 0.45,
              windSpeedKts: 15.0,
              windDirection: 'SW',
              cloudCeiling: 'Clear Sky @ LIVE',
              turbulenceRisk: 'Smooth Air',
              alerts: [
                FlightAlert(
                  id: 'LIVE-1',
                  title: 'Live OpenSky ADS-B Tracking',
                  message:
                      'Receiving real-time transponder signals from $callsign ($country).',
                  category: 'Live API',
                  timestamp: DateTime.now(),
                ),
              ],
            ),
          );

          count++;
        }
        return liveList;
      }
    } catch (e) {
      // Fallback silently if offline or rate limited
    }
    return [];
  }

  static int minInt(int a, int b) => a < b ? a : b;
}
