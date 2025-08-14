import 'dart:io';

typedef _CoverageData = Map<String, Map<String, dynamic>>;

/// Entry point for the application.
Future<void> run() async {
  final coverageData = await _readCoverageData();
  final report = await _generateMarkdownReport(coverageData);
  print(report);
}

/// Reads and parses the lcov.info file to extract coverage data
Future<_CoverageData> _readCoverageData() async {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'Error: coverage/lcov.info not found. Run tests with coverage first.',
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

/// Processes a single DA (data) line from the lcov file
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

/// Converts an absolute file path to a relative path
String _makeRelativePath(String absolutePath) {
  final currentDir = Directory.current.path;
  var relativePath = absolutePath;

  if (relativePath.startsWith(currentDir)) {
    relativePath = relativePath.substring(currentDir.length + 1);
  }

  return relativePath.replaceAll(r'\', '/');
}

/// Formats coverage percentage as a string
String _formatPercentage(int covered, int total) {
  if (total == 0) return 'N/A';
  return '${(covered / total * 100).toStringAsFixed(1)}%';
}

/// Checks if all files in the coverage data are fully covered
bool _areAllFilesCovered(_CoverageData coverageData) {
  return !coverageData.values.any(
    (file) => (file['uncoveredLines'] as List<int>).isNotEmpty,
  );
}

/// Calculates the total coverage percentage across all files
String _calculateTotalCoverage(_CoverageData coverageData) {
  var totalLines = 0;
  var totalCovered = 0;

  for (final fileData in coverageData.values) {
    totalLines += fileData['total'] as int;
    totalCovered += fileData['covered'] as int;
  }

  return _formatPercentage(totalCovered, totalLines);
}

/// Groups consecutive line numbers into separate lists
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

/// Detects the programming language from file extension
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

/// Generates a code block for a group of line numbers
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

/// Generates the complete markdown report from coverage data
Future<String> _generateMarkdownReport(_CoverageData coverageData) async {
  final md = StringBuffer()..writeln('# LCOV Reporter\n');

  // Calculate total coverage across all files
  final totalCoverage = _calculateTotalCoverage(coverageData);
  md.writeln('## Total Coverage: $totalCoverage\n');

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
