import '/core/utils/json_utils.dart';

/// Local emergency numbers, which vary per country and are exactly the thing
/// travellers need when they cannot get online.
class EmergencyContactsModel {
  final String police;
  final String ambulance;
  final String notes;

  const EmergencyContactsModel({
    required this.police,
    required this.ambulance,
    required this.notes,
  });

  factory EmergencyContactsModel.fromJson(Map<String, dynamic> json) =>
      EmergencyContactsModel(
        police: jsonString(json['police']),
        ambulance: jsonString(json['ambulance']),
        notes: jsonString(json['notes']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'police': police,
    'ambulance': ambulance,
    'notes': notes,
  };

  factory EmergencyContactsModel.empty() =>
      const EmergencyContactsModel(police: '', ambulance: '', notes: '');

  bool get hasContent => police.isNotEmpty || ambulance.isNotEmpty;
}

/// The "local tips" section: the advice an API cannot give you.
class LocalTipsModel {
  final List<String> currency;
  final List<String> tipping;
  final List<String> scams;
  final List<String> transport;
  final List<String> etiquette;
  final EmergencyContactsModel emergency;

  const LocalTipsModel({
    required this.currency,
    required this.tipping,
    required this.scams,
    required this.transport,
    required this.etiquette,
    required this.emergency,
  });

  factory LocalTipsModel.fromJson(Map<String, dynamic> json) => LocalTipsModel(
    currency: jsonStringList(json['currency']),
    tipping: jsonStringList(json['tipping']),
    scams: jsonStringList(json['scams']),
    transport: jsonStringList(json['transport']),
    etiquette: jsonStringList(json['etiquette']),
    emergency: EmergencyContactsModel.fromJson(jsonMap(json['emergency'])),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'tipping': tipping,
    'scams': scams,
    'transport': transport,
    'etiquette': etiquette,
    'emergency': emergency.toJson(),
  };

  factory LocalTipsModel.empty() => LocalTipsModel(
    currency: const <String>[],
    tipping: const <String>[],
    scams: const <String>[],
    transport: const <String>[],
    etiquette: const <String>[],
    emergency: EmergencyContactsModel.empty(),
  );

  int get totalTips =>
      currency.length +
      tipping.length +
      scams.length +
      transport.length +
      etiquette.length;

  bool get hasContent => totalTips > 0 || emergency.hasContent;
}
