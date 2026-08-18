import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/core/database/app_database.dart';
import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action_repository.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/infrastructure/database/drift_repositories.dart';
import 'package:screenshot_inbox/infrastructure/calendar/device_calendar_gateway.dart';
import 'package:screenshot_inbox/infrastructure/maps/map_launcher_gateway.dart';
import 'package:screenshot_inbox/infrastructure/mlkit/mlkit_barcode_recognition_service.dart';
import 'package:screenshot_inbox/infrastructure/mlkit/mlkit_text_recognition_service.dart';
import 'package:screenshot_inbox/infrastructure/photos/photo_manager_photo_repository.dart';
import 'package:screenshot_inbox/infrastructure/notifications/local_notification_gateway.dart';
import 'package:screenshot_inbox/infrastructure/url_launcher_gateway.dart';
import 'package:screenshot_inbox/infrastructure/uuid_id_generator.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';
import 'package:screenshot_inbox/processing/actions/default_action_policies.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/screenshot_processing_pipeline.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());
final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidIdGenerator());

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => const PhotoManagerPhotoRepository(),
);

final calendarGatewayProvider = Provider<CalendarGateway>(
  (ref) => DeviceCalendarGateway(),
);
final mapsGatewayProvider = Provider<MapsGateway>(
  (ref) => const MapLauncherGateway(),
);
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => LocalNotificationGateway(),
);
final urlGatewayProvider = Provider<UrlGateway>(
  (ref) => const UrlLauncherGateway(),
);

final screenshotRepositoryProvider = Provider<ScreenshotRepository>(
  (ref) => DriftScreenshotRepository(ref.watch(databaseProvider)),
);
final entityRepositoryProvider = Provider<EntityRepository>(
  (ref) => DriftEntityRepository(ref.watch(databaseProvider)),
);
final extractedObjectRepositoryProvider = Provider<ExtractedObjectRepository>(
  (ref) => DriftExtractedObjectRepository(ref.watch(databaseProvider)),
);
final suggestedActionRepositoryProvider = Provider<SuggestedActionRepository>(
  (ref) => DriftSuggestedActionRepository(ref.watch(databaseProvider)),
);
final lifecycleEventRepositoryProvider = Provider<LifecycleEventRepository>(
  (ref) => DriftLifecycleEventRepository(ref.watch(databaseProvider)),
);
final processingStoreProvider = Provider<ProcessingStore>(
  (ref) => DriftProcessingStore(ref.watch(databaseProvider)),
);

final textRecognitionProvider = Provider<TextRecognitionService>((ref) {
  final service = MlKitTextRecognitionService();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final barcodeRecognitionProvider = Provider<BarcodeRecognitionService>((ref) {
  final service = MlKitBarcodeRecognitionService();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final entityExtractorProvider = Provider<EntityExtractor>(
  (ref) => RegexEntityExtractor(ref.watch(idGeneratorProvider)),
);

final classifierProvider = Provider<ScreenshotClassifier>((ref) {
  return RuleBasedScreenshotClassifier([
    ClassificationRule(
      result: const ClassificationResult(
        type: ScreenshotType.event,
        subtype: 'event.generic',
        confidence: 0.72,
      ),
      matches: (context) {
        final text = context.ocrText.toLowerCase();
        return context.entities.any(
              (entity) => entity.type == EntityType.date,
            ) &&
            (text.contains('ticket') || text.contains('event'));
      },
    ),
    ClassificationRule(
      result: const ClassificationResult(
        type: ScreenshotType.coupon,
        subtype: 'coupon.discount',
        confidence: 0.7,
      ),
      matches: (context) {
        final text = context.ocrText.toLowerCase();
        return text.contains('coupon') || text.contains('discount');
      },
    ),
  ]);
});

final parserRegistryProvider = Provider<ParserRegistry>(
  (ref) => ParserRegistry([
    GenericScreenshotParser(
      ref.watch(idGeneratorProvider),
      ref.watch(clockProvider),
    ),
  ]),
);

final actionPolicyRegistryProvider = Provider<ActionPolicyRegistry>(
  (ref) =>
      ActionPolicyRegistry(const [UrlActionPolicy(), SaveObjectActionPolicy()]),
);

final actionEngineProvider = Provider<ActionEngine>(
  (ref) => ActionEngine(
    ref.watch(actionPolicyRegistryProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  ),
);

final lifecyclePolicyRegistryProvider = Provider<LifecyclePolicyRegistry>(
  (ref) => LifecyclePolicyRegistry(const [
    TemporalLifecyclePolicy(),
    DefaultLifecyclePolicy(),
  ]),
);

final lifecycleEngineProvider = Provider<LifecycleEngine>(
  (ref) => LifecycleEngine(
    ref.watch(lifecyclePolicyRegistryProvider),
    ref.watch(clockProvider),
  ),
);

final processingPipelineProvider = Provider<ScreenshotProcessingPipeline>(
  (ref) => ScreenshotProcessingPipeline(
    photos: ref.watch(photoRepositoryProvider),
    textRecognition: ref.watch(textRecognitionProvider),
    barcodeRecognition: ref.watch(barcodeRecognitionProvider),
    entityExtractor: ref.watch(entityExtractorProvider),
    classifier: ref.watch(classifierProvider),
    parsers: ref.watch(parserRegistryProvider),
    actions: ref.watch(actionEngineProvider),
    lifecycle: ref.watch(lifecycleEngineProvider),
    store: ref.watch(processingStoreProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
