import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/flight_file.dart';
import '../models/flight_plan.dart';
import '../models/telemetry_point.dart';

class FlightFileService extends ChangeNotifier {
  final List<FlightFileTrack> _files = [];
  String _searchQuery = '';
  FlightFileStatus? _selectedStatusFilter;
  FlightFileType? _selectedTypeFilter;
  FlightFileTrack? _selectedFile;

  List<FlightFileTrack> get allFiles => List.unmodifiable(_files);
  String get searchQuery => _searchQuery;
  FlightFileStatus? get selectedStatusFilter => _selectedStatusFilter;
  FlightFileType? get selectedTypeFilter => _selectedTypeFilter;
  FlightFileTrack? get selectedFile => _selectedFile;

  FlightFileService() {
    _loadSampleFiles();
  }

  void _loadSampleFiles() {
    _files.addAll([
      FlightFileTrack(
        id: 'FILE-001',
        fileName: 'JFK_BOS_AAL452_FMS.fms',
        fileType: FlightFileType.fms,
        status: FlightFileStatus.inFlight,
        flightNumber: 'AAL452',
        aircraftRegistration: 'N737AA',
        originIcao: 'KJFK',
        destinationIcao: 'KBOS',
        fileSizeBytes: 14200,
        lastModified: DateTime.now().subtract(const Duration(minutes: 45)),
        uploadedBy: 'Capt. Vance',
        fileContent: '''
[FlightPlan]
AppVersion=11.50
FlightPlanType=IFR
Origin=KJFK
Destination=KBOS
CruiseAlt=33000
Waypoints:
1,KJFK,40.6413,-73.7781,0
2,MERIT,41.1542,-72.8801,33000
3,ORW,41.5558,-71.9997,33000
4,WOONS,42.0125,-71.4583,24000
5,KBOS,42.3656,-71.0096,0
''',
        metadata: {
          'waypointsCount': 5,
          'totalDistanceNM': 186.4,
          'estTimeMins': 38,
          'aircraft': 'Boeing 737-800'
        },
      ),
      FlightFileTrack(
        id: 'FILE-002',
        fileName: 'LAX_SFO_DLH882_GPX.gpx',
        fileType: FlightFileType.gpx,
        status: FlightFileStatus.dispatched,
        flightNumber: 'DLH882',
        aircraftRegistration: 'N320AF',
        originIcao: 'KLAX',
        destinationIcao: 'KSFO',
        fileSizeBytes: 38400,
        lastModified: DateTime.now().subtract(const Duration(hours: 2)),
        uploadedBy: 'FO Elena Rostova',
        fileContent: '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="AeroNav Pro">
  <trk>
    <name>KLAX to KSFO Flight Path</name>
    <trkseg>
      <trkpt lat="33.9416" lon="-118.4085"><ele>38</ele><time>2026-09-12T12:00:00Z</time></trkpt>
      <trkpt lat="34.6200" lon="-119.5800"><ele>10668</ele><time>2026-09-12T12:15:00Z</time></trkpt>
      <trkpt lat="36.3100" lon="-121.2200"><ele>10668</ele><time>2026-09-12T12:45:00Z</time></trkpt>
      <trkpt lat="37.6188" lon="-122.3750"><ele>4</ele><time>2026-09-12T13:10:00Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>''',
        metadata: {
          'waypointsCount': 4,
          'totalDistanceNM': 294.1,
          'estTimeMins': 52,
          'aircraft': 'Airbus A320-200'
        },
      ),
      FlightFileTrack(
        id: 'FILE-003',
        fileName: 'MIA_MCO_G650_OVERLAY.kml',
        fileType: FlightFileType.kml,
        status: FlightFileStatus.completed,
        flightNumber: 'GEX991',
        aircraftRegistration: 'N650GS',
        originIcao: 'KMIA',
        destinationIcao: 'KMCO',
        fileSizeBytes: 24800,
        lastModified: DateTime.now().subtract(const Duration(hours: 5)),
        uploadedBy: 'Dispatcher Marcus',
        fileContent: '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>KMIA to KMCO Airway Corridor</name>
    <Placemark>
      <LineString>
        <coordinates>-80.2906,25.7959,0 -80.6500,27.1000,12192 -81.3089,28.4294,0</coordinates>
      </LineString>
    </Placemark>
  </Document>
</kml>''',
        metadata: {
          'waypointsCount': 3,
          'totalDistanceNM': 168.0,
          'estTimeMins': 26,
          'aircraft': 'Gulfstream G650'
        },
      ),
      FlightFileTrack(
        id: 'FILE-004',
        fileName: 'LHR_CDG_C172_LOG.json',
        fileType: FlightFileType.json,
        status: FlightFileStatus.draft,
        flightNumber: 'G-BKOA',
        aircraftRegistration: 'N172SP',
        originIcao: 'EGLL',
        destinationIcao: 'LFPG',
        fileSizeBytes: 8900,
        lastModified: DateTime.now().subtract(const Duration(hours: 12)),
        uploadedBy: 'Capt. Vance',
        fileContent: jsonEncode({
          'flightNumber': 'G-BKOA',
          'origin': 'EGLL',
          'destination': 'LFPG',
          'cruiseSpeedKts': 120,
          'route': ['EGLL', 'DVR', 'ABB', 'LFPG']
        }),
        metadata: {
          'waypointsCount': 4,
          'totalDistanceNM': 188.5,
          'estTimeMins': 94,
          'aircraft': 'Cessna 172 Skyhawk'
        },
      ),
    ]);
    if (_files.isNotEmpty) {
      _selectedFile = _files.first;
    }
  }

  List<FlightFileTrack> get filteredFiles {
    return _files.where((file) {
      final matchesSearch = _searchQuery.isEmpty ||
          file.fileName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          file.flightNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          file.originIcao.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          file.destinationIcao.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          file.aircraftRegistration.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == null || file.status == _selectedStatusFilter;
      final matchesType = _selectedTypeFilter == null || file.fileType == _selectedTypeFilter;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(FlightFileStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setTypeFilter(FlightFileType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void selectFile(FlightFileTrack file) {
    _selectedFile = file;
    notifyListeners();
  }

  void updateFileStatus(String fileId, FlightFileStatus newStatus) {
    final index = _files.indexWhere((f) => f.id == fileId);
    if (index != -1) {
      _files[index] = _files[index].copyWith(
        status: newStatus,
        lastModified: DateTime.now(),
      );
      if (_selectedFile?.id == fileId) {
        _selectedFile = _files[index];
      }
      notifyListeners();
    }
  }

  void addFile(FlightFileTrack newFile) {
    _files.insert(0, newFile);
    _selectedFile = newFile;
    notifyListeners();
  }

  void deleteFile(String fileId) {
    _files.removeWhere((f) => f.id == fileId);
    if (_selectedFile?.id == fileId) {
      _selectedFile = _files.isNotEmpty ? _files.first : null;
    }
    notifyListeners();
  }

  FlightFileTrack generateFileFromPlan(FlightPlan plan, FlightFileType type) {
    String ext = type.name.toUpperCase();
    String fileName = '${plan.flightNumber}_${plan.origin.identifier}_${plan.destination.identifier}.$ext';
    String content = '';

    if (type == FlightFileType.fms) {
      content = '''[FlightPlan]
Title=${plan.flightNumber} ${plan.origin.identifier} to ${plan.destination.identifier}
Aircraft=${plan.aircraft.model}
Origin=${plan.origin.identifier}
Destination=${plan.destination.identifier}
Altitude=${plan.cruiseAltitudeFeet}
Waypoints:
''';
      int idx = 1;
      for (var wp in plan.fullRouteWaypoints) {
        content += '$idx,${wp.identifier},${wp.latitude},${wp.longitude},${wp.altitudeFeet}\n';
        idx++;
      }
    } else if (type == FlightFileType.json) {
      content = jsonEncode({
        'flightNumber': plan.flightNumber,
        'aircraft': plan.aircraft.model,
        'registration': plan.aircraft.registration,
        'origin': plan.origin.toJson(),
        'destination': plan.destination.toJson(),
        'cruiseAltitudeFeet': plan.cruiseAltitudeFeet,
        'totalDistanceNM': plan.totalDistanceNM,
        'estTimeHours': plan.estimatedFlightTimeHours,
        'waypoints': plan.fullRouteWaypoints.map((w) => w.toJson()).toList(),
      });
    } else if (type == FlightFileType.gpx) {
      content = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="AeroNav Pro">
  <trk>
    <name>${plan.flightNumber}</name>
    <trkseg>
${plan.fullRouteWaypoints.map((w) => '      <trkpt lat="${w.latitude}" lon="${w.longitude}"><ele>${w.altitudeFeet}</ele><name>${w.identifier}</name></trkpt>').join('\n')}
    </trkseg>
  </trk>
</gpx>''';
    } else {
      content = 'TYPE,IDENTIFIER,LAT,LON,ALT\n';
      for (var wp in plan.fullRouteWaypoints) {
        content += '${wp.type},${wp.identifier},${wp.latitude},${wp.longitude},${wp.altitudeFeet}\n';
      }
    }

    final newTrack = FlightFileTrack(
      id: 'FILE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      fileName: fileName,
      fileType: type,
      status: FlightFileStatus.filed,
      flightNumber: plan.flightNumber,
      aircraftRegistration: plan.aircraft.registration,
      originIcao: plan.origin.identifier,
      destinationIcao: plan.destination.identifier,
      fileSizeBytes: content.length,
      lastModified: DateTime.now(),
      uploadedBy: 'Flight Planner',
      fileContent: content,
      metadata: {
        'waypointsCount': plan.fullRouteWaypoints.length,
        'totalDistanceNM': double.parse(plan.totalDistanceNM.toStringAsFixed(1)),
        'estTimeMins': (plan.estimatedFlightTimeHours * 60).round(),
        'aircraft': plan.aircraft.model,
      },
    );

    addFile(newTrack);
    return newTrack;
  }

  // Generate telemetry sample points for visualization chart
  List<TelemetryPoint> generateTelemetryPoints(FlightFileTrack file) {
    final List<TelemetryPoint> points = [];
    int pointCount = 25;
    double maxAlt = (file.metadata['aircraft'] as String?)?.contains('Cessna') == true ? 8000.0 : 35000.0;
    double cruiseSpeed = (file.metadata['aircraft'] as String?)?.contains('Cessna') == true ? 120.0 : 450.0;

    DateTime startTime = DateTime.now().subtract(const Duration(minutes: 60));

    for (int i = 0; i <= pointCount; i++) {
      double progress = i / pointCount;
      double alt = 0.0;
      if (progress < 0.25) {
        alt = maxAlt * (progress / 0.25); // Climb phase
      } else if (progress < 0.75) {
        alt = maxAlt; // Cruise phase
      } else {
        alt = maxAlt * (1.0 - (progress - 0.75) / 0.25); // Descent phase
      }

      double speed = progress < 0.1 ? cruiseSpeed * 0.4 : (progress > 0.9 ? cruiseSpeed * 0.5 : cruiseSpeed);
      double fuel = 12000 - (progress * 4500);

      points.add(TelemetryPoint(
        timestamp: startTime.add(Duration(minutes: (progress * 60).round())),
        latitude: 40.64 + (progress * 1.7),
        longitude: -73.77 + (progress * 2.7),
        altitudeFeet: alt,
        airspeedKnots: speed,
        groundSpeedKnots: speed + 15.0, // Wind tailwind
        headingDegrees: 65.0,
        pitchDegrees: progress < 0.25 ? 7.5 : (progress > 0.75 ? -3.0 : 0.5),
        rollDegrees: (i % 5 == 0 && progress > 0.2 && progress < 0.8) ? 12.0 : 0.0,
        verticalSpeedFpm: progress < 0.25 ? 1800.0 : (progress > 0.75 ? -1500.0 : 0.0),
        fuelRemainingLbs: fuel,
      ));
    }
    return points;
  }
}
