import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/activity.dart';
import '../data/activity_repository.dart';

/// Community feed screen — social wall showing what everyone is watching & rating
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Community'),
          ],
        ),
      ),
      body: feedAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(communityFeedProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityCard(activity: activity)
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
                      duration: 350.ms,
                    )
                    .slideY(begin: 0.08, end: 0);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('Could not load feed\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
            ),
            child: const Icon(Icons.movie_filter_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start watching & rating movies to see\nthe community come alive! 🎬',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single activity card in the community feed
class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: activity.movieId != null
            ? () => context.push('/movie/${activity.movieId}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name + action
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: activity.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(text: ' ${activity.description} '),
                          TextSpan(
                            text: activity.movieTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Score (if rated)
                    if (activity.type == ActivityType.rated &&
                        activity.score != null) ...[
                      const SizedBox(height: 8),
                      _buildScoreBadge(activity.score!),
                    ],

                    const SizedBox(height: 8),

                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          _activityIcon,
                          size: 13,
                          color: _activityColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(activity.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mini poster
              if (activity.posterPath != null) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: ApiConstants.posterUrl(activity.posterPath,
                        size: ApiConstants.posterSmall),
                    width: 48,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 72,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.movie_outlined,
                          color: AppColors.textTertiary, size: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: activity.userPhotoUrl != null
            ? CachedNetworkImageProvider(activity.userPhotoUrl!)
            : null,
        child: activity.userPhotoUrl == null
            ? Text(
                activity.userName.isNotEmpty
                    ? activity.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.scoreColor(score).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.scoreColor(score).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              size: 16, color: AppColors.scoreColor(score)),
          const SizedBox(width: 4),
          Text(
            '$score/10',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.scoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _activityIcon {
    switch (activity.type) {
      case ActivityType.watched:
        return Icons.visibility_rounded;
      case ActivityType.rated:
        return Icons.star_rounded;
      case ActivityType.addedToList:
        return Icons.playlist_add_rounded;
      case ActivityType.createdList:
        return Icons.list_alt_rounded;
    }
  }

  Color get _activityColor {
    switch (activity.type) {
      case ActivityType.watched:
        return AppColors.watched;
      case ActivityType.rated:
        return AppColors.primary;
      case ActivityType.addedToList:
        return AppColors.pending;
      case ActivityType.createdList:
        return AppColors.watching;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
