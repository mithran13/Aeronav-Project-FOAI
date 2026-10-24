enum FlightFileStatus { draft, filed, dispatched, inFlight, completed, archived }

enum FlightFileType { fms, gpx, kml, json, csv }

class FlightFileTrack {
  final String id;
  final String fileName;
  final FlightFileType fileType;
  final FlightFileStatus status;
  final String flightNumber;
  final String aircraftRegistration;
  final String originIcao;
  final String destinationIcao;
  final int fileSizeBytes;
  final DateTime lastModified;
  final String uploadedBy;
  final String fileContent;
  final Map<String, dynamic> metadata;

  FlightFileTrack({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.status,
    required this.flightNumber,
    required this.aircraftRegistration,
    required this.originIcao,
    required this.destinationIcao,
    required this.fileSizeBytes,
    required this.lastModified,
    required this.uploadedBy,
    required this.fileContent,
    this.metadata = const {},
  });

  String get fileExtension {
    switch (fileType) {
      case FlightFileType.fms:
        return 'FMS';
      case FlightFileType.gpx:
        return 'GPX';
      case FlightFileType.kml:
        return 'KML';
      case FlightFileType.json:
        return 'JSON';
      case FlightFileType.csv:
        return 'CSV';
    }
  }

  String get statusLabel {
    switch (status) {
      case FlightFileStatus.draft:
        return 'Draft';
      case FlightFileStatus.filed:
        return 'Filed';
      case FlightFileStatus.dispatched:
        return 'Dispatched';
      case FlightFileStatus.inFlight:
        return 'In-Flight';
      case FlightFileStatus.completed:
        return 'Completed';
      case FlightFileStatus.archived:
        return 'Archived';
    }
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  FlightFileTrack copyWith({
    FlightFileStatus? status,
    DateTime? lastModified,
    String? fileContent,
    Map<String, dynamic>? metadata,
  }) {
    return FlightFileTrack(
      id: id,
      fileName: fileName,
      fileType: fileType,
      status: status ?? this.status,
      flightNumber: flightNumber,
      aircraftRegistration: aircraftRegistration,
      originIcao: originIcao,
      destinationIcao: destinationIcao,
      fileSizeBytes: fileSizeBytes,
      lastModified: lastModified ?? this.lastModified,
      uploadedBy: uploadedBy,
      fileContent: fileContent ?? this.fileContent,
      metadata: metadata ?? this.metadata,
    );
  }
}
