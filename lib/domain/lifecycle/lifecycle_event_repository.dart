import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';

abstract interface class LifecycleEventRepository {
  Future<void> appendAll(List<LifecycleEvent> events);

  Future<List<LifecycleEvent>> findForScreenshot(String screenshotId);
}
