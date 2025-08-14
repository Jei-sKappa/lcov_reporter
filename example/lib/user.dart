import 'package:meta/meta.dart';

/// A model class representing a User
@immutable
class User {
  const User({required this.id, required this.name});

  /// Creates a User from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] as String, name: json['name'] as String);
  }

  final String id;
  final String name;

  /// Creates a copy of this User with the given fields replaced
  User copyWith({String? id, String? name}) {
    return User(id: id ?? this.id, name: name ?? this.name);
  }

  /// Converts this User to a JSON map
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.name == name;
  }

  @override
  int get hashCode {
    return Object.hash(id, name);
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name)';
  }
}
