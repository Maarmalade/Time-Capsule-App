import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Model for structured notification data and navigation
@immutable
class NotificationPayload {
  final String type;
  final String targetId;
  final Map<String, dynamic> data;

  const NotificationPayload({
    required this.type,
    required this.targetId,
    required this.data,
  });

  /// Create NotificationPayload from JSON
  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] as String? ?? 'unknown',
      targetId: json['targetId'] as String? ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }

  /// Create NotificationPayload from RemoteMessage
  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    return NotificationPayload(
      type: data['type'] as String? ?? 'general',
      targetId: data['targetId'] as String? ?? '',
      data: Map<String, dynamic>.from(data),
    );
  }

  /// Convert NotificationPayload to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'targetId': targetId,
      'data': data,
    };
  }

  /// Create a copy with updated fields
  NotificationPayload copyWith({
    String? type,
    String? targetId,
    Map<String, dynamic>? data,
  }) {
    return NotificationPayload(
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }

  /// Check if this is a scheduled message notification
  bool get isScheduledMessage => type == 'scheduled_message';

  /// Check if this is a shared folder notification
  bool get isSharedFolder => type == 'shared_folder';

  /// Check if this is a friend request notification
  bool get isFriendRequest => type == 'friend_request';

  /// Get the title for this notification type
  String get defaultTitle {
    switch (type) {
      case 'scheduled_message':
        return 'New Scheduled Message';
      case 'shared_folder':
        return 'Shared Folder Update';
      case 'friend_request':
        return 'New Friend Request';
      default:
        return 'Time Capsule';
    }
  }

  /// Get the body for this notification type
  String get defaultBody {
    switch (type) {
      case 'scheduled_message':
        return 'You have received a new scheduled message';
      case 'shared_folder':
        return 'A shared folder has been updated';
      case 'friend_request':
        return 'You have a new friend request';
      default:
        return 'You have a new notification';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPayload &&
        other.type == type &&
        other.targetId == targetId &&
        mapEquals(other.data, data);
  }

  @override
  int get hashCode {
    return Object.hash(type, targetId, data);
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, targetId: $targetId, data: $data)';
  }
}