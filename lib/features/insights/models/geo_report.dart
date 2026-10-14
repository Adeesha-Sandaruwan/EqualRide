import '../../../models/community_report.dart';

/// A latitude/longitude pair. Kept local to the insights feature so it does
/// not depend on map package types.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// How a report's location text was turned into coordinates.
enum GeoSource { coordinates, gazetteer, geocoded, unresolved }

/// A community report paired with its resolved map position, if any.
class GeoReport {
  const GeoReport({
    required this.report,
    required this.point,
    required this.source,
  });

  final CommunityReport report;
  final GeoPoint? point;
  final GeoSource source;

  bool get isMapped => point != null;
}
