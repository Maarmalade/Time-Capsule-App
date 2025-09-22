import 'package:flutter/foundation.dart';

/// Model for storing FCM device tokens in Firestore
@immutable
class FCMTokenModel {
  final String userId;
  final String token;
  final DateTime lastUpdated;
  final String platform;

  const FCMTokenModel({
    required this.userId,
    required this.token,
    required this.lastUpdated,
    required this.platform,
  });

  /// Create FCMTokenModel from JSON
  factory FCMTokenModel.fromJson(Map<String, dynamic> json) {
    return FCMTokenModel(
      userId: json['userId'] as String,
      token: json['token'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      platform: json['platform'] as String,
    );
  }

  /// Convert FCMTokenModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
      'lastUpdated': lastUpdated.toIso8601String(),
      'platform': platform,
    };
  }

  /// Create a copy with updated fields
  FCMTokenModel copyWith({
    String? userId,
    String? token,
    DateTime? lastUpdated,
    String? platform,
  }) {
    return FCMTokenModel(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      platform: platform ?? this.platform,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FCMTokenModel &&
        other.userId == userId &&
        other.token == token &&
        other.lastUpdated == lastUpdated &&
        other.platform == platform;
  }

  @override
  int get hashCode {
    return Object.hash(userId, token, lastUpdated, platform);
  }

  @override
  String toString() {
    final tokenPreview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
    return 'FCMTokenModel(userId: $userId, token: $tokenPreview, lastUpdated: $lastUpdated, platform: $platform)';
  }
}