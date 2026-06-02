import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/movie.dart';
import '../../../core/network/tmdb_client.dart';
import '../../../core/providers/language_provider.dart';
import '../../my_lists/data/list_repository.dart';
import '../../../core/models/movie_entry.dart';
/// Provides the movie repository
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository();
});

/// Provider for trending movies
final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getTrendingMovies(language: lang);
});

/// Provider for popular movies
final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getPopularMovies(language: lang);
});

/// Provider for top rated movies
final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getTopRatedMovies(language: lang);
});

/// Provider for personalized recommendations based on highest rated/watched movies
final recommendedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  
  if (entries.isEmpty) {
    return []; // No base movies to recommend from
  }

  // Get highly rated movies (score >= 8), or if none, recently added watched movies
  var baseMovies = entries.where((e) => e.score != null && e.score! >= 8).toList();
  if (baseMovies.isEmpty) {
    baseMovies = entries.where((e) => e.status == MovieStatus.watched).toList();
  }
  if (baseMovies.isEmpty) {
    baseMovies = entries.take(3).toList();
  }

  // Shuffle and take up to 2 movies to base recommendations on
  baseMovies.shuffle();
  final targetMovies = baseMovies.take(2).toList();
  
  final Set<int> recommendedIds = {};
  final List<Movie> allRecommendations = [];

  for (final movie in targetMovies) {
    try {
      final recs = await repo.getRecommendations(movie.tmdbId);
      for (final rec in recs) {
        if (!recommendedIds.contains(rec.id) && !entries.any((e) => e.tmdbId == rec.id)) {
          recommendedIds.add(rec.id);
          allRecommendations.add(rec);
        }
      }
    } catch (_) {
      // Ignore errors for individual movie recommendation requests
    }
  }

  allRecommendations.shuffle();
  return allRecommendations.take(20).toList();
});

/// Provider for movie details (parameterized by movieId)
final movieDetailProvider =
    FutureProvider.family<Movie, int>((ref, movieId) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getMovieDetail(movieId, language: lang);
});

/// Provider for movie credits (parameterized by movieId)
final movieCreditsProvider =
    FutureProvider.family<List<CastMember>, int>((ref, movieId) async {
  final repo = ref.watch(movieRepositoryProvider);
  // Credits doesn't take language
  return repo.getMovieCredits(movieId);
});

/// Provider for similar movies
final similarMoviesProvider =
    FutureProvider.family<List<Movie>, int>((ref, movieId) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getSimilarMovies(movieId, language: lang);
});

/// Provider for search results
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String val) => state = val;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

final searchResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.watch(movieRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.searchMovies(query, language: lang);
});

/// Provider for genres
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getGenres();
});

/// Provider for discover movies with filters
class DiscoverFiltersNotifier extends Notifier<DiscoverFilters> {
  @override
  DiscoverFilters build() => const DiscoverFilters();
  void set(DiscoverFilters val) => state = val;
}
final discoverFiltersProvider = NotifierProvider<DiscoverFiltersNotifier, DiscoverFilters>(() => DiscoverFiltersNotifier());

final discoverMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final filters = ref.watch(discoverFiltersProvider);
  final repo = ref.watch(movieRepositoryProvider);
  return repo.discoverMovies(
    genreId: filters.genreId,
    year: filters.year,
    sortBy: filters.sortBy,
  );
});

/// Filters for discover screen
class DiscoverFilters {
  final int? genreId;
  final int? year;
  final String sortBy;

  const DiscoverFilters({
    this.genreId,
    this.year,
    this.sortBy = 'popularity.desc',
  });

  DiscoverFilters copyWith({
    int? genreId,
    int? year,
    String? sortBy,
    bool clearGenre = false,
    bool clearYear = false,
  }) {
    return DiscoverFilters(
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      year: clearYear ? null : (year ?? this.year),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Repository wrapping TMDB API calls and mapping to domain models
class MovieRepository {
  final TmdbClient _client = TmdbClient.instance;

  Future<List<Movie>> getTrendingMovies({String language = 'en-US'}) async {
    final results = await _client.getTrendingMovies(language: language);
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> getPopularMovies({
    int page = 1,
    String language = 'en-US',
  }) async {
    final results = await _client.getPopularMovies(page: page, language: language);
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> getTopRatedMovies({
    int page = 1,
    String language = 'en-US',
  }) async {
    final results = await _client.getTopRatedMovies(page: page, language: language);
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Movie> getMovieDetail(
    int movieId, {
    String language = 'en-US',
  }) async {
    final json = await _client.getMovieDetail(movieId, language: language);
    return Movie.fromJson(json);
  }

  Future<List<CastMember>> getMovieCredits(int movieId) async {
    final results = await _client.getMovieCredits(movieId);
    return results
        .map((json) => CastMember.fromJson(json as Map<String, dynamic>))
        .take(20)
        .toList();
  }

  Future<List<Movie>> getSimilarMovies(
    int movieId, {
    String language = 'en-US',
  }) async {
    final results = await _client.getSimilarMovies(movieId, language: language);
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> getRecommendations(int movieId) async {
    final results = await _client.getMovieRecommendations(movieId);
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    String language = 'en-US',
  }) async {
    final results = await _client.searchMovies(query, page: page, language: language);
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> discoverMovies({
    int? genreId,
    int? year,
    String sortBy = 'popularity.desc',
    int page = 1,
  }) async {
    final results = await _client.discoverMovies(
      withGenres: genreId?.toString(),
      year: year,
      sortBy: sortBy,
      page: page,
    );
    return results
        .map((json) => Movie.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Genre>> getGenres({String language = 'en-US'}) async {
    final results = await _client.getGenres(language: language);
    return results
        .map((json) => Genre.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
