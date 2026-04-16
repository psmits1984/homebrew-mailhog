class ClaimModel {
  final String schadeNummer;
  final String polisNummer;
  final String omschrijving;
  final ClaimStatus status;
  final DateTime schadeDatum;
  final DateTime meldDatum;
  final double? gereserveerdBedrag;
  final double? uitgekeerdBedrag;

  const ClaimModel({
    required this.schadeNummer,
    required this.polisNummer,
    required this.omschrijving,
    required this.status,
    required this.schadeDatum,
    required this.meldDatum,
    this.gereserveerdBedrag,
    this.uitgekeerdBedrag,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) => ClaimModel(
        schadeNummer: json['schadeNummer'] as String,
        polisNummer: json['polisNummer'] as String,
        omschrijving: json['omschrijving'] as String,
        status: ClaimStatus.fromString(json['status'] as String),
        schadeDatum: DateTime.parse(json['schadeDatum'] as String),
        meldDatum: DateTime.parse(json['meldDatum'] as String),
        gereserveerdBedrag: json['gereserveerdBedrag'] != null
            ? (json['gereserveerdBedrag'] as num).toDouble()
            : null,
        uitgekeerdBedrag: json['uitgekeerdBedrag'] != null
            ? (json['uitgekeerdBedrag'] as num).toDouble()
            : null,
      );
}

enum ClaimStatus {
  inBehandeling,
  afgehandeld,
  afgewezen,
  ingediend;

  static ClaimStatus fromString(String s) => switch (s) {
        'Afgehandeld' => afgehandeld,
        'Afgewezen' => afgewezen,
        'Ingediend' => ingediend,
        _ => inBehandeling,
      };

  String get label => switch (this) {
        inBehandeling => 'In behandeling',
        afgehandeld => 'Afgehandeld',
        afgewezen => 'Afgewezen',
        ingediend => 'Ingediend',
      };
}
