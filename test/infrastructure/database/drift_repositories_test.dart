import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/core/database/app_database.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/infrastructure/database/drift_repositories.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/priority/priority_engine.dart';

import '../../support/fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftScreenshotRepository screenshots;
  late DriftEntityRepository entities;
  late DriftExtractedObjectRepository objects;
  late DriftSuggestedActionRepository actions;
  late DriftLifecycleEventRepository lifecycleEvents;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    screenshots = DriftScreenshotRepository(database);
    entities = DriftEntityRepository(database);
    objects = DriftExtractedObjectRepository(database);
    actions = DriftSuggestedActionRepository(database);
    lifecycleEvents = DriftLifecycleEventRepository(database);
  });

  tearDown(() => database.close());

  test('repositories persist and rehydrate domain models and JSON', () async {
    final screenshot = screenshotFixture();
    final entity = ExtractedEntity(
      id: 'entity-1',
      screenshotId: screenshot.id,
      type: EntityType.couponCode,
      rawValue: 'SAVE20',
      normalizedValue: 'SAVE20',
      confidence: 0.95,
      metadata: const {'source': 'fixture'},
    );
    final object = objectFixture(
      structuredData: const {
        'code': 'SAVE20',
        'nested': {'percent': 20},
      },
    );
    final action = SuggestedAction(
      id: 'action-1',
      screenshotId: screenshot.id,
      extractedObjectId: object.id,
      type: SuggestedActionType.copy,
      payload: const {'value': 'SAVE20'},
      confidence: 0.9,
      status: SuggestedActionStatus.suggested,
      createdAt: screenshot.createdAt,
    );
    final event = LifecycleEvent(
      id: 'event-1',
      screenshotId: screenshot.id,
      type: LifecycleEventType.understood,
      timestamp: screenshot.createdAt,
      reason: 'Fixture processed.',
      metadata: const {'version': 1},
    );

    await screenshots.save(screenshot);
    await entities.replaceForScreenshot(screenshot.id, [entity]);
    await objects.replaceForScreenshot(screenshot.id, [object]);
    await actions.replaceForScreenshot(screenshot.id, [action]);
    await lifecycleEvents.appendAll([event]);

    expect(
      (await screenshots.findByAssetId(screenshot.assetId))?.id,
      screenshot.id,
    );
    expect(
      (await entities.findForScreenshot(screenshot.id))
          .single
          .metadata['source'],
      'fixture',
    );
    expect(
      (await objects.findForScreenshot(screenshot.id))
          .single
          .structuredData['nested'],
      {'percent': 20},
    );
    expect(
      (await actions.findForScreenshot(screenshot.id)).single.payload['value'],
      'SAVE20',
    );
    expect(
      (await lifecycleEvents.findForScreenshot(screenshot.id)).single.reason,
      'Fixture processed.',
    );
  });

  test(
    'processing store persists the complete aggregate transactionally',
    () async {
      final screenshot = screenshotFixture(
        status: ScreenshotProcessingStatus.processed,
        lifecycleState: LifecycleState.actionable,
      );
      final object = objectFixture();
      final store = DriftProcessingStore(database);
      await store.persist(
        ProcessingResult(
          screenshot: screenshot,
          entities: const [],
          objects: [object],
          actions: [
            SuggestedAction(
              id: 'action-1',
              screenshotId: screenshot.id,
              extractedObjectId: object.id,
              type: SuggestedActionType.saveObject,
              payload: const {},
              confidence: 1,
              status: SuggestedActionStatus.suggested,
              createdAt: screenshot.createdAt,
            ),
          ],
          lifecycleEvents: [
            LifecycleEvent(
              id: 'event-1',
              screenshotId: screenshot.id,
              type: LifecycleEventType.becameActionable,
              timestamp: screenshot.createdAt,
              reason: 'Action generated.',
            ),
          ],
        ),
      );

      expect(
        await screenshots.countByLifecycleStates({LifecycleState.actionable}),
        1,
      );
      expect(await objects.findForScreenshot(screenshot.id), hasLength(1));
      expect(await actions.findForScreenshot(screenshot.id), hasLength(1));
      expect(
        await lifecycleEvents.findForScreenshot(screenshot.id),
        hasLength(1),
      );
    },
  );

  test(
    'foreign keys cascade child records when a screenshot is removed',
    () async {
      final screenshot = screenshotFixture();
      await screenshots.save(screenshot);
      await entities.replaceForScreenshot(screenshot.id, [
        ExtractedEntity(
          id: 'entity-1',
          screenshotId: screenshot.id,
          type: EntityType.other,
          rawValue: 'value',
          normalizedValue: 'value',
          confidence: 1,
        ),
      ]);

      await (database.delete(
        database.screenshots,
      )..where((table) => table.id.equals(screenshot.id))).go();

      expect(await entities.findForScreenshot(screenshot.id), isEmpty);
    },
  );

  test('inbox search covers OCR, object data and saved library', () async {
    final screenshot = screenshotFixture(
      status: ScreenshotProcessingStatus.processed,
      lifecycleState: LifecycleState.actionable,
    ).copyWith(ocrText: 'Restaurant in San Sebastián');
    final object = objectFixture(
      type: ExtractedObjectType.place,
      structuredData: const {'name': 'La Viña', 'city': 'San Sebastián'},
    ).copyWith(saved: true, title: 'La Viña');
    await screenshots.save(screenshot);
    await objects.replaceForScreenshot(screenshot.id, [object]);
    final inbox = DriftInboxRepository(database, const PriorityEngine());

    expect(await inbox.find(const InboxQuery.search('viña')), hasLength(1));
    expect(
      await inbox.find(const InboxQuery.search('san sebastián')),
      hasLength(1),
    );
    expect(
      (await inbox.find(const InboxQuery.library())).single.title,
      'La Viña',
    );
  });

  test(
    'reprocessing preserves user-confirmed fields and saved state',
    () async {
      final screenshot = screenshotFixture(
        status: ScreenshotProcessingStatus.processed,
      );
      final store = DriftProcessingStore(database);
      final confirmed = objectFixture(
        type: ExtractedObjectType.place,
        structuredData: const {
          'importantDate': '2026-09-01T09:00:00Z',
          '_userConfirmedFields': ['title', 'type', 'importantDate'],
        },
      ).copyWith(title: 'User title', saved: true);
      await store.persist(
        ProcessingResult(
          screenshot: screenshot,
          entities: const [],
          objects: [confirmed],
          actions: const [],
          lifecycleEvents: const [],
        ),
      );

      final generated = objectFixture(
        id: 'generated-object',
        type: ExtractedObjectType.product,
        structuredData: const {'productName': 'Generated title'},
      ).copyWith(title: 'Generated title');
      await store.persist(
        ProcessingResult(
          screenshot: screenshot,
          entities: const [],
          objects: [generated],
          actions: const [],
          lifecycleEvents: const [],
        ),
      );

      final persisted = (await objects.findForScreenshot(screenshot.id)).single;
      expect(persisted.title, 'User title');
      expect(persisted.type, ExtractedObjectType.place);
      expect(persisted.structuredData['importantDate'], '2026-09-01T09:00:00Z');
      expect(persisted.saved, isTrue);
    },
  );
}
