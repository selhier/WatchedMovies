import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of community activity
enum ActivityType {
  watched,
  rated,
  addedToList,
  createdList,
}

/// A single activity entry in the community feed
class Activity {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ActivityType type;
  final String movieTitle;
  final int? movieId;
  final String? posterPath;
  final int? score;
  final String? review;
  final String? listTitle;
  final String? listId;
  final DateTime createdAt;
  final int likesCount;
  final List<String> likedBy;

  const Activity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.movieTitle,
    this.movieId,
    this.posterPath,
    this.score,
    this.review,
    this.listTitle,
    this.listId,
    required this.createdAt,
    this.likesCount = 0,
    this.likedBy = const [],
  });

  factory Activity.fromFirestore(Map<String, dynamic> data, String id) {
    return Activity(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      type: ActivityType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'watched'),
        orElse: () => ActivityType.watched,
      ),
      movieTitle: data['movieTitle'] as String? ?? '',
      movieId: data['movieId'] as int?,
      posterPath: data['posterPath'] as String?,
      score: data['score'] as int?,
      review: data['review'] as String?,
      listTitle: data['listTitle'] as String?,
      listId: data['listId'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type.name,
      'movieTitle': movieTitle,
      'movieId': movieId,
      'posterPath': posterPath,
      'score': score,
      'review': review,
      'listTitle': listTitle,
      'listId': listId,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
    };
  }

  /// Human-readable description of the activity
  String get description {
    switch (type) {
      case ActivityType.watched:
        return 'watched';
      case ActivityType.rated:
        return 'rated';
      case ActivityType.addedToList:
        return 'added to list';
      case ActivityType.createdList:
        return 'created a list';
    }
  }
}
