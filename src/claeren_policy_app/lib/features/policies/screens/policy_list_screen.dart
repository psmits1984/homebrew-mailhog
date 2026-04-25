import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../models/policy_model.dart';
import '../repository/policy_repository.dart';

final polissenProvider =
    FutureProvider.family<List<PolicyModel>, String>((ref, entityId) {
  return ref.read(policyRepositoryProvider).getPolissen(entityId);
});

class PolicyListScreen extends ConsumerWidget {
  final String entityId;
  const PolicyListScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polissenAsync = ref.watch(polissenProvider(entityId));
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn polissen'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Uitloggen',
            onPressed: () async {
              await ref.read(secureStorageProvider).clearAll();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        entityId: entityId,
        currentTab: BottomNavTab.polissen,
      ),
      body: polissenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(polissenProvider(entityId))),
        data: (polissen) {
          final actief = polissen.where((p) => p.status == PolicyStatus.actief).toList();
          final overig = polissen.where((p) => p.status != PolicyStatus.actief).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(polissenProvider(entityId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (actief.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Actieve polissen',
                    count: actief.length,
                  ),
                  ...actief.map((p) => _PolicyCard(
                        policy: p,
                        currencyFormat: currencyFormat,
                        onTap: () => context.push('/polissen/$entityId/${p.polisNummer}'),
                      )),
                ],
                if (overig.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionHeader(title: 'Overige polissen', count: overig.length),
                  ...overig.map((p) => _PolicyCard(
                        policy: p,
                        currencyFormat: currencyFormat,
                        onTap: () => context.push('/polissen/$entityId/${p.polisNummer}'),
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
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _PolicyCard extends StatelessWidget {
  final PolicyModel policy;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _PolicyCard({
    required this.policy,
    required this.currencyFormat,
    required this.onTap,
  });

  Color get _statusColor => switch (policy.status) {
        PolicyStatus.actief => AppColors.statusActief,
        PolicyStatus.geroyeerd => AppColors.statusGeroyeerd,
        PolicyStatus.geschorst => AppColors.statusGeschorst,
        PolicyStatus.inAanvraag => AppColors.statusInAanvraag,
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
                    child: Text(policy.omschrijving,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      policy.status.label,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(policy.maatschappij,
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    '${currencyFormat.format(policy.jaarPremie)} / jaar',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(policy.polisNummer,
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    'Verloopt: ${dateFormat.format(policy.vervaldatum)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
              if (policy.status == PolicyStatus.actief) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 13,
                      color: policy.automatischIncasso
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      policy.automatischIncasso
                          ? 'Automatisch incasso actief'
                          : 'Geen automatisch incasso',
                      style: TextStyle(
                        fontSize: 11,
                        color: policy.automatischIncasso
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (!policy.automatischIncasso) ...[
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push(
                          '/entiteiten/${policy.entityId}/sepa'
                          '?polis=${policy.polisNummer}'
                          '&omschrijving=${Uri.encodeComponent(policy.omschrijving)}',
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Instellen',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios,
                                size: 10, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Polissen konden niet worden geladen',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('Opnieuw')),
          ],
        ),
      );
}
