import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:screenshot_inbox/core/database/app_database.dart';
import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart'
    as domain;
import 'package:screenshot_inbox/domain/actions/suggested_action_repository.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart' as domain;
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart'
    as domain;
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart' as domain;
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart' as domain;
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';

final class DriftScreenshotRepository implements ScreenshotRepository {
  DriftScreenshotRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(domain.Screenshot screenshot) =>
      _saveScreenshot(_db, screenshot);

  @override
  Future<domain.Screenshot?> findById(String id) async {
    final row = await (_db.select(
      _db.screenshots,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _screenshotFromRow(row);
  }

  @override
  Future<domain.Screenshot?> findByAssetId(String assetId) async {
    final row = await (_db.select(
      _db.screenshots,
    )..where((table) => table.assetId.equals(assetId))).getSingleOrNull();
    return row == null ? null : _screenshotFromRow(row);
  }

  @override
  Stream<List<domain.Screenshot>> watchRecent({int limit = 20}) {
    final query = _db.select(_db.screenshots)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
      ..limit(limit);
    return query.watch().map(
      (rows) => rows.map(_screenshotFromRow).toList(growable: false),
    );
  }

  @override
  Future<int> countByLifecycleStates(Set<domain.LifecycleState> states) async {
    if (states.isEmpty) return 0;
    final count = _db.screenshots.id.count();
    final query = _db.selectOnly(_db.screenshots)
      ..addColumns([count])
      ..where(
        _db.screenshots.currentLifecycleState.isIn(
          states.map((state) => state.name),
        ),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }
}

final class DriftEntityRepository implements EntityRepository {
  DriftEntityRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<domain.ExtractedEntity> entities,
  ) => _db.transaction(() => _replaceEntities(_db, screenshotId, entities));

  @override
  Future<List<domain.ExtractedEntity>> findForScreenshot(
    String screenshotId,
  ) async {
    final rows = await (_db.select(
      _db.entities,
    )..where((table) => table.screenshotId.equals(screenshotId))).get();
    return rows
        .map(
          (row) => domain.ExtractedEntity(
            id: row.id,
            screenshotId: row.screenshotId,
            type: domain.EntityType(row.type),
            rawValue: row.rawValue,
            normalizedValue: row.normalizedValue,
            confidence: row.confidence,
            metadata: _decodeJson(row.metadataJson),
          ),
        )
        .toList(growable: false);
  }
}

final class DriftExtractedObjectRepository
    implements ExtractedObjectRepository {
  DriftExtractedObjectRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<domain.ExtractedObject> objects,
  ) => _db.transaction(() => _replaceObjects(_db, screenshotId, objects));

  @override
  Future<List<domain.ExtractedObject>> findForScreenshot(
    String screenshotId,
  ) async {
    final rows = await (_db.select(
      _db.extractedObjects,
    )..where((table) => table.screenshotId.equals(screenshotId))).get();
    return rows
        .map(
          (row) => domain.ExtractedObject(
            id: row.id,
            screenshotId: row.screenshotId,
            type: domain.ExtractedObjectType(row.type),
            subtype: row.subtype,
            title: row.title,
            subtitle: row.subtitle,
            structuredData: _decodeJson(row.structuredDataJson),
            confidence: row.confidence,
            saved: row.saved,
            handled: row.handled,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }
}

final class DriftSuggestedActionRepository
    implements SuggestedActionRepository {
  DriftSuggestedActionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<domain.SuggestedAction> actions,
  ) => _db.transaction(() => _replaceActions(_db, screenshotId, actions));

  @override
  Future<List<domain.SuggestedAction>> findForScreenshot(
    String screenshotId,
  ) async {
    final rows = await (_db.select(
      _db.suggestedActions,
    )..where((table) => table.screenshotId.equals(screenshotId))).get();
    return rows
        .map(
          (row) => domain.SuggestedAction(
            id: row.id,
            screenshotId: row.screenshotId,
            extractedObjectId: row.extractedObjectId,
            type: domain.SuggestedActionType(row.type),
            payload: _decodeJson(row.payloadJson),
            confidence: row.confidence,
            status: domain.SuggestedActionStatus.values.byName(row.status),
            createdAt: row.createdAt,
            completedAt: row.completedAt,
            dismissedAt: row.dismissedAt,
          ),
        )
        .toList(growable: false);
  }
}

final class DriftLifecycleEventRepository implements LifecycleEventRepository {
  DriftLifecycleEventRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> appendAll(List<domain.LifecycleEvent> events) =>
      _appendLifecycleEvents(_db, events);

  @override
  Future<List<domain.LifecycleEvent>> findForScreenshot(
    String screenshotId,
  ) async {
    final query = _db.select(_db.lifecycleEvents)
      ..where((table) => table.screenshotId.equals(screenshotId))
      ..orderBy([(table) => OrderingTerm.asc(table.timestamp)]);
    final rows = await query.get();
    return rows
        .map(
          (row) => domain.LifecycleEvent(
            id: row.id,
            screenshotId: row.screenshotId,
            type: domain.LifecycleEventType(row.type),
            timestamp: row.timestamp,
            reason: row.reason,
            metadata: _decodeJson(row.metadataJson),
          ),
        )
        .toList(growable: false);
  }
}

final class DriftProcessingStore implements ProcessingStore {
  DriftProcessingStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> markProcessing(domain.Screenshot screenshot, DateTime at) =>
      _saveScreenshot(
        _db,
        screenshot.copyWith(
          processingStatus: domain.ScreenshotProcessingStatus.processing,
          lastProcessedAt: at,
        ),
      );

  @override
  Future<void> persist(ProcessingResult result) => _db.transaction(() async {
    await _saveScreenshot(_db, result.screenshot);
    await _replaceEntities(_db, result.screenshot.id, result.entities);
    await _replaceObjects(_db, result.screenshot.id, result.objects);
    await _replaceActions(_db, result.screenshot.id, result.actions);
    await _appendLifecycleEvents(_db, result.lifecycleEvents);
  });

  @override
  Future<void> markFailed(
    domain.Screenshot screenshot,
    DateTime at,
    Object error,
  ) => _saveScreenshot(
    _db,
    screenshot.copyWith(
      processingStatus: domain.ScreenshotProcessingStatus.failed,
      lastProcessedAt: at,
    ),
  );
}

Future<void> _saveScreenshot(AppDatabase db, domain.Screenshot screenshot) => db
    .into(db.screenshots)
    .insertOnConflictUpdate(
      ScreenshotsCompanion.insert(
        id: screenshot.id,
        assetId: screenshot.assetId,
        createdAt: screenshot.createdAt,
        indexedAt: screenshot.indexedAt,
        width: screenshot.width,
        height: screenshot.height,
        sizeBytes: Value(screenshot.sizeBytes),
        processingStatus: screenshot.processingStatus.name,
        ocrText: Value(screenshot.ocrText),
        primaryType: Value(screenshot.primaryType?.value),
        primarySubtype: Value(screenshot.primarySubtype),
        classificationConfidence: Value(screenshot.classificationConfidence),
        currentLifecycleState: screenshot.currentLifecycleState.name,
        lastProcessedAt: Value(screenshot.lastProcessedAt),
        processingVersion: Value(screenshot.processingVersion),
      ),
    );

Future<void> _replaceEntities(
  AppDatabase db,
  String screenshotId,
  List<domain.ExtractedEntity> entities,
) async {
  await (db.delete(
    db.entities,
  )..where((table) => table.screenshotId.equals(screenshotId))).go();
  await db.batch((batch) {
    batch.insertAll(db.entities, [
      for (final entity in entities)
        EntitiesCompanion.insert(
          id: entity.id,
          screenshotId: entity.screenshotId,
          type: entity.type.value,
          rawValue: entity.rawValue,
          normalizedValue: entity.normalizedValue,
          confidence: entity.confidence,
          metadataJson: jsonEncode(entity.metadata),
        ),
    ]);
  });
}

Future<void> _replaceObjects(
  AppDatabase db,
  String screenshotId,
  List<domain.ExtractedObject> objects,
) async {
  await (db.delete(
    db.extractedObjects,
  )..where((table) => table.screenshotId.equals(screenshotId))).go();
  await db.batch((batch) {
    batch.insertAll(db.extractedObjects, [
      for (final object in objects)
        ExtractedObjectsCompanion.insert(
          id: object.id,
          screenshotId: object.screenshotId,
          type: object.type.value,
          subtype: object.subtype,
          title: object.title,
          subtitle: Value(object.subtitle),
          structuredDataJson: jsonEncode(object.structuredData),
          confidence: object.confidence,
          saved: Value(object.saved),
          handled: Value(object.handled),
          createdAt: object.createdAt,
          updatedAt: object.updatedAt,
        ),
    ]);
  });
}

Future<void> _replaceActions(
  AppDatabase db,
  String screenshotId,
  List<domain.SuggestedAction> actions,
) async {
  await (db.delete(
    db.suggestedActions,
  )..where((table) => table.screenshotId.equals(screenshotId))).go();
  await db.batch((batch) {
    batch.insertAll(db.suggestedActions, [
      for (final action in actions)
        SuggestedActionsCompanion.insert(
          id: action.id,
          screenshotId: action.screenshotId,
          extractedObjectId: Value(action.extractedObjectId),
          type: action.type.value,
          payloadJson: jsonEncode(action.payload),
          confidence: action.confidence,
          status: action.status.name,
          createdAt: action.createdAt,
          completedAt: Value(action.completedAt),
          dismissedAt: Value(action.dismissedAt),
        ),
    ]);
  });
}

Future<void> _appendLifecycleEvents(
  AppDatabase db,
  List<domain.LifecycleEvent> events,
) async {
  await db.batch((batch) {
    batch.insertAll(db.lifecycleEvents, [
      for (final event in events)
        LifecycleEventsCompanion.insert(
          id: event.id,
          screenshotId: event.screenshotId,
          type: event.type.value,
          timestamp: event.timestamp,
          reason: event.reason,
          metadataJson: jsonEncode(event.metadata),
        ),
    ], mode: InsertMode.insertOrIgnore);
  });
}

domain.Screenshot _screenshotFromRow(ScreenshotRow row) => domain.Screenshot(
  id: row.id,
  assetId: row.assetId,
  createdAt: row.createdAt,
  indexedAt: row.indexedAt,
  width: row.width,
  height: row.height,
  sizeBytes: row.sizeBytes,
  processingStatus: domain.ScreenshotProcessingStatus.values.byName(
    row.processingStatus,
  ),
  ocrText: row.ocrText,
  primaryType: row.primaryType == null
      ? null
      : ScreenshotType(row.primaryType!),
  primarySubtype: row.primarySubtype,
  classificationConfidence: row.classificationConfidence,
  currentLifecycleState: domain.LifecycleState.values.byName(
    row.currentLifecycleState,
  ),
  lastProcessedAt: row.lastProcessedAt,
  processingVersion: row.processingVersion,
);

JsonMap _decodeJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return decoded;
}
