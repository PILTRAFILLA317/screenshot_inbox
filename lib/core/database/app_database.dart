import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('ScreenshotRow')
@TableIndex(name: 'screenshots_asset_id_idx', columns: {#assetId}, unique: true)
@TableIndex(
  name: 'screenshots_lifecycle_idx',
  columns: {#currentLifecycleState},
)
@TableIndex(name: 'screenshots_created_at_idx', columns: {#createdAt})
class Screenshots extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get indexedAt => dateTime()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get processingStatus => text()();
  TextColumn get ocrText => text().nullable()();
  TextColumn get primaryType => text().nullable()();
  TextColumn get primarySubtype => text().nullable()();
  RealColumn get classificationConfidence => real().nullable()();
  TextColumn get currentLifecycleState => text()();
  DateTimeColumn get lastProcessedAt => dateTime().nullable()();
  IntColumn get processingVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntityRow')
@TableIndex(name: 'entities_screenshot_idx', columns: {#screenshotId})
@TableIndex(name: 'entities_type_idx', columns: {#type})
class Entities extends Table {
  TextColumn get id => text()();
  TextColumn get screenshotId =>
      text().references(Screenshots, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get rawValue => text()();
  TextColumn get normalizedValue => text()();
  RealColumn get confidence => real()();
  TextColumn get metadataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExtractedObjectRow')
@TableIndex(name: 'objects_screenshot_idx', columns: {#screenshotId})
@TableIndex(name: 'objects_type_subtype_idx', columns: {#type, #subtype})
class ExtractedObjects extends Table {
  TextColumn get id => text()();
  TextColumn get screenshotId =>
      text().references(Screenshots, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get subtype => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get structuredDataJson => text()();
  RealColumn get confidence => real()();
  BoolColumn get saved => boolean().withDefault(const Constant(false))();
  BoolColumn get handled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SuggestedActionRow')
@TableIndex(
  name: 'actions_screenshot_status_idx',
  columns: {#screenshotId, #status},
)
@TableIndex(name: 'actions_object_idx', columns: {#extractedObjectId})
class SuggestedActions extends Table {
  TextColumn get id => text()();
  TextColumn get screenshotId =>
      text().references(Screenshots, #id, onDelete: KeyAction.cascade)();
  TextColumn get extractedObjectId => text().nullable().references(
    ExtractedObjects,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  RealColumn get confidence => real()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LifecycleEventRow')
@TableIndex(
  name: 'lifecycle_screenshot_time_idx',
  columns: {#screenshotId, #timestamp},
)
@TableIndex(name: 'lifecycle_type_idx', columns: {#type})
class LifecycleEvents extends Table {
  TextColumn get id => text()();
  TextColumn get screenshotId =>
      text().references(Screenshots, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get reason => text()();
  TextColumn get metadataJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProcessingRecordRow')
@TableIndex(name: 'processing_fast_state_idx', columns: {#fastState})
@TableIndex(
  name: 'processing_deep_state_priority_idx',
  columns: {#deepState, #aiPriority},
)
class ProcessingRecords extends Table {
  TextColumn get screenshotId =>
      text().references(Screenshots, #id, onDelete: KeyAction.cascade)();
  TextColumn get assetFingerprint => text()();
  TextColumn get fastState => text()();
  TextColumn get deepState => text()();
  TextColumn get fastFingerprint => text().nullable()();
  TextColumn get deepFingerprint => text().nullable()();
  TextColumn get fastPayloadJson => text().nullable()();
  RealColumn get aiPriority => real().withDefault(const Constant(0))();
  TextColumn get aiEligibilityReasonsJson => text()();
  TextColumn get fastTimingsJson => text()();
  TextColumn get deepTimingsJson => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {screenshotId};
}

@DriftDatabase(
  tables: [
    Screenshots,
    Entities,
    ExtractedObjects,
    SuggestedActions,
    LifecycleEvents,
    ProcessingRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'screenshot_inbox'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(screenshots, screenshots.processingVersion);
      }
      if (from < 3) {
        await migrator.createTable(processingRecords);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
