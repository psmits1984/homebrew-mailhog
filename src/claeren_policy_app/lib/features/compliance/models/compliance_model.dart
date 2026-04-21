class ComplianceResult {
  final String id;
  final String entityId;
  final String offerteId;
  final String relatieSoort;
  final ComplianceStatus status;
  final String? vnabReferentie;
  final DateTime tijdstempel;
  final String? bevindingen;

  const ComplianceResult({
    required this.id,
    required this.entityId,
    required this.offerteId,
    required this.relatieSoort,
    required this.status,
    this.vnabReferentie,
    required this.tijdstempel,
    this.bevindingen,
  });

  factory ComplianceResult.fromJson(Map<String, dynamic> json) => ComplianceResult(
        id: json['id'] as String,
        entityId: json['entityId'] as String,
        offerteId: json['offerteId'] as String,
        relatieSoort: json['relatieSoort'] as String,
        status: ComplianceStatus.fromString(json['status'] as String),
        vnabReferentie: json['vnabReferentie'] as String?,
        tijdstempel: DateTime.parse(json['tijdstempel'] as String),
        bevindingen: json['bevindingen'] as String?,
      );
}

enum ComplianceStatus {
  goedgekeurd,
  afgewezen,
  handmatigVereist,
  inBehandeling;

  static ComplianceStatus fromString(String s) => switch (s) {
        'Goedgekeurd' => goedgekeurd,
        'Afgewezen' => afgewezen,
        'HandmatigVereist' => handmatigVereist,
        'InBehandeling' => inBehandeling,
        _ => inBehandeling,
      };

  String get label => switch (this) {
        goedgekeurd => 'Goedgekeurd',
        afgewezen => 'Afgewezen',
        handmatigVereist => 'Handmatige beoordeling vereist',
        inBehandeling => 'In behandeling',
      };
}
