import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/naverrrekening_model.dart';
import '../repository/naverrrekening_repository.dart';

final uitvragenProvider =
    FutureProvider.family<List<NaverrekenUitvraag>, String>((ref, entityId) {
  return ref.read(navRepoProvider).getUitvragen(entityId);
});

class NaverrekenScreen extends ConsumerWidget {
  final String entityId;
  const NaverrekenScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uitvragenAsync = ref.watch(uitvragenProvider(entityId));
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Naverrrekening')),
      body: uitvragenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Kon uitvragen niet laden.')),
        data: (uitvragen) {
          if (uitvragen.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success),
                  SizedBox(height: 16),
                  Text('Geen openstaande uitvragen'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: uitvragen.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final u = uitvragen[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.assignment_outlined, color: AppColors.warning),
                  ),
                  title: Text(u.omschrijving,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Polis: ${u.polisNummer}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Deadline: ${dateFormat.format(u.deadline)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: u.deadline.isBefore(
                                      DateTime.now().add(const Duration(days: 14)))
                                  ? AppColors.error
                                  : AppColors.textSecondary)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NaverrekenFormScreen(
                        entityId: entityId,
                        uitvraag: u,
                        onCompleted: () => ref.invalidate(uitvragenProvider(entityId)),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NaverrekenFormScreen extends ConsumerStatefulWidget {
  final String entityId;
  final NaverrekenUitvraag uitvraag;
  final VoidCallback onCompleted;

  const NaverrekenFormScreen({
    super.key,
    required this.entityId,
    required this.uitvraag,
    required this.onCompleted,
  });

  @override
  ConsumerState<NaverrekenFormScreen> createState() => _NaverrekenFormScreenState();
}

class _NaverrekenFormScreenState extends ConsumerState<NaverrekenFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectedValues = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (final v in widget.uitvraag.vragen) {
      if (v.type != 'select') _controllers[v.vraagId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final antwoorden = <String, String>{};
    for (final v in widget.uitvraag.vragen) {
      if (v.type == 'select') {
        antwoorden[v.vraagId] = _selectedValues[v.vraagId] ?? '';
      } else {
        antwoorden[v.vraagId] = _controllers[v.vraagId]?.text.trim() ?? '';
      }
    }

    try {
      await ref.read(navRepoProvider).beantwoord(
            entityId: widget.entityId,
            uitvraagId: widget.uitvraag.uitvraagId,
            antwoorden: antwoorden,
          );
      if (!mounted) return;
      widget.onCompleted();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Naverrekeningsgegevens ingediend'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indienen mislukt. Probeer opnieuw.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Uitvraag ${widget.uitvraag.jaar}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.uitvraag.omschrijving,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Polis: ${widget.uitvraag.polisNummer}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              ...widget.uitvraag.vragen.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildVraagField(v),
                  )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Indienen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVraagField(NaverrekenVraag v) {
    if (v.type == 'select' && v.opties != null) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: v.vraag,
          filled: false,
          fillColor: Colors.transparent,
        ),
        items: v.opties!
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (val) => setState(() => _selectedValues[v.vraagId] = val),
        validator: v.verplicht
            ? (val) => val == null ? 'Verplicht veld' : null
            : null,
      );
    }
    return TextFormField(
      controller: _controllers[v.vraagId],
      keyboardType: v.type == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: v.vraag,
        filled: false,
        fillColor: Colors.transparent,
      ),
      validator: v.verplicht
          ? (val) => (val == null || val.trim().isEmpty) ? 'Verplicht veld' : null
          : null,
    );
  }
}
