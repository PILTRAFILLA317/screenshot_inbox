import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';

final class FixedClock implements Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class SequenceIdGenerator implements IdGenerator {
  int _value = 0;

  @override
  String next() => 'id-${_value++}';
}

Screenshot screenshotFixture({
  String id = 'screenshot-1',
  String assetId = 'asset-1',
  LifecycleState lifecycleState = LifecycleState.newItem,
  ScreenshotProcessingStatus status = ScreenshotProcessingStatus.discovered,
}) {
  final createdAt = DateTime.utc(2026, 8, 18, 12);
  return Screenshot(
    id: id,
    assetId: assetId,
    createdAt: createdAt,
    indexedAt: createdAt,
    width: 1179,
    height: 2556,
    processingStatus: status,
    currentLifecycleState: lifecycleState,
    processingVersion: 1,
  );
}

ExtractedObject objectFixture({
  String id = 'object-1',
  String screenshotId = 'screenshot-1',
  ExtractedObjectType type = ExtractedObjectType.coupon,
  String subtype = 'coupon.discount',
  Map<String, Object?> structuredData = const {},
}) {
  final createdAt = DateTime.utc(2026, 8, 18, 12);
  return ExtractedObject(
    id: id,
    screenshotId: screenshotId,
    type: type,
    subtype: subtype,
    title: 'Fixture object',
    structuredData: structuredData,
    confidence: 0.9,
    saved: false,
    handled: false,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

const eventClassification = ScreenshotType('event');
