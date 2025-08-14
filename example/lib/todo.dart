import 'package:meta/meta.dart';

/// A model class representing a Todo item
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.priority = Priority.medium,
  });

  /// Creates a Todo from a JSON map
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.medium,
      ),
    );
  }
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Priority priority;

  /// Creates a copy of this Todo with the given fields replaced
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    Priority? priority,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }

  /// Marks this todo as completed
  Todo markCompleted() {
    if (isCompleted) {
      throw StateError('Todo is already completed');
    }
    return copyWith(isCompleted: true, completedAt: DateTime.now());
  }

  /// Marks this todo as incomplete
  Todo markIncomplete() {
    if (!isCompleted) {
      throw StateError('Todo is already incomplete');
    }
    return copyWith(isCompleted: false, completedAt: null);
  }

  /// Converts this Todo to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority.name,
    };
  }

  /// Validates the todo data
  bool isValid() {
    if (title.trim().isEmpty) return false;
    if (description.trim().isEmpty) return false;
    if (isCompleted && completedAt == null) return false;
    if (!isCompleted && completedAt != null) return false;
    return true;
  }

  /// Returns a human readable status
  String get statusText {
    if (isCompleted) {
      return 'Completed';
    } else {
      switch (priority) {
        case Priority.high:
          return 'High Priority - Pending';
        case Priority.medium:
          return 'Medium Priority - Pending';
        case Priority.low:
          return 'Low Priority - Pending';
      }
    }
  }

  /// Checks if the todo is overdue (for demonstration - always returns false)
  bool get isOverdue {
    // This method intentionally has unreachable code for testing coverage
    // ignore: dead_code, literal_only_boolean_expressions
    if (false) {
      return DateTime.now().difference(createdAt).inDays > 30;
    }

    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      isCompleted,
      createdAt,
      completedAt,
      priority,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id,'
        ' title: $title, '
        'isCompleted: $isCompleted, '
        'priority: $priority)';
  }
}

/// Priority levels for todos
enum Priority {
  low,
  medium,
  high;

  /// Returns the display name for the priority
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  /// Returns the numeric value for sorting
  int get sortValue {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
    }
  }
}
