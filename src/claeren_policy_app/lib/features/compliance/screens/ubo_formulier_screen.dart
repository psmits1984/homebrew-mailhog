import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../offertes/models/offerte_model.dart';
import '../../offertes/repository/offerte_repository.dart';

class UboFormulierScreen extends ConsumerStatefulWidget {
  final String offerteId;
  final String entityId;

  const UboFormulierScreen({
    super.key,
    required this.offerteId,
    required this.entityId,
  });

  @override
  ConsumerState<UboFormulierScreen> createState() =>
      _UboFormulierScreenState();
}

class _UboFormulierScreenState extends ConsumerState<UboFormulierScreen> {
  final _uboNaamCtrl = TextEditingController();
  final _nationaliteitCtrl = TextEditingController();
  final _belangCtrl = TextEditingController();
  final _herkomstCtrl = TextEditingController();
  final _activiteitenCtrl = TextEditingController();
  DateTime? _geboortedatum;
  bool _loading = false;
  RelatieType _relatieType = RelatieType.zakelijk;

  // Validation errors
  String? _naamError;
  String? _geboortedatumError;
  String? _nationaliteitError;
  String? _belangError;
  String? _herkomstError;
  String? _activiteitenError;

  @override
  void dispose() {
    _uboNaamCtrl.dispose();
    _nationaliteitCtrl.dispose();
    _belangCtrl.dispose();
    _herkomstCtrl.dispose();
    _activiteitenCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    double? belang = double.tryParse(_belangCtrl.text.replaceAll(',', '.'));
    setState(() {
      _naamError = _uboNaamCtrl.text.trim().isEmpty ? 'Naam is verplicht' : null;
      _geboortedatumError =
          _geboortedatum == null ? 'Geboortedatum is verplicht' : null;
      _nationaliteitError = _relatieType == RelatieType.zakelijk &&
              _nationaliteitCtrl.text.trim().isEmpty
          ? 'Nationaliteit is verplicht'
          : null;
      _belangError = belang == null || belang < 0 || belang > 100
          ? 'Voer een geldig percentage in (0-100)'
          : null;
      _herkomstError = _relatieType == RelatieType.zakelijk &&
              _herkomstCtrl.text.trim().isEmpty
          ? 'Herkomst van gelden is verplicht'
          : null;
      _activiteitenError = _relatieType == RelatieType.zakelijk &&
              _activiteitenCtrl.text.trim().isEmpty
          ? 'Bedrijfsactiviteiten zijn verplicht'
          : null;
    });

    return _naamError == null &&
        _geboortedatumError == null &&
        _nationaliteitError == null &&
        _belangError == null &&
        _herkomstError == null &&
        _activiteitenError == null;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
      helpText: 'Selecteer geboortedatum',
    );
    if (picked != null) {
      setState(() {
        _geboortedatum = picked;
        _geboortedatumError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(apiClientProvider);
      final belang =
          double.parse(_belangCtrl.text.replaceAll(',', '.'));

      await api.post(ApiConstants.complianceUbo, data: {
        'offerteId': widget.offerteId,
        'entityId': widget.entityId,
        'uboNaam': _uboNaamCtrl.text.trim(),
        'uboGeboortedatum':
            '${_geboortedatum!.year.toString().padLeft(4, '0')}'
            '-${_geboortedatum!.month.toString().padLeft(2, '0')}'
            '-${_geboortedatum!.day.toString().padLeft(2, '0')}',
        'uboNationaliteit': _nationaliteitCtrl.text.trim().isNotEmpty
            ? _nationaliteitCtrl.text.trim()
            : 'NL',
        'uboBelangPercentage': belang,
        'herkomstGelden': _herkomstCtrl.text.trim().isNotEmpty
            ? _herkomstCtrl.text.trim()
            : 'n.v.t.',
        'bedrijfsActiviteiten': _activiteitenCtrl.text.trim().isNotEmpty
            ? _activiteitenCtrl.text.trim()
            : 'n.v.t.',
      });

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.hourglass_top_outlined,
                color: AppColors.warning, size: 52),
            title: const Text('Formulier ingediend'),
            content: const Text(
              'Uw UBO/compliance-formulier is ontvangen en wordt '
              'beoordeeld door ons compliance-team. U ontvangt bericht '
              'zodra de beoordeling is afgerond.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/polissen/${widget.entityId}');
                },
                child: const Text('Terug naar polissen'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij indienen: $e')),
        );
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
        title: const Text('UBO / Compliance formulier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outlined,
                    color: AppColors.warning, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Op basis van de sanctiecontrole is handmatige '
                    'beoordeling vereist. Vul het onderstaande formulier '
                    'in conform de Wwft-vereisten.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Relatietype toggle
          _SectionHeader(title: 'Type relatie', icon: Icons.people_outlined),
          const SizedBox(height: 12),
          _ToggleRow(
            options: const ['Zakelijk', 'Particulier'],
            selected: _relatieType == RelatieType.zakelijk
                ? 'Zakelijk'
                : 'Particulier',
            onChanged: (v) => setState(() {
              _relatieType = v == 'Zakelijk'
                  ? RelatieType.zakelijk
                  : RelatieType.particulier;
            }),
          ),
          const SizedBox(height: 20),

          // UBO-gegevens
          _SectionHeader(
              title: 'UBO-gegevens', icon: Icons.person_outlined),
          const SizedBox(height: 12),
          _InputField(
            controller: _uboNaamCtrl,
            hint: 'Volledige naam UBO',
            icon: Icons.badge_outlined,
            error: _naamError,
            onChanged: (_) => setState(() => _naamError = null),
          ),
          const SizedBox(height: 12),

          // Geboortedatum
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _selectDate,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _geboortedatumError != null
                      ? AppColors.error
                      : AppColors.divider,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _geboortedatum != null
                          ? '${_geboortedatum!.day.toString().padLeft(2, '0')}'
                              '-${_geboortedatum!.month.toString().padLeft(2, '0')}'
                              '-${_geboortedatum!.year}'
                          : 'Geboortedatum UBO',
                      style: TextStyle(
                        color: _geboortedatum != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_geboortedatumError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(_geboortedatumError!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ),
          const SizedBox(height: 12),

          _InputField(
            controller: _nationaliteitCtrl,
            hint: 'Nationaliteit (bijv. NL, DE)',
            icon: Icons.flag_outlined,
            error: _nationaliteitError,
            onChanged: (_) => setState(() => _nationaliteitError = null),
          ),
          const SizedBox(height: 12),

          _InputField(
            controller: _belangCtrl,
            hint: 'Belang percentage (bijv. 25)',
            icon: Icons.percent,
            error: _belangError,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _belangError = null),
          ),
          const SizedBox(height: 20),

          // Zakelijk-only fields
          if (_relatieType == RelatieType.zakelijk) ...[
            _SectionHeader(
                title: 'Bedrijfsinformatie',
                icon: Icons.business_outlined),
            const SizedBox(height: 12),
            _MultilineInputField(
              controller: _herkomstCtrl,
              hint: 'Herkomst van gelden (bijv. reguliere bedrijfsactiviteiten)',
              icon: Icons.account_balance_outlined,
              error: _herkomstError,
              onChanged: (_) =>
                  setState(() => _herkomstError = null),
            ),
            const SizedBox(height: 12),
            _MultilineInputField(
              controller: _activiteitenCtrl,
              hint: 'Omschrijf de bedrijfsactiviteiten',
              icon: Icons.work_outlined,
              error: _activiteitenError,
              onChanged: (_) =>
                  setState(() => _activiteitenError = null),
            ),
            const SizedBox(height: 20),
          ],

          // Submit
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Formulier indienen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

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
            .map(
              (o) => Expanded(
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
              ),
            )
            .toList(),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.error,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

class _MultilineInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? error;
  final ValueChanged<String>? onChanged;

  const _MultilineInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.error,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      minLines: 3,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
