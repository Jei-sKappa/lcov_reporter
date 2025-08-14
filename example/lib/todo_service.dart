import 'dart:math';

import 'package:example/exceptions.dart';
import 'package:example/todo.dart';
import 'package:example/todo_repository.dart';

/// Service class providing business logic for todo management
class TodoService {
  TodoService(this._repository, {bool enableLogging = false})
    : _enableLogging = enableLogging;
  final TodoRepository _repository;
  final bool _enableLogging;

  /// Creates a new todo
  Future<Todo> createTodo({
    required String title,
    required String description,
    Priority priority = Priority.medium,
  }) async {
    _log('Creating new todo: $title');

    // Validate input
    final errors = <String>[];
    if (title.trim().isEmpty) {
      errors.add('Title cannot be empty');
    }
    if (description.trim().isEmpty) {
      errors.add('Description cannot be empty');
    }
    if (title.length > 100) {
      errors.add('Title cannot exceed 100 characters');
    }
    if (description.length > 500) {
      errors.add('Description cannot exceed 500 characters');
    }

    if (errors.isNotEmpty) {
      throw InvalidTodoException(errors);
    }

    // Generate unique ID
    final id = _generateId();

    // Check for duplicate ID (rare but possible)
    final existing = await _repository.getById(id);
    if (existing != null) {
      throw DuplicateTodoException(id);
    }

    final todo = Todo(
      id: id,
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
      priority: priority,
    );

    await _repository.save(todo);
    _log('Todo created successfully: ${todo.id}');
    return todo;
  }

  /// Updates an existing todo
  Future<Todo> updateTodo(
    String id, {
    String? title,
    String? description,
    Priority? priority,
  }) async {
    _log('Updating todo: $id');

    final existing = await _repository.getById(id);
    if (existing == null) {
      throw TodoNotFoundException(id);
    }

    // Validate updates
    final errors = <String>[];
    if (title != null && title.trim().isEmpty) {
      errors.add('Title cannot be empty');
    }
    if (description != null && description.trim().isEmpty) {
      errors.add('Description cannot be empty');
    }
    if (title != null && title.length > 100) {
      errors.add('Title cannot exceed 100 characters');
    }
    if (description != null && description.length > 500) {
      errors.add('Description cannot exceed 500 characters');
    }

    if (errors.isNotEmpty) {
      throw InvalidTodoException(errors);
    }

    final updated = existing.copyWith(
      title: title?.trim(),
      description: description?.trim(),
      priority: priority,
    );

    await _repository.save(updated);
    _log('Todo updated successfully: ${updated.id}');
    return updated;
  }

  /// Completes a todo
  Future<Todo> completeTodo(String id) async {
    _log('Completing todo: $id');

    final existing = await _repository.getById(id);
    if (existing == null) {
      throw TodoNotFoundException(id);
    }

    if (existing.isCompleted) {
      throw const InvalidStateException('completed', 'complete');
    }

    final completed = existing.markCompleted();
    await _repository.save(completed);
    _log('Todo completed successfully: ${completed.id}');
    return completed;
  }

  /// Uncompletes a todo
  Future<Todo> uncompleteTodo(String id) async {
    _log('Uncompleting todo: $id');

    final existing = await _repository.getById(id);
    if (existing == null) {
      throw TodoNotFoundException(id);
    }

    if (!existing.isCompleted) {
      throw const InvalidStateException('incomplete', 'uncomplete');
    }

    final uncompleted = existing.markIncomplete();
    await _repository.save(uncompleted);
    _log('Todo uncompleted successfully: ${uncompleted.id}');
    return uncompleted;
  }

  /// Deletes a todo
  Future<void> deleteTodo(String id) async {
    _log('Deleting todo: $id');

    // Check if todo exists before deletion
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw TodoNotFoundException(id);
    }

    await _repository.delete(id);
    _log('Todo deleted successfully: $id');
  }

  /// Gets all todos
  Future<List<Todo>> getAllTodos() async {
    _log('Fetching all todos');
    return _repository.getAll();
  }

  /// Gets a specific todo by ID
  Future<Todo> getTodo(String id) async {
    _log('Fetching todo: $id');

    final todo = await _repository.getById(id);
    if (todo == null) {
      throw TodoNotFoundException(id);
    }

    return todo;
  }

  /// Gets todos by completion status
  Future<List<Todo>> getTodosByStatus(bool isCompleted) async {
    _log('Fetching todos by status: $isCompleted');
    return _repository.getByStatus(isCompleted);
  }

  /// Gets todos by priority
  Future<List<Todo>> getTodosByPriority(Priority priority) async {
    _log('Fetching todos by priority: $priority');
    return _repository.getByPriority(priority);
  }

  /// Gets todos sorted by creation date
  Future<List<Todo>> getTodosSortedByDate({bool ascending = true}) async {
    _log('Fetching todos sorted by date: ascending=$ascending');

    final todos = await _repository.getAll();
    todos.sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return ascending ? comparison : -comparison;
    });

    return todos;
  }

  /// Gets todos sorted by priority
  Future<List<Todo>> getTodosSortedByPriority({bool ascending = false}) async {
    _log('Fetching todos sorted by priority: ascending=$ascending');

    final todos = await _repository.getAll();
    todos.sort((a, b) {
      final comparison = a.priority.sortValue.compareTo(b.priority.sortValue);
      return ascending ? comparison : -comparison;
    });

    return todos;
  }

  /// Searches todos by text
  Future<List<Todo>> searchTodos(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      throw const InvalidTodoException(['Search term cannot be empty']);
    }

    _log('Searching todos: $searchTerm');

    if (_repository is FileTodoRepository) {
      return _repository.search(searchTerm);
    }

    // Fallback implementation for other repository types
    final allTodos = await _repository.getAll();
    final term = searchTerm.toLowerCase();
    return allTodos.where((todo) {
      return todo.title.toLowerCase().contains(term) ||
          todo.description.toLowerCase().contains(term);
    }).toList();
  }

  /// Gets completion statistics
  Future<Map<String, dynamic>> getStatistics() async {
    _log('Calculating statistics');

    final todos = await _repository.getAll();
    final completed = todos.where((t) => t.isCompleted).length;
    final pending = todos.length - completed;

    final priorityBreakdown = <String, int>{};
    for (final priority in Priority.values) {
      priorityBreakdown[priority.name] = todos
          .where((t) => t.priority == priority)
          .length;
    }

    return {
      'total': todos.length,
      'completed': completed,
      'pending': pending,
      'completionRate': todos.isEmpty ? 0.0 : (completed / todos.length) * 100,
      'priorityBreakdown': priorityBreakdown,
    };
  }

  /// Bulk operation to complete multiple todos
  Future<List<Todo>> bulkCompleteTodos(List<String> ids) async {
    _log('Bulk completing ${ids.length} todos');

    final results = <Todo>[];
    final errors = <String>[];

    for (final id in ids) {
      try {
        final completed = await completeTodo(id);
        results.add(completed);
      } on Object catch (e) {
        errors.add('Failed to complete todo $id: $e');
      }
    }

    if (errors.isNotEmpty && results.isEmpty) {
      // All operations failed
      throw InvalidTodoException(errors);
    }

    // Some operations might have failed, but we return successful ones
    // This behavior is intentionally different for testing
    return results;
  }

  /// Bulk operation to delete multiple todos
  Future<void> bulkDeleteTodos(List<String> ids) async {
    _log('Bulk deleting ${ids.length} todos');

    final errors = <String>[];

    for (final id in ids) {
      try {
        await deleteTodo(id);
      } on Object catch (e) {
        errors.add('Failed to delete todo $id: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw InvalidTodoException(errors);
    }
  }

  /// Archives all completed todos (method that won't be tested)
  Future<int> archiveCompletedTodos() async {
    _log('Archiving completed todos');

    // This method is intentionally not covered in tests
    final completed = await getTodosByStatus(true);
    if (completed.isEmpty) {
      return 0;
    }

    // Archive logic would go here
    for (final todo in completed) {
      await _repository.delete(todo.id);
    }

    return completed.length;
  }

  /// Validates all todos in the repository (uncovered method)
  Future<List<String>> validateAllTodos() async {
    _log('Validating all todos');

    final todos = await _repository.getAll();
    final invalidTodos = <String>[];

    // This validation logic won't be covered
    for (final todo in todos) {
      if (!todo.isValid()) {
        invalidTodos.add(todo.id);
      }
    }

    return invalidTodos;
  }

  /// Exports todos to a specific format (uncovered method)
  Future<String> exportTodos(String format) async {
    final todos = await _repository.getAll();

    // Different format exports - some branches will be uncovered
    switch (format.toLowerCase()) {
      case 'csv':
        return _exportToCsv(todos);
      case 'json':
        return _exportToJson(todos);
      case 'xml':
        // This branch will be uncovered
        return _exportToXml(todos);
      default:
        throw InvalidTodoException(['Unsupported export format: $format']);
    }
  }

  /// Generates a unique ID for todos
  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Logs messages if logging is enabled
  void _log(String message) {
    if (_enableLogging) {
      print('[TodoService] $message');
    }
  }

  /// Exports todos to CSV format
  String _exportToCsv(List<Todo> todos) {
    final buffer = StringBuffer()
      ..writeln('ID,Title,Description,IsCompleted,CreatedAt,Priority');

    for (final todo in todos) {
      buffer.writeln(
        '${todo.id},'
        '"${todo.title}",'
        '"${todo.description}",'
        '${todo.isCompleted},'
        '${todo.createdAt.toIso8601String()},'
        '${todo.priority.name}',
      );
    }

    return buffer.toString();
  }

  /// Exports todos to JSON format
  String _exportToJson(List<Todo> todos) {
    final jsonList = todos.map((todo) => todo.toJson()).toList();
    return jsonList.toString();
  }

  /// Exports todos to XML format (uncovered method)
  String _exportToXml(List<Todo> todos) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<todos>');

    for (final todo in todos) {
      buffer
        ..writeln('  <todo>')
        ..writeln('    <id>${todo.id}</id>')
        ..writeln('    <title>${todo.title}</title>')
        ..writeln('    <description>${todo.description}</description>')
        ..writeln('    <isCompleted>${todo.isCompleted}</isCompleted>')
        ..writeln(
          '    <createdAt>${todo.createdAt.toIso8601String()}</createdAt>',
        )
        ..writeln('    <priority>${todo.priority.name}</priority>')
        ..writeln('  </todo>');
    }

    buffer.writeln('</todos>');
    return buffer.toString();
  }
}
