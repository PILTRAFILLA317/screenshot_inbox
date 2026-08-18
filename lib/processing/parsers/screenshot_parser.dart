import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class ParseResult {
  const ParseResult({required this.objects});

  const ParseResult.empty() : objects = const [];

  final List<ExtractedObject> objects;
}

abstract interface class ScreenshotParser {
  String get id;

  Set<ScreenshotType> get supportedTypes;

  int get priority;

  bool canParse(ProcessingContext context);

  Future<ParseResult> parse(ProcessingContext context);
}
