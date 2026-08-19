import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class GenericScreenshotParser implements ScreenshotParser {
  GenericScreenshotParser(this._ids, this._clock);

  final IdGenerator _ids;
  final Clock _clock;

  @override
  String get id => 'generic.v1';

  @override
  int get priority => -1000;

  @override
  Set<ScreenshotType> get supportedTypes => {
    ScreenshotType.generic,
    ScreenshotType.event,
    ScreenshotType.coupon,
    ScreenshotType.product,
    ScreenshotType.place,
    ScreenshotType.order,
    ScreenshotType.conversationTask,
    ScreenshotType.conversation,
    ScreenshotType.reference,
    ScreenshotType.other,
  };

  @override
  bool canParse(ProcessingContext context) => context.ocrText.trim().isNotEmpty;

  @override
  Future<ParseResult> parse(ProcessingContext context) async {
    final classification = context.classification!;
    final type = ExtractedObjectType(classification.type.value);
    final firstLine = context.ocrText
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => 'Screenshot');
    final now = _clock.now();
    final structuredData = <String, Object?>{
      'entityIds': context.entities.map((entity) => entity.id).toList(),
    };
    for (final entity in context.entities) {
      structuredData.putIfAbsent(
        entity.type.value,
        () => entity.normalizedValue,
      );
    }
    return ParseResult(
      objects: [
        ExtractedObject(
          id: _ids.next(),
          screenshotId: context.screenshot.id,
          type: type,
          subtype:
              classification.subtype ?? '${classification.type.value}.generic',
          title: firstLine,
          structuredData: structuredData,
          confidence: classification.confidence,
          saved: false,
          handled: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }
}
