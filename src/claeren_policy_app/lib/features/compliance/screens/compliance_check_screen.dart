import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../models/compliance_model.dart';
import '../../offertes/models/offerte_model.dart';

final _complianceCheckProvider =
    FutureProvider.family<ComplianceResult, _ComplianceCheckArgs>(
        (ref, args) async {
  final api = ref.read(apiClientProvider);
  final res = await api.post(ApiConstants.complianceCheck, data: {
    'entityId': args.entityId,
    'offerteId': args.offerteId,
    'relatieSoort': args.relatieSoort,
    if (args.kvkNummer != null) 'kvkNummer': args.kvkNummer,
  });
  return ComplianceResult.fromJson(res.data as Map<String, dynamic>);
});

class _ComplianceCheckArgs {
  final String entityId;
  final String offerteId;
  final String relatieSoort;
  final String? kvkNummer;

  const _ComplianceCheckArgs({
    required this.entityId,
    required this.offerteId,
    required this.relatieSoort,
    this.kvkNummer,
  });

  @override
  bool operator ==(Object other) =>
      other is _ComplianceCheckArgs &&
      other.entityId == entityId &&
      other.offerteId == offerteId;

  @override
  int get hashCode => Object.hash(entityId, offerteId);
}

class ComplianceCheckScreen extends ConsumerWidget {
  final String offerteId;
  final String entityId;
  final String relatieSoort;
  final String? kvkNummer;

  const ComplianceCheckScreen({
    super.key,
    required this.offerteId,
    required this.entityId,
    required this.relatieSoort,
    this.kvkNummer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _ComplianceCheckArgs(
      entityId: entityId,
      offerteId: offerteId,
      relatieSoort: relatieSoort,
      kvkNummer: kvkNummer,
    );
    final checkAsync = ref.watch(_complianceCheckProvider(args));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sanctiecontrole'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: checkAsync.when(
        loading: () => _LoadingView(),
        error: (e, _) => _ErrorView(
          error: e.toString(),
          onRetry: () =>
              ref.invalidate(_complianceCheckProvider(args)),
          onManual: () => context.pushReplacement(
            '/offertes/$offerteId/ubo',
            extra: {'entityId': entityId},
          ),
        ),
        data: (result) => _ResultView(
          result: result,
          offerteId: offerteId,
        ),
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _opacity,
              builder: (_, child) => Opacity(
                opacity: _opacity.value,
                child: child,
              ),
              child: const Icon(Icons.security,
                  size: 72, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            Text(
              'Sanctiecontrole wordt uitgevoerd...',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Even geduld. Wij raadplegen de EU-, VN-\nen OFAC-sanctielijsten.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      );
}

class _ResultView extends StatelessWidget {
  final ComplianceResult result;
  final String offerteId;

  const _ResultView({required this.result, required this.offerteId});

  @override
  Widget build(BuildContext context) {
    final isGoedgekeurd =
        result.status == ComplianceStatus.goedgekeurd;
    final color =
        isGoedgekeurd ? AppColors.success : AppColors.warning;
    final icon = isGoedgekeurd
        ? Icons.check_circle_outline
        : Icons.warning_amber_outlined;
    final title = isGoedgekeurd
        ? 'Sanctiecontrole geslaagd'
        : 'Handmatige beoordeling vereist';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: color.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.vnabReferentie != null) ...[
                    _ResultRow(
                        'VNAB referentie', result.vnabReferentie!),
                    const SizedBox(height: 4),
                  ],
                  if (result.bevindingen != null)
                    _ResultRow('Bevindingen', result.bevindingen!),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (isGoedgekeurd) {
                  context.pushReplacement(
                    '/offertes/$offerteId/slotverklaring',
                    extra: {
                      'entityId': result.entityId,
                    },
                  );
                } else {
                  context.pushReplacement(
                    '/offertes/$offerteId/ubo',
                    extra: {
                      'entityId': result.entityId,
                    },
                  );
                }
              },
              icon: Icon(isGoedgekeurd
                  ? Icons.draw_outlined
                  : Icons.assignment_outlined),
              label: Text(isGoedgekeurd
                  ? 'Doorgaan naar slotverklaring'
                  : 'UBO-formulier invullen'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onManual;

  const _ErrorView(
      {required this.error,
      required this.onRetry,
      required this.onManual});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 20),
              Text('Sanctiecontrole niet beschikbaar',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'De VNAB-dienst is momenteel niet bereikbaar. '
                'U kunt handmatig het UBO-formulier invullen.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Opnieuw proberen'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onManual,
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('UBO-formulier invullen'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48)),
              ),
            ],
          ),
        ),
      );
}
