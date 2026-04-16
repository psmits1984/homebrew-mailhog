import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/policy_model.dart';
import '../repository/policy_repository.dart';

final polisDetailProvider =
    FutureProvider.family<PolicyDetailModel?, (String, String)>((ref, args) {
  return ref.read(policyRepositoryProvider).getPolisDetail(args.$1, args.$2);
});

class PolicyDetailScreen extends ConsumerWidget {
  final String entityId;
  final String polisNummer;

  const PolicyDetailScreen({
    super.key,
    required this.entityId,
    required this.polisNummer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(polisDetailProvider((entityId, polisNummer)));
    final currency = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(polisNummer)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Polisdetail kon niet worden geladen.')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Polis niet gevonden.'));
          }
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _PolicyHeader(detail: detail, currency: currency, dateFormat: dateFormat),
                const TabBar(
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Dekking'),
                    Tab(text: 'Documenten'),
                    Tab(text: 'Historie'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DekkingTab(dekkingen: detail.dekkingen, currency: currency),
                      _DocumentenTab(documenten: detail.documenten, dateFormat: dateFormat),
                      _HistorieTab(historie: detail.historie, currency: currency, dateFormat: dateFormat),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/polissen/$entityId/$polisNummer/claim'),
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Schade melden'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  final PolicyDetailModel detail;
  final NumberFormat currency;
  final DateFormat dateFormat;

  const _PolicyHeader({required this.detail, required this.currency, required this.dateFormat});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.omschrijving,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(detail.maatschappij,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                    label: currency.format(detail.jaarPremie),
                    sublabel: 'per jaar'),
                const SizedBox(width: 12),
                _InfoChip(
                    label: currency.format(detail.eigenRisico),
                    sublabel: 'eigen risico'),
                const SizedBox(width: 12),
                _InfoChip(
                    label: dateFormat.format(detail.vervaldatum),
                    sublabel: 'vervaldatum'),
              ],
            ),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String sublabel;
  const _InfoChip({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sublabel,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}

class _DekkingTab extends StatelessWidget {
  final List<Dekking> dekkingen;
  final NumberFormat currency;
  const _DekkingTab({required this.dekkingen, required this.currency});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: dekkingen
            .map((d) => Card(
                  child: ListTile(
                    title: Text(d.omschrijving),
                    subtitle: Text(d.code),
                    trailing: d.bedrag != null
                        ? Text(currency.format(d.bedrag),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary))
                        : const Text('Inbegrepen',
                            style: TextStyle(color: AppColors.success)),
                  ),
                ))
            .toList(),
      );
}

class _DocumentenTab extends StatelessWidget {
  final List<PolisDocument> documenten;
  final DateFormat dateFormat;
  const _DocumentenTab({required this.documenten, required this.dateFormat});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: documenten
            .map((d) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined,
                        color: AppColors.error),
                    title: Text(d.naam),
                    subtitle: Text(
                        '${d.type} · ${dateFormat.format(d.datum)}',
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: const Icon(Icons.download_outlined,
                        color: AppColors.primary),
                    onTap: () {
                      // TODO: open document via URL launcher
                    },
                  ),
                ))
            .toList(),
      );
}

class _HistorieTab extends StatelessWidget {
  final List<PolisHistorie> historie;
  final NumberFormat currency;
  final DateFormat dateFormat;
  const _HistorieTab(
      {required this.historie,
      required this.currency,
      required this.dateFormat});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historie.length,
        itemBuilder: (_, i) {
          final h = historie[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text(h.omschrijving),
              subtitle: Text(dateFormat.format(h.datum),
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: h.nieuwePremie != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currency.format(h.nieuwePremie),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        if (h.oudePremie != null)
                          Text(currency.format(h.oudePremie),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough)),
                      ],
                    )
                  : null,
            ),
          );
        },
      );
}
