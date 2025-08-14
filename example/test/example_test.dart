import 'package:example/todo.dart';
import 'package:example/todo_manager.dart';
import 'package:example/user.dart';
import 'package:test/test.dart';

void main() {
  group('Todo Tests (Full Coverage)', () {
    test('should create a todo with required fields', () {
      const todo = Todo(id: '1', title: 'Test Todo');

      expect(todo.id, equals('1'));
      expect(todo.user, isNull);
      expect(todo.title, equals('Test Todo'));
      expect(todo.isCompleted, isFalse);
    });

    test('should create a todo with completion status', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: true);

      expect(todo.isCompleted, isTrue);
    });

    test('should create todo from JSON', () {
      final json = {'id': '1', 'title': 'Test Todo', 'isCompleted': false};

      final todo = Todo.fromJson(json);

      expect(todo.id, equals('1'));
      expect(todo.user, isNull);
      expect(todo.title, equals('Test Todo'));
      expect(todo.isCompleted, isFalse);

      const user = User(id: '1', name: 'Alice');

      final jsonWithUser = {
        'id': '1',
        'title': 'Test Todo',
        'isCompleted': false,
        'user': user.toJson(),
      };

      final todoWithUser = Todo.fromJson(jsonWithUser);

      expect(todoWithUser.id, equals('1'));
      expect(todoWithUser.user, equals(user));
      expect(todoWithUser.title, equals('Test Todo'));
      expect(todoWithUser.isCompleted, isFalse);
    });

    test('should convert todo to JSON', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: true);

      final json = todo.toJson();

      expect(json['id'], equals('1'));
      expect(json['title'], equals('Test Todo'));
      expect(json['isCompleted'], isTrue);
    });

    test('should copy todo with new fields', () {
      const todo = Todo(id: '1', title: 'Original Title');

      final copied = todo.copyWith(
        id: '2',
        title: 'New Title',
        isCompleted: true,
      );

      expect(copied.id, equals('2'));
      expect(copied.user, isNull);
      expect(copied.title, equals('New Title'));
      expect(copied.isCompleted, isTrue);
    });

    test('should copy todo with partial fields', () {
      const todo = Todo(id: '1', title: 'Original Title');

      final copied = todo.copyWith(title: 'New Title');

      expect(copied.id, equals('1'));
      expect(copied.user, isNull);
      expect(copied.title, equals('New Title'));
      expect(copied.isCompleted, isFalse);
    });

    test('should mark todo as completed', () {
      const todo = Todo(id: '1', title: 'Test Todo');

      final completed = todo.markCompleted();

      expect(completed.isCompleted, isTrue);
      expect(completed.id, equals(todo.id));
      expect(completed.user, isNull);
      expect(completed.title, equals(todo.title));
    });

    test('should throw when marking already completed todo', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: true);

      expect(todo.markCompleted, throwsStateError);
    });

    test('should mark todo as incomplete', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: true);

      final incomplete = todo.markIncomplete();

      expect(incomplete.isCompleted, isFalse);
      expect(incomplete.id, equals(todo.id));
      expect(incomplete.user, isNull);
      expect(incomplete.title, equals(todo.title));
    });

    test('should throw when marking already incomplete todo', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: false);

      expect(todo.markIncomplete, throwsStateError);
    });

    test('should validate valid todo', () {
      const todo = Todo(id: '1', title: 'Valid Todo');

      expect(todo.isValid(), isTrue);
    });

    test('should invalidate todo with empty title', () {
      const todo = Todo(id: '1', title: '');

      expect(todo.isValid(), isFalse);
    });

    test('should invalidate todo with whitespace-only title', () {
      const todo = Todo(id: '1', title: '   ');

      expect(todo.isValid(), isFalse);
    });

    test('should return correct status text for completed todo', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: true);

      expect(todo.statusText, equals('Completed'));
    });

    test('should return correct status text for pending todo', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: false);

      expect(todo.statusText, equals('Pending'));
    });

    test('should implement equality correctly', () {
      const todo1 = Todo(id: '1', title: 'Test Todo', isCompleted: false);

      const todo2 = Todo(id: '1', title: 'Test Todo', isCompleted: false);

      const todo3 = Todo(id: '2', title: 'Test Todo', isCompleted: false);

      expect(todo1 == todo2, isTrue);
      expect(todo1 == todo3, isFalse);

      expect(todo1, equals(todo2));
      expect(todo1, isNot(equals(todo3)));
    });

    test('should have consistent hashCode', () {
      const todo1 = Todo(id: '1', title: 'Test Todo', isCompleted: false);

      const todo2 = Todo(id: '1', title: 'Test Todo', isCompleted: false);

      expect(todo1.hashCode, equals(todo2.hashCode));
    });

    test('should implement toString correctly', () {
      const todo = Todo(id: '1', title: 'Test Todo', isCompleted: true);

      final result = todo.toString();

      expect(result, contains('Todo('));
      expect(result, contains('id: 1'));
      expect(result, contains('user: null'));
      expect(result, contains('title: Test Todo'));
      expect(result, contains('isCompleted: true'));
    });
  });

  group('TodoManager Tests (Partial Coverage)', () {
    late TodoManager manager;
    late Todo todo1;
    late Todo todo2;

    setUp(() {
      manager = TodoManager();
      todo1 = const Todo(id: '1', title: 'Learn Dart');
      todo2 = const Todo(id: '2', title: 'Build App');
    });

    test('should start with empty list', () {
      expect(manager.getAllTodos(), isEmpty);
    });

    test('should add todo', () {
      manager.addTodo(todo1);

      final todos = manager.getAllTodos();
      expect(todos.length, equals(1));
      expect(todos.first, equals(todo1));
    });

    test('should add multiple todos', () {
      manager
        ..addTodo(todo1)
        ..addTodo(todo2);

      final todos = manager.getAllTodos();
      expect(todos.length, equals(2));
      expect(todos, contains(todo1));
      expect(todos, contains(todo2));
    });

    test('should throw when adding todo with duplicate id', () {
      manager.addTodo(todo1);

      const duplicateTodo = Todo(id: '1', title: 'Duplicate');
      expect(() => manager.addTodo(duplicateTodo), throwsArgumentError);
    });

    test('should remove existing todo', () {
      manager
        ..addTodo(todo1)
        ..addTodo(todo2);

      final removed = manager.removeTodo(todo1.id);

      expect(removed, isTrue);
      final todos = manager.getAllTodos();
      expect(todos.length, equals(1));
      expect(todos, isNot(contains(todo1)));
      expect(todos, contains(todo2));
    });

    test('should return false when removing non-existent todo', () {
      manager.addTodo(todo1);

      final removed = manager.removeTodo('nonexistent');

      expect(removed, isFalse);
      expect(manager.getAllTodos().length, equals(1));
    });

    test('should complete existing todo', () {
      manager.addTodo(todo1);

      final completed = manager.completeTodo(todo1.id);

      expect(completed, isTrue);
      final todos = manager.getAllTodos();
      expect(todos.first.isCompleted, isTrue);
    });

    test('should return false when completing non-existent todo', () {
      manager.addTodo(todo1);

      final completed = manager.completeTodo('nonexistent');

      expect(completed, isFalse);
    });

    test('should return false when completing already completed todo', () {
      const completedTodo = Todo(
        id: '1',
        title: 'Completed Todo',
        isCompleted: true,
      );
      manager.addTodo(completedTodo);

      final result = manager.completeTodo(completedTodo.id);

      expect(result, isFalse);
    });

    // Note: Intentionally NOT testing uncompleteTodo method
    // This will show as uncovered in the coverage report
  });

  // Note: Intentionally NOT testing User class at all
  // This will show as completely uncovered in the coverage report
}
