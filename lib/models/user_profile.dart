import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String username;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create UserProfile from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert UserProfile to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, username: $username, profilePictureUrl: $profilePictureUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.profilePictureUrl == profilePictureUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        username.hashCode ^
        profilePictureUrl.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}