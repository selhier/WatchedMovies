import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model stored in Firestore
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<int> top4MovieIds;
  final List<String> badges;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    this.top4MovieIds = const [],
    this.badges = const [],
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin:
          (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      top4MovieIds: List<int>.from(data['top4MovieIds'] ?? []),
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'top4MovieIds': top4MovieIds,
      'badges': badges,
    };
  }
}

/// Statistics for a user profile
class UserStats {
  final int moviesWatched;
  final int moviesRated;
  final int followingCount;
  final int followersCount;
  final int publicListsCount;

  const UserStats({
    required this.moviesWatched,
    required this.moviesRated,
    required this.followingCount,
    required this.followersCount,
    required this.publicListsCount,
  });

  factory UserStats.empty() {
    return const UserStats(
      moviesWatched: 0,
      moviesRated: 0,
      followingCount: 0,
      followersCount: 0,
      publicListsCount: 0,
    );
  }
}
