import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/user_profile.dart';
import '../../shared_list/data/shared_list_repository.dart';

/// Provider for UserProfileRepository
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

/// Future provider for a single user profile
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(userProfileRepositoryProvider).getUserProfile(uid);
});

/// Future provider for user stats
final userStatsProvider = FutureProvider.family<UserStats, String>((ref, uid) {
  return ref.watch(userProfileRepositoryProvider).getUserStats(uid);
});

/// Future provider for public shared lists of a user
final userPublicListsProvider = FutureProvider.family<List<SharedList>, String>((ref, uid) {
  return ref.watch(userProfileRepositoryProvider).getUserPublicLists(uid);
});

/// Stream provider to check if current user is following a target user
final isFollowingProvider = StreamProvider.family<bool, String>((ref, targetUid) {
  return ref.watch(userProfileRepositoryProvider).watchIsFollowing(targetUid);
});

/// Stream provider for the list of IDs the current user is following
final myFollowingIdsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(userProfileRepositoryProvider).watchMyFollowingIds();
});

/// User profile repository
class UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── PROFILE & STATS ─────────────────────────────────────────

  /// Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc.data()!, doc.id);
  }

  /// Get user statistics using aggregation queries
  Future<UserStats> getUserStats(String uid) async {
    try {
      // Parallel count queries
      final results = await Future.wait([
        // Watched movies count
        _firestore
            .collection(FirestorePaths.movieEntries(uid))
            .where('status', isEqualTo: 'watched')
            .count()
            .get(),
        // Rated movies count
        _firestore
            .collection(FirestorePaths.movieEntries(uid))
            .where('score', isGreaterThan: 0)
            .count()
            .get(),
        // Following count
        _firestore.collection(FirestorePaths.following(uid)).count().get(),
        // Followers count
        _firestore.collection(FirestorePaths.followers(uid)).count().get(),
        // Public lists count
        _firestore
            .collection(FirestorePaths.sharedLists)
            .where('ownerId', isEqualTo: uid)
            .where('isPublic', isEqualTo: true)
            .count()
            .get(),
      ]);

      final stats = UserStats(
        moviesWatched: results[0].count ?? 0,
        moviesRated: results[1].count ?? 0,
        followingCount: results[2].count ?? 0,
        followersCount: results[3].count ?? 0,
        publicListsCount: results[4].count ?? 0,
      );

      // Evaluate Badges
      await _evaluateBadges(uid, stats);

      return stats;
    } catch (e) {
      print('Error getting user stats: $e');
      return UserStats.empty();
    }
  }

  Future<void> _evaluateBadges(String uid, UserStats stats) async {
    final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return;
    
    final currentBadges = List<String>.from(doc.data()?['badges'] ?? []);
    final newBadges = <String>{...currentBadges};

    if (stats.moviesWatched >= 10) newBadges.add('Cinéfilo Novato');
    if (stats.moviesWatched >= 50) newBadges.add('Cinéfilo Pro');
    if (stats.moviesWatched >= 100) newBadges.add('Leyenda del Cine');
    
    if (stats.moviesRated >= 10) newBadges.add('Crítico Amateur');
    if (stats.moviesRated >= 50) newBadges.add('Crítico Experto');

    if (stats.followersCount >= 10) newBadges.add('Influencer');

    if (newBadges.length != currentBadges.length) {
      await _firestore.collection(FirestorePaths.users).doc(uid).update({
        'badges': newBadges.toList(),
      });
    }
  }

  /// Update Top 4 Movies
  Future<void> updateTop4Movies(String uid, List<int> movieIds) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'top4MovieIds': movieIds,
    });
  }

  /// Get user's public shared lists
  Future<List<SharedList>> getUserPublicLists(String uid) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.sharedLists)
        .where('ownerId', isEqualTo: uid)
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SharedList.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ─── FOLLOW SYSTEM ───────────────────────────────────────────

  /// Toggle follow status (atomic transaction via batch)
  Future<void> toggleFollow(String currentUid, String targetUid) async {
    if (currentUid == targetUid) return;

    final followingRef = _firestore.collection(FirestorePaths.following(currentUid)).doc(targetUid);
    final followersRef = _firestore.collection(FirestorePaths.followers(targetUid)).doc(currentUid);

    final doc = await followingRef.get();
    final isFollowing = doc.exists;

    final batch = _firestore.batch();
    
    if (isFollowing) {
      // Unfollow
      batch.delete(followingRef);
      batch.delete(followersRef);
    } else {
      // Follow
      final now = FieldValue.serverTimestamp();
      batch.set(followingRef, {'createdAt': now});
      batch.set(followersRef, {'createdAt': now});
      
      // Notification
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUid != targetUid) {
        final notifRef = _firestore.collection(FirestorePaths.notifications(targetUid)).doc();
        batch.set(notifRef, {
          'userId': targetUid,
          'actorId': currentUid,
          'actorName': currentUser.displayName ?? 'Someone',
          'actorAvatar': currentUser.photoURL,
          'type': 'follow',
          'isRead': false,
          'createdAt': now,
        });
      }
    }

    await batch.commit();
  }

  /// Watch follow status (live)
  Stream<bool> watchIsFollowing(String targetUid) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Stream.value(false);

    return _firestore
        .collection(FirestorePaths.following(currentUserId))
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Watch list of user IDs that the current user is following
  Stream<List<String>> watchMyFollowingIds() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection(FirestorePaths.following(currentUserId))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get list of user IDs that the current user is following (one-time)
  Future<List<String>> getFollowingIds(String uid) async {
    final snapshot = await _firestore.collection(FirestorePaths.following(uid)).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
