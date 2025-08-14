import 'dart:io';

/// Type alias for coverage data structure.
///
/// Maps file paths to their coverage information including:
/// - `total`: Total number of lines
/// - `covered`: Number of covered lines
/// - `uncoveredLines`: List of uncovered line numbers
typedef _CoverageData = Map<String, Map<String, dynamic>>;

/// Configuration class for the LCOV reporter.
///
/// Defines all the settings and options for generating coverage reports.
///
/// Example:
/// ```dart
/// final config = ReporterConfig(
///   inputPath: 'coverage/lcov.info',
///   outputPath: 'coverage_report.md',
///   excludePattern: '**/test/**',
///   uncoveredOnly: true,
///   failUnder: 80.0,
///   summary: false,
/// );
/// ```
class ReporterConfig {
  /// Creates a new reporter configuration.
  ///
  /// All parameters are optional and have sensible defaults.
  const ReporterConfig({
    this.inputPath = 'coverage/lcov.info',
    this.outputPath,
    this.excludePattern,
    this.uncoveredOnly = false,
    this.failUnder,
    this.summary = false,
  });

  /// Path to the input LCOV file.
  ///
  /// Defaults to `coverage/lcov.info`.
  final String inputPath;

  /// Path to save the output report.
  ///
  /// If `null`, the report will be printed to stdout.
  final String? outputPath;

  /// Glob pattern to exclude files from the report.
  ///
  /// Supports wildcards like `*` and `?`. Examples:
  /// - `**/test/**` - Exclude all files in test directories
  /// - `**/*_test.dart` - Exclude all test files
  /// - `**/generated/**` - Exclude generated code
  final String? excludePattern;

  /// Whether to show only files with uncovered lines.
  ///
  /// When `true`, fully covered files are filtered out of the report.
  final bool uncoveredOnly;

  /// Minimum coverage threshold percentage.
  ///
  /// If specified and the total coverage falls below this threshold,
  /// the program will exit with code 1. Useful for CI/CD pipelines.
  ///
  /// Must be between 0.0 and 100.0.
  final double? failUnder;

  /// Whether to output summary with individual file coverage.
  ///
  /// When `true`, shows individual file coverage percentages and total
  /// instead of the full detailed report.
  final bool summary;
}

/// Main entry point for the LCOV reporter.
///
/// Generates a coverage report based on the provided [config].
/// If no configuration is provided, uses default settings.
///
/// The process includes:
/// 1. Reading coverage data from the input LCOV file
/// 2. Applying filters (exclude patterns, uncovered-only)
/// 3. Generating the markdown report
/// 4. Outputting to file or stdout
/// 5. Checking coverage thresholds and exiting with appropriate code
///
/// Example:
/// ```dart
/// // Use default configuration
/// await run();
///
/// // Use custom configuration
/// final config = ReporterConfig(
///   inputPath: 'my_coverage.info',
///   outputPath: 'report.md',
///   failUnder: 80.0,
/// );
/// await run(config);
/// ```
///
/// Throws [Exception] if the input file doesn't exist or is malformed.
/// Exits with code 1 if coverage is below the threshold specified in [config].
Future<void> run([ReporterConfig? config]) async {
  final cfg = config ?? const ReporterConfig();

  final coverageData = await _readCoverageData(cfg.inputPath);
  final filteredData = _applyFilters(coverageData, cfg);
  final report = await _generateMarkdownReport(filteredData, cfg);

  await _outputReport(report, cfg);

  // Check coverage threshold and exit if needed
  if (cfg.failUnder != null) {
    final totalCoverage = _calculateTotalCoverageValue(filteredData);
    if (totalCoverage < cfg.failUnder!) {
      stderr.writeln(
        'Coverage ${totalCoverage.toStringAsFixed(1)}% is below threshold '
        '${cfg.failUnder}%',
      );
      exit(1);
    }
  }
}

/// Reads and parses an LCOV file to extract coverage data.
///
/// Parses the LCOV format file at [inputPath] and extracts:
/// - File paths (SF: lines)
/// - Line coverage data (DA: lines)
/// - Total and covered line counts
/// - Lists of uncovered line numbers
///
/// Returns a map where keys are file paths and values contain coverage
/// metadata.
///
/// Throws [Exception] and exits with code 1 if the input file doesn't exist.
///
/// Example LCOV format:
/// ```text
/// SF:/path/to/file.dart
/// DA:1,1
/// DA:2,0
/// DA:3,1
/// end_of_record
/// ```
Future<_CoverageData> _readCoverageData(String inputPath) async {
  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'Error: $inputPath not found. Run tests with coverage first.',
    );
    exit(1);
  }

  final content = await file.readAsLines();
  final results = <String, Map<String, dynamic>>{};
  String? currentFile;

  for (final line in content) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      results[currentFile] = {
        'total': 0,
        'covered': 0,
        'uncoveredLines': <int>[],
      };
    } else if (line.startsWith('DA:') && currentFile != null) {
      _processDataLine(line, currentFile, results);
    }
  }

  return results;
}

/// Processes a single DA (data) line from an LCOV file.
///
/// Parses DA lines which contain line-by-line coverage information:
/// - [line]: The DA line in format "DA:line_number,hit_count"
/// - [currentFile]: The current file being processed
/// - [results]: The coverage data structure to update
///
/// Updates the total line count, covered line count, and uncovered lines list
/// for the current file in the results map.
///
/// Example: "DA:42,3" means line 42 was hit 3 times (covered).
///          "DA:43,0" means line 43 was never hit (uncovered).
void _processDataLine(String line, String currentFile, _CoverageData results) {
  final parts = line.substring(3).split(',');
  final lineNumber = int.parse(parts[0]);
  final hitCount = int.parse(parts[1]);

  results[currentFile]!['total'] = (results[currentFile]!['total'] as int) + 1;

  if (hitCount > 0) {
    results[currentFile]!['covered'] =
        (results[currentFile]!['covered'] as int) + 1;
  } else {
    (results[currentFile]!['uncoveredLines'] as List<int>).add(lineNumber);
  }
}

/// Converts an absolute file path to a relative path.
///
/// Takes an [absolutePath] and makes it relative to the current working
/// directory. This creates cleaner, more readable paths in the output report.
///
/// Returns the relative path with forward slashes for cross-platform
/// compatibility.
///
/// Example:
/// ```dart
/// // If current directory is /home/user/project
/// _makeRelativePath('/home/user/project/lib/main.dart')
/// // Returns: 'lib/main.dart'
/// ```
String _makeRelativePath(String absolutePath) {
  final currentDir = Directory.current.path;
  var relativePath = absolutePath;

  if (relativePath.startsWith(currentDir)) {
    relativePath = relativePath.substring(currentDir.length + 1);
  }

  return relativePath.replaceAll(r'\', '/');
}

/// Formats coverage data as a percentage string.
///
/// Calculates the percentage of [covered] lines out of [total] lines
/// and formats it to one decimal place with a % sign.
///
/// Returns 'N/A' if [total] is 0 to avoid division by zero.
///
/// Example:
/// ```dart
/// _formatPercentage(85, 100)  // Returns: '85.0%'
/// _formatPercentage(0, 0)     // Returns: 'N/A'
/// ```
String _formatPercentage(int covered, int total) {
  if (total == 0) return 'N/A';
  return '${(covered / total * 100).toStringAsFixed(1)}%';
}

/// Checks if all files in the coverage data are fully covered.
///
/// Returns `true` if every file has 100% line coverage (no uncovered lines).
/// This is used to display a special "CODE FULLY COVERED!" message.
///
/// [coverageData]: The coverage data map to check.
bool _areAllFilesCovered(_CoverageData coverageData) {
  return !coverageData.values.any(
    (file) => (file['uncoveredLines'] as List<int>).isNotEmpty,
  );
}

/// Calculates the total coverage percentage across all files.
///
/// Aggregates coverage data from all files to compute an overall percentage.
/// This provides a project-wide coverage metric.
///
/// [coverageData]: Map of file paths to their coverage information.
///
/// Returns the total coverage as a formatted percentage string (e.g., "85.3%").
String _calculateTotalCoverage(_CoverageData coverageData) {
  var totalLines = 0;
  var totalCovered = 0;

  for (final fileData in coverageData.values) {
    totalLines += fileData['total'] as int;
    totalCovered += fileData['covered'] as int;
  }

  return _formatPercentage(totalCovered, totalLines);
}

/// Calculates the total coverage percentage as a numeric value.
///
/// Similar to [_calculateTotalCoverage] but returns a raw double value
/// instead of a formatted string. This is used for threshold comparisons.
///
/// [coverageData]: Map of file paths to their coverage information.
///
/// Returns the total coverage as a percentage (0.0 to 100.0).
/// Returns 0.0 if there are no lines to cover.
double _calculateTotalCoverageValue(_CoverageData coverageData) {
  var totalLines = 0;
  var totalCovered = 0;

  for (final fileData in coverageData.values) {
    totalLines += fileData['total'] as int;
    totalCovered += fileData['covered'] as int;
  }

  if (totalLines == 0) return 0;
  return (totalCovered / totalLines) * 100;
}

/// Applies filters to coverage data based on configuration.
///
/// Processes the raw coverage data and applies the following filters:
/// - **Exclude patterns**: Removes files matching the glob pattern
/// - **Uncovered only**: Removes files with 100% coverage
///
/// [coverageData]: The raw coverage data to filter.
/// [config]: Configuration containing filter settings.
///
/// Returns a new filtered coverage data map.
///
/// Example:
/// ```dart
/// final config = ReporterConfig(
///   excludePattern: '**/test/**',
///   uncoveredOnly: true,
/// );
/// final filtered = _applyFilters(rawData, config);
/// ```
_CoverageData _applyFilters(_CoverageData coverageData, ReporterConfig config) {
  final filtered = <String, Map<String, dynamic>>{};

  for (final entry in coverageData.entries) {
    final filePath = entry.key;
    final fileData = entry.value;
    final uncoveredLines = fileData['uncoveredLines'] as List<int>;

    // Apply exclude pattern filter
    if (config.excludePattern != null &&
        _matchesPattern(filePath, config.excludePattern!)) {
      continue;
    }

    // Apply uncovered-only filter
    if (config.uncoveredOnly && uncoveredLines.isEmpty) {
      continue;
    }

    filtered[filePath] = fileData;
  }

  return filtered;
}

/// Simple glob pattern matching for file exclusion.
///
/// Converts a glob-style [pattern] to a regular expression and tests it
/// against the given file [path]. Supports common wildcards:
/// - `*` matches any characters
/// - `?` matches a single character
/// - `/` is escaped for path matching
///
/// If the pattern is invalid regex, falls back to literal string matching.
///
/// [path]: File path to test against the pattern.
/// [pattern]: Glob pattern (e.g., "**/test/**", "*.generated.dart").
///
/// Returns `true` if the path matches the pattern.
///
/// Example:
/// ```dart
/// _matchesPattern('lib/test/helper.dart', '**/test/**')  // true
/// _matchesPattern('lib/main.dart', '**/test/**')        // false
/// ```
bool _matchesPattern(String path, String pattern) {
  // Convert simple glob pattern to regex
  final regexPattern = pattern
      .replaceAll('*', '.*')
      .replaceAll('?', '.')
      .replaceAll('/', r'\/');

  try {
    final regex = RegExp(regexPattern);
    return regex.hasMatch(path);
  } on Object catch (_) {
    // If pattern is invalid, treat as literal string match
    return path.contains(pattern);
  }
}

/// Outputs the generated report to file or stdout.
///
/// If [ReporterConfig.outputPath] is specified, writes the [report] to that
/// file,
/// creating parent directories as needed. Otherwise, prints to stdout.
///
/// Shows a confirmation message when writing to file (unless in summary mode).
///
/// [report]: The generated markdown report content.
/// [config]: Configuration containing output settings.
///
/// Throws [Exception] if file writing fails.
Future<void> _outputReport(String report, ReporterConfig config) async {
  if (config.outputPath != null) {
    final file = File(config.outputPath!);
    await file.parent.create(recursive: true);
    
    // Add a newline to the end of the report
    await file.writeAsString('$report\n');
    if (!config.summary) {
      print('Report written to ${config.outputPath}');
    }
  } else {
    print(report);
  }
}

/// Groups consecutive line numbers into separate code blocks.
///
/// Takes a list of uncovered [lineNumbers] and groups consecutive numbers
/// together. This creates cleaner code blocks in the output instead of
/// showing each line individually.
///
/// [lineNumbers]: List of uncovered line numbers (must be sorted).
///
/// Returns a list of groups, where each group contains consecutive line
/// numbers.
///
/// Example:
/// ```dart
/// _groupConsecutiveLines([1, 2, 3, 7, 8, 12])
/// // Returns: [[1, 2, 3], [7, 8], [12]]
/// ```
List<List<int>> _groupConsecutiveLines(List<int> lineNumbers) {
  if (lineNumbers.isEmpty) return [];

  final lineGroups = <List<int>>[];
  var currentGroup = <int>[];

  for (final lineNum in lineNumbers) {
    if (currentGroup.isEmpty || lineNum == currentGroup.last + 1) {
      currentGroup.add(lineNum);
    } else {
      lineGroups.add(List.from(currentGroup));
      currentGroup = [lineNum];
    }
  }

  if (currentGroup.isNotEmpty) {
    lineGroups.add(currentGroup);
  }

  return lineGroups;
}

/// Detects the programming language from a file extension.
///
/// Maps common file extensions to their corresponding language identifiers
/// for syntax highlighting in markdown code blocks.
///
/// [filePath]: Path to the file (only the extension is used).
///
/// Returns the language identifier for markdown syntax highlighting.
/// Returns 'text' for unknown extensions.
///
/// Supported languages include: dart, javascript, typescript, python, java,
/// kotlin, swift, c/c++, go, rust, php, ruby, and many others.
///
/// Example:
/// ```dart
/// _detectLanguageFromExtension('lib/main.dart')     // Returns: 'dart'
/// _detectLanguageFromExtension('src/app.ts')        // Returns: 'typescript'
/// _detectLanguageFromExtension('unknown.xyz')       // Returns: 'text'
/// ```
String _detectLanguageFromExtension(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();

  const extensionToLanguage = {
    'dart': 'dart',
    'js': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'jsx': 'javascript',
    'py': 'python',
    'java': 'java',
    'kt': 'kotlin',
    'swift': 'swift',
    'cpp': 'cpp',
    'cc': 'cpp',
    'cxx': 'cpp',
    'c': 'c',
    'h': 'c',
    'hpp': 'cpp',
    'cs': 'csharp',
    'go': 'go',
    'rs': 'rust',
    'php': 'php',
    'rb': 'ruby',
    'scala': 'scala',
    'sh': 'bash',
    'bash': 'bash',
    'zsh': 'bash',
    'ps1': 'powershell',
    'sql': 'sql',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'sass': 'sass',
    'less': 'less',
    'xml': 'xml',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'toml': 'toml',
    'md': 'markdown',
    'dockerfile': 'dockerfile',
  };

  return extensionToLanguage[extension] ?? 'text';
}

/// Generates a markdown code block for a group of uncovered lines.
///
/// Reads the source file and extracts the specified lines to create
/// a formatted code block with line numbers and syntax highlighting.
///
/// [lineNumbers]: List of line numbers to include in the code block.
/// [filePath]: Path to the source file to read from.
///
/// Returns a markdown code block string with proper syntax highlighting.
/// Shows "[Line not found]" for invalid line numbers.
///
/// Example output:
/// ```dart
///   42: if (condition) {
///   43:   return null;
///   44: }
/// ```
Future<String> _generateCodeBlock(
  List<int> lineNumbers,
  String filePath,
) async {
  final sourceFile = File(filePath);
  var sourceLines = <String>[];

  if (sourceFile.existsSync()) {
    sourceLines = await sourceFile.readAsLines();
  }

  final codeLines = lineNumbers
      .map((lineNum) {
        if (lineNum - 1 < sourceLines.length && lineNum > 0) {
          final code = sourceLines[lineNum - 1];
          return '${lineNum.toString().padLeft(4)}: $code';
        }
        return '${lineNum.toString().padLeft(4)}: [Line not found]';
      })
      .join('\n');

  final language = _detectLanguageFromExtension(filePath);
  return '```$language\n$codeLines\n```\n';
}

/// Generates the complete markdown coverage report.
///
/// Creates either a detailed markdown report or a summary based on the
/// configuration. The report includes:
/// - Overall coverage percentage
/// - Per-file coverage details (unless in summary mode)
/// - Code blocks showing uncovered lines with syntax highlighting
/// - Special message for 100% coverage
///
/// [coverageData]: Filtered coverage data to report on.
/// [config]: Configuration controlling report format and content.
///
/// Returns the complete markdown report as a string.
///
/// In summary mode, returns individual file coverage percentages and total.
/// In normal mode, returns a detailed report with uncovered code blocks for
/// each file.
Future<String> _generateMarkdownReport(
  _CoverageData coverageData,
  ReporterConfig config,
) async {
  final md = StringBuffer();

  // Calculate total coverage across all files
  final totalCoverage = _calculateTotalCoverage(coverageData);

  if (config.summary) {
    // Summary mode: show individual file coverage and total
    for (final entry in coverageData.entries) {
      final fileData = entry.value;

      final total = fileData['total'] as int;
      final covered = fileData['covered'] as int;

      // If the file is fully covered, skip it
      if (covered == total) continue;

      final relativePath = _makeRelativePath(entry.key);
      final coverage = _formatPercentage(covered, total);
      md.writeln("File '$relativePath' coverage: $coverage");
    }
    md.writeln('Total Coverage: $totalCoverage');
    return md.toString();
  }

  md
    ..writeln('# LCOV Reporter\n')
    ..writeln('## Total Coverage: $totalCoverage\n');

  if (_areAllFilesCovered(coverageData)) {
    md.writeln('CODE FULLY COVERED!');
    return md.toString();
  }

  for (final entry in coverageData.entries) {
    final fileData = entry.value;
    final total = fileData['total'] as int;
    final covered = fileData['covered'] as int;
    final uncoveredLines = fileData['uncoveredLines'] as List<int>;

    // Skip fully covered files
    if (uncoveredLines.isEmpty) continue;

    final relativePath = _makeRelativePath(entry.key);
    md
      ..writeln('## File: $relativePath\n')
      ..writeln('### Coverage: ${_formatPercentage(covered, total)}\n')
      ..writeln('### Uncovered Lines:\n');

    final lineGroups = _groupConsecutiveLines(uncoveredLines);

    for (final group in lineGroups) {
      final codeBlock = await _generateCodeBlock(group, entry.key);
      md
        ..write(codeBlock)
        ..writeln('\n');
    }
  }

  return md.toString().trimRight();
}
