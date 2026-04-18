import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/entity_model.dart';
import '../repository/entity_repository.dart';

final entiteitenProvider = FutureProvider<List<EntityModel>>((ref) {
  return ref.read(entityRepositoryProvider).getEntiteiten();
});

class EntitySelectionScreen extends ConsumerWidget {
  const EntitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entiteitenAsync = ref.watch(entiteitenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn omgevingen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(secureStorageProvider).clearAll();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
      body: entiteitenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Kon omgevingen niet laden', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(entiteitenProvider),
                child: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
        data: (entiteiten) {
          if (entiteiten.length == 1) {
            // Automatisch doorsturen bij 1 entiteit
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _selectEntity(context, ref, entiteiten.first);
            });
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Text(
                'Selecteer een omgeving',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'U heeft toegang tot de volgende omgevingen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ...entiteiten.map((e) => _EntityCard(
                    entity: e,
                    onTap: () => _selectEntity(context, ref, e),
                  )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectEntity(
      BuildContext context, WidgetRef ref, EntityModel entity) async {
    await ref.read(secureStorageProvider).saveSelectedEntity(entity.id);
    if (context.mounted) context.go('/polissen/${entity.id}');
  }
}

class _EntityCard extends StatelessWidget {
  final EntityModel entity;
  final VoidCallback onTap;

  const _EntityCard({required this.entity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isZakelijk = entity.type == EntityType.zakelijk;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isZakelijk
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.accent.withValues(alpha: 0.15),
          child: Icon(
            isZakelijk ? Icons.business : Icons.person_outlined,
            color: isZakelijk ? AppColors.primary : AppColors.accent,
          ),
        ),
        title: Text(entity.naam,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isZakelijk ? 'KvK: ${entity.kvkNummer}' : 'Particulier',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
