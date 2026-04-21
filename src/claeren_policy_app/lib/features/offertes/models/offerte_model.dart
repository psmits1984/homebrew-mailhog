class OfferteModel {
  final String id;
  final String entityId;
  final String referentie;
  final String omschrijving;
  final RelatieType relatieType;
  final OfferteStatus status;
  final String productType;
  final String dekking;
  final double jaarPremie;
  final DateTime ingangsdatum;
  final DateTime geldigTot;
  final DateTime aangemaaktOp;
  final String? kvkNummer;
  final String? contactpersoonEmail;

  const OfferteModel({
    required this.id,
    required this.entityId,
    required this.referentie,
    required this.omschrijving,
    required this.relatieType,
    required this.status,
    required this.productType,
    required this.dekking,
    required this.jaarPremie,
    required this.ingangsdatum,
    required this.geldigTot,
    required this.aangemaaktOp,
    this.kvkNummer,
    this.contactpersoonEmail,
  });

  factory OfferteModel.fromJson(Map<String, dynamic> json) => OfferteModel(
        id: json['id'] as String,
        entityId: json['entityId'] as String,
        referentie: json['referentie'] as String,
        omschrijving: json['omschrijving'] as String,
        relatieType: RelatieType.fromString(json['relatieSoort'] as String),
        status: OfferteStatus.fromString(json['status'] as String),
        productType: json['productType'] as String,
        dekking: json['dekking'] as String,
        jaarPremie: (json['jaarPremie'] as num).toDouble(),
        ingangsdatum: DateTime.parse(json['ingangsdatum'] as String),
        geldigTot: DateTime.parse(json['geldigTot'] as String),
        aangemaaktOp: DateTime.parse(json['aangemaaktOp'] as String),
        kvkNummer: json['kvkNummer'] as String?,
        contactpersoonEmail: json['contactpersoonEmail'] as String?,
      );
}

enum OfferteStatus {
  concept,
  verzonden,
  geaccordeerd,
  geweigerd,
  getekend;

  static OfferteStatus fromString(String s) => switch (s) {
        'Concept' => concept,
        'Verzonden' => verzonden,
        'Geaccordeerd' => geaccordeerd,
        'Geweigerd' => geweigerd,
        'Getekend' => getekend,
        _ => concept,
      };

  String get label => switch (this) {
        concept => 'Concept',
        verzonden => 'Verzonden',
        geaccordeerd => 'Geaccordeerd',
        geweigerd => 'Geweigerd',
        getekend => 'Getekend',
      };

  bool get isNieuw => this == verzonden;
  bool get isAfgerond =>
      this == geaccordeerd || this == geweigerd || this == getekend;
}

enum RelatieType {
  zakelijk,
  particulier;

  static RelatieType fromString(String s) => switch (s) {
        'Zakelijk' => zakelijk,
        _ => particulier,
      };

  String get label => switch (this) {
        zakelijk => 'Zakelijk',
        particulier => 'Particulier',
      };
}
