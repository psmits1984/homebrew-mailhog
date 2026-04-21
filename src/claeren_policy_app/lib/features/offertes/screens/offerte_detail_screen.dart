import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/offerte_model.dart';
import '../repository/offerte_repository.dart';

final offerteDetailProvider =
    FutureProvider.family<OfferteModel, String>((ref, id) {
  return ref.read(offerteRepositoryProvider).getOfferte(id);
});

class OfferteDetailScreen extends ConsumerStatefulWidget {
  final String offerteId;
  const OfferteDetailScreen({super.key, required this.offerteId});

  @override
  ConsumerState<OfferteDetailScreen> createState() =>
      _OfferteDetailScreenState();
}

class _OfferteDetailScreenState extends ConsumerState<OfferteDetailScreen> {
  bool _loading = false;

  Future<void> _accorderen(OfferteModel offerte) async {
    setState(() => _loading = true);
    try {
      final updated = await ref
          .read(offerteRepositoryProvider)
          .accorderen(widget.offerteId);
      ref.invalidate(offerteDetailProvider(widget.offerteId));
      if (mounted) {
        context.push(
          '/offertes/${widget.offerteId}/compliance',
          extra: {
            'entityId': updated.entityId,
            'relatieSoort': updated.relatieType.label,
            'kvkNummer': updated.kvkNummer,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Fout'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Sluiten'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _weigeren(OfferteModel offerte) async {
    final bottomCtx = context;
    final confirmed = await showModalBottomSheet<bool>(
      context: bottomCtx,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Offerte weigeren',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Weet u zeker dat u offerte ${offerte.referentie} wilt weigeren?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bevestig weigeren'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(offerteRepositoryProvider).weigeren(widget.offerteId);
      ref.invalidate(offerteDetailProvider(widget.offerteId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Fout'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Sluiten'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerteAsync =
        ref.watch(offerteDetailProvider(widget.offerteId));
    final currencyFormat =
        NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offerte details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: offerteAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Offerte kon niet worden geladen'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref
                    .invalidate(offerteDetailProvider(widget.offerteId)),
                child: const Text('Opnieuw'),
              ),
            ],
          ),
        ),
        data: (offerte) {
          final isVerzonden =
              offerte.status == OfferteStatus.verzonden;
          final statusColor = switch (offerte.status) {
            OfferteStatus.concept => AppColors.textSecondary,
            OfferteStatus.verzonden => AppColors.warning,
            OfferteStatus.geaccordeerd => AppColors.success,
            OfferteStatus.geweigerd => AppColors.error,
            OfferteStatus.getekend => AppColors.primary,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(offerte.status),
                        color: statusColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offerte.status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (isVerzonden)
                            const Text(
                              'Actie vereist — akkoord geven of weigeren',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          'Offerte',
                          Icons.description_outlined),
                      const SizedBox(height: 12),
                      _InfoRow('Referentie', offerte.referentie),
                      _InfoRow('Omschrijving', offerte.omschrijving),
                      _InfoRow('Producttype', offerte.productType),
                      _InfoRow('Dekking', offerte.dekking),
                      _InfoRow(
                        'Jaarpremiie',
                        '${currencyFormat.format(offerte.jaarPremie)} / jaar',
                        valueColor: AppColors.primary,
                        valueBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          'Looptijd', Icons.calendar_today_outlined),
                      const SizedBox(height: 12),
                      _InfoRow('Ingangsdatum',
                          dateFormat.format(offerte.ingangsdatum)),
                      _InfoRow('Geldig tot',
                          dateFormat.format(offerte.geldigTot)),
                      _InfoRow('Aangemaakt op',
                          dateFormat.format(offerte.aangemaaktOp)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Relatie', Icons.business_outlined),
                      const SizedBox(height: 12),
                      _InfoRow('Type', offerte.relatieType.label),
                      if (offerte.kvkNummer != null)
                        _InfoRow('KvK-nummer', offerte.kvkNummer!),
                      if (offerte.contactpersoonEmail != null)
                        _InfoRow(
                            'E-mail', offerte.contactpersoonEmail!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons – only for Verzonden offertes
              if (isVerzonden) ...[
                ElevatedButton.icon(
                  onPressed:
                      _loading ? null : () => _accorderen(offerte),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Akkoord geven'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _loading ? null : () => _weigeren(offerte),
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.error),
                  label: const Text('Weigeren',
                      style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],

              if (offerte.status == OfferteStatus.geaccordeerd) ...[
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/offertes/${offerte.id}/compliance',
                    extra: {
                      'entityId': offerte.entityId,
                      'relatieSoort': offerte.relatieType.label,
                      'kvkNummer': offerte.kvkNummer,
                    },
                  ),
                  icon: const Icon(Icons.security_outlined),
                  label: const Text('Doorgaan naar sanctiecontrole'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],

              if (offerte.status == OfferteStatus.getekend) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_outlined,
                          color: AppColors.success, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Slotverklaring ondertekend. '
                          'Uw polis wordt zo spoedig mogelijk verwerkt.',
                          style: TextStyle(
                              color: AppColors.success, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  IconData _statusIcon(OfferteStatus status) => switch (status) {
        OfferteStatus.concept => Icons.edit_outlined,
        OfferteStatus.verzonden => Icons.mark_email_unread_outlined,
        OfferteStatus.geaccordeerd => Icons.thumb_up_outlined,
        OfferteStatus.geweigerd => Icons.thumb_down_outlined,
        OfferteStatus.getekend => Icons.verified_outlined,
      };
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionLabel(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _InfoRow(this.label, this.value,
      {this.valueColor, this.valueBold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: valueBold
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}
