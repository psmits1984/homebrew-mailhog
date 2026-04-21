class MachtigingBevestiging {
  final String mandaatReferentie;
  final String mandaatType;
  final String iban;
  final String? polisNummer;
  final DateTime tijdstempel;
  final String ipAdres;
  final String bevestigingsEmail;

  const MachtigingBevestiging({
    required this.mandaatReferentie,
    required this.mandaatType,
    required this.iban,
    this.polisNummer,
    required this.tijdstempel,
    required this.ipAdres,
    required this.bevestigingsEmail,
  });

  factory MachtigingBevestiging.fromJson(Map<String, dynamic> json) =>
      MachtigingBevestiging(
        mandaatReferentie: json['mandaatReferentie'] as String,
        mandaatType:       json['mandaatType'] as String,
        iban:              json['iban'] as String,
        polisNummer:       json['polisNummer'] as String?,
        tijdstempel:       DateTime.parse(json['tijdstempel'] as String),
        ipAdres:           json['ipAdres'] as String,
        bevestigingsEmail: json['bevestigingsEmail'] as String,
      );
}
