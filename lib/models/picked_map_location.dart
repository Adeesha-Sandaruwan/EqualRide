// Holds the coordinates and address picked on the map.
// Carries a chosen point and its readable address.
class PickedMapLocation {
  const PickedMapLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}
