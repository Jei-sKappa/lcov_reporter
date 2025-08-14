# LCOV Reporter Example

This example demonstrates the LCOV Reporter tool by implementing a comprehensive Todo management system with intentional coverage gaps.

## What This Example Demonstrates

The example includes:

1. **Multiple Library Files** (4+ files in `lib/`):
   - `todo.dart` - Todo model with serialization, validation, and state management
   - `todo_repository.dart` - File-based data persistence with backup/restore functionality
   - `todo_service.dart` - Business logic layer with CRUD operations and bulk operations
   - `todo_validator.dart` - Comprehensive validation utilities for business rules
   - `exceptions.dart` - Custom exception hierarchy for error handling

2. **Comprehensive Example Usage** (`bin/example.dart`):
   - Creates and manages todos
   - Demonstrates error handling
   - Shows bulk operations
   - Includes cleanup procedures

3. **Intentional Test Coverage Gaps** (`test/example_test.dart`):
   - Tests cover ~60-70% of the code deliberately
   - Many methods and code branches left untested
   - Specific uncovered areas include:
     - Archive and backup functionality
     - XML export functionality
     - Complex validation edge cases
     - Error logging methods
     - Data integrity validation
     - Recovery and restoration methods

## Running the Example

1. **Install dependencies:**
   ```bash
   dart pub get
   ```

2. **Run the example:**
   ```bash
   dart run bin/example.dart
   ```

3. **Run tests with coverage:**
   ```bash
   dart test --coverage=coverage
   dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib
   ```

4. **Generate coverage report:**
   ```bash
   dart run lcov_reporter:lcov_reporter
   ```

## Expected Coverage Report

When you run the LCOV Reporter on this example, you should see output similar to the format shown in the main project, with multiple files having partial coverage and specific uncovered code blocks highlighted.

The uncovered code includes:

- **Exception handling paths** that are difficult to trigger in normal testing
- **Archive and backup methods** that are operational but not tested
- **Complex validation scenarios** with edge cases
- **Export functionality** for formats like XML
- **Data integrity checks** that run in background processes
- **Error logging and monitoring** code paths

This demonstrates how the LCOV Reporter helps identify code that may need additional testing or could potentially be removed if truly unreachable.
