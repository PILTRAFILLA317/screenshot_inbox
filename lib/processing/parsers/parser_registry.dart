import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class ParserRegistry {
  ParserRegistry(List<ScreenshotParser> parsers)
    : parsers = List.unmodifiable(
        [...parsers]..sort((a, b) => b.priority.compareTo(a.priority)),
      );

  final List<ScreenshotParser> parsers;

  ScreenshotParser? resolve(ProcessingContext context) {
    final type = context.classification?.type;
    if (type == null) return null;

    for (final parser in parsers) {
      if (parser.supportedTypes.contains(type) && parser.canParse(context)) {
        return parser;
      }
    }
    return null;
  }

  Future<ParseResult> parse(ProcessingContext context) async {
    final parser = resolve(context);
    return parser == null ? const ParseResult.empty() : parser.parse(context);
  }
}
