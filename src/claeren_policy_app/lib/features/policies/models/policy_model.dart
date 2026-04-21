class PolicyModel {
  final String polisNummer;
  final String omschrijving;
  final String maatschappij;
  final PolicyStatus status;
  final double jaarPremie;
  final DateTime ingangsdatum;
  final DateTime vervaldatum;
  final String productCode;
  final String entityId;
  final bool automatischIncasso;

  const PolicyModel({
    required this.polisNummer,
    required this.omschrijving,
    required this.maatschappij,
    required this.status,
    required this.jaarPremie,
    required this.ingangsdatum,
    required this.vervaldatum,
    required this.productCode,
    required this.entityId,
    this.automatischIncasso = false,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) => PolicyModel(
        polisNummer: json['polisNummer'] as String,
        omschrijving: json['omschrijving'] as String,
        maatschappij: json['maatschappij'] as String,
        status: PolicyStatus.fromString(json['status'] as String),
        jaarPremie: (json['jaarPremie'] as num).toDouble(),
        ingangsdatum: DateTime.parse(json['ingangsdatum'] as String),
        vervaldatum: DateTime.parse(json['vervaldatum'] as String),
        productCode: json['productCode'] as String,
        entityId: json['entityId'] as String,
        automatischIncasso: json['automatischIncasso'] as bool? ?? false,
      );
}

enum PolicyStatus {
  actief,
  geroyeerd,
  geschorst,
  inAanvraag;

  static PolicyStatus fromString(String s) => switch (s) {
        'Geroyeerd' => geroyeerd,
        'Geschorst' => geschorst,
        'InAanvraag' => inAanvraag,
        _ => actief,
      };

  String get label => switch (this) {
        actief => 'Actief',
        geroyeerd => 'Geroyeerd',
        geschorst => 'Geschorst',
        inAanvraag => 'In aanvraag',
      };
}

class PolicyDetailModel extends PolicyModel {
  final double eigenRisico;
  final List<Dekking> dekkingen;
  final List<PolisDocument> documenten;
  final List<PolisHistorie> historie;

  const PolicyDetailModel({
    required super.polisNummer,
    required super.omschrijving,
    required super.maatschappij,
    required super.status,
    required super.jaarPremie,
    required super.ingangsdatum,
    required super.vervaldatum,
    required super.productCode,
    required super.entityId,
    super.automatischIncasso,
    required this.eigenRisico,
    required this.dekkingen,
    required this.documenten,
    required this.historie,
  });

  factory PolicyDetailModel.fromJson(Map<String, dynamic> json) {
    final base = PolicyModel.fromJson(json);
    return PolicyDetailModel(
      polisNummer: base.polisNummer,
      omschrijving: base.omschrijving,
      maatschappij: base.maatschappij,
      status: base.status,
      jaarPremie: base.jaarPremie,
      ingangsdatum: base.ingangsdatum,
      vervaldatum: base.vervaldatum,
      productCode: base.productCode,
      entityId: base.entityId,
      automatischIncasso: base.automatischIncasso,
      eigenRisico: (json['eigenRisico'] as num).toDouble(),
      dekkingen: (json['dekkingen'] as List)
          .map((d) => Dekking.fromJson(d as Map<String, dynamic>))
          .toList(),
      documenten: (json['documenten'] as List)
          .map((d) => PolisDocument.fromJson(d as Map<String, dynamic>))
          .toList(),
      historie: (json['historie'] as List)
          .map((h) => PolisHistorie.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Dekking {
  final String code;
  final String omschrijving;
  final double? bedrag;

  const Dekking({required this.code, required this.omschrijving, this.bedrag});

  factory Dekking.fromJson(Map<String, dynamic> json) => Dekking(
        code: json['code'] as String,
        omschrijving: json['omschrijving'] as String,
        bedrag: json['bedrag'] != null ? (json['bedrag'] as num).toDouble() : null,
      );
}

class PolisDocument {
  final String documentId;
  final String naam;
  final String type;
  final DateTime datum;
  final String downloadUrl;

  const PolisDocument({
    required this.documentId,
    required this.naam,
    required this.type,
    required this.datum,
    required this.downloadUrl,
  });

  factory PolisDocument.fromJson(Map<String, dynamic> json) => PolisDocument(
        documentId: json['documentId'] as String,
        naam: json['naam'] as String,
        type: json['type'] as String,
        datum: DateTime.parse(json['datum'] as String),
        downloadUrl: json['downloadUrl'] as String,
      );
}

class PolisHistorie {
  final DateTime datum;
  final String omschrijving;
  final double? oudePremie;
  final double? nieuwePremie;

  const PolisHistorie({
    required this.datum,
    required this.omschrijving,
    this.oudePremie,
    this.nieuwePremie,
  });

  factory PolisHistorie.fromJson(Map<String, dynamic> json) => PolisHistorie(
        datum: DateTime.parse(json['datum'] as String),
        omschrijving: json['omschrijving'] as String,
        oudePremie: json['oudePremie'] != null ? (json['oudePremie'] as num).toDouble() : null,
        nieuwePremie: json['nieuwePremie'] != null ? (json['nieuwePremie'] as num).toDouble() : null,
      );
}
