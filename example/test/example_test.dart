import 'dart:io';

import 'package:example/example.dart';
import 'package:example/exceptions.dart';
import 'package:example/todo.dart';
import 'package:example/todo_repository.dart';
import 'package:example/todo_service.dart';
import 'package:test/test.dart';

void main() {
  group('Todo Model Tests', () {
    test('should create a todo with required fields', () {
      final todo = Todo(
        id: 'test-1',
        title: 'Test Todo',
        description: 'Test Description',
        createdAt: DateTime.now(),
      );

      expect(todo.id, equals('test-1'));
      expect(todo.title, equals('Test Todo'));
      expect(todo.description, equals('Test Description'));
      expect(todo.isCompleted, isFalse);
      expect(todo.priority, equals(Priority.medium));
    });

    test('should mark todo as completed', () {
      final todo = Todo(
        id: 'test-1',
        title: 'Test Todo',
        description: 'Test Description',
        createdAt: DateTime.now(),
      );

      final completed = todo.markCompleted();
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);
    });

    test('should throw when marking already completed todo', () {
      final todo = Todo(
        id: 'test-1',
        title: 'Test Todo',
        description: 'Test Description',
        createdAt: DateTime.now(),
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      expect(todo.markCompleted, throwsStateError);
    });

    test('should convert to and from JSON', () {
      final original = Todo(
        id: 'test-1',
        title: 'Test Todo',
        description: 'Test Description',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        priority: Priority.high,
      );

      final json = original.toJson();
      final restored = Todo.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.description, equals(original.description));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.priority, equals(original.priority));
    });

    test('should validate todo data', () {
      final validTodo = Todo(
        id: 'test-1',
        title: 'Valid Todo',
        description: 'Valid Description',
        createdAt: DateTime.now(),
      );

      final invalidTodo = Todo(
        id: 'test-2',
        title: '',
        description: 'Description',
        createdAt: DateTime.now(),
      );

      expect(validTodo.isValid(), isTrue);
      expect(invalidTodo.isValid(), isFalse);
    });

    // Note: Not testing markIncomplete, copyWith, statusText, isOverdue methods
    // These will show up as uncovered in the coverage report
  });

  group('Todo Repository Tests', () {
    late FileTodoRepository repository;
    const testFile = 'test_todos.json';

    setUp(() {
      repository = FileTodoRepository(filePath: testFile);
    });

    tearDown(() async {
      final file = File(testFile);
      if (file.existsSync()) {
        await file.delete();
      }
    });

    test('should save and retrieve todos', () async {
      final todo = Todo(
        id: 'test-1',
        title: 'Test Todo',
        description: 'Test Description',
        createdAt: DateTime.now(),
      );

      await repository.save(todo);
      final retrieved = await repository.getById('test-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(todo.id));
      expect(retrieved.title, equals(todo.title));
    });

    test('should return null for non-existent todo', () async {
      final result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('should delete todo', () async {
      final todo = Todo(
        id: 'test-1',
        title: 'Test Todo',
        description: 'Test Description',
        createdAt: DateTime.now(),
      );

      await repository.save(todo);
      await repository.delete('test-1');

      final result = await repository.getById('test-1');
      expect(result, isNull);
    });

    test('should throw when deleting non-existent todo', () async {
      expect(
        () => repository.delete('nonexistent'),
        throwsA(isA<TodoNotFoundException>()),
      );
    });

    test('should get todos by status', () async {
      final todo1 = Todo(
        id: 'test-1',
        title: 'Pending Todo',
        description: 'Description',
        createdAt: DateTime.now(),
      );

      final todo2 = Todo(
        id: 'test-2',
        title: 'Completed Todo',
        description: 'Description',
        createdAt: DateTime.now(),
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      await repository.save(todo1);
      await repository.save(todo2);

      final pending = await repository.getByStatus(false);
      final completed = await repository.getByStatus(true);

      expect(pending.length, equals(1));
      expect(completed.length, equals(1));
    });

    // Note: Not testing getByPriority, search, archiveCompleted,
    // validateFileIntegrity, backup, restoreFromBackup methods. These will show
    // as uncovered.
  });

  group('Todo Service Tests', () {
    late TodoService service;
    late FileTodoRepository repository;
    const testFile = 'test_service_todos.json';

    setUp(() {
      repository = FileTodoRepository(filePath: testFile);
      service = TodoService(repository);
    });

    tearDown(() async {
      final file = File(testFile);
      if (file.existsSync()) {
        await file.delete();
      }
    });

    test('should create todo with valid data', () async {
      final todo = await service.createTodo(
        title: 'Test Todo',
        description: 'Test Description',
        priority: Priority.high,
      );

      expect(todo.title, equals('Test Todo'));
      expect(todo.description, equals('Test Description'));
      expect(todo.priority, equals(Priority.high));
      expect(todo.isCompleted, isFalse);
    });

    test('should throw on invalid todo creation', () async {
      expect(
        () => service.createTodo(title: '', description: 'Description'),
        throwsA(isA<InvalidTodoException>()),
      );
    });

    test('should complete a todo', () async {
      final created = await service.createTodo(
        title: 'Test Todo',
        description: 'Test Description',
      );

      final completed = await service.completeTodo(created.id);
      expect(completed.isCompleted, isTrue);
    });

    test('should throw when completing non-existent todo', () async {
      expect(
        () => service.completeTodo('nonexistent'),
        throwsA(isA<TodoNotFoundException>()),
      );
    });

    test('should get all todos', () async {
      await service.createTodo(title: 'Todo 1', description: 'Description 1');
      await service.createTodo(title: 'Todo 2', description: 'Description 2');

      final todos = await service.getAllTodos();
      expect(todos.length, equals(2));
    });

    test('should get todo by id', () async {
      final created = await service.createTodo(
        title: 'Test Todo',
        description: 'Test Description',
      );

      final retrieved = await service.getTodo(created.id);
      expect(retrieved.id, equals(created.id));
    });

    test('should throw when getting non-existent todo', () async {
      expect(
        () => service.getTodo('nonexistent'),
        throwsA(isA<TodoNotFoundException>()),
      );
    });

    test('should update todo', () async {
      final created = await service.createTodo(
        title: 'Original Title',
        description: 'Original Description',
      );

      final updated = await service.updateTodo(
        created.id,
        title: 'New Title',
        priority: Priority.high,
      );

      expect(updated.title, equals('New Title'));
      expect(updated.priority, equals(Priority.high));
    });

    test('should search todos', () async {
      await service.createTodo(
        title: 'Flutter App',
        description: 'Mobile development',
      );
      await service.createTodo(
        title: 'Web App',
        description: 'Frontend development',
      );
      await service.createTodo(
        title: 'Backend',
        description: 'Server development',
      );

      final results = await service.searchTodos('app');
      expect(results.length, equals(2));
    });

    test('should get statistics', () async {
      final todo1 = await service.createTodo(
        title: 'Todo 1',
        description: 'Description',
      );
      await service.createTodo(title: 'Todo 2', description: 'Description');
      await service.completeTodo(todo1.id);

      final stats = await service.getStatistics();
      expect(stats['total'], equals(2));
      expect(stats['completed'], equals(1));
      expect(stats['pending'], equals(1));
      expect(stats['completionRate'], equals(50.0));
    });

    // Note: Not testing uncompleteTodo, deleteTodo, getTodosByStatus,
    // getTodosByPriority, getTodosSortedByDate, getTodosSortedByPriority,
    // bulkCompleteTodos, bulkDeleteTodos, archiveCompletedTodos,
    // validateAllTodos, exportTodos methods.
    // These will show as uncovered in the coverage report.
  });

  group('Exception Tests', () {
    test('should create TodoNotFoundException', () {
      const exception = TodoNotFoundException('test-id');
      expect(exception.todoId, equals('test-id'));
      expect(exception.message, contains('test-id'));
    });

    test('should create InvalidTodoException', () {
      const exception = InvalidTodoException(['Error 1', 'Error 2']);
      expect(exception.validationErrors.length, equals(2));
    });

    test('should handle exceptions with ExceptionHandler', () {
      const todoNotFound = TodoNotFoundException('test-id');
      const invalidTodo = InvalidTodoException(['Invalid data']);

      final message1 = ExceptionHandler.handleException(todoNotFound);
      final message2 = ExceptionHandler.handleException(invalidTodo);

      expect(message1, contains('could not be found'));
      expect(message2, contains('Invalid todo'));
    });

    // Note: Not testing DuplicateTodoException, StorageException,
    // NetworkException, InvalidStateException, and
    // ExceptionHandler.logException and isRecoverable methods.
    // These will show as uncovered.
  });

  group('TodoExample Integration Tests', () {
    late TodoExample example;
    const testFile = 'example_todos.json';

    setUp(() {
      example = TodoExample();
    });

    tearDown(() async {
      final file = File(testFile);
      if (file.existsSync()) {
        await file.delete();
      }
    });

    test('should run example without errors', () async {
      // This only tests the basic run method, not demonstrateErrorHandling,
      // demonstrateBulkOperations, or cleanup methods
      await expectLater(example.run(), completes);
    });

    // Note: Not testing demonstrateErrorHandling, demonstrateBulkOperations,
    // and cleanup methods. These will be uncovered.
  });

  group('Priority Enum Tests', () {
    test('should have correct display names', () {
      expect(Priority.low.displayName, equals('Low'));
      expect(Priority.medium.displayName, equals('Medium'));
      expect(Priority.high.displayName, equals('High'));
    });

    test('should have correct sort values', () {
      expect(Priority.low.sortValue, equals(1));
      expect(Priority.medium.sortValue, equals(2));
      expect(Priority.high.sortValue, equals(3));
    });
  });
}
