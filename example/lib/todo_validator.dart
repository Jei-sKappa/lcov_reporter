import 'package:example/exceptions.dart';
import 'package:example/todo.dart';

/// Utility class for validating todo data and business rules
class TodoValidator {
  /// Validates a todo title
  static List<String> validateTitle(String title) {
    final errors = <String>[];

    if (title.trim().isEmpty) {
      errors.add('Title cannot be empty');
    }

    if (title.length > 100) {
      errors.add('Title cannot exceed 100 characters');
    }

    if (title.length < 3) {
      errors.add('Title must be at least 3 characters long');
    }

    // Check for inappropriate content (uncovered branch)
    if (title.toLowerCase().contains('inappropriate')) {
      errors.add('Title contains inappropriate content');
    }

    return errors;
  }

  /// Validates a todo description
  static List<String> validateDescription(String description) {
    final errors = <String>[];

    if (description.trim().isEmpty) {
      errors.add('Description cannot be empty');
    }

    if (description.length > 500) {
      errors.add('Description cannot exceed 500 characters');
    }

    if (description.length < 10) {
      errors.add('Description must be at least 10 characters long');
    }

    return errors;
  }

  /// Validates a complete todo object
  static void validateTodo(Todo todo) {
    final errors = <String>[
      ...validateTitle(todo.title),
      ...validateDescription(todo.description),
    ];

    // Validate completion state consistency
    if (todo.isCompleted && todo.completedAt == null) {
      errors.add('Completed todos must have a completion date');
    }

    if (!todo.isCompleted && todo.completedAt != null) {
      errors.add('Incomplete todos cannot have a completion date');
    }

    // Validate creation date (uncovered branch)
    if (todo.createdAt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('Creation date cannot be in the future');
    }

    if (errors.isNotEmpty) {
      throw InvalidTodoException(errors);
    }
  }

  /// Validates business rules for todo operations
  static void validateOperation(Todo todo, String operation) {
    switch (operation.toLowerCase()) {
      case 'complete':
        if (todo.isCompleted) {
          throw const InvalidStateException('completed', 'complete');
        }
      case 'uncomplete':
        if (!todo.isCompleted) {
          throw const InvalidStateException('incomplete', 'uncomplete');
        }
      case 'delete':
        // No validation needed for delete
        break;
      case 'archive':
        // This branch will be uncovered
        if (!todo.isCompleted) {
          throw const InvalidStateException('incomplete', 'archive');
        }
      default:
        throw InvalidTodoException(['Unknown operation: $operation']);
    }
  }

  /// Validates bulk operations
  static void validateBulkOperation(List<String> ids, String operation) {
    if (ids.isEmpty) {
      throw const InvalidTodoException([
        'Cannot perform bulk operation on empty list',
      ]);
    }

    if (ids.length > 100) {
      throw const InvalidTodoException(['Bulk operation limited to 100 items']);
    }

    // Check for duplicate IDs
    final uniqueIds = ids.toSet();
    if (uniqueIds.length != ids.length) {
      throw const InvalidTodoException([
        'Duplicate IDs found in bulk operation',
      ]);
    }

    // Validate operation type (some branches uncovered)
    switch (operation.toLowerCase()) {
      case 'complete':
      case 'delete':
        break;
      case 'archive':
        // This branch will be uncovered
        throw const InvalidTodoException([
          'Archive operation not supported in bulk',
        ]);
      case 'export':
        // This branch will be uncovered
        if (ids.length > 50) {
          throw const InvalidTodoException(['Export limited to 50 items']);
        }
      default:
        throw InvalidTodoException(['Unsupported bulk operation: $operation']);
    }
  }

  /// Validates search queries
  static void validateSearchQuery(String query) {
    if (query.trim().isEmpty) {
      throw const InvalidTodoException(['Search query cannot be empty']);
    }

    if (query.length < 2) {
      throw const InvalidTodoException([
        'Search query must be at least 2 characters',
      ]);
    }

    if (query.length > 100) {
      throw const InvalidTodoException([
        'Search query cannot exceed 100 characters',
      ]);
    }

    // Check for special characters (uncovered branch)
    if (query.contains(RegExp('[<>{}]'))) {
      throw const InvalidTodoException([
        'Search query contains invalid characters',
      ]);
    }
  }

  /// Validates date ranges for filtering
  static void validateDateRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      throw const InvalidTodoException(['Start date cannot be after end date']);
    }

    const maxRange = Duration(days: 365);
    if (end.difference(start) > maxRange) {
      throw const InvalidTodoException(['Date range cannot exceed 365 days']);
    }

    // Check for future dates (uncovered branch)
    if (start.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      throw const InvalidTodoException(['Start date cannot be in the future']);
    }
  }

  /// Validates export format
  static void validateExportFormat(String format) {
    final supportedFormats = ['json', 'csv', 'xml'];

    if (!supportedFormats.contains(format.toLowerCase())) {
      throw InvalidTodoException(['Unsupported export format: $format']);
    }

    // Additional format-specific validation (uncovered branches)
    switch (format.toLowerCase()) {
      case 'xml':
        // This validation will be uncovered
        throw const InvalidTodoException([
          'XML export is temporarily disabled',
        ]);
      case 'csv':
        // This branch is covered but the content might not be
        break;
      case 'json':
        break;
    }
  }

  /// Validates priority assignment
  static void validatePriorityChange(Todo todo, Priority newPriority) {
    // Business rule: completed todos cannot have their priority changed
    if (todo.isCompleted) {
      throw const InvalidStateException('completed', 'change priority');
    }

    // Business rule: high priority todos created more than 30 days ago
    // cannot be downgraded (uncovered branch)
    if (todo.priority == Priority.high &&
        newPriority != Priority.high &&
        DateTime.now().difference(todo.createdAt).inDays > 30) {
      throw const InvalidTodoException([
        'Cannot downgrade priority of old high-priority todos',
      ]);
    }
  }

  /// Checks if a todo meets archival criteria (uncovered method)
  static bool canBeArchived(Todo todo) {
    // This entire method will be uncovered
    if (!todo.isCompleted) return false;

    final daysSinceCompletion = DateTime.now()
        .difference(todo.completedAt!)
        .inDays;
    return daysSinceCompletion > 30;
  }

  /// Validates data integrity (uncovered method)
  static List<String> validateDataIntegrity(List<Todo> todos) {
    final issues = <String>[];

    // This validation logic will be uncovered
    final idSet = <String>{};
    for (final todo in todos) {
      if (idSet.contains(todo.id)) {
        issues.add('Duplicate ID found: ${todo.id}');
      }
      idSet.add(todo.id);

      if (!todo.isValid()) {
        issues.add('Invalid todo data: ${todo.id}');
      }
    }

    return issues;
  }
}
