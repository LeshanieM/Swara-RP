/// The child a child account belongs to (from the API's `user.child`).
class ChildRef {
  final String childId;
  final String firstName;
  final int age;

  const ChildRef({required this.childId, required this.firstName, required this.age});

  factory ChildRef.fromJson(Map<String, dynamic> json) => ChildRef(
        childId: json['childId'] ?? '',
        firstName: json['firstName'] ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'childId': childId, 'firstName': firstName, 'age': age};

  ChildRef copyWith({String? firstName, int? age}) => ChildRef(
        childId: childId,
        firstName: firstName ?? this.firstName,
        age: age ?? this.age,
      );
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;
  final String? photoUrl;
  final ChildRef? child;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.photoUrl,
    this.child,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'],
      photoUrl: json['photoUrl'] as String?,
      child: json['child'] is Map<String, dynamic> ? ChildRef.fromJson(json['child']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (child != null) 'child': child!.toJson(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? token,
    String? photoUrl,
    ChildRef? child,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      photoUrl: photoUrl ?? this.photoUrl,
      child: child ?? this.child,
    );
  }
}
