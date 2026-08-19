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
  Future<void> save(ExtractedObject object);

  Future<void> replaceForScreenshot(
    String screenshotId,
    List<ExtractedObject> objects,
  );

  Future<List<ExtractedObject>> findForScreenshot(String screenshotId);

  Future<void> setSaved(String id, bool saved, DateTime at);

  Future<void> setHandled(String id, bool handled, DateTime at);
}
