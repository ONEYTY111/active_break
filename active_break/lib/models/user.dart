class User {
  final int? userId;
  final String username;
  final String passwordHash;
  final String email;
  final String? phone;
  final String? gender;
  final String? avatarUrl;
  final DateTime? lastLoginTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool deleted;

  User({
    this.userId,
    required this.username,
    required this.passwordHash,
    required this.email,
    this.phone,
    this.gender,
    this.avatarUrl,
    this.lastLoginTime,
    this.createdAt,
    this.updatedAt,
    this.deleted = false,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      email: map['email'],
      phone: map['phone'],
      gender: map['gender'],
      avatarUrl: map['avatar_url'],
      lastLoginTime: map['last_login_time'] != null 
          ? DateTime.parse(map['last_login_time']) 
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      deleted: map['deleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'password_hash': passwordHash,
      'email': email,
      'phone': phone,
      'gender': gender,
      'avatar_url': avatarUrl,
      'last_login_time': lastLoginTime?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? passwordHash,
    String? email,
    String? phone,
    String? gender,
    String? avatarUrl,
    DateTime? lastLoginTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}
