import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/activity.dart';
import '../data/activity_repository.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/notification_repository.dart';
import 'activity_comments_sheet.dart';
import '../../../core/widgets/empty_state_widget.dart';

/// Community feed screen — social wall showing what everyone is watching & rating
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Reached the bottom, load more
      final currentLimit = ref.read(feedLimitProvider);
      ref.read(feedLimitProvider.notifier).state = currentLimit + 20;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(communityFeedProvider);
    final followingIdsAsync = ref.watch(myFollowingIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Community'),
          ],
        ),
        actions: [
          _NotificationBell(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── GLOBAL TAB ──────────────────────────────────────────────────
          feedAsync.when(
            data: (activities) => _buildFeedList(activities),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => _buildErrorState(e),
          ),

          // ─── FOLLOWING TAB ───────────────────────────────────────────────
          followingIdsAsync.when(
            data: (followingIds) {
              if (followingIds.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.person_add_rounded,
                  title: 'No following yet',
                  subtitle: 'Follow other users to see their activity here.',
                );
              }
              return feedAsync.when(
                data: (activities) {
                  final followingActivities = activities
                      .where((a) => followingIds.contains(a.userId))
                      .toList();
                  return _buildFeedList(followingActivities, isFollowingTab: true);
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => _buildErrorState(e),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => _buildErrorState(e),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(List<Activity> activities, {bool isFollowingTab = false}) {
    if (activities.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.movie_filter_rounded,
        title: isFollowingTab ? 'No recent activity' : 'No activity yet',
        subtitle: isFollowingTab
            ? 'The people you follow haven\'t done anything recently.'
            : 'Start watching & rating movies to see the community come alive! 🎬',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(communityFeedProvider);
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: activities.length + 1, // +1 for loading indicator
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == activities.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
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
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Could not load feed\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

/// A single activity card in the community feed
class _ActivityCard extends ConsumerWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              GestureDetector(
                onTap: () {
                  context.push('/user/${activity.userId}');
                },
                child: _buildAvatar(),
              ),
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

                    // Review (if any)
                    if (activity.review != null &&
                        activity.review!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.divider.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '"${activity.review!}"',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
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

                    const SizedBox(height: 12),

                    // Actions (Like / Comment)
                    _buildActions(context, ref),
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

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isLiked = user != null && activity.likedBy.contains(user.uid);

    return Row(
      children: [
        // Like Button
        InkWell(
          onTap: user == null
              ? null
              : () {
                  ref
                      .read(activityRepositoryProvider)
                      .toggleLikeActivity(activity.id, user.uid);
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  size: 18,
                  color: isLiked ? AppColors.error : AppColors.textTertiary,
                )
                .animate(target: isLiked ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 150.ms)
                .then()
                .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 150.ms),
                if (activity.likesCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${activity.likesCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isLiked ? AppColors.error : AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Comment Button
        InkWell(
          onTap: () {
            ActivityCommentsSheet.show(context, activity.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_rounded),
        onPressed: () => context.push('/notifications'),
      );
    }

    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider(user.uid));

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push('/notifications'),
        ),
        unreadCountAsync.when(
          data: (count) {
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
