import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../movie_detail/data/movie_repository.dart';

/// Search & discover screen with search bar, genre filters, and results grid
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(searchQueryProvider.notifier).set(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final genres = ref.watch(genresProvider);
    final discoverFilters = ref.watch(discoverFiltersProvider);
    final discoverMovies = ref.watch(discoverMoviesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Discover'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearch,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search movies...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textTertiary),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppColors.textTertiary),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  icon: Icon(
                    _showFilters
                        ? Icons.filter_list_off_rounded
                        : Icons.filter_list_rounded,
                    color: _showFilters
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Genre filter chips
          if (_showFilters && searchQuery.isEmpty)
            genres.when(
              data: (genreList) {
                return SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: genreList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final genre = genreList[index];
                      final isSelected =
                          discoverFilters.genreId == genre.id;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(genre.name),
                        onSelected: (selected) {
                          ref
                              .read(discoverFiltersProvider.notifier)
                              .set(discoverFilters.copyWith(
                            genreId: selected ? genre.id : null,
                            clearGenre: !selected,
                          ));
                        },
                        selectedColor: AppColors.primarySurface,
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
              },
              loading: () => const SizedBox(height: 44),
              error: (_, __) => const SizedBox(),
            ),

          // Year filter
          if (_showFilters && searchQuery.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final year = DateTime.now().year - index;
                    final isSelected = discoverFilters.year == year;
                    return FilterChip(
                      selected: isSelected,
                      label: Text('$year'),
                      onSelected: (selected) {
                        ref.read(discoverFiltersProvider.notifier).set(
                            discoverFilters.copyWith(
                          year: selected ? year : null,
                          clearYear: !selected,
                        ));
                      },
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: searchQuery.isNotEmpty
                ? _buildSearchResults(searchResults)
                : _buildDiscoverResults(discoverMovies),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<dynamic>> results) {
    return results.when(
      data: (movies) {
        if (movies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text(
                  'No movies found',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ],
            ),
          );
        }
        return _buildMovieGrid(movies);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.textTertiary)),
      ),
    );
  }

  Widget _buildDiscoverResults(AsyncValue<List<dynamic>> results) {
    return results.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const Center(
            child: Text(
              'No movies found for these filters',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          );
        }
        return _buildMovieGrid(movies);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.textTertiary)),
      ),
    );
  }

  Widget _buildMovieGrid(List<dynamic> movies) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 6
            : constraints.maxWidth > 600
                ? 4
                : 3;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.52,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return MovieCard(
              movieId: movie.id,
              title: movie.title,
              posterPath: movie.posterPath,
              voteAverage: movie.voteAverage,
              year: movie.year?.toString(),
              width: double.infinity,
              height: double.infinity,
              onTap: () => context.push('/movie/${movie.id}'),
            );
          },
        );
      },
    );
  }
}
