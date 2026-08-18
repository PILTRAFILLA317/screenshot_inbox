import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';

void main() {
  test('selects the highest-priority parser that can parse the type', () {
    final low = _Parser('low', priority: 10);
    final unavailable = _Parser(
      'unavailable',
      priority: 100,
      isAvailable: false,
    );
    final high = _Parser('high', priority: 50);
    final registry = ParserRegistry([low, unavailable, high]);

    expect(registry.resolve(_context()), same(high));
  });

  test('returns null when no parser supports the classification', () {
    final registry = ParserRegistry([
      _Parser('coupon', supportedTypes: {ScreenshotType.coupon}),
    ]);

    expect(registry.resolve(_context()), isNull);
  });
}

ProcessingContext _context() => ProcessingContext(
  screenshot: screenshotFixture(),
  imageBytes: Uint8List.fromList([1]),
  classification: const ClassificationResult(
    type: ScreenshotType.event,
    confidence: 1,
  ),
);

final class _Parser implements ScreenshotParser {
  _Parser(
    this.id, {
    this.priority = 0,
    this.isAvailable = true,
    Set<ScreenshotType>? supportedTypes,
  }) : supportedTypes = supportedTypes ?? {ScreenshotType.event};

  @override
  final String id;
  @override
  final int priority;
  final bool isAvailable;
  @override
  final Set<ScreenshotType> supportedTypes;

  @override
  bool canParse(ProcessingContext context) => isAvailable;

  @override
  Future<ParseResult> parse(ProcessingContext context) async =>
      const ParseResult.empty();
}
