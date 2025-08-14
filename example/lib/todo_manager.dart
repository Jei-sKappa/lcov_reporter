import 'package:example/todo.dart';

/// Simple todo manager for managing a list of todos
class TodoManager {
  final List<Todo> _todos = [];

  /// Get all todos
  List<Todo> getAllTodos() {
    return List.from(_todos);
  }

  /// Add a new todo to the list
  void addTodo(Todo todo) {
    if (_todos.any((t) => t.id == todo.id)) {
      throw ArgumentError('Todo with id ${todo.id} already exists');
    }
    _todos.add(todo);
  }

  /// Remove a todo by ID
  bool removeTodo(String id) {
    final initialLength = _todos.length;
    _todos.removeWhere((todo) => todo.id == id);
    return _todos.length < initialLength;
  }

  /// Mark a todo as completed
  bool completeTodo(String id) {
    final todoIndex = _todos.indexWhere((todo) => todo.id == id);
    if (todoIndex == -1) return false;

    final todo = _todos[todoIndex];
    if (todo.isCompleted) return false;

    _todos[todoIndex] = todo.markCompleted();
    return true;
  }

  /// Mark a todo as incomplete
  bool uncompleteTodo(String id) {
    final todoIndex = _todos.indexWhere((todo) => todo.id == id);
    if (todoIndex == -1) return false;

    final todo = _todos[todoIndex];
    if (!todo.isCompleted) return false;

    _todos[todoIndex] = todo.markIncomplete();
    return true;
  }
}
