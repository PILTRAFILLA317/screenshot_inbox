import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';

abstract interface class ScreenshotRepository {
  Future<void> save(Screenshot screenshot);

  Future<Screenshot?> findById(String id);

  Future<Screenshot?> findByAssetId(String assetId);

  Future<Map<String, Screenshot>> findByAssetIds(Iterable<String> assetIds);

  Future<List<Screenshot>> findAll();

  Future<List<Screenshot>> findByProcessingStatuses(
    Set<ScreenshotProcessingStatus> statuses,
  );

  Future<void> setLifecycleState(String id, LifecycleState state);

  Stream<List<Screenshot>> watchRecent({int limit = 20});

  Future<int> countByLifecycleStates(Set<LifecycleState> states);
}
