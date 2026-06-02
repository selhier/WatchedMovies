import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/movie_entry.dart';
import '../../../core/models/movie.dart';
import '../../auth/data/auth_repository.dart';

/// Provides the list repository
final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository();
});

/// Stream of all movie entries for the current user
final movieEntriesStreamProvider =
    StreamProvider<List<MovieEntry>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(listRepositoryProvider).watchMovieEntries(user.uid);
});

enum ListSortOption {
  dateAddedDesc,
  dateAddedAsc,
  ratingDesc,
  titleAsc,
  releaseYearDesc,
}

class ListSortNotifier extends Notifier<ListSortOption> {
  @override
  ListSortOption build() => ListSortOption.dateAddedDesc;
  void updateState(ListSortOption newValue) => state = newValue;
}
final listSortProvider = NotifierProvider<ListSortNotifier, ListSortOption>(ListSortNotifier.new);

class ListGenreFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateState(String? newValue) => state = newValue;
}
final listGenreFilterProvider = NotifierProvider<ListGenreFilterNotifier, String?>(ListGenreFilterNotifier.new);

List<MovieEntry> _applySortAndFilter(List<MovieEntry> entries, ListSortOption sort, String? genre) {
  var result = entries;
  if (genre != null && genre.isNotEmpty) {
    result = result.where((e) => e.genres.contains(genre)).toList();
  }
  
  result = List.from(result);
  result.sort((a, b) {
    switch (sort) {
      case ListSortOption.dateAddedDesc:
        return b.addedAt.compareTo(a.addedAt);
      case ListSortOption.dateAddedAsc:
        return a.addedAt.compareTo(b.addedAt);
      case ListSortOption.ratingDesc:
        return (b.score ?? -1).compareTo(a.score ?? -1);
      case ListSortOption.titleAsc:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case ListSortOption.releaseYearDesc:
        return (b.year ?? 0).compareTo(a.year ?? 0);
    }
  });
  return result;
}

/// Filtered movie entries by status
final watchedMoviesProvider = Provider<List<MovieEntry>>((ref) {
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  final filtered = entries.where((e) => e.status == MovieStatus.watched).toList();
  return _applySortAndFilter(filtered, ref.watch(listSortProvider), ref.watch(listGenreFilterProvider));
});

final pendingMoviesProvider = Provider<List<MovieEntry>>((ref) {
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  final filtered = entries.where((e) => e.status == MovieStatus.pending).toList();
  return _applySortAndFilter(filtered, ref.watch(listSortProvider), ref.watch(listGenreFilterProvider));
});

final abandonedMoviesProvider = Provider<List<MovieEntry>>((ref) {
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  final filtered = entries.where((e) => e.status == MovieStatus.abandoned).toList();
  return _applySortAndFilter(filtered, ref.watch(listSortProvider), ref.watch(listGenreFilterProvider));
});

final watchingMoviesProvider = Provider<List<MovieEntry>>((ref) {
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  final filtered = entries.where((e) => e.status == MovieStatus.watching).toList();
  return _applySortAndFilter(filtered, ref.watch(listSortProvider), ref.watch(listGenreFilterProvider));
});

final allFilteredMoviesProvider = Provider<List<MovieEntry>>((ref) {
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  return _applySortAndFilter(entries, ref.watch(listSortProvider), ref.watch(listGenreFilterProvider));
});

/// Check if a specific movie is in the user's list
final movieEntryProvider =
    Provider.family<MovieEntry?, int>((ref, tmdbId) {
  final entries = ref.watch(movieEntriesStreamProvider).value ?? [];
  try {
    return entries.firstWhere((e) => e.tmdbId == tmdbId);
  } catch (_) {
    return null;
  }
});

/// Repository for user's movie list CRUD operations with Firestore
class ListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Watch all movie entries for a user (real-time)
  Stream<List<MovieEntry>> watchMovieEntries(String userId) {
    return _firestore
        .collection(FirestorePaths.movieEntries(userId))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MovieEntry.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// Get all movie entries for a user (one-time)
  Future<List<MovieEntry>> getMovieEntries(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.movieEntries(userId))
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => MovieEntry.fromFirestore(doc.data()))
        .toList();
  }

  /// Add or update a movie entry
  Future<void> setMovieEntry(String userId, MovieEntry entry) async {
    await _firestore
        .collection(FirestorePaths.movieEntries(userId))
        .doc(entry.tmdbId.toString())
        .set(entry.toFirestore(), SetOptions(merge: true));
  }

  /// Create a movie entry from a Movie model
  Future<void> addMovieToList({
    required String userId,
    required Movie movie,
    required MovieStatus status,
    int? score,
    String? review,
  }) async {
    final now = DateTime.now();
    final entry = MovieEntry(
      tmdbId: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      status: status,
      score: score,
      review: review,
      genres: movie.genres.isNotEmpty
          ? movie.genres.map((g) => g.name).toList()
          : [],
      year: movie.year,
      addedAt: now,
      updatedAt: now,
    );

    await setMovieEntry(userId, entry);
  }

  /// Update the status and/or score of an existing entry
  Future<void> updateMovieEntry({
    required String userId,
    required int tmdbId,
    MovieStatus? status,
    int? score,
    String? review,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (status != null) updates['status'] = status.name;
    if (score != null) updates['score'] = score;
    if (review != null) updates['review'] = review;

    await _firestore
        .collection(FirestorePaths.movieEntries(userId))
        .doc(tmdbId.toString())
        .update(updates);
  }

  /// Remove a movie from the user's list
  Future<void> removeMovieEntry(String userId, int tmdbId) async {
    await _firestore
        .collection(FirestorePaths.movieEntries(userId))
        .doc(tmdbId.toString())
        .delete();
  }

  /// Get count of entries by status
  Future<Map<MovieStatus, int>> getStats(String userId) async {
    final entries = await getMovieEntries(userId);
    final stats = <MovieStatus, int>{};
    for (final status in MovieStatus.values) {
      stats[status] = entries.where((e) => e.status == status).length;
    }
    return stats;
  }
}
