import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';

final class LifecycleRefreshService {
  const LifecycleRefreshService({
    required this.inbox,
    required this.screenshots,
    required this.lifecycleEvents,
    required this.lifecycle,
    required this.clock,
    required this.ids,
  });

  final InboxRepository inbox;
  final ScreenshotRepository screenshots;
  final LifecycleEventRepository lifecycleEvents;
  final LifecycleEngine lifecycle;
  final Clock clock;
  final IdGenerator ids;

  Future<void> refresh() async {
    final items = await inbox.find(const InboxQuery.recent(limit: null));
    for (final item in items) {
      if (item.screenshot.currentLifecycleState == LifecycleState.keep ||
          item.screenshot.currentLifecycleState == LifecycleState.deleted) {
        continue;
      }
      final object = item.object;
      if (object == null) continue;
      final evaluation = lifecycle.evaluate([object]).single;
      final next =
          evaluation.state == LifecycleState.understood &&
              item.pendingActions.isNotEmpty &&
              !item.isHandled
          ? LifecycleState.actionable
          : evaluation.state;
      if (next == item.screenshot.currentLifecycleState) continue;
      await screenshots.setLifecycleState(item.screenshot.id, next);
      await lifecycleEvents.appendAll([
        LifecycleEvent(
          id: ids.next(),
          screenshotId: item.screenshot.id,
          type: evaluation.eventType ?? LifecycleEventType.understood,
          timestamp: clock.now(),
          reason: evaluation.reason,
          metadata: evaluation.metadata,
        ),
      ]);
    }
  }
}
