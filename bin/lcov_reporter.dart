import 'dart:io';
import 'package:args/args.dart';
import 'package:lcov_reporter/lcov_reporter.dart' as lcov_reporter;

/// Current version of the LCOV Reporter tool.
const String version = '1.0.0';

/// Builds and configures the command line argument parser.
///
/// Defines all available command line options including:
/// - Help and version flags
/// - Input/output file paths
/// - Filtering options (exclude patterns, uncovered-only, line filtering)
/// - Coverage thresholds and summary mode
///
/// Returns a configured [ArgParser] instance ready to parse arguments.
ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Input LCOV file path (default: coverage/lcov.info)',
      defaultsTo: 'coverage/lcov.info',
    )
    ..addOption('output', abbr: 'o', help: 'Output file path (default: stdout)')
    ..addOption('exclude', help: 'Exclude files matching pattern (glob)')
    ..addFlag(
      'uncovered-only',
      negatable: false,
      help: 'Show only files with uncovered lines',
    )
    ..addOption(
      'fail-under',
      help: 'Exit with error if coverage below threshold (percentage)',
    )
    ..addFlag(
      'summary',
      abbr: 's',
      negatable: false,
      help: 'Show summary with individual file coverage',
    )
    ..addFlag(
      'no-filter',
      negatable: false,
      help:
          'Disable filtering of common useless lines (@override, braces, etc.)',
    );
}

/// Prints usage information for the command line tool.
///
/// Shows the command syntax and all available options with their descriptions.
///
/// [argParser]: The configured argument parser to extract usage from.
void printUsage(ArgParser argParser) {
  print('Usage: dart lcov_reporter.dart <flags> [arguments]');
  print(argParser.usage);
}

/// Prints the current version of the LCOV Reporter tool.
void printVersion() {
  print('lcov_reporter version: $version');
}

/// Main entry point for the LCOV Reporter command line tool.
///
/// Parses command line arguments and executes the coverage report generation.
/// Handles the following options:
/// - `-h, --help`: Show usage information
/// - `--version`: Show version information
/// - `-i, --input`: Input LCOV file path
/// - `-o, --output`: Output file path
/// - `--exclude`: Exclude files matching pattern
/// - `--uncovered-only`: Show only files with uncovered lines
/// - `--fail-under`: Exit with error if coverage below threshold
/// - `-s, --summary`: Show summary with individual file coverage
/// - `--no-filter`: Disable filtering of common useless lines
///
/// [arguments]: Command line arguments to parse.
///
/// Exits with code 0 on success, or code 1 if:
/// - Invalid arguments are provided
/// - Coverage falls below the specified threshold
/// - Input file doesn't exist or other errors occur
///
/// Example usage:
/// ```bash
/// dart run lcov_reporter.dart --input coverage/lcov.info --output report.md
/// dart run lcov_reporter.dart --exclude "**/test/**" --fail-under 80
/// dart run lcov_reporter.dart --summary --uncovered-only
/// dart run lcov_reporter.dart --no-filter --output raw_report.md
/// ```
Future<void> main(List<String> arguments) async {
  final argParser = buildParser();
  try {
    final results = argParser.parse(arguments);
    var verbose = false;

    // Process the parsed arguments.
    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      printVersion();
      return;
    }
    if (results.flag('verbose')) {
      verbose = true;
    }

    if (verbose) {
      print('[VERBOSE] All arguments: ${results.arguments}');
    }

    // Parse fail-under option
    double? failUnder;
    if (results.option('fail-under') != null) {
      try {
        failUnder = double.parse(results.option('fail-under')!);
        if (failUnder < 0 || failUnder > 100) {
          stderr.writeln('Error: fail-under must be between 0 and 100');
          exit(1);
        }
      } on Object catch (_) {
        stderr.writeln('Error: fail-under must be a valid number');
        exit(1);
      }
    }

    // Create configuration
    final config = lcov_reporter.ReporterConfig(
      inputPath: results.option('input')!,
      outputPath: results.option('output'),
      excludePattern: results.option('exclude'),
      uncoveredOnly: results.flag('uncovered-only'),
      failUnder: failUnder,
      summary: results.flag('summary'),
      noFilter: results.flag('no-filter'),
    );

    await lcov_reporter.run(config);
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
