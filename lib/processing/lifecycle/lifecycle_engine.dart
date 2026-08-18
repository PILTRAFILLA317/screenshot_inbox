import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';

final class LifecycleEngine {
  LifecycleEngine(this._registry, this._clock);

  final LifecyclePolicyRegistry _registry;
  final Clock _clock;

  List<LifecycleEvaluation> evaluate(List<ExtractedObject> objects) => [
    for (final object in objects) _registry.evaluate(object, _clock.now()),
  ];
}
