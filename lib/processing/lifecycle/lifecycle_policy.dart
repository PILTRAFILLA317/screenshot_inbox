import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';

abstract interface class LifecyclePolicy {
  String get id;

  int get priority;

  bool supports(ExtractedObject object);

  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now);
}
