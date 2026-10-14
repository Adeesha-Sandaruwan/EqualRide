import '../models/geo_report.dart';

/// Approximate coordinates for well-known Sri Lankan stations, stops and
/// towns. Used first so common report locations map instantly and offline.
/// Positions are approximate and good enough for hotspot-level mapping.
class LandmarkGazetteer {
  const LandmarkGazetteer._();

  /// Finds the landmark mentioned in [location]. When several match, the
  /// longest name wins (so "Colombo Fort" beats "Colombo"), then the one
  /// mentioned first.
  static GeoPoint? lookup(String location) {
    final text = location.toLowerCase();
    String? bestName;
    var bestIndex = 0;

    for (final name in _landmarks.keys) {
      final index = text.indexOf(name);
      if (index < 0) continue;
      if (bestName == null ||
          name.length > bestName.length ||
          (name.length == bestName.length && index < bestIndex)) {
        bestName = name;
        bestIndex = index;
      }
    }

    return bestName == null ? null : _landmarks[bestName];
  }

  static const _landmarks = <String, GeoPoint>{
    'colombo fort': GeoPoint(6.9335, 79.8500),
    'fort railway': GeoPoint(6.9335, 79.8500),
    'pettah': GeoPoint(6.9366, 79.8510),
    'maradana': GeoPoint(6.9286, 79.8643),
    'dematagoda': GeoPoint(6.9400, 79.8780),
    'borella': GeoPoint(6.9147, 79.8776),
    'slave island': GeoPoint(6.9220, 79.8560),
    'kollupitiya': GeoPoint(6.9114, 79.8493),
    'bambalapitiya': GeoPoint(6.8896, 79.8561),
    'wellawatte': GeoPoint(6.8744, 79.8603),
    'kirulapone': GeoPoint(6.8836, 79.8766),
    'dehiwala': GeoPoint(6.8514, 79.8650),
    'mount lavinia': GeoPoint(6.8389, 79.8636),
    'ratmalana': GeoPoint(6.8190, 79.8820),
    'moratuwa': GeoPoint(6.7730, 79.8816),
    'university of moratuwa': GeoPoint(6.7951, 79.9009),
    'piliyandala': GeoPoint(6.8018, 79.9227),
    'panadura': GeoPoint(6.7133, 79.9026),
    'kalutara': GeoPoint(6.5854, 79.9607),
    'aluthgama': GeoPoint(6.4333, 79.9990),
    'galle': GeoPoint(6.0329, 80.2170),
    'matara': GeoPoint(5.9549, 80.5550),
    'rajagiriya': GeoPoint(6.9094, 79.8947),
    'battaramulla': GeoPoint(6.9006, 79.9189),
    'malabe': GeoPoint(6.9066, 79.9582),
    'kaduwela': GeoPoint(6.9333, 79.9833),
    'nugegoda': GeoPoint(6.8649, 79.8997),
    'maharagama': GeoPoint(6.8480, 79.9265),
    'pannipitiya': GeoPoint(6.8454, 79.9515),
    'kottawa': GeoPoint(6.8411, 79.9660),
    'homagama': GeoPoint(6.8440, 80.0020),
    'athurugiriya': GeoPoint(6.8731, 79.9900),
    'avissawella': GeoPoint(6.9533, 80.2100),
    'kelaniya': GeoPoint(6.9553, 79.9220),
    'kadawatha': GeoPoint(7.0010, 79.9500),
    'ragama': GeoPoint(7.0278, 79.9220),
    'ja-ela': GeoPoint(7.0744, 79.8920),
    'gampaha': GeoPoint(7.0840, 79.9990),
    'veyangoda': GeoPoint(7.1500, 80.0500),
    'negombo': GeoPoint(7.2083, 79.8358),
    'katunayake': GeoPoint(7.1800, 79.8840),
    'kandy': GeoPoint(7.2906, 80.6337),
    'peradeniya': GeoPoint(7.2570, 80.5970),
    'kegalle': GeoPoint(7.2513, 80.3464),
    'polgahawela': GeoPoint(7.3333, 80.3000),
    'kurunegala': GeoPoint(7.4863, 80.3623),
    'matale': GeoPoint(7.4675, 80.6234),
    'nuwara eliya': GeoPoint(6.9497, 80.7891),
    'badulla': GeoPoint(6.9934, 81.0550),
    'ratnapura': GeoPoint(6.6828, 80.3992),
    'anuradhapura': GeoPoint(8.3114, 80.4037),
    'trincomalee': GeoPoint(8.5874, 81.2152),
    'batticaloa': GeoPoint(7.7102, 81.6924),
    'jaffna': GeoPoint(9.6615, 80.0255),
    'colombo': GeoPoint(6.9271, 79.8612),
  };
}
