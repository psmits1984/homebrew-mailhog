import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../repository/claim_repository.dart';

class NewClaimScreen extends ConsumerStatefulWidget {
  final String entityId;
  final String polisNummer;

  const NewClaimScreen({
    super.key,
    required this.entityId,
    required this.polisNummer,
  });

  @override
  ConsumerState<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends ConsumerState<NewClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _omschrijvingCtrl = TextEditingController();
  final _locatieCtrl = TextEditingController();
  final _schattingCtrl = TextEditingController();
  DateTime? _schadeDatum;
  bool _loading = false;

  @override
  void dispose() {
    _omschrijvingCtrl.dispose();
    _locatieCtrl.dispose();
    _schattingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('nl'),
    );
    if (picked != null) setState(() => _schadeDatum = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_schadeDatum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecteer een schadedatum')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final schadeNummer = await ref.read(claimRepositoryProvider).meldClaim(
            entityId: widget.entityId,
            polisNummer: widget.polisNummer,
            schadeDatum: _schadeDatum!,
            omschrijving: _omschrijvingCtrl.text.trim(),
            locatie: _locatieCtrl.text.trim().isEmpty ? null : _locatieCtrl.text.trim(),
            schatting: double.tryParse(_schattingCtrl.text.replaceAll(',', '.')),
          );

      if (!mounted) return;
      _showSuccessDialog(schadeNummer);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schademelding mislukt. Probeer opnieuw.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String schadeNummer) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Schade gemeld'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            Text('Uw schademelding is ontvangen.\nSchadenummer: $schadeNummer'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.pop();
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
    final dateFormat = DateFormat('dd-MM-yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Schade melden')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Polis: ${widget.polisNummer}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Schadedatum *',
                      hintText: 'Selecteer een datum',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixText: _schadeDatum != null
                          ? dateFormat.format(_schadeDatum!)
                          : null,
                    ),
                    controller: TextEditingController(
                      text: _schadeDatum != null
                          ? dateFormat.format(_schadeDatum!)
                          : '',
                    ),
                    validator: (_) =>
                        _schadeDatum == null ? 'Selecteer een datum' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _omschrijvingCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Omschrijving schade *',
                  hintText: 'Beschrijf wat er is gebeurd...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Geef een beschrijving van minimaal 10 tekens'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locatieCtrl,
                decoration: const InputDecoration(
                  labelText: 'Locatie (optioneel)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schattingCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Geschatte schade in € (optioneel)',
                  prefixIcon: Icon(Icons.euro_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Schade melden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
