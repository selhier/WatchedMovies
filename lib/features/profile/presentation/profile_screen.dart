import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/movie_entry.dart';
import '../../auth/data/auth_repository.dart';
import '../../my_lists/data/list_repository.dart';
import '../../shared_list/data/shared_list_repository.dart';
import '../../../core/providers/language_provider.dart';

/// Profile screen with user info, stats, and shared lists
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final entries = ref.watch(movieEntriesStreamProvider);
    final sharedLists = ref.watch(mySharedListsProvider);

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('profile.title'.tr()),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage(context);
            },
            icon: const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
            label: Text(
              ref.watch(languageProvider).split('-')[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceLight,
                    AppColors.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surfaceHighlight,
                      backgroundImage: user.photoURL != null
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              (user.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.displayName ?? 'Movie Lover',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Stats grid
            entries.when(
              data: (allEntries) {
                final watched = allEntries
                    .where((e) => e.status == MovieStatus.watched)
                    .length;
                final pending = allEntries
                    .where((e) => e.status == MovieStatus.pending)
                    .length;
                final scored =
                    allEntries.where((e) => e.score != null).toList();
                final avgScore = scored.isEmpty
                    ? 0.0
                    : scored.map((e) => e.score!).reduce((a, b) => a + b) /
                        scored.length;

                // Genre distribution
                final genreCounts = <String, int>{};
                for (final entry in allEntries) {
                  for (final genre in entry.genres) {
                    genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
                  }
                }
                final topGenres = genreCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _StatCard(
                          label: 'profile.stats.total'.tr(),
                          value: '${allEntries.length}',
                          icon: Icons.movie_rounded,
                          color: AppColors.primary,
                        ),
                        _StatCard(
                          label: 'profile.stats.watched'.tr(),
                          value: '$watched',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.watched,
                        ),
                        _StatCard(
                          label: 'profile.stats.pending'.tr(),
                          value: '$pending',
                          icon: Icons.bookmark_rounded,
                          color: AppColors.pending,
                        ),
                        _StatCard(
                          label: 'profile.stats.avgScore'.tr(),
                          value: avgScore.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms),

                    // Top genres
                    if (topGenres.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'profile.genres'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...topGenres.take(5).map((entry) {
                        final maxCount = topGenres.first.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: entry.value / maxCount,
                                  backgroundColor: AppColors.surfaceLight,
                                  color: AppColors.primary,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // Shared lists
            sharedLists.when(
              data: (lists) {
                if (lists.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.sharedLists'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...lists.map((list) => Card(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(list.title,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${list.movieIds.length} ${'profile.movies'.tr()}',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.share_rounded,
                                  color: AppColors.primary, size: 20),
                              onPressed: () async {
                                final shareLink = 'https://watchedmovies-394dc.firebaseapp.com/list/${list.id}';
                                await Share.share(
                                  'share.text'.tr(args: ['${list.title}\n$shareLink']),
                                  subject: 'share.title'.tr(),
                                );
                              },
                            ),
                          ),
                        )),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
