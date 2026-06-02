import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/movie_entry.dart';
import '../../../shared/widgets/rating_widget.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/movie_card.dart';
import '../data/movie_repository.dart';
import '../../my_lists/data/list_repository.dart';
import '../../auth/data/auth_repository.dart';

/// Movie detail screen with hero backdrop, info, cast, and add-to-list functionality
class MovieDetailScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieAsync = ref.watch(movieDetailProvider(movieId));
    final creditsAsync = ref.watch(movieCreditsProvider(movieId));
    final similarAsync = ref.watch(similarMoviesProvider(movieId));
    final existingEntry = ref.watch(movieEntryProvider(movieId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: movieAsync.when(
        data: (movie) {
          return CustomScrollView(
            slivers: [
              // Hero backdrop
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (movie.backdropPath != null)
                        CachedNetworkImage(
                          imageUrl: ApiConstants.backdropUrl(
                            movie.backdropPath,
                            size: ApiConstants.backdropLarge,
                          ),
                          fit: BoxFit.cover,
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withOpacity(0.5),
                              AppColors.background,
                            ],
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Movie Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster + Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: movie.posterPath != null
                                ? CachedNetworkImage(
                                    imageUrl: ApiConstants.posterUrl(
                                        movie.posterPath,
                                        size: ApiConstants.posterMedium),
                                    width: 120,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 120,
                                    height: 180,
                                    color: AppColors.surfaceLight,
                                    child: const Icon(Icons.movie_outlined,
                                        color: AppColors.textTertiary),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Title & meta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                if (movie.tagline != null &&
                                    movie.tagline!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    movie.tagline!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // Meta row
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    if (movie.year != null)
                                      _MetaChip(
                                        icon: Icons.calendar_today_rounded,
                                        label: movie.year.toString(),
                                      ),
                                    if (movie.runtime != null &&
                                        movie.runtime! > 0)
                                      _MetaChip(
                                        icon: Icons.access_time_rounded,
                                        label: movie.formattedRuntime,
                                      ),
                                    _MetaChip(
                                      icon: Icons.star_rounded,
                                      label:
                                          movie.voteAverage.toStringAsFixed(1),
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // User's entry status badge
                                if (existingEntry != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusColor(
                                              existingEntry.status.name)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.statusColor(
                                                existingEntry.status.name)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          existingEntry.status.icon,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          existingEntry.status.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.statusColor(
                                                existingEntry.status.name),
                                          ),
                                        ),
                                        if (existingEntry.score != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${existingEntry.score}/10',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.scoreColor(
                                                  existingEntry.score!),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 16),

                      // Genres
                      if (movie.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: movie.genres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                genre.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 20),

                      // Overview
                      if (movie.overview != null &&
                          movie.overview!.isNotEmpty) ...[
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.overview!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],

                      const SizedBox(height: 24),

                      // Cast
                      creditsAsync.when(
                        data: (cast) {
                          if (cast.isEmpty) return const SizedBox();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cast',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cast.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final member = cast[index];
                                    return SizedBox(
                                      width: 70,
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor:
                                                AppColors.surfaceLight,
                                            backgroundImage: member
                                                        .profilePath !=
                                                    null
                                                ? CachedNetworkImageProvider(
                                                    ApiConstants.profileUrl(
                                                        member.profilePath),
                                                  )
                                                : null,
                                            child:
                                                member.profilePath == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        color: AppColors
                                                            .textTertiary,
                                                        size: 20,
                                                      )
                                                    : null,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            member.name,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (member.character != null)
                                            Text(
                                              member.character!,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color:
                                                    AppColors.textTertiary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms);
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),

                      const SizedBox(height: 24),

                      // Similar Movies
                      similarAsync.when(
                        data: (movies) {
                          if (movies.isEmpty) return const SizedBox();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Similar Movies',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 280,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: movies.length.clamp(0, 10),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final m = movies[index];
                                    return MovieCard(
                                      movieId: m.id,
                                      title: m.title,
                                      posterPath: m.posterPath,
                                      voteAverage: m.voteAverage,
                                      year: m.year?.toString(),
                                      onTap: () =>
                                          context.push('/movie/${m.id}'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 400.ms);
                        },
                        loading: () => const ShimmerMovieRow(),
                        error: (_, __) => const SizedBox(),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const ShimmerMovieDetail(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.abandoned, size: 48),
              const SizedBox(height: 12),
              Text('Error: $e',
                  style: const TextStyle(color: AppColors.textTertiary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),

      // FAB: Add/Edit in list
      floatingActionButton: movieAsync.when(
        data: (movie) => FloatingActionButton.extended(
          onPressed: () => _showAddToListSheet(context, ref, movie, existingEntry),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          icon: Icon(existingEntry != null ? Icons.edit_rounded : Icons.add_rounded),
          label: Text(existingEntry != null ? 'Edit' : 'Add to List'),
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  void _showAddToListSheet(BuildContext context, WidgetRef ref, dynamic movie,
      MovieEntry? existing) {
    var selectedStatus = existing?.status ?? MovieStatus.pending;
    int? selectedScore = existing?.score;
    final reviewController =
        TextEditingController(text: existing?.review ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      existing != null ? 'Edit Entry' : 'Add to List',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status selector
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MovieStatus.values.map((status) {
                        final isSelected = selectedStatus == status;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedStatus = status);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.statusColor(status.name)
                                      .withOpacity(0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.statusColor(status.name)
                                    : AppColors.divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(status.icon,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  status.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.statusColor(status.name)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Score
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingWidget(
                      currentRating: selectedScore,
                      onRatingChanged: (value) {
                        setSheetState(() => selectedScore = value);
                      },
                      size: 28,
                    ),

                    const SizedBox(height: 20),

                    // Review
                    const Text(
                      'Notes (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Write your thoughts...',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        if (existing != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final user =
                                    ref.read(authStateProvider).value;
                                if (user != null) {
                                  await ref
                                      .read(listRepositoryProvider)
                                      .removeMovieEntry(user.uid, movieId);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.abandoned),
                              label: const Text('Remove',
                                  style:
                                      TextStyle(color: AppColors.abandoned)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.abandoned),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        if (existing != null) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final user =
                                  ref.read(authStateProvider).value;
                              if (user == null) return;

                              await ref
                                  .read(listRepositoryProvider)
                                  .addMovieToList(
                                    userId: user.uid,
                                    movie: movie,
                                    status: selectedStatus,
                                    score: selectedScore,
                                    review: reviewController.text.isEmpty
                                        ? null
                                        : reviewController.text,
                                  );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(existing != null
                                        ? 'Entry updated!'
                                        : 'Added to list!'),
                                  ),
                                );
                              }
                            },
                            child: Text(
                                existing != null ? 'Update' : 'Add'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
