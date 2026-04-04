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
    this.role = 'user',
    this.status = 'pending',
    this.phone,
    this.timezone,
    this.birthDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String status;
  final String? phone;
  final String? timezone;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isBirthdayToday {
    if (birthDate == null) return false;
    final now = DateTime.now();
    return birthDate!.month == now.month && birthDate!.day == now.day;
  }

  bool get isBirthdayThisWeek {
    if (birthDate == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (birthDate!.month == day.month && birthDate!.day == day.day) return true;
    }
    return false;
  }

  bool get isApproved => status == 'active';
  bool get isPending => status == 'pending';
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isUser => role == 'user';

  String get displayName => (fullName != null && fullName!.isNotEmpty) ? fullName! : email.split('@').first;

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
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'pending',
      phone: json['phone'] as String?,
      timezone: json['timezone'] as String?,
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date'] as String) : null,
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
      'status': status,
      'phone': phone,
      'timezone': timezone,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? status,
    String? phone,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
