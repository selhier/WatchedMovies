import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/comment.dart';
import '../../auth/data/auth_repository.dart';

// ═══════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════

/// Shared list model
class SharedList {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final bool isPublic;
  final List<int> movieIds;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedList({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    this.description = '',
    this.isPublic = true,
    this.movieIds = const [],
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SharedList.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedList(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? true,
      movieIds: (data['movieIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      likesCount: data['likesCount'] as int? ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'isPublic': isPublic,
      'movieIds': movieIds,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if a user has liked this list
  bool isLikedBy(String userId) => likedBy.contains(userId);
}



// ═══════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════

/// Provider for shared list repository
final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  return SharedListRepository();
});

/// User's own shared lists stream
final mySharedListsProvider =
    StreamProvider<List<SharedList>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(sharedListRepositoryProvider).watchUserLists(user.uid);
});

/// A specific shared list by ID (one-time fetch)
final sharedListByIdProvider =
    FutureProvider.family<SharedList?, String>((ref, listId) async {
  return ref.watch(sharedListRepositoryProvider).getList(listId);
});

/// Real-time stream of a shared list (for live like updates)
final sharedListStreamProvider =
    StreamProvider.family<SharedList?, String>((ref, listId) {
  return ref.watch(sharedListRepositoryProvider).watchList(listId);
});

/// Real-time stream of comments for a shared list
final commentsStreamProvider =
    StreamProvider.family<List<Comment>, String>((ref, listId) {
  return ref.watch(sharedListRepositoryProvider).watchComments(listId);
});

// ═══════════════════════════════════════════════════════════════
// Repository
// ═══════════════════════════════════════════════════════════════

/// Repository for shared lists with social features
class SharedListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── CRUD ──────────────────────────────────────────────────

  /// Create a new shared list
  Future<String> createList({
    required String ownerId,
    required String ownerName,
    required String title,
    String description = '',
    List<int> movieIds = const [],
  }) async {
    final now = DateTime.now();
    final doc = await _firestore
        .collection(FirestorePaths.sharedLists)
        .add(SharedList(
          id: '',
          ownerId: ownerId,
          ownerName: ownerName,
          title: title,
          description: description,
          isPublic: true,
          movieIds: movieIds,
          createdAt: now,
          updatedAt: now,
        ).toFirestore());
    return doc.id;
  }

  /// Watch the current user's shared lists
  Stream<List<SharedList>> watchUserLists(String userId) {
    return _firestore
        .collection(FirestorePaths.sharedLists)
        .where('ownerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SharedList.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get a single shared list by ID (one-time)
  Future<SharedList?> getList(String listId) async {
    final doc = await _firestore
        .collection(FirestorePaths.sharedLists)
        .doc(listId)
        .get();
    if (!doc.exists) return null;
    return SharedList.fromFirestore(doc.data()!, doc.id);
  }

  /// Watch a single shared list in real-time (for live like updates)
  Stream<SharedList?> watchList(String listId) {
    return _firestore
        .collection(FirestorePaths.sharedLists)
        .doc(listId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return SharedList.fromFirestore(doc.data()!, doc.id);
    });
  }

  /// Update shared list
  Future<void> updateList(String listId, {
    String? title,
    String? description,
    List<int>? movieIds,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (movieIds != null) updates['movieIds'] = movieIds;

    await _firestore
        .collection(FirestorePaths.sharedLists)
        .doc(listId)
        .update(updates);
  }

  /// Delete a shared list
  Future<void> deleteList(String listId) async {
    await _firestore
        .collection(FirestorePaths.sharedLists)
        .doc(listId)
        .delete();
  }

  // ─── LIKES ─────────────────────────────────────────────────

  /// Toggle like on a shared list (atomic transaction)
  Future<void> toggleLikeList(String listId, String userId) async {
    final docRef = _firestore
        .collection(FirestorePaths.sharedLists)
        .doc(listId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        // Unlike
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
        });
        
        // Trigger notification
        final ownerId = data['ownerId'] as String?;
        if (ownerId != null && userId != ownerId) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final notifRef = _firestore.collection(FirestorePaths.notifications(ownerId)).doc();
            transaction.set(notifRef, {
              'userId': ownerId,
              'actorId': userId,
              'actorName': currentUser.displayName ?? 'Someone',
              'actorAvatar': currentUser.photoURL,
              'type': 'likeList',
              'referenceId': listId,
              'referenceTitle': data['title'] as String?,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
  }

  // ─── COMMENTS ──────────────────────────────────────────────

  /// Add a comment to a shared list
  Future<void> addComment(String listId, Comment comment) async {
    await _firestore
        .collection(FirestorePaths.sharedListComments(listId))
        .add(comment.toFirestore());

    // Trigger notification
    final doc = await _firestore.collection(FirestorePaths.sharedLists).doc(listId).get();
    if (doc.exists) {
      final ownerId = doc.data()?['ownerId'] as String?;
      final listTitle = doc.data()?['title'] as String?;
      if (ownerId != null && comment.userId != ownerId) {
        final notifRef = _firestore.collection(FirestorePaths.notifications(ownerId)).doc();
        await notifRef.set({
          'userId': ownerId,
          'actorId': comment.userId,
          'actorName': comment.userName,
          'actorAvatar': comment.userAvatar,
          'type': 'commentList',
          'referenceId': listId,
          'referenceTitle': listTitle,
          'message': comment.text,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Watch comments for a shared list (real-time, newest first)
  Stream<List<Comment>> watchComments(String listId) {
    return _firestore
        .collection(FirestorePaths.sharedListComments(listId))
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Delete a comment (only own comments)
  Future<void> deleteComment(String listId, String commentId) async {
    await _firestore
        .collection(FirestorePaths.sharedListComments(listId))
        .doc(commentId)
        .delete();
  }
}
