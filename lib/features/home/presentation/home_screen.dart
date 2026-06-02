import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../movie_detail/data/movie_repository.dart';
import '../../my_lists/data/list_repository.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/movie_entry.dart' show MovieStatus;
import '../../../core/models/movie.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Home screen with trending carousel, popular movies, and quick access to user lists
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(popularMoviesProvider);
          ref.invalidate(topRatedMoviesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      size: 18,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('WatchedMovies'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => context.go('/search'),
                ),
              ],
            ),

            // Trending Section (Hero Carousel)
            SliverToBoxAdapter(
              child: _TrendingCarousel(),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: _QuickStats(),
            ),

            // Recommendations
            SliverToBoxAdapter(
              child: _MovieSection(
                title: '✨ Recomendado para ti',
                provider: recommendedMoviesProvider,
              ),
            ),

            // Popular Movies
            SliverToBoxAdapter(
              child: _MovieSection(
                title: '🔥 Popular Now',
                provider: popularMoviesProvider,
              ),
            ),

            // Top Rated
            SliverToBoxAdapter(
              child: _MovieSection(
                title: '⭐ Top Rated',
                provider: topRatedMoviesProvider,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trending movies horizontal carousel with backdrop images
class _TrendingCarousel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends ConsumerState<_TrendingCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      if (_pageController.page != null) {
        _currentPage = _pageController.page!.round();
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _itemCount > 0) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _itemCount) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(trendingMoviesProvider);

    return trending.when(
      data: (movies) {
        if (movies.isEmpty) return const SizedBox();
        _itemCount = movies.length.clamp(0, 10);
        return SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _itemCount,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () => context.push('/movie/${movie.id}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Backdrop image
                        CachedNetworkImage(
                          imageUrl: ApiConstants.backdropUrl(
                            movie.backdropPath,
                            size: ApiConstants.backdropLarge,
                          ),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),

                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),

                        // Content
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'TRENDING',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textOnPrimary,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    movie.voteAverage
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (movie.releaseDate != null &&
                                  movie.releaseDate!.isNotEmpty)
                                Text(
                                  movie.releaseDate!.substring(0, 4),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: 0.1, end: 0),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 220,
        child: Center(
          child: Text('Error loading trending: $e',
              style: const TextStyle(color: AppColors.textTertiary)),
        ),
      ),
    );
  }
}

/// Quick stats showing user's movie counts
class _QuickStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(movieEntriesStreamProvider);

    return entries.when(
      data: (movies) {
        if (movies.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Start tracking!',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tap any movie to add it to your list',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          );
        }

        final watched = movies.where((e) => e.status == MovieStatus.watched).length;
        final pending = movies.where((e) => e.status == MovieStatus.pending).length;
        final watching = movies.where((e) => e.status == MovieStatus.watching).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _StatChip(
                  count: watched,
                  label: 'Watched',
                  color: AppColors.watched,
                  icon: Icons.check_circle_rounded),
              const SizedBox(width: 8),
              _StatChip(
                  count: pending,
                  label: 'Pending',
                  color: AppColors.pending,
                  icon: Icons.bookmark_rounded),
              const SizedBox(width: 8),
              _StatChip(
                  count: watching,
                  label: 'Watching',
                  color: AppColors.watching,
                  icon: Icons.play_circle_rounded),
            ],
          ).animate().fadeIn(duration: 400.ms),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Movie section with horizontal scrolling list
class _MovieSection extends ConsumerWidget {
  final String title;
  final FutureProvider<List<Movie>> provider;

  const _MovieSection({
    required this.title,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(provider);

    // Let it build the section so we can see if it's empty

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        moviesAsync.when(
          data: (movies) {
            if (movies.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Text(
                  'Agrega películas o califícalas para recibir recomendaciones personalizadas.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              );
            }
            return SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return MovieCard(
                    movieId: movie.id,
                    title: movie.title,
                    posterPath: movie.posterPath,
                    voteAverage: movie.voteAverage,
                    year: movie.year?.toString(),
                    onTap: () => context.push('/movie/${movie.id}'),
                  );
                },
              ),
            );
          },
          loading: () => const ShimmerMovieRow(),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ),
      ],
    );
  }
}
