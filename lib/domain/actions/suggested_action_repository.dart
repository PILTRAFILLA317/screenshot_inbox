import 'package:screenshot_inbox/domain/actions/suggested_action.dart';

abstract interface class SuggestedActionRepository {
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<SuggestedAction> actions,
  );

  Future<List<SuggestedAction>> findForScreenshot(String screenshotId);
}
