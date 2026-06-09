import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/notification.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/data/auth_repository.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const Center(
          child: Text('Please log in to see notifications.',
              style: TextStyle(color: AppColors.textTertiary)),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationRepositoryProvider).markAllAsRead(user.uid);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'All caught up!',
              subtitle: 'When others interact with you,\nit will show up here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification, userId: user.uid);
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final UserNotification notification;
  final String userId;

  const _NotificationTile({required this.notification, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          ref
              .read(notificationRepositoryProvider)
              .markAsRead(userId, notification.id);
        }

        // Navigate based on type
        switch (notification.type) {
          case NotificationType.likeList:
          case NotificationType.commentList:
            if (notification.referenceId != null) {
              context.push('/shared-list/${notification.referenceId}');
            }
            break;
          case NotificationType.follow:
            context.push('/user/${notification.actorId}');
            break;
          case NotificationType.likeActivity:
          case NotificationType.commentActivity:
            // Could navigate to a specific activity detail screen if we had one.
            // For now, navigating to feed or user profile is fine.
            context.push('/community');
            break;
        }
      },
      child: Container(
        color: notification.isRead ? Colors.transparent : AppColors.primarySurface.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with type badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: notification.actorAvatar != null
                      ? CachedNetworkImageProvider(notification.actorAvatar!)
                      : null,
                  child: notification.actorAvatar == null
                      ? Text(
                          notification.actorName.isNotEmpty
                              ? notification.actorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        )
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(notification.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Icon(
                      _getBadgeIcon(notification.type),
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: notification.actorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(text: _getActionText(notification.type)),
                        if (notification.referenceTitle != null)
                          TextSpan(
                            text: ' "${notification.referenceTitle}"',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (notification.message != null && notification.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${notification.message}"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread dot indicator
            if (!notification.isRead) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActionText(NotificationType type) {
    switch (type) {
      case NotificationType.likeList:
        return ' liked your list';
      case NotificationType.commentList:
        return ' commented on your list';
      case NotificationType.likeActivity:
        return ' liked your activity';
      case NotificationType.commentActivity:
        return ' replied to your activity';
      case NotificationType.follow:
        return ' started following you';
    }
  }

  Color _getBadgeColor(NotificationType type) {
    switch (type) {
      case NotificationType.likeList:
      case NotificationType.likeActivity:
        return AppColors.error; // Red for likes
      case NotificationType.commentList:
      case NotificationType.commentActivity:
        return AppColors.watched; // Blue for comments
      case NotificationType.follow:
        return AppColors.primary; // Gold for follows
    }
  }

  IconData _getBadgeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.likeList:
      case NotificationType.likeActivity:
        return Icons.favorite_rounded;
      case NotificationType.commentList:
      case NotificationType.commentActivity:
        return Icons.chat_bubble_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
