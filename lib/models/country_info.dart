class CountryInfo {
  final String name;
  final String code; // e.g. "US", "JP", "IN", "GB", "AE"
  final double centerLat;
  final double centerLon;
  final double zoomLevel;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.centerLat,
    required this.centerLon,
    required this.zoomLevel,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  static const List<CountryInfo> presets = [
    CountryInfo(
      name: 'United States',
      code: 'US',
      centerLat: 38.0,
      centerLon: -97.0,
      zoomLevel: 1.2,
      minLat: 24.0,
      maxLat: 50.0,
      minLon: -125.0,
      maxLon: -66.0,
    ),
    CountryInfo(
      name: 'Japan',
      code: 'JP',
      centerLat: 36.0,
      centerLon: 138.0,
      zoomLevel: 1.8,
      minLat: 30.0,
      maxLat: 45.0,
      minLon: 128.0,
      maxLon: 146.0,
    ),
    CountryInfo(
      name: 'India',
      code: 'IN',
      centerLat: 20.5,
      centerLon: 78.9,
      zoomLevel: 1.5,
      minLat: 8.0,
      maxLat: 37.0,
      minLon: 68.0,
      maxLon: 97.0,
    ),
    CountryInfo(
      name: 'United Kingdom',
      code: 'GB',
      centerLat: 54.0,
      centerLon: -2.0,
      zoomLevel: 2.2,
      minLat: 50.0,
      maxLat: 59.0,
      minLon: -8.0,
      maxLon: 2.0,
    ),
    CountryInfo(
      name: 'United Arab Emirates',
      code: 'AE',
      centerLat: 24.0,
      centerLon: 54.0,
      zoomLevel: 2.5,
      minLat: 22.0,
      maxLat: 26.5,
      minLon: 51.0,
      maxLon: 56.5,
    ),
    CountryInfo(
      name: 'France',
      code: 'FR',
      centerLat: 46.5,
      centerLon: 2.5,
      zoomLevel: 2.0,
      minLat: 41.0,
      maxLat: 51.0,
      minLon: -5.0,
      maxLon: 9.5,
    ),
    CountryInfo(
      name: 'Germany',
      code: 'DE',
      centerLat: 51.0,
      centerLon: 10.0,
      zoomLevel: 2.2,
      minLat: 47.0,
      maxLat: 55.0,
      minLon: 5.5,
      maxLon: 15.0,
    ),
    CountryInfo(
      name: 'Singapore',
      code: 'SG',
      centerLat: 1.35,
      centerLon: 103.8,
      zoomLevel: 3.5,
      minLat: 1.1,
      maxLat: 1.5,
      minLon: 103.5,
      maxLon: 104.1,
    ),
    CountryInfo(
      name: 'Australia',
      code: 'AU',
      centerLat: -25.0,
      centerLon: 133.0,
      zoomLevel: 1.2,
      minLat: -44.0,
      maxLat: -10.0,
      minLon: 112.0,
      maxLon: 154.0,
    ),
  ];
}
