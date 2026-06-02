import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/movie_entry.dart';
import '../../../shared/widgets/rating_widget.dart';
import '../data/list_repository.dart';

/// My Lists screen with tabs for all statuses
class MyListsScreen extends ConsumerStatefulWidget {
  const MyListsScreen({super.key});

  @override
  ConsumerState<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends ConsumerState<MyListsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We watch the streams to handle loading/error states for the whole page
    final allEntriesAsync = ref.watch(movieEntriesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('My Lists'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final sortBy = ref.watch(listSortProvider);
              return PopupMenuButton<ListSortOption>(
                icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
                color: AppColors.surface,
                onSelected: (value) => ref.read(listSortProvider.notifier).updateState(value),
                itemBuilder: (_) => [
                  _sortMenuItem(ListSortOption.dateAddedDesc, 'Date Added (Newest)', Icons.calendar_today_rounded, sortBy),
                  _sortMenuItem(ListSortOption.dateAddedAsc, 'Date Added (Oldest)', Icons.calendar_today_outlined, sortBy),
                  _sortMenuItem(ListSortOption.ratingDesc, 'Score', Icons.star_rounded, sortBy),
                  _sortMenuItem(ListSortOption.titleAsc, 'Title', Icons.sort_by_alpha_rounded, sortBy),
                  _sortMenuItem(ListSortOption.releaseYearDesc, 'Year', Icons.date_range_rounded, sortBy),
                ],
              );
            }
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '✅ Watched'),
            Tab(text: '📋 Pending'),
            Tab(text: '▶️ Watching'),
            Tab(text: '❌ Abandoned'),
          ],
        ),
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: allEntriesAsync.when(
              data: (_) {
                // The actual lists are obtained through the filtered providers synchronously
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(ref.watch(allFilteredMoviesProvider)),
                    _buildList(ref.watch(watchedMoviesProvider)),
                    _buildList(ref.watch(pendingMoviesProvider)),
                    _buildList(ref.watch(watchingMoviesProvider)),
                    _buildList(ref.watch(abandonedMoviesProvider)),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.textTertiary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ListSortOption> _sortMenuItem(
      ListSortOption value, String label, IconData icon, ListSortOption currentSort) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: currentSort == value
                  ? AppColors.primary
                  : AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: currentSort == value
                  ? AppColors.primary
                  : AppColors.textPrimary,
              fontWeight:
                  currentSort == value ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<MovieEntry> entries) {
    final sorted = entries; // Already sorted and filtered by the providers

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined,
                size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text(
              'No movies here yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browse and add movies to your list!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Discover'),
            ),
          ],
        ),
      );
    }

    // Stats header
    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                '${sorted.length} movies',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (sorted.any((e) => e.score != null))
                Text(
                  'Avg: ${_avgScore(sorted).toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),

        // Movie list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final entry = sorted[index];
              return _MovieListTile(entry: entry)
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
                    duration: 300.ms,
                  )
                  .slideX(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }

  double _avgScore(List<MovieEntry> entries) {
    final scored = entries.where((e) => e.score != null).toList();
    if (scored.isEmpty) return 0;
    return scored.map((e) => e.score!).reduce((a, b) => a + b) /
        scored.length;
  }
}

class _MovieListTile extends StatelessWidget {
  final MovieEntry entry;

  const _MovieListTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/movie/${entry.tmdbId}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: entry.posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: ApiConstants.posterUrl(entry.posterPath,
                            size: ApiConstants.posterSmall),
                        width: 56,
                        height: 84,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 84,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.movie_outlined,
                            color: AppColors.textTertiary, size: 20),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry.year != null)
                          Text(
                            '${entry.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        if (entry.year != null && entry.genres.isNotEmpty)
                          const Text(' • ',
                              style: TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12)),
                        if (entry.genres.isNotEmpty)
                          Expanded(
                            child: Text(
                              entry.genres.take(2).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.statusColor(entry.status.name)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.status.icon} ${entry.status.label}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusColor(entry.status.name),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Score badge
              if (entry.score != null) ...[
                const SizedBox(width: 8),
                RatingBadge(score: entry.score!, fontSize: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get unique genres from all user movies to populate the filter
    final allEntries = ref.watch(movieEntriesStreamProvider).value ?? [];
    final Set<String> genres = {};
    for (final entry in allEntries) {
      genres.addAll(entry.genres);
    }
    final sortedGenres = genres.toList()..sort();

    final selectedGenre = ref.watch(listGenreFilterProvider);

    if (sortedGenres.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sortedGenres.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedGenre == null;
            return FilterChip(
              label: const Text('All Genres'),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary.withOpacity(0.2),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
              ),
              onSelected: (_) => ref.read(listGenreFilterProvider.notifier).updateState(null),
            );
          }

          final genre = sortedGenres[index - 1];
          final isSelected = selectedGenre == genre;
          
          return FilterChip(
            label: Text(genre),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: AppColors.primary.withOpacity(0.2),
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            ),
            onSelected: (_) => ref.read(listGenreFilterProvider.notifier).updateState(genre),
          );
        },
      ),
    );
  }
}
