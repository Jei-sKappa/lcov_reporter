import 'package:example/todo.dart';
import 'package:example/todo_manager.dart';

Future<void> main(List<String> arguments) async {
  final manager = TodoManager();

  // Create some todos
  const todo1 = Todo(id: '1', title: 'Learn Dart');
  const todo2 = Todo(id: '2', title: 'Build an app');
  const todo3 = Todo(id: '3', title: 'Write tests');

  print('=== Todo Manager Example ===\n');

  // Add todos
  print('Adding todos...');
  manager
    ..addTodo(todo1)
    ..addTodo(todo2)
    ..addTodo(todo3);

  // Get all todos
  print('Current todos:');
  for (final todo in manager.getAllTodos()) {
    print(
      '- ${todo.title} by ${todo.user?.name ?? 'unknown'} [${todo.statusText}]',
    );
  }

  // Complete a todo
  print('\nCompleting todo: ${todo1.title}');
  final completed = manager.completeTodo(todo1.id);
  print('Success: $completed');

  // Show todos again
  print('\nTodos after completion:');
  for (final todo in manager.getAllTodos()) {
    print(
      '- ${todo.title} by ${todo.user?.name ?? 'unknown'} [${todo.statusText}]',
    );
  }

  // Uncomplete a todo
  print('\nUncompleting todo: ${todo1.title}');
  final uncompleted = manager.uncompleteTodo(todo1.id);
  print('Success: $uncompleted');

  // Remove a todo
  print('\nRemoving todo: ${todo2.title}');
  final removed = manager.removeTodo(todo2.id);
  print('Success: $removed');

  // Final state
  print('\nFinal todos:');
  for (final todo in manager.getAllTodos()) {
    print(
      '- ${todo.title} by ${todo.user?.name ?? 'unknown'} [${todo.statusText}]',
    );
  }

  print('\nExample completed!');
}
