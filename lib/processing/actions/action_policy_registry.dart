import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy.dart';

final class ActionPolicyRegistry {
  ActionPolicyRegistry(List<ActionPolicy> policies)
    : policies = List.unmodifiable(
        [...policies]..sort((a, b) => b.priority.compareTo(a.priority)),
      );

  final List<ActionPolicy> policies;

  List<ActionPolicy> resolve(ExtractedObject object) => [
    for (final policy in policies)
      if (policy.supports(object)) policy,
  ];

  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final proposals = <ActionProposal>[];
    for (final policy in resolve(object)) {
      proposals.addAll(await policy.propose(object));
    }
    return proposals;
  }
}
