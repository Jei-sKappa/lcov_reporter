import 'dart:convert';
import 'dart:io';

import 'package:example/exceptions.dart';
import 'package:example/todo.dart';

/// Abstract interface for todo data persistence
abstract class TodoRepository {
  /// Retrieves all todos
  Future<List<Todo>> getAll();

  /// Retrieves a todo by its ID
  Future<Todo?> getById(String id);

  /// Saves a todo (create or update)
  Future<void> save(Todo todo);

  /// Deletes a todo by its ID
  Future<void> delete(String id);

  /// Clears all todos
  Future<void> clear();

  /// Gets todos by completion status
  Future<List<Todo>> getByStatus(bool isCompleted);

  /// Gets todos by priority
  Future<List<Todo>> getByPriority(Priority priority);
}

/// File-based implementation of TodoRepository
class FileTodoRepository implements TodoRepository {

  FileTodoRepository({String filePath = 'todos.json'}) : _filePath = filePath;
  final String _filePath;
  List<Todo>? _cache;

  /// Loads todos from file into cache
  Future<void> _loadCache() async {
    if (_cache != null) return;

    try {
      final file = File(_filePath);
      if (!file.existsSync()) {
        _cache = [];
        return;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _cache = [];
        return;
      }

      final jsonList = jsonDecode(content) as List<dynamic>;
      _cache = jsonList
          .map((json) => Todo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageException.readFailure(e);
    }
  }

  /// Saves cache to file
  Future<void> _saveCache() async {
    if (_cache == null) return;

    try {
      final file = File(_filePath);
      await file.parent.create(recursive: true);

      final jsonList = _cache!.map((todo) => todo.toJson()).toList();
      final content = jsonEncode(jsonList);
      await file.writeAsString(content);
    } catch (e) {
      throw StorageException.writeFailure(e);
    }
  }

  @override
  Future<List<Todo>> getAll() async {
    await _loadCache();
    return List.from(_cache!);
  }

  @override
  Future<Todo?> getById(String id) async {
    await _loadCache();
    try {
      return _cache!.firstWhere((todo) => todo.id == id);
    } on Object catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Todo todo) async {
    await _loadCache();

    // Validate the todo
    if (!todo.isValid()) {
      throw const InvalidTodoException(['Todo data is invalid']);
    }

    final existingIndex = _cache!.indexWhere((t) => t.id == todo.id);
    if (existingIndex != -1) {
      _cache![existingIndex] = todo;
    } else {
      _cache!.add(todo);
    }

    await _saveCache();
  }

  @override
  Future<void> delete(String id) async {
    await _loadCache();

    final initialLength = _cache!.length;
    _cache!.removeWhere((todo) => todo.id == id);

    if (_cache!.length == initialLength) {
      throw TodoNotFoundException(id);
    }

    await _saveCache();
  }

  @override
  Future<void> clear() async {
    _cache = [];
    await _saveCache();
  }

  @override
  Future<List<Todo>> getByStatus(bool isCompleted) async {
    await _loadCache();
    return _cache!.where((todo) => todo.isCompleted == isCompleted).toList();
  }

  @override
  Future<List<Todo>> getByPriority(Priority priority) async {
    await _loadCache();
    return _cache!.where((todo) => todo.priority == priority).toList();
  }

  /// Gets todos created within a date range
  Future<List<Todo>> getByDateRange(DateTime start, DateTime end) async {
    await _loadCache();
    return _cache!.where((todo) {
      return todo.createdAt.isAfter(start) && todo.createdAt.isBefore(end);
    }).toList();
  }

  /// Gets todos that contain a search term
  Future<List<Todo>> search(String searchTerm) async {
    await _loadCache();
    final term = searchTerm.toLowerCase();
    return _cache!.where((todo) {
      return todo.title.toLowerCase().contains(term) ||
          todo.description.toLowerCase().contains(term);
    }).toList();
  }

  /// Archives completed todos (method for testing - never called)
  Future<void> archiveCompleted() async {
    await _loadCache();

    // This method is intentionally left uncovered for testing
    final completed = _cache!.where((todo) => todo.isCompleted).toList();
    if (completed.isEmpty) {
      return;
    }

    // Create archive file
    final archiveFile = File(
      'archive_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    final archiveContent = jsonEncode(
      completed.map((t) => t.toJson()).toList(),
    );
    await archiveFile.writeAsString(archiveContent);

    // Remove from main cache
    _cache!.removeWhere((todo) => todo.isCompleted);
    await _saveCache();
  }

  /// Validates file integrity (method for testing - never called)
  Future<bool> validateFileIntegrity() async {
    try {
      final file = File(_filePath);
      if (!file.existsSync()) return true;

      final content = await file.readAsString();
      if (content.trim().isEmpty) return true;

      // This validation logic is left uncovered
      final json = jsonDecode(content);
      if (json is! List) return false;

      for (final item in json) {
        if (item is! Map<String, dynamic>) return false;
        if (!item.containsKey('id') || !item.containsKey('title')) {
          return false;
        }
      }

      return true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Backs up data to a backup file (uncovered method)
  Future<void> backup() async {
    await _loadCache();

    // This backup logic will be uncovered in tests
    final backupPath = '$_filePath.backup';
    final backupFile = File(backupPath);

    if (_cache!.isNotEmpty) {
      final jsonList = _cache!.map((todo) => todo.toJson()).toList();
      final content = jsonEncode(jsonList);
      await backupFile.writeAsString(content);
    }
  }

  /// Restores data from backup file (uncovered method)
  Future<void> restoreFromBackup() async {
    final backupPath = '$_filePath.backup';
    final backupFile = File(backupPath);

    if (!backupFile.existsSync()) {
      throw const StorageException('Backup file not found');
    }

    try {
      final content = await backupFile.readAsString();
      final jsonList = jsonDecode(content) as List<dynamic>;
      _cache = jsonList
          .map((json) => Todo.fromJson(json as Map<String, dynamic>))
          .toList();
      await _saveCache();
    } on Object catch (e) {
      throw StorageException.corruption(e);
    }
  }
}
