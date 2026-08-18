import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';

import '../support/fixtures.dart';

void main() {
  test('composes all matching policies in priority order', () async {
    final registry = ActionPolicyRegistry([
      _Policy('low', 1, SuggestedActionType.copy),
      _Policy('ignored', 100, SuggestedActionType.maps, isSupported: false),
      _Policy('high', 10, SuggestedActionType.reminder),
    ]);

    final resolved = registry.resolve(objectFixture());
    final proposals = await registry.propose(objectFixture());

    expect(resolved.map((policy) => policy.id), ['high', 'low']);
    expect(proposals.map((proposal) => proposal.type), [
      SuggestedActionType.reminder,
      SuggestedActionType.copy,
    ]);
  });
}

final class _Policy implements ActionPolicy {
  const _Policy(this.id, this.priority, this.type, {this.isSupported = true});

  @override
  final String id;
  @override
  final int priority;
  final SuggestedActionType type;
  final bool isSupported;

  @override
  bool supports(ExtractedObject object) => isSupported;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async => [
    ActionProposal(type: type, payload: const {}, confidence: 1),
  ];
}
