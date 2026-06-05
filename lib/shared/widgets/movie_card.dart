import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../app/theme/app_colors.dart';
import '../../features/my_lists/data/list_repository.dart';
import '../../core/models/movie_entry.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/movie_detail/data/movie_repository.dart';

/// Reusable movie poster card with hover effects and rating badge
class MovieCard extends ConsumerStatefulWidget {
  final int movieId;
  final String title;
  final String? posterPath;
  final double? voteAverage;
  final String? year;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const MovieCard({
    super.key,
    required this.movieId,
    required this.title,
    this.posterPath,
    this.voteAverage,
    this.year,
    this.onTap,
    this.width = 140,
    this.height = 210,
  });

  @override
  ConsumerState<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends ConsumerState<MovieCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          transform: _isHovering
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.height == double.infinity)
                Expanded(child: _buildPosterStack())
              else
                SizedBox(
                  width: widget.width == double.infinity ? double.infinity : widget.width,
                  height: widget.height,
                  child: _buildPosterStack(),
                ),

              const SizedBox(height: 8),

              // Title
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              // Year
              if (widget.year != null)
                Text(
                  widget.year!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.textTertiary,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildPosterStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: widget.posterPath != null
              ? CachedNetworkImage(
                  imageUrl: ApiConstants.posterUrl(widget.posterPath),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildPlaceholder(),
                  errorWidget: (_, __, ___) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),

        // Rating badge
        if (widget.voteAverage != null && widget.voteAverage! > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _ratingColor(widget.voteAverage!),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: _ratingColor(widget.voteAverage!),
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.voteAverage!.toStringAsFixed(1),
                    style: TextStyle(
                      color: _ratingColor(widget.voteAverage!),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Hover overlay
        if (_isHovering)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
        
        // Watched status badge / button
        Positioned(
          top: 8,
          left: 8,
          child: Consumer(
            builder: (context, ref, child) {
              final entry = ref.watch(movieEntryProvider(widget.movieId));
              final isWatched = entry?.status == MovieStatus.watched;

              return GestureDetector(
                onTap: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debes iniciar sesión primero')),
                    );
                    return;
                  }

                  final repo = ref.read(listRepositoryProvider);
                  if (isWatched) {
                    // Remove from list
                    await repo.removeMovieEntry(user.uid, widget.movieId);
                  } else {
                    // Add as watched
                    final movieRepo = ref.read(movieRepositoryProvider);
                    try {
                      final movie = await movieRepo.getMovieDetail(widget.movieId);
                      await repo.addMovieToList(
                        userId: user.uid,
                        movie: movie,
                        status: MovieStatus.watched,
                        userName: user.displayName ?? 'User',
                        userPhotoUrl: user.photoURL,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Marcada como vista ✅'),
                            backgroundColor: AppColors.watched,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al marcar película'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isWatched
                        ? AppColors.watched
                        : AppColors.surfaceLight.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isWatched ? Icons.check_rounded : Icons.visibility_outlined,
                    color: isWatched ? Colors.white : AppColors.textPrimary,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 7.5) return AppColors.ratingHigh;
    if (rating >= 5.0) return AppColors.ratingMedium;
    return AppColors.ratingLow;
  }
}
