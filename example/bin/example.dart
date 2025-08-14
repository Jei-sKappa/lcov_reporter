import 'package:example/example.dart';

Future<void> main(List<String> arguments) async {
  final todoExample = TodoExample();

  try {
    // Run the main example
    await todoExample.run();

    // Demonstrate error handling
    await todoExample.demonstrateErrorHandling();

    // Demonstrate bulk operations
    await todoExample.demonstrateBulkOperations();

    // Clean up
    await todoExample.cleanup();

    print('\nExample completed successfully!');
  } on Object catch (e, stackTrace) {
    print('Example failed: $e');
    print('Stack trace: $stackTrace');
  }
}
