import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';

final class ActionEngine {
  ActionEngine(this._registry, this._ids, this._clock);

  final ActionPolicyRegistry _registry;
  final IdGenerator _ids;
  final Clock _clock;

  Future<List<SuggestedAction>> generate(
    String screenshotId,
    List<ExtractedObject> objects,
  ) async {
    final actions = <SuggestedAction>[];
    final deduplicationKeys = <String>{};
    for (final object in objects) {
      if (object.structuredData['_suppressActions'] == true) continue;
      final proposals = await _registry.propose(object);
      for (final proposal in proposals) {
        final key = '${object.id}:${proposal.type.value}:${proposal.payload}';
        if (!deduplicationKeys.add(key)) continue;
        actions.add(
          SuggestedAction(
            id: _ids.next(),
            screenshotId: screenshotId,
            extractedObjectId: object.id,
            type: proposal.type,
            payload: proposal.payload,
            confidence: proposal.confidence,
            status: SuggestedActionStatus.suggested,
            createdAt: _clock.now(),
          ),
        );
      }
    }
    return actions;
  }
}
