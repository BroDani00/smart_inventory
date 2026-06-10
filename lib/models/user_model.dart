class User {
  final int? id;
  final String name;
  final String storeName;
  final String? profileImage;
  final String createdAt;
  final String updatedAt;

  User({
    this.id,
    required this.name,
    required this.storeName,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'store_name': storeName,
      'profile_image': profileImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      storeName: map['store_name'],
      profileImage: map['profile_image'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Copy with method untuk update
  User copyWith({
    int? id,
    String? name,
    String? storeName,
    String? profileImage,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}