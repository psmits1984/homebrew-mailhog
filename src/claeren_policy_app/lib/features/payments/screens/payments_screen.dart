import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/payment_model.dart';
import '../repository/payment_repository.dart';

final betalingenProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, entityId) {
  return ref.read(paymentRepositoryProvider).getBetalingen(entityId);
});

class PaymentsScreen extends ConsumerWidget {
  final String entityId;
  const PaymentsScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final betalingenAsync = ref.watch(betalingenProvider(entityId));
    final currency = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Betaalbewijzen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: betalingenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Betalingen konden niet worden geladen',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(betalingenProvider(entityId)),
                child: const Text('Opnieuw'),
              ),
            ],
          ),
        ),
        data: (betalingen) {
          final aandacht = betalingen
              .where((b) =>
                  b.status == PaymentStatus.openstaand ||
                  b.status == PaymentStatus.mislukt)
              .toList();
          final betaald = betalingen
              .where((b) => b.status == PaymentStatus.betaald)
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(betalingenProvider(entityId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (aandacht.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Aandacht vereist',
                      count: aandacht.length,
                      color: AppColors.warning),
                  ...aandacht.map((b) => _PaymentCard(
                      payment: b,
                      currency: currency,
                      dateFormat: dateFormat)),
                  const SizedBox(height: 8),
                ],
                if (betaald.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Betaalhistorie',
                      count: betaald.length,
                      color: AppColors.success),
                  ...betaald.map((b) => _PaymentCard(
                      payment: b,
                      currency: currency,
                      dateFormat: dateFormat)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/entiteiten/$entityId/sepa'),
        icon: const Icon(Icons.account_balance_outlined),
        label: const Text('Automatische incasso'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.count, required this.color});

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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final NumberFormat currency;
  final DateFormat dateFormat;
  const _PaymentCard(
      {required this.payment,
      required this.currency,
      required this.dateFormat});

  Color get _statusColor => switch (payment.status) {
        PaymentStatus.betaald => AppColors.success,
        PaymentStatus.openstaand => AppColors.warning,
        PaymentStatus.mislukt => AppColors.error,
      };

  IconData get _statusIcon => switch (payment.status) {
        PaymentStatus.betaald => Icons.check_circle_outline,
        PaymentStatus.openstaand => Icons.schedule_outlined,
        PaymentStatus.mislukt => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon, size: 18, color: _statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(payment.omschrijvingPolis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(payment.status.label,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.tag,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(payment.polisNummer,
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(currency.format(payment.bedrag),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(payment.factuurNummer,
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(dateFormat.format(payment.datum),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      );
}
