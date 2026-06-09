import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/comment.dart';

/// Provider for the activity repository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Provider for the current limit of feed items to load
final feedLimitProvider = StateProvider<int>((ref) => 20);

/// Stream of community feed activities, reacting to feedLimitProvider
final communityFeedProvider = StreamProvider<List<Activity>>((ref) {
  final limit = ref.watch(feedLimitProvider);
  return ref.watch(activityRepositoryProvider).watchCommunityFeed(limit: limit);
});

/// Repository for community activity feed
class ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Publish an activity to the community feed
  Future<void> publishActivity(Activity activity) async {
    await _firestore
        .collection(FirestorePaths.communityFeed)
        .add(activity.toFirestore());
  }

  /// Watch the community feed (last 50 activities, newest first)
  Stream<List<Activity>> watchCommunityFeed({int limit = 50}) {
    return _firestore
        .collection(FirestorePaths.communityFeed)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Activity.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Toggle like on an activity
  Future<void> toggleLikeActivity(String activityId, String userId) async {
    final docRef = _firestore.collection(FirestorePaths.communityFeed).doc(activityId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final activity = Activity.fromFirestore(snapshot.data()!, snapshot.id);
      final isLiked = activity.likedBy.contains(userId);

      if (isLiked) {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
        });
        
        // Trigger notification
        if (userId != activity.userId) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final notifRef = _firestore.collection(FirestorePaths.notifications(activity.userId)).doc();
            transaction.set(notifRef, {
              'userId': activity.userId,
              'actorId': userId,
              'actorName': currentUser.displayName ?? 'Someone',
              'actorAvatar': currentUser.photoURL,
              'type': 'likeActivity',
              'referenceId': activityId,
              'referenceTitle': activity.movieTitle,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
  }

  // ─── COMMENTS ──────────────────────────────────────────────

  /// Add a comment to an activity
  Future<void> addComment(String activityId, Comment comment) async {
    await _firestore
        .collection(FirestorePaths.activityComments(activityId))
        .add(comment.toFirestore());

    // Trigger notification
    final doc = await _firestore.collection(FirestorePaths.communityFeed).doc(activityId).get();
    if (doc.exists) {
      final activity = Activity.fromFirestore(doc.data()!, doc.id);
      if (comment.userId != activity.userId) {
        final notifRef = _firestore.collection(FirestorePaths.notifications(activity.userId)).doc();
        await notifRef.set({
          'userId': activity.userId,
          'actorId': comment.userId,
          'actorName': comment.userName,
          'actorAvatar': comment.userAvatar,
          'type': 'commentActivity',
          'referenceId': activityId,
          'referenceTitle': activity.movieTitle,
          'message': comment.text,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Watch comments for an activity
  Stream<List<Comment>> watchComments(String activityId) {
    return _firestore
        .collection(FirestorePaths.activityComments(activityId))
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Delete a comment
  Future<void> deleteComment(String activityId, String commentId) async {
    await _firestore
        .collection(FirestorePaths.activityComments(activityId))
        .doc(commentId)
        .delete();
  }
}
