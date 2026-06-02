import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/auth_repository.dart';

/// Shared list model
class SharedList {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final bool isPublic;
  final List<int> movieIds;
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

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

/// A specific shared list by ID
final sharedListByIdProvider =
    FutureProvider.family<SharedList?, String>((ref, listId) async {
  return ref.watch(sharedListRepositoryProvider).getList(listId);
});

/// Repository for shared lists
class SharedListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Get a single shared list by ID (for public viewing)
  Future<SharedList?> getList(String listId) async {
    final doc = await _firestore
        .collection(FirestorePaths.sharedLists)
        .doc(listId)
        .get();
    if (!doc.exists) return null;
    return SharedList.fromFirestore(doc.data()!, doc.id);
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
}
