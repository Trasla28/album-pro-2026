import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/group_provider.dart';
import '../../widgets/app_button.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'join_group_screen.dart';

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) => groups.isEmpty
            ? _EmptyGroups(onCreateTap: () => _openCreate(context), onJoinTap: () => _openJoin(context))
            : ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                itemCount: groups.length,
                itemBuilder: (ctx, i) => _GroupCard(
                  group: groups[i],
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: groups[i]),
                    ),
                  ),
                ),
              ),
      ),
      // FABs solo se muestran cuando el usuario no pertenece a ningún grupo.
      floatingActionButton: null,
    );
  }

  void _openCreate(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
      );

  void _openJoin(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
      );
}

class _GroupCard extends StatelessWidget {
  final dynamic group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group, color: AppColors.primary),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberCount} ${group.memberCount == 1 ? 'miembro' : 'miembros'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  final VoidCallback onCreateTap;
  final VoidCallback onJoinTap;

  const _EmptyGroups({required this.onCreateTap, required this.onJoinTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 72)),
          const SizedBox(height: AppConstants.spacingL),
          Text('Grupos familiares',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Coordiná con tu familia quién consigue cada figurita en tiempo real.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXXL),
          AppButton(label: 'Crear mi primer grupo', onPressed: onCreateTap),
          const SizedBox(height: AppConstants.spacingM),
          AppButton(
            label: 'Unirme con código',
            variant: AppButtonVariant.outlined,
            onPressed: onJoinTap,
          ),
        ],
      ),
    );
  }
}
