import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/platform/web_init.dart';
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
      backgroundColor: AppColors.background,
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
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(betalingenProvider(entityId)),
                  child: const Text('Opnieuw'),
                ),
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

  void _downloadFactuur() {
    if (payment.factuurDownloadUrl.isNotEmpty) {
      openUrl('${ApiConstants.baseUrl}${payment.factuurDownloadUrl}');
    }
  }

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
              if (payment.status == PaymentStatus.openstaand ||
                  payment.status == PaymentStatus.mislukt) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.payment_outlined, size: 16),
                      label: const Text('Betaal nu'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () =>
                          _showBetaalOpties(context, payment, currency),
                    ),
                  ],
                ),
              ],
              if (payment.factuurDownloadUrl.isNotEmpty) ...[
                if (payment.status == PaymentStatus.betaald)
                  const SizedBox(height: 8),
                if (payment.status == PaymentStatus.betaald)
                  const Divider(height: 1),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Factuur downloaden'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _downloadFactuur,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

void _showBetaalOpties(
    BuildContext context, PaymentModel payment, NumberFormat currency) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BetaalOptiesSheet(payment: payment, currency: currency),
  );
}

// ─── Betaalopties bottom sheet ─────────────────────────────────────────────────

class _BetaalOptiesSheet extends StatefulWidget {
  final PaymentModel payment;
  final NumberFormat currency;
  const _BetaalOptiesSheet({required this.payment, required this.currency});

  @override
  State<_BetaalOptiesSheet> createState() => _BetaalOptiesSheetState();
}

class _BetaalOptiesSheetState extends State<_BetaalOptiesSheet> {
  String? _selectedBank;
  bool _loading = false;
  bool _done = false;
  String? _method;

  static const _banks = [
    ('ABN AMRO', 'ABNANL2A'),
    ('ING', 'INGBNL2A'),
    ('Rabobank', 'RABONL2U'),
    ('SNS Bank', 'SNSBNL2A'),
    ('ASN Bank', 'ASNBNL21'),
    ('Bunq', 'BUNQNL2A'),
    ('Knab', 'KNABNL2H'),
    ('Triodos', 'TRIONL2U'),
  ];

  Future<void> _betaal(String method) async {
    setState(() {
      _method = method;
      _loading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: _done ? _buildSuccess() : _buildOptions(),
    );
  }

  Widget _buildSuccess() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          const SizedBox(height: 12),
          const Text('Betaling geslaagd',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Uw betaling van ${widget.currency.format(widget.payment.bedrag)} '
            'is verwerkt via ${_method ?? ""}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sluiten'),
            ),
          ),
        ],
      );

  Widget _buildOptions() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Betaal ${widget.currency.format(widget.payment.bedrag)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(widget.payment.omschrijvingPolis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Wero
            _PayMethodTile(
              logo: Icons.contactless_outlined,
              name: 'Wero',
              subtitle: 'Betaal direct via uw bank-app',
              color: const Color(0xFF00A859),
              onTap: () => _betaal('Wero'),
            ),
            const SizedBox(height: 12),

            // iDEAL
            const Text('iDEAL — kies uw bank',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...(_banks.map((b) => _BankTile(
                  naam: b.$1,
                  bic: b.$2,
                  selected: _selectedBank == b.$1,
                  onTap: () => setState(() => _selectedBank = b.$1),
                ))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _selectedBank != null
                  ? () => _betaal('iDEAL ($_selectedBank)')
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(_selectedBank != null
                  ? 'Betaal via iDEAL · $_selectedBank'
                  : 'Selecteer een bank'),
            ),
          ],
        ],
      );
}

class _PayMethodTile extends StatelessWidget {
  final IconData logo;
  final String name;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _PayMethodTile(
      {required this.logo,
      required this.name,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(logo, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      );
}

class _BankTile extends StatelessWidget {
  final String naam;
  final String bic;
  final bool selected;
  final VoidCallback onTap;
  const _BankTile(
      {required this.naam,
      required this.bic,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance,
                  size: 18,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(naam,
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    )),
              ),
              if (selected)
                const Icon(Icons.check_circle,
                    size: 16, color: AppColors.primary),
            ],
          ),
        ),
      );
}
