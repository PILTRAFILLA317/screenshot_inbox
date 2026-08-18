import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';

abstract interface class EntityRepository {
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<ExtractedEntity> entities,
  );

  Future<List<ExtractedEntity>> findForScreenshot(String screenshotId);
}

abstract interface class ExtractedObjectRepository {
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<ExtractedObject> objects,
  );

  Future<List<ExtractedObject>> findForScreenshot(String screenshotId);
}
