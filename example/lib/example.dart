import 'package:example/exceptions.dart';
import 'package:example/todo.dart';
import 'package:example/todo_repository.dart';
import 'package:example/todo_service.dart';

/// Example demonstrating the todo management system
class TodoExample {
  TodoExample() {
    final repository = FileTodoRepository(filePath: 'example_todos.json');
    _todoService = TodoService(repository, enableLogging: true);
  }
  late final TodoService _todoService;

  /// Runs the todo example
  Future<void> run() async {
    print('=== Todo Management Example ===\n');

    try {
      // Create some example todos
      await _createExampleTodos();

      // Demonstrate various operations
      await _demonstrateOperations();

      // Show statistics
      await _showStatistics();
    } catch (e) {
      print('Error running example: $e');
      rethrow;
    }
  }

  /// Creates example todos
  Future<void> _createExampleTodos() async {
    print('Creating example todos...\n');

    final todos = [
      {
        'title': 'Learn Dart programming',
        'description': 'Study Dart language fundamentals and best practices',
        'priority': Priority.high,
      },
      {
        'title': 'Build a mobile app',
        'description':
            'Create a cross-platform mobile application using Flutter',
        'priority': Priority.medium,
      },
      {
        'title': 'Write unit tests',
        'description': 'Add comprehensive test coverage for the todo system',
        'priority': Priority.medium,
      },
      {
        'title': 'Update documentation',
        'description': 'Improve code documentation and add examples',
        'priority': Priority.low,
      },
    ];

    for (final todoData in todos) {
      final todo = await _todoService.createTodo(
        title: todoData['title']! as String,
        description: todoData['description']! as String,
        priority: todoData['priority']! as Priority,
      );
      print('Created: ${todo.title} (${todo.priority.displayName} priority)');
    }

    print('');
  }

  /// Demonstrates various todo operations
  Future<void> _demonstrateOperations() async {
    print('Demonstrating operations...\n');

    // Get all todos
    final allTodos = await _todoService.getAllTodos();
    print('Total todos: ${allTodos.length}');

    // Complete the first todo
    if (allTodos.isNotEmpty) {
      final firstTodo = allTodos.first;
      final completed = await _todoService.completeTodo(firstTodo.id);
      print('Completed: ${completed.title}');
    }

    // Update a todo
    if (allTodos.length > 1) {
      final secondTodo = allTodos[1];
      final updated = await _todoService.updateTodo(
        secondTodo.id,
        title: 'Build an awesome mobile app',
        priority: Priority.high,
      );
      print('Updated: ${updated.title}');
    }

    // Search todos
    final searchResults = await _todoService.searchTodos('app');
    print('Search results for "app": ${searchResults.length} todos');

    // Get todos by priority
    final highPriorityTodos = await _todoService.getTodosByPriority(
      Priority.high,
    );
    print('High priority todos: ${highPriorityTodos.length}');

    print('');
  }

  /// Shows todo statistics
  Future<void> _showStatistics() async {
    print('Statistics:');

    final stats = await _todoService.getStatistics();
    print(
      '  Total: '
      '${stats['total'] as int}',
    );
    print(
      '  Completed: '
      '${stats['completed'] as int}',
    );
    print(
      '  Pending: '
      '${stats['pending'] as int}',
    );
    print(
      '  Completion Rate: '
      '${(stats['completionRate'] as double).toStringAsFixed(1)}%',
    );

    final priorityBreakdown = stats['priorityBreakdown'] as Map<String, int>;
    print('  Priority Breakdown:');
    for (final entry in priorityBreakdown.entries) {
      print('    ${entry.key}: ${entry.value}');
    }
  }

  /// Demonstrates error handling
  Future<void> demonstrateErrorHandling() async {
    print('\n=== Error Handling Examples ===\n');

    try {
      // Try to get a non-existent todo
      await _todoService.getTodo('nonexistent');
    } on TodoNotFoundException catch (e) {
      print('Caught expected exception: $e');
    }

    try {
      // Try to create an invalid todo
      await _todoService.createTodo(title: '', description: '');
    } on InvalidTodoException catch (e) {
      print('Caught validation error: $e');
    }

    try {
      // Try to complete a non-existent todo
      await _todoService.completeTodo('nonexistent');
    } on TodoNotFoundException catch (e) {
      print('Caught expected exception: $e');
    }
  }

  /// Demonstrates bulk operations
  Future<void> demonstrateBulkOperations() async {
    print('\n=== Bulk Operations Example ===\n');

    final todos = await _todoService.getAllTodos();
    final pendingIds = todos
        .where((todo) => !todo.isCompleted)
        .map((todo) => todo.id)
        .take(2)
        .toList();

    if (pendingIds.isNotEmpty) {
      print('Bulk completing ${pendingIds.length} todos...');
      final completed = await _todoService.bulkCompleteTodos(pendingIds);
      print('Successfully completed ${completed.length} todos');
    }
  }

  /// Cleans up example data
  Future<void> cleanup() async {
    print('\nCleaning up example data...');
    await _todoService.bulkDeleteTodos(
      (await _todoService.getAllTodos()).map((t) => t.id).toList(),
    );
    print('Cleanup complete.');
  }
}
