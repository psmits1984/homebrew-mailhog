class EntityModel {
  final String id;
  final String naam;
  final String kvkNummer;
  final EntityType type;

  const EntityModel({
    required this.id,
    required this.naam,
    required this.kvkNummer,
    required this.type,
  });

  factory EntityModel.fromJson(Map<String, dynamic> json) => EntityModel(
        id: json['id'] as String,
        naam: json['naam'] as String,
        kvkNummer: json['kvkNummer'] as String,
        type: json['type'] == 'Zakelijk' ? EntityType.zakelijk : EntityType.particulier,
      );
}

enum EntityType { particulier, zakelijk }
