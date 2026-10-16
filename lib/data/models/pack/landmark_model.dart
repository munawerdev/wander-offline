import '/core/utils/json_utils.dart';

/// A single hand-picked place inside a country pack.
///
/// [whyVisit] is editorial (written by hand, opinionated) while [description]
/// carries factual context. Keeping them separate is deliberate: the
/// editorial voice is the reason someone pays for a pack instead of opening a
/// search engine.
class LandmarkModel {
  final String id;
  final String name;
  final String city;
  final String category;
  final double latitude;
  final double longitude;
  final String whyVisit;
  final String description;
  final String bestTime;
  final String entryFee;
  final String tip;

  const LandmarkModel({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.whyVisit,
    required this.description,
    required this.bestTime,
    required this.entryFee,
    required this.tip,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) => LandmarkModel(
    id: jsonString(json['id']),
    name: jsonString(json['name']),
    city: jsonString(json['city']),
    category: jsonString(json['category'], fallback: 'monument'),
    latitude: jsonDouble(json['latitude']),
    longitude: jsonDouble(json['longitude']),
    whyVisit: jsonString(json['whyVisit']),
    description: jsonString(json['description']),
    bestTime: jsonString(json['bestTime']),
    entryFee: jsonString(json['entryFee']),
    tip: jsonString(json['tip']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'city': city,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'whyVisit': whyVisit,
    'description': description,
    'bestTime': bestTime,
    'entryFee': entryFee,
    'tip': tip,
  };

  /// Stable key for the offline schematic map and for list diffs.
  String get mapKey => id.isEmpty ? '$name@$latitude,$longitude' : id;

  /// `18th-century palace` style label derived from the category slug.
  String get categoryLabel {
    if (category.isEmpty) return 'Place';
    return category
        .split(RegExp(r'[-_\s]+'))
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  bool get hasCoordinates => latitude != 0 || longitude != 0;
}
