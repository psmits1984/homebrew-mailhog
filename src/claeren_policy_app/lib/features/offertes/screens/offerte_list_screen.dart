import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../models/offerte_model.dart';
import '../repository/offerte_repository.dart';

final offertesProvider =
    FutureProvider.family<List<OfferteModel>, String>((ref, entityId) {
  return ref.read(offerteRepositoryProvider).getOffertes(entityId);
});

class OfferteListScreen extends ConsumerWidget {
  final String entityId;
  const OfferteListScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offertesAsync = ref.watch(offertesProvider(entityId));
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offertes'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNav(
        entityId: entityId,
        currentTab: BottomNavTab.offertes,
      ),
      body: offertesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
            onRetry: () => ref.invalidate(offertesProvider(entityId))),
        data: (offertes) {
          final nieuw =
              offertes.where((o) => o.status == OfferteStatus.verzonden).toList();
          final inBehandeling = offertes
              .where((o) =>
                  o.status == OfferteStatus.concept ||
                  o.status == OfferteStatus.geaccordeerd)
              .toList();
          final afgerond = offertes
              .where((o) =>
                  o.status == OfferteStatus.geweigerd ||
                  o.status == OfferteStatus.getekend)
              .toList();

          if (offertes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined,
                      size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Geen offertes gevonden',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Er zijn momenteel geen offertes beschikbaar.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(offertesProvider(entityId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (nieuw.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Nieuw',
                    count: nieuw.length,
                    badgeColor: AppColors.warning,
                  ),
                  ...nieuw.map((o) => _OfferteCard(
                        offerte: o,
                        currencyFormat: currencyFormat,
                        onTap: () =>
                            context.push('/offertes/${o.id}'),
                      )),
                ],
                if (inBehandeling.isNotEmpty) ...[
                  if (nieuw.isNotEmpty) const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'In behandeling',
                    count: inBehandeling.length,
                  ),
                  ...inBehandeling.map((o) => _OfferteCard(
                        offerte: o,
                        currencyFormat: currencyFormat,
                        onTap: () =>
                            context.push('/offertes/${o.id}'),
                      )),
                ],
                if (afgerond.isNotEmpty) ...[
                  if (nieuw.isNotEmpty || inBehandeling.isNotEmpty)
                    const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'Afgerond',
                    count: afgerond.length,
                  ),
                  ...afgerond.map((o) => _OfferteCard(
                        offerte: o,
                        currencyFormat: currencyFormat,
                        onTap: () =>
                            context.push('/offertes/${o.id}'),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color badgeColor;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.badgeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _OfferteCard extends StatelessWidget {
  final OfferteModel offerte;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _OfferteCard({
    required this.offerte,
    required this.currencyFormat,
    required this.onTap,
  });

  Color get _statusColor => switch (offerte.status) {
        OfferteStatus.concept => AppColors.textSecondary,
        OfferteStatus.verzonden => AppColors.warning,
        OfferteStatus.geaccordeerd => AppColors.success,
        OfferteStatus.geweigerd => AppColors.error,
        OfferteStatus.getekend => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offerte.omschrijving,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      offerte.status.label,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.tag,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    offerte.referentie,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${currencyFormat.format(offerte.jaarPremie)} / jaar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      offerte.dekking,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Geldig t/m ${dateFormat.format(offerte.geldigTot)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Offertes konden niet worden geladen',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Opnieuw')),
          ],
        ),
      );
}
