class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.name,
    required this.address,
  });

  final String id;
  final String name;
  final String address;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
    };
  }

  factory SavedLocation.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return SavedLocation(
      id: id,
      name: map['name'] as String? ?? 'Saved location',
      address: map['address'] as String? ?? '',
    );
  }
}