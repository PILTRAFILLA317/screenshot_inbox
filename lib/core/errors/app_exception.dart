sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class ScreenshotProcessingException extends AppException {
  const ScreenshotProcessingException(super.message, [super.cause]);
}
