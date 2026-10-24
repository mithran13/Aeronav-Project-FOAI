import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum TileProviderType {
  googleRoadmap,   // Clear Google Street / Roadmap View (lyrs=m)
  openStreetMap,   // Clear Standard OpenStreetMap Street View
  esriStreetMap,   // Clear Esri World Street View
  cartoDbLight,    // Clear Light Vector Street View
  googleHybrid,    // Google Hybrid Satellite
  cartoDbDark,     // Dark Vector Map
}

class TileCoord {
  final int x;
  final int y;
  final int z;

  const TileCoord(this.x, this.y, this.z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoord && runtimeType == other.runtimeType && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}

class RealTileEngine {
  static final Map<String, ui.Image> _tileCache = {};
  static final Map<String, Completer<ui.Image>> _loadingTiles = {};

  // Get tile URL based on provider type
  static String getTileUrl(TileCoord coord, TileProviderType type) {
    int z = coord.z.clamp(0, 19);
    int maxTiles = 1 << z;
    int x = (coord.x % maxTiles + maxTiles) % maxTiles;
    int y = coord.y.clamp(0, maxTiles - 1);

    switch (type) {
      case TileProviderType.googleRoadmap:
        return 'https://mt1.google.com/vt/lyrs=m&x=$x&y=$y&z=$z';
      case TileProviderType.openStreetMap:
        return 'https://a.tile.openstreetmap.org/$z/$x/$y.png';
      case TileProviderType.esriStreetMap:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/$z/$y/$x';
      case TileProviderType.cartoDbLight:
        return 'https://a.basemaps.cartocdn.com/light_all/$z/$x/$y.png';
      case TileProviderType.googleHybrid:
        return 'https://mt1.google.com/vt/lyrs=y&x=$x&y=$y&z=$z';
      case TileProviderType.cartoDbDark:
        return 'https://a.basemaps.cartocdn.com/dark_all/$z/$x/$y.png';
    }
  }

  // Convert Latitude / Longitude to Normalized Mercator Offset (0.0 to 1.0)
  static Offset latLonToMercator(double lat, double lon) {
    double x = (lon + 180.0) / 360.0;
    double sinLat = sin(lat * pi / 180.0);
    sinLat = sinLat.clamp(-0.9999, 0.9999);
    double y = 0.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * pi);
    return Offset(x, y);
  }

  // Convert Latitude / Longitude to Web Mercator Tile Coordinate
  static TileCoord latLonToTile(double lat, double lon, int zoom) {
    int z = zoom.clamp(0, 19);
    double latRad = lat * (pi / 180.0);
    int x = ((lon + 180.0) / 360.0 * (1 << z)).floor();
    int y = ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * (1 << z)).floor();
    return TileCoord(x, y, z);
  }

  // Convert Tile Coordinate to Latitude / Longitude of Top-Left corner
  static Offset tileToLatLon(int x, int y, int zoom) {
    int n = 1 << zoom;
    double lon = x / n * 360.0 - 180.0;
    double latRad = atan(sinh(pi * (1 - 2 * y / n)));
    double lat = latRad * 180.0 / pi;
    return Offset(lat, lon);
  }

  static double sinh(double x) => (exp(x) - exp(-x)) / 2.0;

  // Load and cache real satellite tile image
  static Future<ui.Image?> loadTile(TileCoord coord, TileProviderType type) async {
    String key = '${type.name}_${coord.z}_${coord.x}_${coord.y}';

    if (_tileCache.containsKey(key)) {
      return _tileCache[key];
    }

    if (_loadingTiles.containsKey(key)) {
      return _loadingTiles[key]!.future;
    }

    final completer = Completer<ui.Image>();
    _loadingTiles[key] = completer;

    try {
      String url = getTileUrl(coord, type);
      final ImageStream stream = NetworkImage(url).resolve(ImageConfiguration.empty);
      ImageStreamListener? listener;

      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          _tileCache[key] = info.image;
          _loadingTiles.remove(key);
          if (!completer.isCompleted) completer.complete(info.image);
          if (listener != null) stream.removeListener(listener);
        },
        onError: (dynamic error, StackTrace? stackTrace) {
          _loadingTiles.remove(key);
          if (!completer.isCompleted) completer.completeError(error);
          if (listener != null) stream.removeListener(listener);
        },
      );

      stream.addListener(listener);
      return completer.future;
    } catch (e) {
      _loadingTiles.remove(key);
      return null;
    }
  }

  static ui.Image? getCachedTile(TileCoord coord, TileProviderType type) {
    String key = '${type.name}_${coord.z}_${coord.x}_${coord.y}';
    return _tileCache[key];
  }
}
