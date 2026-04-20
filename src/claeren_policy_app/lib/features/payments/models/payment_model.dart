class PaymentModel {
  final String id;
  final String entityId;
  final String polisNummer;
  final String omschrijvingPolis;
  final DateTime datum;
  final double bedrag;
  final PaymentStatus status;
  final String factuurNummer;

  const PaymentModel({
    required this.id,
    required this.entityId,
    required this.polisNummer,
    required this.omschrijvingPolis,
    required this.datum,
    required this.bedrag,
    required this.status,
    required this.factuurNummer,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        entityId: json['entityId'] as String,
        polisNummer: json['polisNummer'] as String,
        omschrijvingPolis: json['omschrijvingPolis'] as String,
        datum: DateTime.parse(json['datum'] as String),
        bedrag: (json['bedrag'] as num).toDouble(),
        status: PaymentStatus.fromString(json['status'] as String),
        factuurNummer: json['factuurNummer'] as String,
      );
}

enum PaymentStatus {
  betaald,
  openstaand,
  mislukt;

  static PaymentStatus fromString(String s) => switch (s) {
        'Openstaand' => openstaand,
        'Mislukt' => mislukt,
        _ => betaald,
      };

  String get label => switch (this) {
        betaald => 'Betaald',
        openstaand => 'Openstaand',
        mislukt => 'Mislukt',
      };
}
