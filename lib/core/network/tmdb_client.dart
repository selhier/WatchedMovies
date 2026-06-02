import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Singleton TMDB API client with Dio
class TmdbClient {
  static TmdbClient? _instance;
  late final Dio _dio;

  TmdbClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Authorization': 'Bearer ${ApiConstants.tmdbAccessToken}',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add logging in debug mode
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Log errors for debugging
          print('TMDB API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  static TmdbClient get instance {
    _instance ??= TmdbClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // ─── Convenience Methods ──────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // ─── Movie Endpoints ──────────────────────────────────────

  Future<List<dynamic>> getTrendingMovies({String language = 'en-US'}) async {
    final response = await get(
      ApiConstants.trendingMovies,
      queryParameters: {'language': language},
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<List<dynamic>> getPopularMovies({
    String language = 'en-US',
    int page = 1,
  }) async {
    final response = await get(
      ApiConstants.popularMovies,
      queryParameters: {'language': language, 'page': page},
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<List<dynamic>> getTopRatedMovies({
    String language = 'en-US',
    int page = 1,
  }) async {
    final response = await get(
      ApiConstants.topRatedMovies,
      queryParameters: {'language': language, 'page': page},
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMovieDetail(
    int movieId, {
    String language = 'en-US',
  }) async {
    final response = await get(
      ApiConstants.movieDetail(movieId),
      queryParameters: {'language': language},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMovieCredits(int movieId) async {
    final response = await get(ApiConstants.movieCredits(movieId));
    return response.data['cast'] as List<dynamic>;
  }

  Future<List<dynamic>> getSimilarMovies(
    int movieId, {
    String language = 'en-US',
  }) async {
    final response = await get(
      ApiConstants.movieSimilar(movieId),
      queryParameters: {'language': language},
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<List<dynamic>> getMovieRecommendations(
    int movieId, {
    String language = 'en-US',
  }) async {
    final response = await get(
      ApiConstants.movieRecommendations(movieId),
      queryParameters: {'language': language},
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<List<dynamic>> searchMovies(
    String query, {
    String language = 'en-US',
    int page = 1,
  }) async {
    final response = await get(
      ApiConstants.searchMovies,
      queryParameters: {
        'query': query,
        'language': language,
        'page': page,
      },
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<List<dynamic>> discoverMovies({
    String language = 'en-US',
    int page = 1,
    String? withGenres,
    int? year,
    String sortBy = 'popularity.desc',
  }) async {
    final params = <String, dynamic>{
      'language': language,
      'page': page,
      'sort_by': sortBy,
    };
    if (withGenres != null) params['with_genres'] = withGenres;
    if (year != null) params['primary_release_year'] = year;

    final response = await get(
      ApiConstants.discoverMovies,
      queryParameters: params,
    );
    return response.data['results'] as List<dynamic>;
  }

  Future<List<dynamic>> getGenres({String language = 'en-US'}) async {
    final response = await get(
      ApiConstants.genreList,
      queryParameters: {'language': language},
    );
    return response.data['genres'] as List<dynamic>;
  }
}
