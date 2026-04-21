import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SepaMandateScreen extends StatefulWidget {
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
  State<SepaMandateScreen> createState() => _SepaMandateScreenState();
}

class _SepaMandateScreenState extends State<SepaMandateScreen> {
  final _ibanCtrl = TextEditingController();
  final _naamCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _mandaatType = 'Doorlopend';
  bool _hasSig = false;
  bool _loading = false;
  String? _ibanError;
  String? _naamError;
  String? _emailError;

  String get _mandaatRef =>
      'MAND-${widget.entityId}-${DateTime.now().year}';

  bool get _canSubmit =>
      _ibanCtrl.text.replaceAll(' ', '').length >= 15 &&
      _naamCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.contains('@') &&
      _hasSig;

  bool _validate() {
    setState(() {
      _ibanError = _ibanCtrl.text.replaceAll(' ', '').length < 15
          ? 'Voer een geldig IBAN in'
          : null;
      _naamError = _naamCtrl.text.trim().isEmpty ? 'Voer de naam in' : null;
      _emailError = !_emailCtrl.text.contains('@')
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
    if (!_validate()) return;
    if (!_hasSig) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voeg uw handtekening toe')),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 52),
        title: const Text('Machtiging ontvangen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uw SEPA-incassomachtiging is succesvol verwerkt.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            _InfoRow(label: 'Referentie', value: _mandaatRef),
            _InfoRow(label: 'Type', value: _mandaatType),
            _InfoRow(label: 'IBAN', value: _ibanCtrl.text),
            if (widget.polisNummer != null)
              _InfoRow(label: 'Polis', value: widget.polisNummer!),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Sluiten'),
          ),
        ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.polisNummer != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                                  fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            widget.polisOmschrijving ?? widget.polisNummer!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(widget.polisNummer!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            _SectionHeader(title: 'Bankgegevens', icon: Icons.account_balance_outlined),
            const SizedBox(height: 12),
            _StyledField(
              controller: _ibanCtrl,
              label: 'IBAN',
              hint: 'NL00 AAAA 0000 0000 00',
              icon: Icons.credit_card_outlined,
              error: _ibanError,
              formatters: [_IbanFormatter()],
              keyboardType: TextInputType.text,
              capitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _StyledField(
              controller: _naamCtrl,
              label: 'Naam rekeninghouder',
              icon: Icons.person_outlined,
              error: _naamError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Contactgegevens', icon: Icons.mail_outlined),
            const SizedBox(height: 12),
            _StyledField(
              controller: _emailCtrl,
              label: 'E-mailadres voor bevestiging',
              icon: Icons.email_outlined,
              error: _emailError,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Mandaattype', icon: Icons.repeat_outlined),
            const SizedBox(height: 12),
            _ToggleRow(
              options: const ['Doorlopend', 'Eenmalig'],
              selected: _mandaatType,
              onChanged: (v) => setState(() => _mandaatType = v),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Machtiging details', icon: Icons.info_outlined),
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
                  _InfoRow(label: 'Schuldeiser ID', value: 'NL13ZZZ123456780000'),
                  _InfoRow(label: 'Mandaatreferentie', value: _mandaatRef),
                  _InfoRow(label: 'Mandaattype', value: _mandaatType),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Uw handtekening', icon: Icons.draw_outlined),
            const SizedBox(height: 6),
            const Text(
              'Teken hieronder ter bevestiging van de machtiging.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            _SignaturePad(onChanged: (has) => setState(() => _hasSig = has)),
            const SizedBox(height: 20),

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
                  Icon(Icons.info_outlined, color: AppColors.warning, size: 16),
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
      ),
    );
  }
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

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final String? error;
  final List<TextInputFormatter>? formatters;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  const _StyledField({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.error,
    this.formatters,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: capitalization,
                  inputFormatters: formatters,
                  onChanged: onChanged,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: hint ?? label,
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!,
              style: const TextStyle(
                  color: AppColors.error, fontSize: 12)),
        ],
      ],
    );
  }
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
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
              border: Border.all(color: AppColors.divider, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
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
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
