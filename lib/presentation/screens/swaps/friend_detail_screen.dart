import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/friend_entity.dart';
import '../../../domain/entities/sticker_entity.dart';
import '../../providers/album_provider.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/user_avatar.dart';

// Simple display structures — no dependency on domain entities.
typedef _TeamSection = ({String teamName, List<StickerEntity> stickers});
typedef _GroupSection = ({String groupName, List<_TeamSection> teams});

class FriendDetailScreen extends ConsumerWidget {
  final FriendEntity friend;
  const FriendDetailScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantitiesAsync =
        ref.watch(friendQuantitiesProvider(friend.userId));
    final albumGroups = ref.watch(albumProvider).groups;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(name: friend.name, size: 28),
            const SizedBox(width: 8),
            Text(friend.name),
          ],
        ),
      ),
      body: quantitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (friendQty) {
          final myQty = ref.read(albumProvider).quantities;

          // Stickers the friend can give me: friend has ≥2, I have 0.
          final canGiveMe = <_GroupSection>[];
          // Stickers I can give the friend: I have ≥2, friend has 0.
          final canGiveFriend = <_GroupSection>[];

          for (final group in albumGroups) {
            final canGiveMeTeams = <_TeamSection>[];
            final canGiveFriendTeams = <_TeamSection>[];

            for (final team in group.teams) {
              final giveMeStickers = team.stickers
                  .where((s) =>
                      (friendQty[s.globalNumber] ?? 0) >= 2 &&
                      (myQty[s.globalNumber] ?? 0) == 0)
                  .toList();
              final giveFriendStickers = team.stickers
                  .where((s) =>
                      (myQty[s.globalNumber] ?? 0) >= 2 &&
                      (friendQty[s.globalNumber] ?? 0) == 0)
                  .toList();

              if (giveMeStickers.isNotEmpty) {
                canGiveMeTeams
                    .add((teamName: team.name, stickers: giveMeStickers));
              }
              if (giveFriendStickers.isNotEmpty) {
                canGiveFriendTeams
                    .add((teamName: team.name, stickers: giveFriendStickers));
              }
            }

            if (canGiveMeTeams.isNotEmpty) {
              canGiveMe.add((groupName: group.name, teams: canGiveMeTeams));
            }
            if (canGiveFriendTeams.isNotEmpty) {
              canGiveFriend
                  .add((groupName: group.name, teams: canGiveFriendTeams));
            }
          }

          final totalCanGiveMe = canGiveMe
              .expand((g) => g.teams)
              .expand((t) => t.stickers)
              .length;
          final totalCanGiveFriend = canGiveFriend
              .expand((g) => g.teams)
              .expand((t) => t.stickers)
              .length;

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Me puede dar ($totalCanGiveMe)'),
                    Tab(text: 'Le puedo dar ($totalCanGiveFriend)'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _StickerListView(
                        groups: canGiveMe,
                        emptyMessage:
                            'No tiene repetidas que vos necesités.',
                      ),
                      _StickerListView(
                        groups: canGiveFriend,
                        emptyMessage:
                            'No tenés repetidas que le falten a ${friend.name}.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── List view ──────────────────────────────────────────────────────────────

class _StickerListView extends StatelessWidget {
  final List<_GroupSection> groups;
  final String emptyMessage;
  const _StickerListView(
      {required this.groups, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Text(
            emptyMessage,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: groups.length,
      itemBuilder: (_, gi) {
        final group = groups[gi];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
              child: Text(group.groupName,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            ...group.teams.map(
              (t) => _TeamRow(teamName: t.teamName, stickers: t.stickers),
            ),
            const SizedBox(height: AppConstants.spacingS),
          ],
        );
      },
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String teamName;
  final List<StickerEntity> stickers;
  const _TeamRow({required this.teamName, required this.stickers});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                stickers.map((s) => _StickerChip(sticker: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _StickerChip extends StatelessWidget {
  final StickerEntity sticker;
  const _StickerChip({required this.sticker});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: sticker.playerName,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          sticker.teamPosition,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary),
        ),
      ),
    );
  }
}
