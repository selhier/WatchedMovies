import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  likeList,
  commentList,
  likeActivity,
  commentActivity,
  follow,
}

class UserNotification {
  final String id;
  final String userId; // The owner of the notification (recipient)
  final String actorId; // The user who performed the action
  final String actorName;
  final String? actorAvatar;
  final NotificationType type;
  final String? referenceId; // e.g. listId, activityId
  final String? referenceTitle; // e.g. list title
  final String? message; // e.g. comment text
  final bool isRead;
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.type,
    this.referenceId,
    this.referenceTitle,
    this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory UserNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return UserNotification(
      id: id,
      userId: data['userId'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'Someone',
      actorAvatar: data['actorAvatar'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.likeList,
      ),
      referenceId: data['referenceId'] as String?,
      referenceTitle: data['referenceTitle'] as String?,
      message: data['message'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'actorId': actorId,
      'actorName': actorName,
      'actorAvatar': actorAvatar,
      'type': type.name,
      'referenceId': referenceId,
      'referenceTitle': referenceTitle,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
