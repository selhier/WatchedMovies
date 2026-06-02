import 'package:flutter_dotenv/flutter_dotenv.dart';

/// TMDB API constants and helpers
class ApiConstants {
  ApiConstants._();

  // ─── TMDB API ─────────────────────────────────────────────
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/';

  // Access token for TMDB API (read-only)
  static String get tmdbAccessToken =>
      dotenv.env['TMDB_ACCESS_TOKEN'] ??
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2MmMyZjRjYzk1YzY0Yjk2NGRiNjU1ZjU4NjE1ODkxOSIsIm5iZiI6MTYxNjIyNTQ4OS41MzIsInN1YiI6IjYwNTVhNGQxMmFjNDk5MDA3NTZiZGQ5MiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.2D7UkX7t0sVXH_930ZaPAkn7ye7IzbWTlsG8WFs5wkM';
  static String get tmdbApiKey =>
      dotenv.env['TMDB_API_KEY'] ?? '62c2f4cc95c64b964db655f586158919';

  // ─── Image Sizes ──────────────────────────────────────────
  static const String posterSmall = 'w185';
  static const String posterMedium = 'w342';
  static const String posterLarge = 'w500';
  static const String posterOriginal = 'original';
  static const String backdropSmall = 'w300';
  static const String backdropMedium = 'w780';
  static const String backdropLarge = 'w1280';
  static const String backdropOriginal = 'original';
  static const String profileSmall = 'w45';
  static const String profileMedium = 'w185';

  // ─── Endpoints ────────────────────────────────────────────
  static const String trendingMovies = '/trending/movie/week';
  static const String popularMovies = '/movie/popular';
  static const String topRatedMovies = '/movie/top_rated';
  static const String upcomingMovies = '/movie/upcoming';
  static const String nowPlayingMovies = '/movie/now_playing';
  static const String searchMovies = '/search/movie';
  static const String discoverMovies = '/discover/movie';
  static const String genreList = '/genre/movie/list';

  static String movieDetail(int id) => '/movie/$id';
  static String movieCredits(int id) => '/movie/$id/credits';
  static String movieSimilar(int id) => '/movie/$id/similar';
  static String movieRecommendations(int id) => '/movie/$id/recommendations';
  static String movieImages(int id) => '/movie/$id/images';

  // ─── Image URL Builders ───────────────────────────────────
  static String posterUrl(String? path, {String size = posterMedium}) {
    if (path == null || path.isEmpty) return '';
    return '$tmdbImageBaseUrl$size$path';
  }

  static String backdropUrl(String? path, {String size = backdropMedium}) {
    if (path == null || path.isEmpty) return '';
    return '$tmdbImageBaseUrl$size$path';
  }

  static String profileUrl(String? path, {String size = profileMedium}) {
    if (path == null || path.isEmpty) return '';
    return '$tmdbImageBaseUrl$size$path';
  }
}
