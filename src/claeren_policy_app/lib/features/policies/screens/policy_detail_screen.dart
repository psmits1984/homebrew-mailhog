import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/platform/web_init.dart';
import '../models/policy_model.dart';
import '../repository/policy_repository.dart';

final polisDetailProvider =
    FutureProvider.family<PolicyDetailModel?, (String, String)>((ref, args) {
  return ref.read(policyRepositoryProvider).getPolisDetail(args.$1, args.$2);
});

class PolicyDetailScreen extends ConsumerStatefulWidget {
  final String entityId;
  final String polisNummer;

  const PolicyDetailScreen({
    super.key,
    required this.entityId,
    required this.polisNummer,
  });

  @override
  ConsumerState<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends ConsumerState<PolicyDetailScreen> {
  int _tabIndex = 0;

  PolisDocument? _latestPolisblad(PolicyDetailModel detail) {
    final bladen =
        detail.documenten.where((d) => d.type == 'Polisblad').toList();
    if (bladen.isEmpty) return null;
    bladen.sort((a, b) => b.datum.compareTo(a.datum));
    return bladen.first;
  }

  void _download(PolisDocument doc) {
    openUrl('${ApiConstants.baseUrl}${doc.downloadUrl}');
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(polisDetailProvider((widget.entityId, widget.polisNummer)));
    final currency = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    final dateFormat = DateFormat('dd-MM-yyyy');

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.polisNummer)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(widget.polisNummer)),
        body:
            const Center(child: Text('Polisdetail kon niet worden geladen.')),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.polisNummer)),
            body: const Center(child: Text('Polis niet gevonden.')),
          );
        }

        final polisblad = _latestPolisblad(detail);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.polisNummer),
            actions: [
              if (polisblad != null)
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Polisblad downloaden',
                  onPressed: () => _download(polisblad),
                ),
            ],
          ),
          body: Column(
            children: [
              _PolicyHeader(
                  detail: detail,
                  currency: currency,
                  dateFormat: dateFormat),
              _CustomTabBar(
                selectedIndex: _tabIndex,
                onTabSelected: (i) => setState(() => _tabIndex = i),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _DekkingTab(
                        dekkingen: detail.dekkingen, currency: currency),
                    _DocumentenTab(
                        documenten: detail.documenten,
                        dateFormat: dateFormat,
                        onDownload: _download),
                    _HistorieTab(
                        historie: detail.historie,
                        currency: currency,
                        dateFormat: dateFormat),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context
                .push('/polissen/${widget.entityId}/${widget.polisNummer}/claim'),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Schade melden'),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}

// ─── Custom tab-balk (geen Flutter TabBar – betrouwbaarder op iOS Safari) ────

class _CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const _tabs = [
    (Icons.shield_outlined, 'Dekking'),
    (Icons.description_outlined, 'Documenten'),
    (Icons.history, 'Historie'),
  ];

  const _CustomTabBar(
      {required this.selectedIndex, required this.onTabSelected});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primary,
        child: Row(
          children: [
            for (int i = 0; i < _tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTabSelected(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == i
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_tabs[i].$1,
                            size: 15,
                            color: selectedIndex == i
                                ? Colors.white
                                : Colors.white54),
                        const SizedBox(width: 5),
                        Text(
                          _tabs[i].$2,
                          style: TextStyle(
                            color: selectedIndex == i
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 13,
                            fontWeight: selectedIndex == i
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─── Polisheader ──────────────────────────────────────────────────────────────

class _PolicyHeader extends StatelessWidget {
  final PolicyDetailModel detail;
  final NumberFormat currency;
  final DateFormat dateFormat;

  const _PolicyHeader(
      {required this.detail,
      required this.currency,
      required this.dateFormat});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.omschrijving,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(detail.maatschappij,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.euro,
                    label: currency.format(detail.jaarPremie),
                    sublabel: 'per jaar'),
                const SizedBox(width: 10),
                _InfoChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: currency.format(detail.eigenRisico),
                    sublabel: 'eigen risico'),
                const SizedBox(width: 10),
                _InfoChip(
                    icon: Icons.event_outlined,
                    label: dateFormat.format(detail.vervaldatum),
                    sublabel: 'vervaldatum'),
              ],
            ),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  const _InfoChip(
      {required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: Colors.white70),
                const SizedBox(width: 3),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
            Text(sublabel,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      );
}

// ─── Tab: Dekking ─────────────────────────────────────────────────────────────

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
                    leading: const Icon(Icons.check_circle_outline,
                        color: AppColors.success),
                    title: Text(d.omschrijving),
                    subtitle: Text(d.code,
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: d.bedrag != null
                        ? Text(currency.format(d.bedrag),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary))
                        : const Text('Inbegrepen',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500)),
                  ),
                ))
            .toList(),
      );
}

// ─── Tab: Documenten ──────────────────────────────────────────────────────────

class _DocumentenTab extends StatelessWidget {
  final List<PolisDocument> documenten;
  final DateFormat dateFormat;
  final ValueChanged<PolisDocument> onDownload;

  const _DocumentenTab(
      {required this.documenten,
      required this.dateFormat,
      required this.onDownload});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: documenten
            .map((d) => Card(
                  child: ListTile(
                    leading: Icon(
                      d.type == 'Polisblad'
                          ? Icons.article_outlined
                          : d.type == 'Voorwaarden'
                              ? Icons.gavel_outlined
                              : Icons.picture_as_pdf_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(d.naam),
                    subtitle: Text(
                        '${d.type} · ${dateFormat.format(d.datum)}',
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_outlined,
                          color: AppColors.primary),
                      tooltip: 'Downloaden',
                      onPressed: () => onDownload(d),
                    ),
                  ),
                ))
            .toList(),
      );
}

// ─── Tab: Historie ────────────────────────────────────────────────────────────

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
              leading: const Icon(Icons.update, color: AppColors.primary),
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
