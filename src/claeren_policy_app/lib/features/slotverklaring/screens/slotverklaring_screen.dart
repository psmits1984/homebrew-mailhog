import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class SlotverklaringScreen extends ConsumerStatefulWidget {
  final String offerteId;
  final String entityId;

  const SlotverklaringScreen({
    super.key,
    required this.offerteId,
    required this.entityId,
  });

  @override
  ConsumerState<SlotverklaringScreen> createState() =>
      _SlotverklaringScreenState();
}

class _SlotverklaringScreenState
    extends ConsumerState<SlotverklaringScreen> {
  // Step 1 = verklaring lezen + OTP versturen
  // Step 2 = OTP invoeren + ondertekenen
  int _step = 1;
  bool _loading = false;
  String? _slotverklaringId;
  DateTime? _otpVerlooptOp;
  String? _otpEmail;
  String? _otpMock; // Only for testing; never show in prod

  final _otpCtrl = TextEditingController();
  bool _hasSig = false;
  String? _otpError;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verstuurOtp() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        ApiConstants.slotverklaringOtp(widget.offerteId),
        data: {'entityId': widget.entityId},
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _slotverklaringId = data['slotverklaringId'] as String?;
        _otpEmail = data['email'] as String?;
        _otpVerlooptOp = data['otpVerlooptOp'] != null
            ? DateTime.parse(data['otpVerlooptOp'] as String)
            : null;
        _otpMock = data['otpMock'] as String?; // dev only
        _step = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kon OTP niet versturen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ondertekenen() async {
    if (_otpCtrl.text.trim().isEmpty) {
      setState(() => _otpError = 'Voer de verificatiecode in');
      return;
    }
    if (!_hasSig) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voeg uw handtekening toe')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _otpError = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        ApiConstants.slotverklaringOndertekenen(widget.offerteId),
        data: {
          'entityId': widget.entityId,
          'otpCode': _otpCtrl.text.trim(),
        },
      );
      final data = res.data as Map<String, dynamic>;

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _AuditDialog(
            offerteId: widget.offerteId,
            tijdstempel: data['ondertekeningTijdstempel'] != null
                ? DateTime.parse(
                    data['ondertekeningTijdstempel'] as String)
                : DateTime.now(),
            ipAdres: data['ipAdres'] as String? ?? 'onbekend',
            auditTrail: data['auditTrail'] as String? ?? '',
            hashPrefix: data['verklaringHashPrefix'] as String? ?? '',
            onClose: () {
              Navigator.pop(ctx);
              context.go('/polissen/${widget.entityId}');
            },
          ),
        );
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('400') || msg.contains('Ongeldige')) {
        setState(
            () => _otpError = 'Ongeldige verificatiecode. Probeer opnieuw.');
      } else if (msg.contains('verlopen')) {
        setState(() => _otpError =
            'OTP is verlopen. Ga terug en verstuur een nieuwe code.');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij ondertekenen: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Slotverklaring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _step == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress indicator
          _StepIndicator(currentStep: 1),
          const SizedBox(height: 20),

          const Text(
            'Verklaring',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Slotverklaring',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ondergetekende verklaart hierbij:\n\n'
                  '1. De in de offerte (referentie: ${widget.offerteId}) '
                  'vermelde gegevens zijn naar waarheid ingevuld.\n\n'
                  '2. Ondergetekende heeft kennis genomen van en gaat akkoord '
                  'met de van toepassing zijnde polisvoorwaarden en '
                  'algemene verzekeringsvoorwaarden.\n\n'
                  '3. De opgegeven informatie is volledig en correct. '
                  'Eventuele verzwijging van relevante informatie kan leiden '
                  'tot nietigheid van de verzekering.\n\n'
                  '4. Ondergetekende machtigt Claeren tot verwerking van de '
                  'persoonsgegevens conform de AVG.',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                const Text(
                  'Door uw handtekening te plaatsen in de volgende stap '
                  'bevestigt u bovenstaande verklaring. De ondertekening '
                  'wordt vastgelegd als eenvoudige elektronische handtekening '
                  '(eEH) conform eIDAS Artikel 3(10).',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Een eenmalige verificatiecode wordt verstuurd naar '
                    'uw e-mailadres ter bevestiging van uw identiteit.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _loading ? null : _verstuurOtp,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Verificatiecode versturen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );

  Widget _buildStep2() {
    final timeFormat = DateFormat("HH:mm");
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepIndicator(currentStep: 2),
        const SizedBox(height: 20),

        if (_otpEmail != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Code verstuurd naar $_otpEmail'
                    '${_otpVerlooptOp != null ? '\nGeldig tot ${timeFormat.format(_otpVerlooptOp!.toLocal())}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Dev-only OTP hint
        if (_otpMock != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_mode,
                    color: Colors.purple, size: 16),
                const SizedBox(width: 8),
                Text(
                  'DEV – OTP: $_otpMock',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.purple,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        const Text(
          'Verificatiecode',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        // OTP input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _otpError != null
                      ? AppColors.error
                      : AppColors.divider,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme:
                            const InputDecorationTheme(filled: false),
                      ),
                      child: TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (_) =>
                            setState(() => _otpError = null),
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: '000000',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                        ),
                        buildCounter: (_, {required currentLength,
                            required isFocused,
                            required maxLength}) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_otpError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_otpError!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          'Handtekening',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Teken hieronder ter bevestiging van de slotverklaring.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        _SignaturePad(
            onChanged: (has) => setState(() => _hasSig = has)),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed:
              _loading ? null : _ondertekenen,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.draw_outlined),
          label: const Text('Slotverklaring ondertekenen'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: _loading ? null : () => setState(() => _step = 1),
          child: const Text('Nieuwe verificatiecode aanvragen',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Step(number: 1, label: 'Verklaring', active: currentStep == 1,
              done: currentStep > 1),
          Expanded(
            child: Container(
              height: 2,
              color: currentStep >= 2
                  ? AppColors.primary
                  : AppColors.divider,
            ),
          ),
          _Step(number: 2, label: 'Ondertekenen', active: currentStep == 2,
              done: false),
        ],
      );
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool done;

  const _Step(
      {required this.number,
      required this.label,
      required this.active,
      required this.done});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active || done
                  ? AppColors.primary
                  : AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color:
                  active ? AppColors.primary : AppColors.textSecondary,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
}

// ─── Audit trail dialog ───────────────────────────────────────────────────────

class _AuditDialog extends StatelessWidget {
  final String offerteId;
  final DateTime tijdstempel;
  final String ipAdres;
  final String auditTrail;
  final String hashPrefix;
  final VoidCallback onClose;

  const _AuditDialog({
    required this.offerteId,
    required this.tijdstempel,
    required this.ipAdres,
    required this.auditTrail,
    required this.hashPrefix,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat =
        DateFormat("dd-MM-yyyy 'om' HH:mm:ss", 'nl_NL');

    return AlertDialog(
      icon: const Icon(Icons.verified_outlined,
          color: AppColors.success, size: 52),
      title: const Text('Slotverklaring ondertekend'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'De slotverklaring voor offerte $offerteId is '
              'succesvol ondertekend.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const _DialogSection('Audittrail'),
            _InfoRow('Tijdstempel',
                dateFormat.format(tijdstempel.toLocal())),
            _InfoRow('IP-adres', ipAdres),
            _InfoRow('Offerte', offerteId),
            _InfoRow('Hash', '$hashPrefix...'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    AppColors.success.withValues(alpha: 0.08),
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
                      'handtekening (eEH) conform eIDAS Art. 3(10).',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.success),
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
  const _DialogSection(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
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

// ─── Signature pad ────────────────────────────────────────────────────────────

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
