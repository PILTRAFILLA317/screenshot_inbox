import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
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
    final type = classification.type == ScreenshotType.other
        ? ExtractedObjectType.other
        : ExtractedObjectType.reference;
    final title = type == ExtractedObjectType.reference
        ? 'Reference'
        : 'Screenshot';
    final now = _clock.now();
    final safeEntities = context.entities.where(
      (entity) =>
          entity.type == EntityType.url ||
          entity.type == EntityType.email ||
          entity.type == EntityType.phone,
    );
    final structuredData = <String, Object?>{
      'entityIds': context.entities.map((entity) => entity.id).toList(),
      '_parserId': id,
      '_fieldMetadata': <String, Object?>{
        for (final entity in safeEntities)
          entity.type.value: {
            'source': 'machineDeterministic',
            'confidence': entity.confidence,
            'confidenceBasis': 'heuristic',
            'evidence': entity.metadata['blockIds'] ?? const <String>[],
          },
      },
      'classificationReasons': classification.reasons,
    };
    for (final entity in safeEntities) {
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
          subtype: '${type.value}.generic',
          title: title,
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
