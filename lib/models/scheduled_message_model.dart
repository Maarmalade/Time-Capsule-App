import 'package:cloud_firestore/cloud_firestore.dart';

enum ScheduledMessageStatus { pending, delivered, failed }

class ScheduledMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String textContent;
  final List<String>? imageUrls;
  final String? videoUrl;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ScheduledMessageStatus status;
  final DateTime? deliveredAt;

  ScheduledMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.textContent,
    this.imageUrls,
    this.videoUrl,
    required this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.deliveredAt,
  });

  // Factory constructor to create ScheduledMessage from Firestore document
  factory ScheduledMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ScheduledMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      textContent: data['textContent'] ?? '',
      imageUrls: data['imageUrls'] != null 
          ? List<String>.from(data['imageUrls'] as List)
          : null,
      videoUrl: data['videoUrl'],
      scheduledFor: (data['scheduledFor'] is Timestamp && data['scheduledFor'] != null)
          ? (data['scheduledFor'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: (data['createdAt'] is Timestamp && data['createdAt'] != null)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp && data['updatedAt'] != null)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: _parseStatus(data['status']),
      deliveredAt: (data['deliveredAt'] is Timestamp && data['deliveredAt'] != null)
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert ScheduledMessage to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'textContent': textContent,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.name,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  // Create a copy of ScheduledMessage with updated fields
  ScheduledMessage copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? textContent,
    List<String>? imageUrls,
    String? videoUrl,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
    ScheduledMessageStatus? status,
    DateTime? deliveredAt,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      textContent: textContent ?? this.textContent,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  // Helper method to parse status from string
  static ScheduledMessageStatus _parseStatus(dynamic statusValue) {
    if (statusValue is String) {
      switch (statusValue.toLowerCase()) {
        case 'pending':
          return ScheduledMessageStatus.pending;
        case 'delivered':
          return ScheduledMessageStatus.delivered;
        case 'failed':
          return ScheduledMessageStatus.failed;
        default:
          return ScheduledMessageStatus.pending;
      }
    }
    return ScheduledMessageStatus.pending;
  }

  // Validation methods
  bool isValid() {
    return senderId.isNotEmpty && 
           recipientId.isNotEmpty && 
           textContent.isNotEmpty &&
           isValidScheduledTime();
  }

  /// Validates that the scheduled time is at least 1 minute in the future
  bool isValidScheduledTime() {
    final now = DateTime.now();
    final minimumFutureTime = now.add(const Duration(minutes: 1));
    return scheduledFor.isAfter(minimumFutureTime);
  }

  bool isPending() => status == ScheduledMessageStatus.pending;
  bool isDelivered() => status == ScheduledMessageStatus.delivered;
  bool isFailed() => status == ScheduledMessageStatus.failed;

  bool isScheduledForFuture() => scheduledFor.isAfter(DateTime.now());
  bool isReadyForDelivery() => isPending() && DateTime.now().isAfter(scheduledFor);

  // Check if message is sent to self
  bool isSelfMessage() => senderId == recipientId;

  // Get time remaining until delivery
  Duration? getTimeUntilDelivery() {
    if (isPending() && isScheduledForFuture()) {
      return scheduledFor.difference(DateTime.now());
    }
    return null;
  }

  // Media validation methods
  bool hasMedia() {
    return (imageUrls?.isNotEmpty ?? false) || videoUrl != null;
  }

  List<String> getAllMediaUrls() {
    final List<String> allUrls = [];
    if (imageUrls != null) {
      allUrls.addAll(imageUrls!);
    }
    if (videoUrl != null) {
      allUrls.add(videoUrl!);
    }
    return allUrls;
  }

  @override
  String toString() {
    return 'ScheduledMessage(id: $id, senderId: $senderId, recipientId: $recipientId, textContent: ${textContent.length > 50 ? '${textContent.substring(0, 50)}...' : textContent}, imageUrls: $imageUrls, videoUrl: $videoUrl, scheduledFor: $scheduledFor, status: $status, deliveredAt: $deliveredAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledMessage &&
        other.id == id &&
        other.senderId == senderId &&
        other.recipientId == recipientId &&
        other.textContent == textContent &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.videoUrl == videoUrl &&
        other.scheduledFor == scheduledFor &&
        other.createdAt == createdAt &&
        other.status == status &&
        other.deliveredAt == deliveredAt;
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        recipientId.hashCode ^
        textContent.hashCode ^
        _getListHashCode(imageUrls) ^
        videoUrl.hashCode ^
        scheduledFor.hashCode ^
        createdAt.hashCode ^
        status.hashCode ^
        deliveredAt.hashCode;
  }

  // Helper method to get hash code for list
  int _getListHashCode<T>(List<T>? list) {
    if (list == null) return 0;
    int hash = 0;
    for (T item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}