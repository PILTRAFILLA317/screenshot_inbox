import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

abstract interface class EntityExtractor {
  Future<List<ExtractedEntity>> extract(ProcessingContext context);
}

final class RegexEntityExtractor implements EntityExtractor {
  RegexEntityExtractor(this._ids);

  final IdGenerator _ids;

  static final _patterns = <EntityType, RegExp>{
    EntityType.url: RegExp(r'https?://[^\s]+', caseSensitive: false),
    EntityType.email: RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ),
    EntityType.percentage: RegExp(r'\b\d{1,3}(?:[.,]\d+)?\s?%'),
    EntityType.money: RegExp(
      r'(?:[$€£]\s?\d+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?\s?(?:EUR|USD|GBP))',
      caseSensitive: false,
    ),
    EntityType.date: RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
  };

  @override
  Future<List<ExtractedEntity>> extract(ProcessingContext context) async {
    final entities = <ExtractedEntity>[];
    for (final entry in _patterns.entries) {
      for (final match in entry.value.allMatches(context.ocrText)) {
        final value = match.group(0)!;
        entities.add(
          ExtractedEntity(
            id: _ids.next(),
            screenshotId: context.screenshot.id,
            type: entry.key,
            rawValue: value,
            normalizedValue: value.trim(),
            confidence: 0.85,
          ),
        );
      }
    }
    for (final barcode in context.barcodes) {
      entities.add(
        ExtractedEntity(
          id: _ids.next(),
          screenshotId: context.screenshot.id,
          type: EntityType.qr,
          rawValue: barcode.rawValue,
          normalizedValue: barcode.rawValue.trim(),
          confidence: 0.98,
          metadata: {'format': barcode.format},
        ),
      );
    }
    return entities;
  }
}
