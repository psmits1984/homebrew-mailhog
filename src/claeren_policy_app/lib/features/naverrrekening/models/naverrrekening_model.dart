class NaverrekenUitvraag {
  final String uitvraagId;
  final String polisNummer;
  final String omschrijving;
  final int jaar;
  final DateTime deadline;
  final List<NaverrekenVraag> vragen;

  const NaverrekenUitvraag({
    required this.uitvraagId,
    required this.polisNummer,
    required this.omschrijving,
    required this.jaar,
    required this.deadline,
    required this.vragen,
  });

  factory NaverrekenUitvraag.fromJson(Map<String, dynamic> json) => NaverrekenUitvraag(
        uitvraagId: json['uitvraagId'] as String,
        polisNummer: json['polisNummer'] as String,
        omschrijving: json['omschrijving'] as String,
        jaar: json['jaar'] as int,
        deadline: DateTime.parse(json['deadline'] as String),
        vragen: (json['vragen'] as List)
            .map((v) => NaverrekenVraag.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class NaverrekenVraag {
  final String vraagId;
  final String vraag;
  final String type;
  final bool verplicht;
  final List<String>? opties;

  const NaverrekenVraag({
    required this.vraagId,
    required this.vraag,
    required this.type,
    required this.verplicht,
    this.opties,
  });

  factory NaverrekenVraag.fromJson(Map<String, dynamic> json) => NaverrekenVraag(
        vraagId: json['vraagId'] as String,
        vraag: json['vraag'] as String,
        type: json['type'] as String,
        verplicht: json['verplicht'] as bool,
        opties: json['opties'] != null
            ? (json['opties'] as List).map((o) => o as String).toList()
            : null,
      );
}
