import 'package:cloud_firestore/cloud_firestore.dart';

class SharedFolderData {
  final List<String> contributorIds;
  final String ownerId;
  final bool isLocked;
  final DateTime? lockedAt;
  final bool isPublic;

  SharedFolderData({
    required this.contributorIds,
    required this.ownerId,
    this.isLocked = false,
    this.lockedAt,
    this.isPublic = false,
  });

  // Factory constructor to create SharedFolderData from Map
  factory SharedFolderData.fromMap(Map<String, dynamic> data) {
    return SharedFolderData(
      contributorIds: List<String>.from(data['contributorIds'] ?? []),
      ownerId: data['ownerId'] ?? '',
      isLocked: data['isLocked'] ?? false,
      lockedAt: (data['lockedAt'] is Timestamp && data['lockedAt'] != null)
          ? (data['lockedAt'] as Timestamp).toDate()
          : null,
      isPublic: data['isPublic'] ?? false,
    );
  }

  // Convert SharedFolderData to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'contributorIds': contributorIds,
      'ownerId': ownerId,
      'isLocked': isLocked,
      'lockedAt': lockedAt != null ? Timestamp.fromDate(lockedAt!) : null,
      'isPublic': isPublic,
    };
  }

  // Create a copy of SharedFolderData with updated fields
  SharedFolderData copyWith({
    List<String>? contributorIds,
    String? ownerId,
    bool? isLocked,
    DateTime? lockedAt,
    bool? isPublic,
    bool clearLockedAt = false,
  }) {
    return SharedFolderData(
      contributorIds: contributorIds ?? List<String>.from(this.contributorIds),
      ownerId: ownerId ?? this.ownerId,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: clearLockedAt ? null : (lockedAt ?? this.lockedAt),
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // Helper methods for contributor management
  bool hasContributor(String userId) {
    return contributorIds.contains(userId);
  }

  bool isOwner(String userId) {
    return ownerId == userId;
  }

  bool canContribute(String userId) {
    return !isLocked && (isOwner(userId) || hasContributor(userId));
  }

  bool canView(String userId) {
    return isPublic || isOwner(userId) || hasContributor(userId);
  }

  bool canManage(String userId) {
    return isOwner(userId);
  }

  SharedFolderData addContributor(String userId) {
    if (!hasContributor(userId) && !isOwner(userId)) {
      final newContributors = List<String>.from(contributorIds)..add(userId);
      return copyWith(contributorIds: newContributors);
    }
    return this;
  }

  SharedFolderData removeContributor(String userId) {
    if (hasContributor(userId)) {
      final newContributors = List<String>.from(contributorIds)..remove(userId);
      return copyWith(contributorIds: newContributors);
    }
    return this;
  }

  SharedFolderData lock() {
    return copyWith(
      isLocked: true,
      lockedAt: DateTime.now(),
    );
  }

  SharedFolderData unlock() {
    return copyWith(
      isLocked: false,
      clearLockedAt: true,
    );
  }

  SharedFolderData makePublic() {
    return copyWith(isPublic: true);
  }

  SharedFolderData makePrivate() {
    return copyWith(isPublic: false);
  }

  // Validation methods
  bool isValid() {
    return ownerId.isNotEmpty && !contributorIds.contains(ownerId);
  }

  int get totalContributors => contributorIds.length + 1; // +1 for owner

  @override
  String toString() {
    return 'SharedFolderData(contributorIds: $contributorIds, ownerId: $ownerId, isLocked: $isLocked, lockedAt: $lockedAt, isPublic: $isPublic)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedFolderData &&
        _listEquals(other.contributorIds, contributorIds) &&
        other.ownerId == ownerId &&
        other.isLocked == isLocked &&
        other.lockedAt == lockedAt &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode {
    return Object.hashAll(contributorIds) ^
        ownerId.hashCode ^
        isLocked.hashCode ^
        lockedAt.hashCode ^
        isPublic.hashCode;
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}