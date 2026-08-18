import 'package:flutter/foundation.dart';
import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';

final class DebugFixtureSeeder {
  DebugFixtureSeeder(this._store, this._clock, this._ids);

  final ProcessingStore _store;
  final Clock _clock;
  final IdGenerator _ids;

  Future<void> seed() async {
    if (!kDebugMode) {
      throw StateError('Debug fixtures are disabled in release builds.');
    }
    final now = _clock.now();
    await _seedOne(
      id: 'debug-actionable',
      assetId: 'debug://actionable',
      title: 'Dinner at La Viña',
      type: ExtractedObjectType.place,
      subtype: 'place.restaurant',
      state: LifecycleState.actionable,
      actionType: SuggestedActionType.maps,
      now: now,
    );
    await _seedOne(
      id: 'debug-expiring',
      assetId: 'debug://expiring',
      title: '20% summer coupon',
      type: ExtractedObjectType.coupon,
      subtype: 'coupon.discount',
      state: LifecycleState.expiring,
      actionType: SuggestedActionType.copy,
      now: now.subtract(const Duration(minutes: 1)),
      structuredData: {
        'couponCode': 'SUMMER20',
        'expiresAt': now.add(const Duration(days: 2)).toIso8601String(),
      },
    );
    await _seedOne(
      id: 'debug-cleanup',
      assetId: 'debug://cleanup',
      title: 'Delivered package',
      type: ExtractedObjectType.order,
      subtype: 'order.package',
      state: LifecycleState.cleanupCandidate,
      actionType: SuggestedActionType.deleteScreenshot,
      now: now.subtract(const Duration(minutes: 2)),
    );
  }

  Future<void> _seedOne({
    required String id,
    required String assetId,
    required String title,
    required ExtractedObjectType type,
    required String subtype,
    required LifecycleState state,
    required SuggestedActionType actionType,
    required DateTime now,
    Map<String, Object?> structuredData = const {},
  }) async {
    final objectId = '$id-object';
    final screenshot = Screenshot(
      id: id,
      assetId: assetId,
      createdAt: now,
      indexedAt: now,
      width: 1179,
      height: 2556,
      processingStatus: ScreenshotProcessingStatus.processed,
      ocrText: title,
      primaryType: ScreenshotType(type.value),
      primarySubtype: subtype,
      classificationConfidence: 0.95,
      currentLifecycleState: state,
      lastProcessedAt: now,
      processingVersion: 1,
    );
    final object = ExtractedObject(
      id: objectId,
      screenshotId: id,
      type: type,
      subtype: subtype,
      title: title,
      structuredData: structuredData,
      confidence: 0.95,
      saved: false,
      handled: false,
      createdAt: now,
      updatedAt: now,
    );
    await _store.persist(
      ProcessingResult(
        screenshot: screenshot,
        entities: const [],
        objects: [object],
        actions: [
          SuggestedAction(
            id: '$id-action',
            screenshotId: id,
            extractedObjectId: objectId,
            type: actionType,
            payload: {'fixture': true},
            confidence: 0.95,
            status: SuggestedActionStatus.suggested,
            createdAt: now,
          ),
        ],
        lifecycleEvents: [
          LifecycleEvent(
            id: _ids.next(),
            screenshotId: id,
            type: LifecycleEventType.understood,
            timestamp: now,
            reason: 'Loaded from a debug-only fixture.',
          ),
        ],
      ),
    );
  }
}
