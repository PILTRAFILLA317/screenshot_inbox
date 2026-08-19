import 'dart:convert';
import 'dart:developer' as developer;

abstract final class LocalDebugLog {
  static void event(
    String name, {
    Map<String, Object?> metadata = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    const release = bool.fromEnvironment('dart.vm.product');
    if (release) return;
    developer.log(
      jsonEncode({'event': name, ...metadata}),
      name: 'screenshot_inbox.local',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
