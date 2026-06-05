/// Firestore collection and document paths
class FirestorePaths {
  FirestorePaths._();

  // ─── Collections ──────────────────────────────────────────
  static const String users = 'users';
  static const String sharedLists = 'sharedLists';
  static const String communityFeed = 'communityFeed';

  // ─── Subcollections ───────────────────────────────────────
  static String movieEntries(String userId) =>
      '$users/$userId/movieEntries';

  static String sharedListMovies(String listId) =>
      '$sharedLists/$listId/movies';

  static String sharedListComments(String listId) =>
      '$sharedLists/$listId/comments';

  // ─── Documents ────────────────────────────────────────────
  static String user(String userId) => '$users/$userId';

  static String movieEntry(String userId, int tmdbId) =>
      '$users/$userId/movieEntries/$tmdbId';

  static String sharedList(String listId) => '$sharedLists/$listId';

  static String sharedListMovie(String listId, int tmdbId) =>
      '$sharedLists/$listId/movies/$tmdbId';

  static String sharedListComment(String listId, String commentId) =>
      '$sharedLists/$listId/comments/$commentId';
}
