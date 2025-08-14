# LCOV Reporter

## Total Coverage: 84.2%

## File: lib/todo_manager.dart

### Coverage: 72.7%

### Uncovered Lines:

```dart
  40:   bool uncompleteTodo(String id) {
  41:     final todoIndex = _todos.indexWhere((todo) => todo.id == id);
  42:     if (todoIndex == -1) return false;
```


```dart
  44:     final todo = _todos[todoIndex];
  45:     if (!todo.isCompleted) return false;
```


```dart
  47:     _todos[todoIndex] = todo.markIncomplete();
```


## File: lib/user.dart

### Coverage: 53.8%

### Uncovered Lines:

```dart
  17:   User copyWith({String? id, String? name}) {
  18:     return User(id: id ?? this.id, name: name ?? this.name);
```


```dart
  32:   @override
```


```dart
  34:     return Object.hash(id, name);
```


```dart
  37:   @override
```


```dart
  39:     return 'User(id: $id, name: $name)';
```