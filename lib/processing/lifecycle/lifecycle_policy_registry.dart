import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy.dart';

final class LifecyclePolicyRegistry {
  LifecyclePolicyRegistry(List<LifecyclePolicy> policies)
    : policies = List.unmodifiable(
        [...policies]..sort((a, b) => b.priority.compareTo(a.priority)),
      );

  final List<LifecyclePolicy> policies;

  LifecyclePolicy? resolve(ExtractedObject object) {
    for (final policy in policies) {
      if (policy.supports(object)) return policy;
    }
    return null;
  }

  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final policy = resolve(object);
    return policy?.evaluate(object, now) ??
        const LifecycleEvaluation(
          state: LifecycleState.understood,
          reason: 'No lifecycle policy matched.',
          eventType: LifecycleEventType.understood,
        );
  }
}
