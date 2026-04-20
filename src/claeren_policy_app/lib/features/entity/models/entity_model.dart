class EntityModel {
  final String id;
  final String naam;
  final String kvkNummer;
  final EntityType type;
  final String? hoedanigheid;
  final String? branche;
  final String? adres;
  final String? postcode;
  final String? woonplaats;
  final String? email;
  final String? telefoon;
  final DateTime? geboortedatum;

  const EntityModel({
    required this.id,
    required this.naam,
    required this.kvkNummer,
    required this.type,
    this.hoedanigheid,
    this.branche,
    this.adres,
    this.postcode,
    this.woonplaats,
    this.email,
    this.telefoon,
    this.geboortedatum,
  });

  factory EntityModel.fromJson(Map<String, dynamic> json) => EntityModel(
        id: json['id'] as String,
        naam: json['naam'] as String,
        kvkNummer: json['kvkNummer'] as String,
        type: json['type'] == 'Zakelijk' ? EntityType.zakelijk : EntityType.particulier,
        hoedanigheid: json['hoedanigheid'] as String?,
        branche: json['branche'] as String?,
        adres: json['adres'] as String?,
        postcode: json['postcode'] as String?,
        woonplaats: json['woonplaats'] as String?,
        email: json['email'] as String?,
        telefoon: json['telefoon'] as String?,
        geboortedatum: json['geboortedatum'] != null
            ? DateTime.parse(json['geboortedatum'] as String)
            : null,
      );
}

enum EntityType { particulier, zakelijk }
