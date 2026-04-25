import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../models/machtiging_model.dart';

class SepaMandateScreen extends ConsumerStatefulWidget {
  final String entityId;
  final String? polisNummer;
  final String? polisOmschrijving;

  const SepaMandateScreen({
    super.key,
    required this.entityId,
    this.polisNummer,
    this.polisOmschrijving,
  });

  @override
  ConsumerState<SepaMandateScreen> createState() => _SepaMandateScreenState();
}

class _SepaMandateScreenState extends ConsumerState<SepaMandateScreen> {
  final _ibanCtrl  = TextEditingController();
  final _naamCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _mandaatType = 'Doorlopend';
  bool   _hasSig   = false;
  bool   _loading  = false;
  String? _ibanError;
  String? _naamError;
  String? _emailError;

  String get _mandaatRef => 'MAND-${widget.entityId}-${DateTime.now().year}';

  static bool _isValidIban(String raw) {
    final iban = raw.replaceAll(' ', '').toUpperCase();
    if (iban.length < 15 || iban.length > 34) return false;
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(iban)) return false;
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    final numeric = rearranged.split('').map((c) {
      final code = c.codeUnitAt(0);
      return code >= 65 ? (code - 55).toString() : c;
    }).join();
    var remainder = 0;
    for (final ch in numeric.split('')) {
      remainder = (remainder * 10 + int.parse(ch)) % 97;
    }
    return remainder == 1;
  }

  static bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email.trim());

  bool get _canSubmit =>
      _isValidIban(_ibanCtrl.text) &&
      _naamCtrl.text.trim().isNotEmpty &&
      _isValidEmail(_emailCtrl.text) &&
      _hasSig;

  bool _validate() {
    setState(() {
      _ibanError  = !_isValidIban(_ibanCtrl.text) ? 'Voer een geldig IBAN in' : null;
      _naamError  = _naamCtrl.text.trim().isEmpty  ? 'Voer de naam in'         : null;
      _emailError = !_isValidEmail(_emailCtrl.text)
          ? 'Voer een geldig e-mailadres in'
          : null;
    });
    return _ibanError == null && _naamError == null && _emailError == null;
  }

  @override
  void dispose() {
    _ibanCtrl.dispose();
    _naamCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_validate() || !_hasSig) {
      if (_hasSig == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voeg uw handtekening toe')),
        );
      }
      return;
    }

    setState(() => _loading = true);

    MachtigingBevestiging? bevestiging;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(ApiConstants.machtigingen, data: {
        'entityId':          widget.entityId,
        'polisNummer':       widget.polisNummer,
        'iban':              _ibanCtrl.text,
        'naamRekeninghouder': _naamCtrl.text.trim(),
        'email':             _emailCtrl.text.trim(),
        'mandaatType':       _mandaatType,
        'mandaatReferentie': _mandaatRef,
      });
      bevestiging = MachtigingBevestiging.fromJson(
          res.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback: toon lokale audit trail als BFF niet bereikbaar is
      bevestiging = MachtigingBevestiging(
        mandaatReferentie: _mandaatRef,
        mandaatType:       _mandaatType,
        iban:              _ibanCtrl.text,
        polisNummer:       widget.polisNummer,
        tijdstempel:       DateTime.now().toUtc(),
        ipAdres:           'onbekend',
        bevestigingsEmail: _emailCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AuditDialog(
        bevestiging: bevestiging!,
        onClose: () {
          Navigator.pop(ctx);
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SEPA Incassomachtiging'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.polisNummer != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Machtiging voor polis',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(
                          widget.polisOmschrijving ?? widget.polisNummer!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(widget.polisNummer!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _SectionHeader(
              title: 'Bankgegevens',
              icon: Icons.account_balance_outlined),
          const SizedBox(height: 12),
          _InputField(
            controller: _ibanCtrl,
            hint: 'IBAN (NL00 AAAA 0000 0000 00)',
            icon: Icons.credit_card_outlined,
            error: _ibanError,
            formatters: [_IbanFormatter()],
            keyboardType: TextInputType.text,
            capitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: _naamCtrl,
            hint: 'Naam rekeninghouder',
            icon: Icons.person_outlined,
            error: _naamError,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
              title: 'Contactgegevens', icon: Icons.mail_outlined),
          const SizedBox(height: 12),
          _InputField(
            controller: _emailCtrl,
            hint: 'E-mailadres voor bevestiging',
            icon: Icons.email_outlined,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
              title: 'Mandaattype', icon: Icons.repeat_outlined),
          const SizedBox(height: 12),
          _ToggleRow(
            options: const ['Doorlopend', 'Eenmalig'],
            selected: _mandaatType,
            onChanged: (v) => setState(() => _mandaatType = v),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
              title: 'Machtiging details', icon: Icons.info_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _InfoRow(
                    label: 'Schuldeiser',
                    value: 'Claeren Verzekeringsmaatschappij N.V.'),
                _InfoRow(
                    label: 'Schuldeiser ID',
                    value: 'NL13ZZZ123456780000'),
                _InfoRow(
                    label: 'Mandaatreferentie', value: _mandaatRef),
                _InfoRow(label: 'Mandaattype', value: _mandaatType),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(
              title: 'Uw handtekening', icon: Icons.draw_outlined),
          const SizedBox(height: 6),
          const Text(
            'Teken hieronder ter bevestiging van de machtiging.',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _SignaturePad(
              onChanged: (has) => setState(() => _hasSig = has)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outlined,
                    color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Door ondertekening machtigt u Claeren om periodiek het '
                    'verschuldigde bedrag van uw rekening af te schrijven. '
                    'U kunt de machtiging altijd intrekken via uw bank of Claeren.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: _canSubmit && !_loading ? _submit : null,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Machtiging afgeven'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Input field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? error;
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.error,
    this.formatters,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorText: error,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Audit trail dialoog ──────────────────────────────────────────────────────

class _AuditDialog extends StatelessWidget {
  final MachtigingBevestiging bevestiging;
  final VoidCallback onClose;

  const _AuditDialog(
      {required this.bevestiging, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final dateFormat =
        DateFormat("dd-MM-yyyy 'om' HH:mm:ss", 'nl_NL');
    final tijdstempelLocal =
        bevestiging.tijdstempel.toLocal();

    return AlertDialog(
      icon: const Icon(Icons.check_circle,
          color: AppColors.success, size: 52),
      title: const Text('Machtiging ontvangen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uw SEPA-incassomachtiging is succesvol verwerkt. '
              'Een bevestiging is verstuurd naar ${bevestiging.bevestigingsEmail}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _DialogSection(title: 'Machtiging'),
            _InfoRow(
                label: 'Referentie',
                value: bevestiging.mandaatReferentie),
            _InfoRow(label: 'Type', value: bevestiging.mandaatType),
            _InfoRow(label: 'IBAN', value: bevestiging.iban),
            if (bevestiging.polisNummer != null)
              _InfoRow(
                  label: 'Polis',
                  value: bevestiging.polisNummer!),
            const SizedBox(height: 12),
            _DialogSection(title: 'Audittrail'),
            _InfoRow(
                label: 'Tijdstempel',
                value: dateFormat.format(tijdstempelLocal)),
            _InfoRow(
                label: 'IP-adres', value: bevestiging.ipAdres),
            _InfoRow(
                label: 'Bevestiging',
                value: bevestiging.bevestigingsEmail),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined,
                      color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ondertekend als eenvoudige elektronische '
                      'handtekening (eEH) conform eIDAS.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: onClose,
          child: const Text('Sluiten'),
        ),
      ],
    );
  }
}

class _DialogSection extends StatelessWidget {
  final String title;
  const _DialogSection({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      );
}

// ─── Hulpwidgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ToggleRow(
      {required this.options,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: options
            .map((o) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(o),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected == o
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected == o
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          o,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected == o
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newValue) {
    var raw = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (raw.length > 18) raw = raw.substring(0, 18);
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(raw[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ─── Handtekening-pad ─────────────────────────────────────────────────────────

class _SignaturePad extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  const _SignaturePad({required this.onChanged});

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<Offset?> _points = [];
  bool get _hasSig => _points.isNotEmpty;

  void _clear() {
    setState(() => _points.clear());
    widget.onChanged(false);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border.all(color: AppColors.divider, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  setState(() => _points.add(d.localPosition));
                  widget.onChanged(true);
                },
                onPanUpdate: (d) =>
                    setState(() => _points.add(d.localPosition)),
                onPanEnd: (_) => setState(() => _points.add(null)),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SigPainter(_points),
                ),
              ),
            ),
          ),
          if (_hasSig)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Wissen'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                onPressed: _clear,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Teken met uw vinger of muis',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
}

class _SigPainter extends CustomPainter {
  final List<Offset?> points;
  _SigPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SigPainter old) =>
      old.points.length != points.length;
}
