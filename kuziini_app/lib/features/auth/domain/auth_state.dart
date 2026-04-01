enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  pendingApproval,
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.role = 'member',
    this.isApproved = false,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final bool isApproved;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
  bool get isViewer => role == 'viewer';

  String get displayName => fullName ?? email.split('@').first;

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      isApproved: json['is_approved'] as bool? ?? false,
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'is_approved': isApproved,
      'fcm_token': fcmToken,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    bool? isApproved,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
