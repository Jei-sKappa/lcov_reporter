import 'package:example/user.dart';
import 'package:meta/meta.dart';

/// A model class representing a Todo item
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    this.user,
    this.isCompleted = false,
  });

  /// Creates a Todo from a JSON map
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  final String id;
  final User? user;
  final String title;
  final bool isCompleted;

  /// Creates a copy of this Todo with the given fields replaced
  Todo copyWith({
    String? id,
    User? Function()? user,
    String? title,
    bool? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      user: user != null ? user() : this.user,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Marks this todo as completed
  Todo markCompleted() {
    if (isCompleted) {
      throw StateError('Todo is already completed');
    }
    return copyWith(isCompleted: true);
  }

  /// Marks this todo as incomplete
  Todo markIncomplete() {
    if (!isCompleted) {
      throw StateError('Todo is already incomplete');
    }
    return copyWith(isCompleted: false);
  }

  /// Converts this Todo to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  /// Validates the todo data
  bool isValid() {
    if (title.trim().isEmpty) return false;
    return true;
  }

  /// Returns a human readable status
  String get statusText {
    if (isCompleted) {
      return 'Completed';
    }

    return 'Pending';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Todo(id: $id, '
        'user: $user, '
        'title: $title, '
        'isCompleted: $isCompleted)';
  }
}
