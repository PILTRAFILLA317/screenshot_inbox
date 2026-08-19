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
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart' as domain;
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';
import 'package:screenshot_inbox/processing/performance/processing_metrics.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/priority/priority_engine.dart';

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
  Future<Map<String, domain.Screenshot>> findByAssetIds(
    Iterable<String> assetIds,
  ) async {
    final ids = assetIds.toSet();
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.screenshots,
    )..where((table) => table.assetId.isIn(ids))).get();
    return {for (final row in rows) row.assetId: _screenshotFromRow(row)};
  }

  @override
  Future<List<domain.Screenshot>> findAll() async =>
      (await _db.select(_db.screenshots).get())
          .map(_screenshotFromRow)
          .toList(growable: false);

  @override
  Future<List<domain.Screenshot>> findByProcessingStatuses(
    Set<domain.ScreenshotProcessingStatus> statuses,
  ) async {
    if (statuses.isEmpty) return const [];
    final query = _db.select(_db.screenshots)
      ..where(
        (table) =>
            table.processingStatus.isIn(statuses.map((status) => status.name)),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    return (await query.get()).map(_screenshotFromRow).toList(growable: false);
  }

  @override
  Future<void> setLifecycleState(String id, domain.LifecycleState state) =>
      (_db.update(
        _db.screenshots,
      )..where((table) => table.id.equals(id))).write(
        ScreenshotsCompanion(currentLifecycleState: Value(state.name)),
      );

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
  Future<void> save(domain.ExtractedObject object) => _saveObject(_db, object);

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
    return rows.map(_objectFromRow).toList(growable: false);
  }

  @override
  Future<void> setSaved(String id, bool saved, DateTime at) =>
      (_db.update(
        _db.extractedObjects,
      )..where((table) => table.id.equals(id))).write(
        ExtractedObjectsCompanion(saved: Value(saved), updatedAt: Value(at)),
      );

  @override
  Future<void> setHandled(String id, bool handled, DateTime at) =>
      (_db.update(
        _db.extractedObjects,
      )..where((table) => table.id.equals(id))).write(
        ExtractedObjectsCompanion(
          handled: Value(handled),
          updatedAt: Value(at),
        ),
      );
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
    return rows.map(_actionFromRow).toList(growable: false);
  }

  @override
  Future<void> save(domain.SuggestedAction action) => _saveAction(_db, action);
}

final class DriftInboxRepository implements InboxRepository {
  DriftInboxRepository(this._db, this._priority);

  final AppDatabase _db;
  final PriorityEngine _priority;

  @override
  Stream<List<InboxItem>> watch(InboxQuery query) => _db
      .customSelect(
        'SELECT 1 AS revision',
        readsFrom: {
          _db.screenshots,
          _db.entities,
          _db.extractedObjects,
          _db.suggestedActions,
          _db.lifecycleEvents,
        },
      )
      .watch()
      .asyncMap((_) => find(query));

  @override
  Future<List<InboxItem>> find(InboxQuery query) async {
    final screenshotQuery = _db.select(_db.screenshots);
    if (query.screenshotId != null) {
      screenshotQuery.where((table) => table.id.equals(query.screenshotId!));
    }
    if (query.filter == InboxFilter.cleanup) {
      screenshotQuery.where(
        (table) => table.currentLifecycleState.equals(
          domain.LifecycleState.cleanupCandidate.name,
        ),
      );
    } else if (query.filter != InboxFilter.one &&
        query.filter != InboxFilter.library) {
      screenshotQuery.where(
        (table) => table.currentLifecycleState.isNotIn([
          domain.LifecycleState.deleted.name,
        ]),
      );
    }
    screenshotQuery.orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    if (query.filter == InboxFilter.recent && query.limit != null) {
      screenshotQuery.limit(query.limit!);
    }
    final screenshots = (await screenshotQuery.get())
        .map(_screenshotFromRow)
        .toList(growable: false);
    if (screenshots.isEmpty) return const [];

    final screenshotIds = screenshots.map((item) => item.id).toSet();
    final objectRows = await (_db.select(
      _db.extractedObjects,
    )..where((table) => table.screenshotId.isIn(screenshotIds))).get();
    final actionRows =
        await (_db.select(_db.suggestedActions)
              ..where((table) => table.screenshotId.isIn(screenshotIds))
              ..orderBy([(table) => OrderingTerm.desc(table.confidence)]))
            .get();
    final entityRows = await (_db.select(
      _db.entities,
    )..where((table) => table.screenshotId.isIn(screenshotIds))).get();
    final eventRows =
        await (_db.select(_db.lifecycleEvents)
              ..where((table) => table.screenshotId.isIn(screenshotIds))
              ..orderBy([(table) => OrderingTerm.desc(table.timestamp)]))
            .get();

    final objects = <String, domain.ExtractedObject>{};
    for (final row in objectRows) {
      final value = _objectFromRow(row);
      final current = objects[row.screenshotId];
      if (current == null || value.confidence > current.confidence) {
        objects[row.screenshotId] = value;
      }
    }
    final actions = <String, List<domain.SuggestedAction>>{};
    for (final row in actionRows) {
      actions.putIfAbsent(row.screenshotId, () => []).add(_actionFromRow(row));
    }
    final entities = <String, List<domain.ExtractedEntity>>{};
    for (final row in entityRows) {
      entities.putIfAbsent(row.screenshotId, () => []).add(_entityFromRow(row));
    }
    final reasons = <String, String>{};
    for (final row in eventRows) {
      reasons.putIfAbsent(row.screenshotId, () => row.reason);
    }

    var items = [
      for (final screenshot in screenshots)
        InboxItem(
          screenshot: screenshot,
          object: objects[screenshot.id],
          actions: actions[screenshot.id] ?? const [],
          entities: entities[screenshot.id] ?? const [],
          lifecycleReason: reasons[screenshot.id],
        ),
    ];
    items = switch (query.filter) {
      InboxFilter.needAction =>
        items.where((item) => item.needsAction).toList(),
      InboxFilter.expiring =>
        items
            .where(
              (item) =>
                  item.expiryDate != null &&
                  !item.isHandled &&
                  item.screenshot.currentLifecycleState !=
                      domain.LifecycleState.cleanupCandidate,
            )
            .toList(),
      InboxFilter.library => items.where((item) => item.isSaved).toList(),
      InboxFilter.search => _search(items, query.search ?? ''),
      _ => items,
    };

    final now = DateTime.now().toUtc();
    if (query.filter == InboxFilter.needAction ||
        query.filter == InboxFilter.search) {
      items = _priority.rank(items, now);
    } else if (query.filter == InboxFilter.expiring) {
      items.sort(
        (a, b) => (a.expiryDate ?? DateTime(9999)).compareTo(
          b.expiryDate ?? DateTime(9999),
        ),
      );
    } else if (query.filter == InboxFilter.library) {
      items.sort(
        (a, b) => (b.object?.updatedAt ?? b.screenshot.createdAt).compareTo(
          a.object?.updatedAt ?? a.screenshot.createdAt,
        ),
      );
    }
    if (query.limit case final int limit when items.length > limit) {
      items = items.take(limit).toList(growable: false);
    }
    return items;
  }

  static List<InboxItem> _search(List<InboxItem> items, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return items
        .where((item) {
          final data = [
            item.screenshot.ocrText ?? '',
            item.title,
            item.subtitle ?? '',
            item.object?.structuredData.toString() ?? '',
            ...item.entities.map((entity) => entity.normalizedValue),
          ].join('\n').toLowerCase();
          return data.contains(needle);
        })
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
    final existingRows = await (_db.select(
      _db.extractedObjects,
    )..where((table) => table.screenshotId.equals(result.screenshot.id))).get();
    final objects = _preserveUserConfirmed(
      existingRows.map(_objectFromRow).toList(growable: false),
      result.objects,
    );
    await _saveScreenshot(_db, result.screenshot);
    await _replaceEntities(_db, result.screenshot.id, result.entities);
    await _replaceObjects(_db, result.screenshot.id, objects);
    await _replaceActions(_db, result.screenshot.id, result.actions);
    await _appendLifecycleEvents(_db, result.lifecycleEvents);
  });

  @override
  Future<ProcessingRecord?> findProcessingRecord(String screenshotId) async {
    final row =
        await (_db.select(_db.processingRecords)
              ..where((table) => table.screenshotId.equals(screenshotId)))
            .getSingleOrNull();
    return row == null ? null : _processingRecordFromRow(row);
  }

  @override
  Future<Map<String, ProcessingRecord>> findProcessingRecords(
    Iterable<String> screenshotIds,
  ) async {
    final ids = screenshotIds.toSet();
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.processingRecords,
    )..where((table) => table.screenshotId.isIn(ids))).get();
    return {
      for (final row in rows) row.screenshotId: _processingRecordFromRow(row),
    };
  }

  @override
  Future<void> saveProcessingRecord(ProcessingRecord record) => _db
      .into(_db.processingRecords)
      .insertOnConflictUpdate(_processingRecordCompanion(record));

  @override
  Future<void> persistFastScan(
    FastScanResult result,
    ProcessingRecord record,
  ) => _db.transaction(() async {
    final existingRows = await (_db.select(
      _db.extractedObjects,
    )..where((table) => table.screenshotId.equals(result.screenshot.id))).get();
    final objects = _preserveUserConfirmed(
      existingRows.map(_objectFromRow).toList(growable: false),
      result.deterministic.objects,
    );
    await _saveScreenshot(_db, result.screenshot);
    await _replaceEntities(_db, result.screenshot.id, result.context.entities);
    await _replaceObjects(_db, result.screenshot.id, objects);
    // Provisional deterministic objects must not retain actions from an older
    // deep interpretation.
    await _replaceActions(_db, result.screenshot.id, const []);
    await _db
        .into(_db.processingRecords)
        .insertOnConflictUpdate(_processingRecordCompanion(record));
  });

  @override
  Future<FastScanResult?> loadFastScan(
    domain.Screenshot screenshot,
    ProcessingRecord record,
  ) async {
    final payload = record.fastPayload;
    if (payload == null) return null;
    final entityRows = await (_db.select(
      _db.entities,
    )..where((table) => table.screenshotId.equals(screenshot.id))).get();
    final objectRows = await (_db.select(
      _db.extractedObjects,
    )..where((table) => table.screenshotId.equals(screenshot.id))).get();
    return FastScanResult.fromCache(
      screenshot: screenshot,
      payload: payload,
      entities: entityRows.map(_entityFromRow).toList(growable: false),
      objects: objectRows.map(_objectFromRow).toList(growable: false),
      record: record,
    );
  }

  @override
  Future<ProcessingCacheStats> processingStats() async {
    final rows = await _db.select(_db.processingRecords).get();
    return ProcessingCacheStats(
      total: rows.length,
      fastScanned: rows
          .where((row) => row.fastState == FastScanState.completed.name)
          .length,
      deepAnalyzed: rows
          .where((row) => row.deepState == DeepAnalysisState.completed.name)
          .length,
      queued: rows
          .where(
            (row) =>
                row.deepState == DeepAnalysisState.queued.name ||
                row.fastState == FastScanState.pending.name,
          )
          .length,
      deferred: rows
          .where((row) => row.deepState == DeepAnalysisState.deferred.name)
          .length,
      failed: rows
          .where(
            (row) =>
                row.deepState == DeepAnalysisState.failed.name ||
                row.fastState == FastScanState.failed.name,
          )
          .length,
    );
  }

  @override
  Future<int> clearProcessingCache() async =>
      _db.transaction(() => _db.delete(_db.processingRecords).go());

  @override
  Future<void> clearProcessingCacheFor(String screenshotId) => (_db.delete(
    _db.processingRecords,
  )..where((table) => table.screenshotId.equals(screenshotId))).go();

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

ProcessingRecordsCompanion _processingRecordCompanion(
  ProcessingRecord record,
) => ProcessingRecordsCompanion.insert(
  screenshotId: record.screenshotId,
  assetFingerprint: record.assetFingerprint,
  fastState: record.fastState.name,
  deepState: record.deepState.name,
  fastFingerprint: Value(record.fastFingerprint),
  deepFingerprint: Value(record.deepFingerprint),
  fastPayloadJson: Value(
    record.fastPayload == null ? null : jsonEncode(record.fastPayload),
  ),
  aiPriority: Value(record.aiPriority),
  aiEligibilityReasonsJson: jsonEncode(
    record.aiEligibilityReasons.map((reason) => reason.name).toList(),
  ),
  fastTimingsJson: jsonEncode(record.fastTimings.toJson()),
  deepTimingsJson: jsonEncode(record.deepTimings.toJson()),
  retryCount: Value(record.retryCount),
  nextRetryAt: Value(record.nextRetryAt),
  updatedAt: record.updatedAt,
);

ProcessingRecord _processingRecordFromRow(
  ProcessingRecordRow row,
) => ProcessingRecord(
  screenshotId: row.screenshotId,
  assetFingerprint: row.assetFingerprint,
  fastState: FastScanState.values.byName(row.fastState),
  deepState: DeepAnalysisState.values.byName(row.deepState),
  fastFingerprint: row.fastFingerprint,
  deepFingerprint: row.deepFingerprint,
  fastPayload: row.fastPayloadJson == null
      ? null
      : _decodeJson(row.fastPayloadJson!),
  aiPriority: row.aiPriority,
  aiEligibilityReasons: (jsonDecode(row.aiEligibilityReasonsJson) as List)
      .whereType<String>()
      .map(AIEligibilityReason.values.byName)
      .toList(growable: false),
  fastTimings: ProcessingTimings(values: _decodeIntMap(row.fastTimingsJson)),
  deepTimings: ProcessingTimings(values: _decodeIntMap(row.deepTimingsJson)),
  retryCount: row.retryCount,
  nextRetryAt: row.nextRetryAt,
  updatedAt: row.updatedAt,
);

Map<String, int> _decodeIntMap(String source) {
  final value = jsonDecode(source);
  if (value is! Map) return const {};
  return value.map(
    (key, value) => MapEntry(key.toString(), (value as num).round()),
  );
}

Future<void> _saveObject(AppDatabase db, domain.ExtractedObject object) => db
    .into(db.extractedObjects)
    .insertOnConflictUpdate(
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
    );

Future<void> _saveAction(AppDatabase db, domain.SuggestedAction action) => db
    .into(db.suggestedActions)
    .insertOnConflictUpdate(
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
    );

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

domain.ExtractedEntity _entityFromRow(EntityRow row) => domain.ExtractedEntity(
  id: row.id,
  screenshotId: row.screenshotId,
  type: domain.EntityType(row.type),
  rawValue: row.rawValue,
  normalizedValue: row.normalizedValue,
  confidence: row.confidence,
  metadata: _decodeJson(row.metadataJson),
);

domain.ExtractedObject _objectFromRow(ExtractedObjectRow row) =>
    domain.ExtractedObject(
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
    );

domain.SuggestedAction _actionFromRow(SuggestedActionRow row) =>
    domain.SuggestedAction(
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
    );

List<domain.ExtractedObject> _preserveUserConfirmed(
  List<domain.ExtractedObject> existing,
  List<domain.ExtractedObject> generated,
) {
  if (existing.isEmpty || generated.isEmpty) return generated;
  final old = existing.first;
  final fields = old.structuredData['_userConfirmedFields'];
  final confirmed = fields is List
      ? fields.whereType<String>().toSet()
      : const <String>{};
  if (confirmed.isEmpty && !old.saved && !old.handled) return generated;
  final next = generated.first;
  final data = <String, Object?>{...next.structuredData};
  if (confirmed.contains('importantDate')) {
    data['importantDate'] = old.structuredData['importantDate'];
  }
  data['_userConfirmedFields'] = confirmed.toList(growable: false);
  return [
    next.copyWith(
      type: confirmed.contains('type') ? old.type : next.type,
      title: confirmed.contains('title') ? old.title : next.title,
      structuredData: data,
      saved: old.saved,
      handled: old.handled,
    ),
    ...generated.skip(1),
  ];
}
