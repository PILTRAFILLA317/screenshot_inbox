import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';

final class ScreenshotCommandService {
  const ScreenshotCommandService({
    required this.photos,
    required this.screenshots,
    required this.lifecycleEvents,
    required this.clock,
    required this.ids,
  });

  final PhotoRepository photos;
  final ScreenshotRepository screenshots;
  final LifecycleEventRepository lifecycleEvents;
  final Clock clock;
  final IdGenerator ids;

  Future<void> keep(Screenshot screenshot) => _transition(
    screenshot.id,
    LifecycleState.keep,
    LifecycleEventType.kept,
    'The user chose to keep this screenshot.',
  );

  Future<bool> delete(Screenshot screenshot) async {
    final deleted = await photos.deleteAssets([screenshot.assetId]);
    if (!deleted.contains(screenshot.assetId)) return false;
    await _transition(
      screenshot.id,
      LifecycleState.deleted,
      LifecycleEventType.deleted,
      'The screenshot was deleted from Photos after user confirmation.',
    );
    return true;
  }

  Future<void> _transition(
    String screenshotId,
    LifecycleState state,
    LifecycleEventType eventType,
    String reason,
  ) async {
    final now = clock.now();
    await screenshots.setLifecycleState(screenshotId, state);
    await lifecycleEvents.appendAll([
      LifecycleEvent(
        id: ids.next(),
        screenshotId: screenshotId,
        type: eventType,
        timestamp: now,
        reason: reason,
      ),
    ]);
  }
}
