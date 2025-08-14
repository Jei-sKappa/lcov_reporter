import 'dart:io';
import 'package:args/args.dart';
import 'package:buggy/buggy.dart' as buggy;

/// Current version of the Buggy tool.
const String version = '1.0.0';

/// Builds and configures the main command line argument parser.
///
/// Creates a command-based CLI structure with:
/// - Global flags (help, version, verbose)
/// - Subcommands for different functionalities
///
/// Returns a configured [ArgParser] instance ready to parse arguments.
ArgParser buildParser() {
  final parser = ArgParser()
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
    ..addCommand('report', _buildReportParser());

  return parser;
}

/// Builds the argument parser for the 'report' command.
///
/// Defines all available options for generating coverage reports:
/// - Input/output file paths
/// - Filtering options (exclude patterns, uncovered-only, line filtering)
/// - Coverage thresholds and summary mode
///
/// Returns a configured [ArgParser] instance for the report command.
ArgParser _buildReportParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print help for the report command.',
    )
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Input LCOV file path (default: coverage/lcov.info)',
      defaultsTo: 'coverage/lcov.info',
    )
    ..addOption('output', abbr: 'o', help: 'Output file path (default: stdout)')
    ..addOption(
      'exclude',
      abbr: 'e',
      help: 'Exclude files matching pattern (glob)',
    )
    ..addOption(
      'fail-under',
      abbr: 'f',
      help: 'Exit with error if coverage below threshold (percentage)',
    )
    ..addFlag(
      'summary',
      abbr: 's',
      negatable: false,
      help: 'Show summary with individual file coverage',
    )
    ..addFlag(
      'uncovered-only',
      negatable: false,
      help: 'Show only files with uncovered lines',
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
/// Shows the command syntax and all available commands with their descriptions.
///
/// [argParser]: The configured argument parser to extract usage from.
void printUsage(ArgParser argParser) {
  print('Usage: buggy <command> [arguments]');
  print('');
  print('Global options:');
  print(argParser.usage);
  print('');
  print('Available commands:');
  print('  report    Generate coverage report from LCOV file');
  print('');
  print('Run "buggy <command> --help" for more information about a command.');
}

/// Prints usage information for the report command.
///
/// Shows the report command syntax and all available options.
///
/// [reportParser]: The configured report argument parser.
void printReportUsage(ArgParser reportParser) {
  print('Usage: buggy report [options]');
  print('');
  print('Generate a coverage report from LCOV file.');
  print('');
  print('Options:');
  print(reportParser.usage);
}

/// Prints the current version of the Buggy tool.
void printVersion() {
  print('buggy version: $version');
}

/// Handles the 'report' command execution.
///
/// Parses the report command arguments and executes coverage report generation.
/// This function contains all the logic that was previously in the main
/// function.
///
/// [arguments]: Arguments for the report command.
/// [verbose]: Whether verbose output is enabled.
Future<void> _handleReportCommand(List<String> arguments, bool verbose) async {
  final reportParser = _buildReportParser();

  try {
    final results = reportParser.parse(arguments);

    // Handle report-specific help
    if (results.flag('help')) {
      printReportUsage(reportParser);
      return;
    }

    if (verbose) {
      print('[VERBOSE] Report arguments: $arguments');
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
    final config = buggy.BuggyConfig(
      inputPath: results.option('input')!,
      outputPath: results.option('output'),
      excludePattern: results.option('exclude'),
      uncoveredOnly: results.flag('uncovered-only'),
      failUnder: failUnder,
      summary: results.flag('summary'),
      noFilter: results.flag('no-filter'),
    );

    await buggy.run(config);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    print('');
    printReportUsage(reportParser);
    exit(1);
  }
}

/// Main entry point for the Buggy command line tool.
///
/// Parses command line arguments and executes the appropriate command.
/// Uses a strict command-based architecture with the following structure:
/// - Global flags: help, version, verbose
/// - Commands: report (generate coverage reports)
///
/// [arguments]: Command line arguments to parse.
///
/// Exits with code 0 on success, or code 1 if:
/// - Invalid arguments are provided
/// - Unknown command is specified
/// - Coverage falls below the specified threshold
/// - Input file doesn't exist or other errors occur
///
/// Example usage:
/// ```bash
/// buggy report --input coverage/lcov.info --output report.md
/// buggy report --exclude "**/test/**" --fail-under 80
/// buggy report --summary --uncovered-only
/// buggy --version
/// ```
Future<void> main(List<String> arguments) async {
  final argParser = buildParser();

  try {
    final results = argParser.parse(arguments);
    var verbose = false;

    // Handle global flags
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

    // Check if a command was provided
    if (results.command == null) {
      if (arguments.isNotEmpty && !arguments.first.startsWith('-')) {
        stderr.writeln('Error: Unknown command "${arguments.first}"');
        print('');
        printUsage(argParser);
        exit(1);
      } else {
        // No arguments at all
        printUsage(argParser);
        return;
      }
    }

    // Handle commands
    switch (results.command!.name) {
      case 'report':
        await _handleReportCommand(results.command!.arguments, verbose);
      default:
        stderr.writeln('Error: Unknown command "${results.command!.name}"');
        printUsage(argParser);
        exit(1);
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    print('');
    printUsage(argParser);
    exit(1);
  }
}
