import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/core/database/app_database.dart';
import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/application/actions/action_execution_service.dart';
import 'package:screenshot_inbox/application/screenshots/interpretation_service.dart';
import 'package:screenshot_inbox/application/screenshots/lifecycle_refresh_service.dart';
import 'package:screenshot_inbox/application/screenshots/screenshot_command_service.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action_repository.dart';
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/infrastructure/database/drift_repositories.dart';
import 'package:screenshot_inbox/infrastructure/intelligence/local_intelligence_provider.dart';
import 'package:screenshot_inbox/infrastructure/clipboard/flutter_clipboard_gateway.dart';
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
import 'package:screenshot_inbox/processing/discovery/screenshot_discovery_coordinator.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/intelligence/interpretation_validator.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/screenshot_processing_pipeline.dart';
import 'package:screenshot_inbox/processing/priority/priority_engine.dart';

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
final clipboardGatewayProvider = Provider<ClipboardGateway>(
  (ref) => const FlutterClipboardGateway(),
);

final priorityEngineProvider = Provider<PriorityEngine>(
  (ref) => const PriorityEngine(),
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
final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => DriftInboxRepository(
    ref.watch(databaseProvider),
    ref.watch(priorityEngineProvider),
  ),
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

final classifierProvider = Provider<ScreenshotClassifier>(
  (ref) => RuleBasedScreenshotClassifier(),
);

final intelligenceUsagePolicyProvider = Provider<IntelligenceUsagePolicy>((
  ref,
) {
  const configured = String.fromEnvironment('INTELLIGENCE_USAGE_POLICY');
  if (configured.isNotEmpty) {
    return IntelligenceUsagePolicy.values
            .where((policy) => policy.name == configured)
            .firstOrNull ??
        IntelligenceUsagePolicy.actionableTypes;
  }
  const release = bool.fromEnvironment('dart.vm.product');
  return release
      ? IntelligenceUsagePolicy.actionableTypes
      : IntelligenceUsagePolicy.alwaysForSupportedTypes;
});

final intelligenceProvider = Provider<IntelligenceProvider>(
  (ref) => const LocalIntelligenceProvider(),
);

final intelligenceEnricherProvider = Provider<IntelligenceEnricher>(
  (ref) => IntelligenceEnricher(
    provider: ref.watch(intelligenceProvider),
    validator: const InterpretationValidator(),
    policy: ref.watch(intelligenceUsagePolicyProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final parserRegistryProvider = Provider<ParserRegistry>(
  (ref) => ParserRegistry([
    EventParser(ref.watch(idGeneratorProvider), ref.watch(clockProvider)),
    CouponParser(ref.watch(idGeneratorProvider), ref.watch(clockProvider)),
    ConversationTaskParser(
      ref.watch(idGeneratorProvider),
      ref.watch(clockProvider),
    ),
    OrderParser(ref.watch(idGeneratorProvider), ref.watch(clockProvider)),
    ProductParser(ref.watch(idGeneratorProvider), ref.watch(clockProvider)),
    PlaceParser(ref.watch(idGeneratorProvider), ref.watch(clockProvider)),
    GenericScreenshotParser(
      ref.watch(idGeneratorProvider),
      ref.watch(clockProvider),
    ),
  ]),
);

final actionPolicyRegistryProvider = Provider<ActionPolicyRegistry>(
  (ref) => ActionPolicyRegistry([
    EventActionPolicy(ref.watch(clockProvider)),
    CouponActionPolicy(ref.watch(clockProvider)),
    ConversationTaskActionPolicy(ref.watch(clockProvider)),
    const OrderActionPolicy(),
    const ProductActionPolicy(),
    const PlaceActionPolicy(),
    const UrlActionPolicy(),
    const SaveObjectActionPolicy(),
  ]),
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
    HandledLifecyclePolicy(),
    EventLifecyclePolicy(),
    CouponLifecyclePolicy(),
    OrderLifecyclePolicy(),
    SavedObjectLifecyclePolicy(),
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
    intelligence: ref.watch(intelligenceEnricherProvider),
    existingObjects: ref.watch(extractedObjectRepositoryProvider),
  ),
);

final discoveryCoordinatorProvider = Provider<ScreenshotDiscoveryCoordinator>((
  ref,
) {
  final coordinator = ScreenshotDiscoveryCoordinator(
    photos: ref.watch(photoRepositoryProvider),
    screenshots: ref.watch(screenshotRepositoryProvider),
    pipeline: ref.watch(processingPipelineProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
});

final actionExecutionServiceProvider = Provider<ActionExecutionService>(
  (ref) => ActionExecutionService(
    calendar: ref.watch(calendarGatewayProvider),
    maps: ref.watch(mapsGatewayProvider),
    notifications: ref.watch(notificationGatewayProvider),
    urls: ref.watch(urlGatewayProvider),
    clipboard: ref.watch(clipboardGatewayProvider),
    actions: ref.watch(suggestedActionRepositoryProvider),
    objects: ref.watch(extractedObjectRepositoryProvider),
    screenshots: ref.watch(screenshotRepositoryProvider),
    lifecycleEvents: ref.watch(lifecycleEventRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final screenshotCommandServiceProvider = Provider<ScreenshotCommandService>(
  (ref) => ScreenshotCommandService(
    photos: ref.watch(photoRepositoryProvider),
    screenshots: ref.watch(screenshotRepositoryProvider),
    lifecycleEvents: ref.watch(lifecycleEventRepositoryProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final interpretationServiceProvider = Provider<InterpretationService>(
  (ref) => InterpretationService(
    objects: ref.watch(extractedObjectRepositoryProvider),
    actions: ref.watch(suggestedActionRepositoryProvider),
    screenshots: ref.watch(screenshotRepositoryProvider),
    lifecycleEvents: ref.watch(lifecycleEventRepositoryProvider),
    actionEngine: ref.watch(actionEngineProvider),
    lifecycleEngine: ref.watch(lifecycleEngineProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final lifecycleRefreshServiceProvider = Provider<LifecycleRefreshService>(
  (ref) => LifecycleRefreshService(
    inbox: ref.watch(inboxRepositoryProvider),
    screenshots: ref.watch(screenshotRepositoryProvider),
    lifecycleEvents: ref.watch(lifecycleEventRepositoryProvider),
    lifecycle: ref.watch(lifecycleEngineProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final inboxItemsProvider = StreamProvider.autoDispose
    .family<List<InboxItem>, InboxQuery>(
      (ref, query) => ref.watch(inboxRepositoryProvider).watch(query),
    );

final thumbnailProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, assetId) => ref.watch(photoRepositoryProvider).getThumbnail(assetId),
);

final currentPhotoPermissionProvider = FutureProvider<PhotoPermissionState>(
  (ref) => ref.watch(photoRepositoryProvider).currentPermission(),
);
