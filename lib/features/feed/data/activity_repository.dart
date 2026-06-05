import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/activity.dart';

/// Provider for the activity repository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Stream of community feed activities (last 50)
final communityFeedProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activityRepositoryProvider).watchCommunityFeed();
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
}
