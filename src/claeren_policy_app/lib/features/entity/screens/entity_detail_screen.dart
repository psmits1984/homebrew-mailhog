import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/entity_model.dart';
import 'entity_selection_screen.dart';

class EntityDetailScreen extends ConsumerWidget {
  final String entityId;
  const EntityDetailScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entiteitenAsync = ref.watch(entiteitenProvider);
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn gegevens'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: entiteitenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Gegevens konden niet worden geladen.')),
        data: (entiteiten) {
          final entity = entiteiten.firstWhere(
            (e) => e.id == entityId,
            orElse: () => entiteiten.first,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EntityHeaderCard(entity: entity),
              const SizedBox(height: 20),
              if (entity.type == EntityType.zakelijk) ...[
                _InfoSection(
                  title: 'Bedrijfsinformatie',
                  icon: Icons.business_outlined,
                  rows: [
                    _Row('Bedrijfsnaam', entity.naam),
                    if (entity.hoedanigheid != null)
                      _Row('Hoedanigheid', entity.hoedanigheid!),
                    if (entity.kvkNummer.isNotEmpty)
                      _Row('KvK-nummer', entity.kvkNummer),
                    if (entity.branche != null)
                      _Row('Branche', entity.branche!),
                  ],
                ),
              ] else ...[
                _InfoSection(
                  title: 'Persoonsgegevens',
                  icon: Icons.person_outlined,
                  rows: [
                    _Row('Naam', entity.naam),
                    if (entity.geboortedatum != null)
                      _Row('Geboortedatum',
                          dateFormat.format(entity.geboortedatum!)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (entity.adres != null || entity.woonplaats != null)
                _InfoSection(
                  title: 'Adresgegevens',
                  icon: Icons.location_on_outlined,
                  rows: [
                    if (entity.adres != null) _Row('Adres', entity.adres!),
                    if (entity.postcode != null && entity.woonplaats != null)
                      _Row('Postcode / Woonplaats',
                          '${entity.postcode!}  ${entity.woonplaats!}'),
                  ],
                ),
              const SizedBox(height: 16),
              if (entity.email != null || entity.telefoon != null)
                _InfoSection(
                  title: 'Contactgegevens',
                  icon: Icons.contact_phone_outlined,
                  rows: [
                    if (entity.email != null) _Row('E-mail', entity.email!),
                    if (entity.telefoon != null)
                      _Row('Telefoon', entity.telefoon!),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _EntityHeaderCard extends StatelessWidget {
  final EntityModel entity;
  const _EntityHeaderCard({required this.entity});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  entity.type == EntityType.zakelijk
                      ? Icons.business
                      : Icons.person_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.naam,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      entity.type == EntityType.zakelijk
                          ? 'Zakelijke relatie'
                          : 'Particuliere relatie',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Row> rows;
  const _InfoSection(
      {required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 135,
                          child: Text(rows[i].label,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ),
                        Expanded(
                          child: Text(rows[i].value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}
