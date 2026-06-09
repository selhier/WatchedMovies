import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../core/constants/responsive_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/comment.dart';
import '../../movie_detail/data/movie_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../data/shared_list_repository.dart';

/// Screen to view a shared list publicly via a link/ID
/// Now includes likes and comments
class PublicSharedListScreen extends ConsumerWidget {
  final String listId;

  const PublicSharedListScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use stream provider for real-time like updates
    final sharedListAsync = ref.watch(sharedListStreamProvider(listId));
    final commentsAsync = ref.watch(commentsStreamProvider(listId));
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Shared List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: sharedListAsync.when(
        data: (list) {
          if (list == null) {
            return _buildErrorState('List not found or is private.');
          }

          return Column(
            children: [
              // Scrollable content
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Header info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              list.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Created by ${list.ownerName}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (list.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                list.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // ── Like Button ─────────────────────
                            _LikeButton(
                              list: list,
                              currentUserId: currentUser?.uid,
                            ),

                            const SizedBox(height: 20),
                            Divider(color: AppColors.divider),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Movies Grid
                    if (list.movieIds.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'This list is empty.',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final movieId = list.movieIds[index];
                              return _SharedMovieItem(movieId: movieId);
                            },
                            childCount: list.movieIds.length,
                          ),
                        ),
                      ),

                    // ── Comments Section ─────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Comments',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            commentsAsync.when(
                              data: (comments) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${comments.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Comments list
                    commentsAsync.when(
                      data: (comments) {
                        if (comments.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No comments yet. Be the first! 💬',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final comment = comments[index];
                                return _CommentTile(
                                  comment: comment,
                                  listId: listId,
                                  isOwn: currentUser?.uid == comment.userId,
                                ).animate().fadeIn(
                                      delay: Duration(
                                          milliseconds:
                                              (index * 50).clamp(0, 300)),
                                      duration: 300.ms,
                                    );
                              },
                              childCount: comments.length,
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                      error: (_, __) => const SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),

              // ── Comment Input Bar ─────────────────
              if (currentUser != null)
                _CommentInputBar(
                  listId: listId,
                  userId: currentUser.uid,
                  userName: currentUser.displayName ?? 'User',
                  userPhotoUrl: currentUser.photoURL,
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => _buildErrorState('Error loading list: $err'),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Like Button with animation
// ═══════════════════════════════════════════════════════════════

class _LikeButton extends ConsumerStatefulWidget {
  final SharedList list;
  final String? currentUserId;

  const _LikeButton({required this.list, this.currentUserId});

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.currentUserId != null &&
        widget.list.isLikedBy(widget.currentUserId!);

    return GestureDetector(
      onTap: () async {
        if (widget.currentUserId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to like lists')),
          );
          return;
        }
        _animController.forward(from: 0);
        await ref
            .read(sharedListRepositoryProvider)
            .toggleLikeList(widget.list.id, widget.currentUserId!);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isLiked
              ? const Color(0xFFFF4757).withOpacity(0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLiked
                ? const Color(0xFFFF4757).withOpacity(0.4)
                : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? const Color(0xFFFF4757) : AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.list.likesCount}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isLiked ? const Color(0xFFFF4757) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Comment Tile
// ═══════════════════════════════════════════════════════════════

class _CommentTile extends ConsumerWidget {
  final Comment comment;
  final String listId;
  final bool isOwn;

  const _CommentTile({
    required this.comment,
    required this.listId,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface,
            backgroundImage: comment.userAvatar != null
                ? NetworkImage(comment.userAvatar!)
                : null,
            child: comment.userAvatar == null
                ? Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    if (isOwn)
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: const Text('Delete comment?',
                                  style: TextStyle(color: AppColors.textPrimary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: AppColors.abandoned)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(sharedListRepositoryProvider)
                                .deleteComment(listId, comment.id);
                          }
                        },
                        child: const Icon(Icons.more_horiz_rounded,
                            size: 16, color: AppColors.textTertiary),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}

// ═══════════════════════════════════════════════════════════════
// Comment Input Bar (sticky at bottom)
// ═══════════════════════════════════════════════════════════════

class _CommentInputBar extends ConsumerStatefulWidget {
  final String listId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const _CommentInputBar({
    required this.listId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  ConsumerState<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends ConsumerState<_CommentInputBar> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ref.read(sharedListRepositoryProvider).addComment(
            widget.listId,
            Comment(
              id: '',
              userId: widget.userId,
              userName: widget.userName,
              userAvatar: widget.userPhotoUrl,
              text: text,
              createdAt: DateTime.now(),
            ),
          );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).viewPadding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: AppColors.textOnPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared Movie Item
// ═══════════════════════════════════════════════════════════════

class _SharedMovieItem extends ConsumerWidget {
  final int movieId;

  const _SharedMovieItem({required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieAsync = ref.watch(movieDetailProvider(movieId));

    return movieAsync.when(
      data: (movie) {
        return MovieCard(
          movieId: movie.id,
          title: movie.title,
          posterPath: movie.posterPath,
          voteAverage: movie.voteAverage,
          year: movie.releaseDate?.isNotEmpty == true
              ? movie.releaseDate!.substring(0, 4)
              : '',
          width: double.infinity,
          height: double.infinity,
          onTap: () => context.push('/movie/${movie.id}'),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      error: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.broken_image_rounded, color: AppColors.textTertiary),
      ),
    );
  }
}
