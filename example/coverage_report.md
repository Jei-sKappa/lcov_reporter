# LCOV Reporter

## Total Coverage: 45.1%

## File: lib/example.dart

### Coverage: 66.3%

### Uncovered Lines:

```dart
  28:       print('Error running example: $e');
```


```dart
 142:   Future<void> demonstrateErrorHandling() async {
 143:     print('\n=== Error Handling Examples ===\n');
```


```dart
 147:       await _todoService.getTodo('nonexistent');
 148:     } on TodoNotFoundException catch (e) {
 149:       print('Caught expected exception: $e');
```


```dart
 154:       await _todoService.createTodo(title: '', description: '');
 155:     } on InvalidTodoException catch (e) {
 156:       print('Caught validation error: $e');
```


```dart
 161:       await _todoService.completeTodo('nonexistent');
 162:     } on TodoNotFoundException catch (e) {
 163:       print('Caught expected exception: $e');
```


```dart
 168:   Future<void> demonstrateBulkOperations() async {
 169:     print('\n=== Bulk Operations Example ===\n');
```


```dart
 171:     final todos = await _todoService.getAllTodos();
```


```dart
 173:         .where((todo) => !todo.isCompleted)
 174:         .map((todo) => todo.id)
 175:         .take(2)
 176:         .toList();
```


```dart
 178:     if (pendingIds.isNotEmpty) {
 179:       print('Bulk completing ${pendingIds.length} todos...');
 180:       final completed = await _todoService.bulkCompleteTodos(pendingIds);
 181:       print('Successfully completed ${completed.length} todos');
```


```dart
 186:   Future<void> cleanup() async {
 187:     print('\nCleaning up example data...');
 188:     await _todoService.bulkDeleteTodos(
 189:       (await _todoService.getAllTodos()).map((t) => t.id).toList(),
```


```dart
 191:     print('Cleanup complete.');
```


## File: lib/exceptions.dart

### Coverage: 21.2%

### Uncovered Lines:

```dart
   8:   @override
```


```dart
  10:     if (code != null) {
  11:       return 'TodoException [$code]: $message';
```


```dart
  13:     return 'TodoException: $message';
```


```dart
  30:   @override
```


```dart
  32:     return 'InvalidTodoException: ${validationErrors.join(', ')}';
```


```dart
  38:   const DuplicateTodoException(this.todoId)
  39:     : super('Todo with id "$todoId" already exists', code: 'DUPLICATE_TODO');
```


```dart
  46:     : super(code: 'STORAGE_ERROR');
```


```dart
  49:   factory StorageException.readFailure([Object? cause]) {
  50:     return StorageException('Failed to read from storage', cause: cause);
```


```dart
  54:   factory StorageException.writeFailure([Object? cause]) {
  55:     return StorageException('Failed to write to storage', cause: cause);
```


```dart
  59:   factory StorageException.corruption([Object? cause]) {
  60:     return StorageException('Storage data is corrupted', cause: cause);
```


```dart
  66:   const NetworkException(super.message, {this.statusCode, super.cause})
  67:     : super(code: 'NETWORK_ERROR');
```


```dart
  70:   factory NetworkException.connectionFailed([Object? cause]) {
  71:     return NetworkException('Failed to connect to server', cause: cause);
```


```dart
  75:   factory NetworkException.timeout([Object? cause]) {
  76:     return NetworkException('Network request timed out', cause: cause);
```


```dart
  80:   factory NetworkException.serverError(int statusCode, [Object? cause]) {
  81:     return NetworkException(
```


```dart
  89:   @override
```


```dart
  91:     if (statusCode != null) {
  92:       return 'NetworkException [$statusCode]: $message';
```


```dart
  94:     return super.toString();
```


```dart
 101:     : super(
```


```dart
 119:       case DuplicateTodoException():
```


```dart
 121:       case StorageException():
```


```dart
 123:       case NetworkException():
```


```dart
 125:       case InvalidStateException():
```


```dart
 133:   static void logException(Exception exception, StackTrace? stackTrace) {
```


```dart
 135:     print('Exception logged: $exception');
```


```dart
 137:       print('Stack trace: $stackTrace');
```


```dart
 142:   static bool isRecoverable(Exception exception) {
```


```dart
 145:       case final NetworkException ex:
 146:         return ex.statusCode != 404 && ex.statusCode != 403;
 147:       case StorageException():
```


```dart
 149:       case TodoNotFoundException():
```


```dart
 151:       case InvalidTodoException():
```


## File: lib/todo.dart

### Coverage: 55.4%

### Uncovered Lines:

```dart
  25:           ? DateTime.parse(json['completedAt'] as String)
```


```dart
  29:         orElse: () => Priority.medium,
```


```dart
  71:   Todo markIncomplete() {
  72:     if (!isCompleted) {
  73:       throw StateError('Todo is already incomplete');
```


```dart
  75:     return copyWith(isCompleted: false, completedAt: null);
```


```dart
 101:   String get statusText {
 102:     if (isCompleted) {
```


```dart
 105:       switch (priority) {
 106:         case Priority.high:
```


```dart
 108:         case Priority.medium:
```


```dart
 110:         case Priority.low:
```


```dart
 117:   bool get isOverdue {
```


```dart
 121:       return DateTime.now().difference(createdAt).inDays > 30;
```


```dart
 127:   @override
```


```dart
 130:     return other is Todo &&
 131:         other.id == id &&
 132:         other.title == title &&
 133:         other.description == description &&
 134:         other.isCompleted == isCompleted &&
 135:         other.createdAt == createdAt &&
 136:         other.completedAt == completedAt &&
 137:         other.priority == priority;
```


```dart
 140:   @override
```


```dart
 142:     return Object.hash(
 143:       id,
 144:       title,
 145:       description,
 146:       isCompleted,
 147:       createdAt,
 148:       completedAt,
 149:       priority,
```


```dart
 153:   @override
```


```dart
 155:     return 'Todo(id: $id,'
 156:         ' title: $title, '
 157:         'isCompleted: $isCompleted, '
 158:         'priority: $priority)';
```


## File: lib/todo_repository.dart

### Coverage: 45.2%

### Uncovered Lines:

```dart
  49:       final content = await file.readAsString();
  50:       if (content.trim().isEmpty) {
  51:         _cache = [];
```


```dart
  55:       final jsonList = jsonDecode(content) as List<dynamic>;
  56:       _cache = jsonList
  57:           .map((json) => Todo.fromJson(json as Map<String, dynamic>))
  58:           .toList();
```


```dart
  60:       throw StorageException.readFailure(e);
```


```dart
  76:       throw StorageException.writeFailure(e);
```


```dart
 129:   @override
```


```dart
 131:     _cache = [];
 132:     await _saveCache();
```


```dart
 148:   Future<List<Todo>> getByDateRange(DateTime start, DateTime end) async {
 149:     await _loadCache();
 150:     return _cache!.where((todo) {
 151:       return todo.createdAt.isAfter(start) && todo.createdAt.isBefore(end);
 152:     }).toList();
```


```dart
 166:   Future<void> archiveCompleted() async {
 167:     await _loadCache();
```


```dart
 170:     final completed = _cache!.where((todo) => todo.isCompleted).toList();
 171:     if (completed.isEmpty) {
```


```dart
 176:     final archiveFile = File(
 177:       'archive_${DateTime.now().millisecondsSinceEpoch}.json',
```


```dart
 179:     final archiveContent = jsonEncode(
 180:       completed.map((t) => t.toJson()).toList(),
```


```dart
 182:     await archiveFile.writeAsString(archiveContent);
```


```dart
 185:     _cache!.removeWhere((todo) => todo.isCompleted);
 186:     await _saveCache();
```


```dart
 190:   Future<bool> validateFileIntegrity() async {
```


```dart
 192:       final file = File(_filePath);
 193:       if (!file.existsSync()) return true;
```


```dart
 195:       final content = await file.readAsString();
 196:       if (content.trim().isEmpty) return true;
```


```dart
 199:       final json = jsonDecode(content);
 200:       if (json is! List) return false;
```


```dart
 202:       for (final item in json) {
 203:         if (item is! Map<String, dynamic>) return false;
 204:         if (!item.containsKey('id') || !item.containsKey('title')) {
```


```dart
 216:   Future<void> backup() async {
 217:     await _loadCache();
```


```dart
 220:     final backupPath = '$_filePath.backup';
 221:     final backupFile = File(backupPath);
```


```dart
 223:     if (_cache!.isNotEmpty) {
 224:       final jsonList = _cache!.map((todo) => todo.toJson()).toList();
 225:       final content = jsonEncode(jsonList);
 226:       await backupFile.writeAsString(content);
```


```dart
 231:   Future<void> restoreFromBackup() async {
 232:     final backupPath = '$_filePath.backup';
 233:     final backupFile = File(backupPath);
```


```dart
 235:     if (!backupFile.existsSync()) {
```


```dart
 240:       final content = await backupFile.readAsString();
 241:       final jsonList = jsonDecode(content) as List<dynamic>;
 242:       _cache = jsonList
 243:           .map((json) => Todo.fromJson(json as Map<String, dynamic>))
 244:           .toList();
 245:       await _saveCache();
```


```dart
 247:       throw StorageException.corruption(e);
```


## File: lib/todo_service.dart

### Coverage: 37.9%

### Uncovered Lines:

```dart
  28:       errors.add('Description cannot be empty');
```


```dart
  31:       errors.add('Title cannot exceed 100 characters');
```


```dart
  34:       errors.add('Description cannot exceed 500 characters');
```


```dart
  47:       throw DuplicateTodoException(id);
```


```dart
  74:       throw TodoNotFoundException(id);
```


```dart
  80:       errors.add('Title cannot be empty');
```


```dart
  82:     if (description != null && description.trim().isEmpty) {
  83:       errors.add('Description cannot be empty');
```


```dart
  86:       errors.add('Title cannot exceed 100 characters');
```


```dart
  88:     if (description != null && description.length > 500) {
  89:       errors.add('Description cannot exceed 500 characters');
```


```dart
  93:       throw InvalidTodoException(errors);
```


```dart
  98:       description: description?.trim(),
```


```dart
 127:   Future<Todo> uncompleteTodo(String id) async {
 128:     _log('Uncompleting todo: $id');
```


```dart
 130:     final existing = await _repository.getById(id);
```


```dart
 132:       throw TodoNotFoundException(id);
```


```dart
 135:     if (!existing.isCompleted) {
```


```dart
 139:     final uncompleted = existing.markIncomplete();
 140:     await _repository.save(uncompleted);
 141:     _log('Todo uncompleted successfully: ${uncompleted.id}');
```


```dart
 146:   Future<void> deleteTodo(String id) async {
 147:     _log('Deleting todo: $id');
```


```dart
 150:     final existing = await _repository.getById(id);
```


```dart
 152:       throw TodoNotFoundException(id);
```


```dart
 155:     await _repository.delete(id);
 156:     _log('Todo deleted successfully: $id');
```


```dart
 178:   Future<List<Todo>> getTodosByStatus(bool isCompleted) async {
 179:     _log('Fetching todos by status: $isCompleted');
 180:     return _repository.getByStatus(isCompleted);
```


```dart
 190:   Future<List<Todo>> getTodosSortedByDate({bool ascending = true}) async {
 191:     _log('Fetching todos sorted by date: ascending=$ascending');
```


```dart
 193:     final todos = await _repository.getAll();
 194:     todos.sort((a, b) {
 195:       final comparison = a.createdAt.compareTo(b.createdAt);
 196:       return ascending ? comparison : -comparison;
```


```dart
 203:   Future<List<Todo>> getTodosSortedByPriority({bool ascending = false}) async {
 204:     _log('Fetching todos sorted by priority: ascending=$ascending');
```


```dart
 206:     final todos = await _repository.getAll();
 207:     todos.sort((a, b) {
 208:       final comparison = a.priority.sortValue.compareTo(b.priority.sortValue);
 209:       return ascending ? comparison : -comparison;
```


```dart
 228:     final allTodos = await _repository.getAll();
 229:     final term = searchTerm.toLowerCase();
 230:     return allTodos.where((todo) {
 231:       return todo.title.toLowerCase().contains(term) ||
 232:           todo.description.toLowerCase().contains(term);
 233:     }).toList();
```


```dart
 261:   Future<List<Todo>> bulkCompleteTodos(List<String> ids) async {
 262:     _log('Bulk completing ${ids.length} todos');
```


```dart
 264:     final results = <Todo>[];
 265:     final errors = <String>[];
```


```dart
 267:     for (final id in ids) {
```


```dart
 269:         final completed = await completeTodo(id);
 270:         results.add(completed);
```


```dart
 272:         errors.add('Failed to complete todo $id: $e');
```


```dart
 276:     if (errors.isNotEmpty && results.isEmpty) {
```


```dart
 278:       throw InvalidTodoException(errors);
```


```dart
 287:   Future<void> bulkDeleteTodos(List<String> ids) async {
 288:     _log('Bulk deleting ${ids.length} todos');
```


```dart
 290:     final errors = <String>[];
```


```dart
 292:     for (final id in ids) {
```


```dart
 294:         await deleteTodo(id);
```


```dart
 296:         errors.add('Failed to delete todo $id: $e');
```


```dart
 300:     if (errors.isNotEmpty) {
 301:       throw InvalidTodoException(errors);
```


```dart
 306:   Future<int> archiveCompletedTodos() async {
 307:     _log('Archiving completed todos');
```


```dart
 310:     final completed = await getTodosByStatus(true);
 311:     if (completed.isEmpty) {
```


```dart
 316:     for (final todo in completed) {
 317:       await _repository.delete(todo.id);
```


```dart
 320:     return completed.length;
```


```dart
 324:   Future<List<String>> validateAllTodos() async {
 325:     _log('Validating all todos');
```


```dart
 327:     final todos = await _repository.getAll();
 328:     final invalidTodos = <String>[];
```


```dart
 331:     for (final todo in todos) {
 332:       if (!todo.isValid()) {
 333:         invalidTodos.add(todo.id);
```


```dart
 341:   Future<String> exportTodos(String format) async {
 342:     final todos = await _repository.getAll();
```


```dart
 345:     switch (format.toLowerCase()) {
 346:       case 'csv':
 347:         return _exportToCsv(todos);
 348:       case 'json':
 349:         return _exportToJson(todos);
 350:       case 'xml':
```


```dart
 352:         return _exportToXml(todos);
```


```dart
 354:         throw InvalidTodoException(['Unsupported export format: $format']);
```


```dart
 376:   String _exportToCsv(List<Todo> todos) {
 377:     final buffer = StringBuffer()
 378:       ..writeln('ID,Title,Description,IsCompleted,CreatedAt,Priority');
```


```dart
 380:     for (final todo in todos) {
 381:       buffer.writeln(
 382:         '${todo.id},'
 383:         '"${todo.title}",'
 384:         '"${todo.description}",'
 385:         '${todo.isCompleted},'
 386:         '${todo.createdAt.toIso8601String()},'
 387:         '${todo.priority.name}',
```


```dart
 391:     return buffer.toString();
```


```dart
 395:   String _exportToJson(List<Todo> todos) {
 396:     final jsonList = todos.map((todo) => todo.toJson()).toList();
 397:     return jsonList.toString();
```


```dart
 401:   String _exportToXml(List<Todo> todos) {
 402:     final buffer = StringBuffer()
 403:       ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
 404:       ..writeln('<todos>');
```


```dart
 406:     for (final todo in todos) {
```


```dart
 408:         ..writeln('  <todo>')
 409:         ..writeln('    <id>${todo.id}</id>')
 410:         ..writeln('    <title>${todo.title}</title>')
 411:         ..writeln('    <description>${todo.description}</description>')
 412:         ..writeln('    <isCompleted>${todo.isCompleted}</isCompleted>')
 413:         ..writeln(
 414:           '    <createdAt>${todo.createdAt.toIso8601String()}</createdAt>',
```


```dart
 416:         ..writeln('    <priority>${todo.priority.name}</priority>')
 417:         ..writeln('  </todo>');
```


```dart
 420:     buffer.writeln('</todos>');
 421:     return buffer.toString();
```