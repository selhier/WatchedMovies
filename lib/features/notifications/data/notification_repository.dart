import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/notification.dart';

/// Provider for the notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Stream provider for a user's notifications
final notificationsProvider = StreamProvider.family<List<UserNotification>, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(userId);
});

/// Stream provider for the unread notification count
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(userId);
});

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Watch a user's notifications
  Stream<List<UserNotification>> watchNotifications(String userId, {int limit = 50}) {
    return _firestore
        .collection(FirestorePaths.notifications(userId))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserNotification.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Watch unread notifications count
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection(FirestorePaths.notifications(userId))
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection(FirestorePaths.notifications(userId))
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final unreadDocs = await _firestore
        .collection(FirestorePaths.notifications(userId))
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    if (unreadDocs.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Internal helper to create a notification
  Future<void> createNotification(UserNotification notification) async {
    // Don't notify yourself
    if (notification.userId == notification.actorId) return;

    await _firestore
        .collection(FirestorePaths.notifications(notification.userId))
        .add(notification.toFirestore());
  }
}
