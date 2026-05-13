import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/album_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/sticker_group_entity.dart';
import '../../../domain/entities/team_entity.dart';
import '../../providers/album_provider.dart';
import '../../widgets/sticker_cell.dart';
import 'album_search_screen.dart';
import 'calculator_screen.dart';
import 'sticker_detail_screen.dart';
import '../swaps/message_swap_screen.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  final Set<String> _expandedGroups = {};
  final Set<String> _expandedTeams = {};

  void _toggleGroup(String groupId, List<TeamEntity> teams) {
    setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
        for (final team in teams) {
          _expandedTeams.add(team.code);
        }
      }
    });
  }

  void _toggleTeam(String teamCode) {
    setState(() {
      if (_expandedTeams.contains(teamCode)) {
        _expandedTeams.remove(teamCode);
      } else {
        _expandedTeams.add(teamCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(albumProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/scan'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        tooltip: 'Escanear láminas',
        child: const Icon(Icons.document_scanner_outlined),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, state),
          SliverToBoxAdapter(child: _StatsRow(state: state)),
          SliverToBoxAdapter(child: _FilterRow(current: state.filter, ref: ref)),
          ..._buildContentSlivers(context, state),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AlbumState state) {
    return SliverAppBar(
      pinned: true,
      title: const Text('AlbumPro 2026'),
      leading: IconButton(
        icon: const Icon(Icons.swap_horiz_outlined),
        tooltip: 'Intercambio por mensaje',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MessageSwapScreen()),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calculate_outlined),
          tooltip: 'Calculadora de sobres',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalculatorScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AlbumSearchScreen()),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: state.stats.percentage,
          backgroundColor: AppColors.primaryDark,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          minHeight: 4,
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context, AlbumState state) {
    final slivers = <Widget>[];
    final groups = state.filteredGroups;

    if (groups.isEmpty) {
      slivers.add(const SliverFillRemaining(child: _EmptyFilter()));
      return slivers;
    }

    for (final group in groups) {
      final isGroupExpanded = _expandedGroups.contains(group.id);
      slivers.add(SliverToBoxAdapter(
        child: _GroupHeader(
          group: group,
          expanded: isGroupExpanded,
          onTap: () => _toggleGroup(group.id, group.teams),
        ),
      ));

      if (!isGroupExpanded) continue;

      for (final team in group.teams) {
        final isTeamExpanded = _expandedTeams.contains(team.code);
        slivers.add(SliverToBoxAdapter(
          child: _TeamHeader(
            team: team,
            state: state,
            expanded: isTeamExpanded,
            onTap: () => _toggleTeam(team.code),
          ),
        ));
        if (isTeamExpanded) {
          slivers.add(_buildTeamGrid(context, team, state));
        }
      }
    }
    return slivers;
  }

  SliverPadding _buildTeamGrid(
    BuildContext context,
    TeamEntity team,
    AlbumState state,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final sticker = team.stickers[i];
            final qty = state.quantities[sticker.globalNumber] ?? 0;
            return StickerCell(
              sticker: sticker,
              quantity: qty,
              onTap: () {
                if (qty == 0) {
                  ref.read(albumProvider.notifier).toggleOwned(sticker.globalNumber);
                } else {
                  showStickerDetail(ctx, sticker);
                }
              },
            );
          },
          childCount: team.stickers.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AlbumState state;

  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _StatCard(
            label: 'Conseguidas',
            value: '${s.owned}/${s.total}',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
          _StatCard(
            label: 'Faltantes',
            value: '${s.missing}',
            color: AppColors.error,
            icon: Icons.radio_button_unchecked,
          ),
          _StatCard(
            label: 'Repetidas',
            value: '${s.duplicates}',
            color: AppColors.warning,
            icon: Icons.copy_outlined,
          ),
          _StatCard(
            label: 'Shiny',
            value: '${s.shinyOwned}/${s.shinyTotal}',
            color: AppColors.accent,
            icon: Icons.auto_awesome,
          ),
          _StatCard(
            label: 'Extras',
            value: '${s.extrasOwned}/${s.extrasTotal}',
            color: AppColors.info,
            icon: Icons.star_outline,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      );
}

class _FilterRow extends StatelessWidget {
  final AlbumFilter current;
  final WidgetRef ref;

  const _FilterRow({required this.current, required this.ref});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: AlbumFilter.values
              .map((f) => _FilterChip(
                    filter: f,
                    selected: f == current,
                    onTap: () => ref.read(albumProvider.notifier).setFilter(f),
                  ))
              .toList(),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final AlbumFilter filter;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.filter, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            filter.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

class _GroupHeader extends StatelessWidget {
  final StickerGroupEntity group;
  final bool expanded;
  final VoidCallback onTap;

  const _GroupHeader({required this.group, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AnimatedRotation(
                turns: expanded ? 0.25 : 0,
                duration: AppConstants.animFast,
                child: const Icon(Icons.chevron_right, color: AppColors.white, size: 18),
              ),
              const SizedBox(width: 6),
              Text(
                group.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${group.teams.length} equipos',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
}

class _TeamHeader extends StatelessWidget {
  final TeamEntity team;
  final AlbumState state;
  final bool expanded;
  final VoidCallback onTap;

  const _TeamHeader({
    required this.team,
    required this.state,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ownedCount = team.stickers
        .where((s) => (state.quantities[s.globalNumber] ?? 0) > 0)
        .length;
    final total = team.stickers.length;
    final progress = total > 0 ? ownedCount / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text(
                  team.code.substring(0, 2),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        team.code,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? AppColors.success : AppColors.primary,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$ownedCount/$total',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: AppConstants.animFast,
              child: const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Sin figuritas en este filtro',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
}
