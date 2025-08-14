# Buggy 🏴‍☠️

[![Pub Version](https://img.shields.io/pub/v/buggy)](https://pub.dev/packages/buggy)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful Dart tool that generates clean, readable, AI-ready Markdown reports from LCOV coverage files.

Transform messy LCOV output into gorgeous Markdown reports that are perfect for documentation, code reviews, and CI/CD pipelines.

## Features

- 🎯 **Clean Markdown Output**: Beautiful, readable coverage reports
- 🤖 **AI-Ready Format**: Perfect for feeding into AI tools and documentation systems
- 🔍 **Smart Filtering**: Automatically filters out boilerplate code (@override, braces, etc.)
- 🎨 **Syntax Highlighting**: Language-specific code blocks with proper highlighting
- 📊 **Flexible Reporting**: Summary mode, detailed reports, or uncovered-only views
- 🚫 **Pattern Exclusion**: Exclude files using glob patterns (test files, generated code, etc.)
- 📈 **Coverage Thresholds**: Fail builds when coverage drops below specified thresholds
- 🗂️ **Smart Grouping**: Groups consecutive uncovered lines into logical code blocks

## Installation

Install Buggy globally using Dart's package manager:

```bash
dart pub global activate buggy
```

## Usage

After installation, you can run Buggy using:

```bash
buggy <command> [arguments]
```

### `--help`

```bash
Usage: buggy <command> [arguments]

Global options:
-h, --help       Print this usage information.
-v, --verbose    Show additional command output.
    --version    Print the tool version.

Available commands:
  report    Generate coverage report from LCOV file

Run "buggy <command> --help" for more information about a command.
```

## Commands: `report`

### `--help`

```bash
Usage: buggy report [options]

Generate a coverage report from LCOV file.

Options:
-h, --help              Print help for the report command.
-i, --input             Input LCOV file path (default: coverage/lcov.info)
                        (defaults to "coverage/lcov.info")
-o, --output            Output file path (default: stdout)
-e, --exclude           Exclude files matching pattern (glob)
-f, --fail-under        Exit with error if coverage below threshold (percentage)
-s, --summary           Show summary with individual file coverage
    --uncovered-only    Show only files with uncovered lines
    --no-filter         Disable filtering of common useless lines (@override, braces, etc.)
```

### `--input`

Specifies the path to the input LCOV coverage file to process. By default, Buggy looks for `coverage/lcov.info` in the current directory.

```bash
buggy report --input path/to/custom_coverage.info
buggy report -i coverage/different_lcov.info
```

### `--output`

Specifies the file path where the generated coverage report should be saved. If not provided, the report is printed to stdout (console output).

```bash
buggy report --output coverage_report.md
buggy report -o docs/coverage.md
```

### `--exclude`

Excludes files from the coverage report using glob patterns. This is useful for filtering out test files, generated code, or other files you don't want to include in coverage analysis.

```bash
buggy report --exclude "**/test/**"
buggy report -e "**/*.g.dart"
```

Common patterns:
- `**/test/**` - Exclude all files in test directories
- `**/*_test.dart` - Exclude all test files
- `**/*.g.dart` - Exclude generated Dart files
- `**/generated/**` - Exclude generated code directories

### `--fail-under`

Sets a minimum coverage threshold percentage. If the total coverage falls below this threshold, Buggy will exit with code 1, making it perfect for CI/CD pipelines to fail builds with insufficient coverage.

```bash
buggy report --fail-under 80
buggy report -f 95.5
```

Example output when coverage is below threshold:
```bash
Coverage 84.2% is below threshold 100.0%
```

### `--summary`

Generates a concise summary report showing individual file coverage percentages and total coverage instead of the detailed report with code blocks. Perfect for quick coverage overviews or CI/CD pipeline status checks.

```bash
buggy report --summary
buggy report -s
```

Example output:
```
File 'lib/todo_manager.dart' coverage: 72.7%
File 'lib/user.dart' coverage: 53.8%
Total Coverage: 84.2%
```

### `--uncovered-only`

Ignore from coverage report files with 100% coverage.
Note that the files with 100% coverage are always excluded from the report, this command just ignore them from the total coverage percentage.

```bash
buggy report --uncovered-only
```

### `--no-filter`

Disables Buggy's smart filtering of common "useless" lines. By default, Buggy filters out lines like `@override` annotations, standalone braces, and empty lines from uncovered line reports. This flag shows all uncovered lines as-is.

```bash
buggy report --no-filter
```

### Example Workflow

1. Run your tests with coverage:
```bash
dart test --coverage=coverage
```

2. Generate LCOV report:
```bash
dart run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --packages=.dart_tool/package_config.json \
  --report-on=lib
```

3. Generate beautiful Markdown report:
```bash
buggy report
```

#### Output

Buggy generates clean, professional coverage reports like this:

```markdown
# Buggy Report

## Total Coverage: 84.2%

## File: lib/todo_manager.dart

### Coverage: 72.7%

### Uncovered Lines:

​```dart
  40:   bool uncompleteTodo(String id) {
  41:     final todoIndex = _todos.indexWhere((todo) => todo.id == id);
  42:     if (todoIndex == -1) return false;
​```

## File: lib/user.dart

### Coverage: 53.8%

### Uncovered Lines:

​```dart
  17:   User copyWith({String? id, String? name}) {
  18:     return User(id: id ?? this.id, name: name ?? this.name);
​```
```

## Integration

### GitHub Actions

Coming soon...

## Why "Buggy"?

Named after Buggy the Clown from One Piece - just like how Buggy can split apart and reassemble, this tool takes apart your LCOV coverage data and puts it back together in a much more beautiful and useful format! 🏴‍☠️

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
