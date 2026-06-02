/// Firestore collection and document paths
class FirestorePaths {
  FirestorePaths._();

  // ─── Collections ──────────────────────────────────────────
  static const String users = 'users';
  static const String sharedLists = 'sharedLists';

  // ─── Subcollections ───────────────────────────────────────
  static String movieEntries(String userId) =>
      '$users/$userId/movieEntries';

  static String sharedListMovies(String listId) =>
      '$sharedLists/$listId/movies';

  // ─── Documents ────────────────────────────────────────────
  static String user(String userId) => '$users/$userId';

  static String movieEntry(String userId, int tmdbId) =>
      '$users/$userId/movieEntries/$tmdbId';

  static String sharedList(String listId) => '$sharedLists/$listId';

  static String sharedListMovie(String listId, int tmdbId) =>
      '$sharedLists/$listId/movies/$tmdbId';
}
