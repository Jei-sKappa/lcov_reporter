/// Base exception for todo-related errors
abstract class TodoException implements Exception {
  const TodoException(this.message, {this.code, this.cause});
  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() {
    if (code != null) {
      return 'TodoException [$code]: $message';
    }
    return 'TodoException: $message';
  }
}

/// Exception thrown when a todo is not found
class TodoNotFoundException extends TodoException {
  const TodoNotFoundException(this.todoId)
    : super('Todo with id "$todoId" not found', code: 'TODO_NOT_FOUND');
  final String todoId;
}

/// Exception thrown when trying to create a todo with invalid data
class InvalidTodoException extends TodoException {
  const InvalidTodoException(this.validationErrors)
    : super('Invalid todo data', code: 'INVALID_TODO');
  final List<String> validationErrors;

  @override
  String toString() {
    return 'InvalidTodoException: ${validationErrors.join(', ')}';
  }
}

/// Exception thrown when a todo already exists
class DuplicateTodoException extends TodoException {
  const DuplicateTodoException(this.todoId)
    : super('Todo with id "$todoId" already exists', code: 'DUPLICATE_TODO');
  final String todoId;
}

/// Exception thrown when storage operations fail
class StorageException extends TodoException {
  const StorageException(super.message, {super.cause})
    : super(code: 'STORAGE_ERROR');

  /// Creates a storage exception for read failures
  factory StorageException.readFailure([Object? cause]) {
    return StorageException('Failed to read from storage', cause: cause);
  }

  /// Creates a storage exception for write failures
  factory StorageException.writeFailure([Object? cause]) {
    return StorageException('Failed to write to storage', cause: cause);
  }

  /// Creates a storage exception for corruption
  factory StorageException.corruption([Object? cause]) {
    return StorageException('Storage data is corrupted', cause: cause);
  }
}

/// Exception thrown when network operations fail
class NetworkException extends TodoException {
  const NetworkException(super.message, {this.statusCode, super.cause})
    : super(code: 'NETWORK_ERROR');

  /// Creates a network exception for connection failures
  factory NetworkException.connectionFailed([Object? cause]) {
    return NetworkException('Failed to connect to server', cause: cause);
  }

  /// Creates a network exception for timeout
  factory NetworkException.timeout([Object? cause]) {
    return NetworkException('Network request timed out', cause: cause);
  }

  /// Creates a network exception for server errors
  factory NetworkException.serverError(int statusCode, [Object? cause]) {
    return NetworkException(
      'Server error occurred',
      statusCode: statusCode,
      cause: cause,
    );
  }
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return 'NetworkException [$statusCode]: $message';
    }
    return super.toString();
  }
}

/// Exception thrown when operations are attempted on invalid states
class InvalidStateException extends TodoException {
  const InvalidStateException(this.currentState, this.attemptedOperation)
    : super(
        'Cannot perform "$attemptedOperation" operation in state '
        '"$currentState"',
        code: 'INVALID_STATE',
      );
  final String currentState;
  final String attemptedOperation;
}

/// Utility class for exception handling
class ExceptionHandler {
  /// Handles exceptions and returns user-friendly messages
  static String handleException(Exception exception) {
    switch (exception) {
      case TodoNotFoundException():
        return 'The requested todo could not be found.';
      case final InvalidTodoException ex:
        return 'Invalid todo: ${ex.validationErrors.join(', ')}';
      case DuplicateTodoException():
        return 'A todo with this ID already exists.';
      case StorageException():
        return 'There was a problem accessing storage.';
      case NetworkException():
        return 'Network connection failed. Please try again.';
      case InvalidStateException():
        return 'This operation is not allowed at this time.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  /// Logs exceptions (this method will be left uncovered in tests)
  static void logException(Exception exception, StackTrace? stackTrace) {
    // This method is intentionally not covered in tests
    print('Exception logged: $exception');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  /// Determines if an exception is recoverable
  static bool isRecoverable(Exception exception) {
    // Some branches left uncovered for testing
    switch (exception) {
      case final NetworkException ex:
        return ex.statusCode != 404 && ex.statusCode != 403;
      case StorageException():
        return false;
      case TodoNotFoundException():
        return true;
      case InvalidTodoException():
        return true;
      default:
        // This branch will be uncovered
        return false;
    }
  }
}
