import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';
import 'package:screenshot_inbox/processing/actions/action_evidence_gate.dart';

final class ActionGenerationResult {
  const ActionGenerationResult({
    required this.actions,
    required this.decisions,
  });

  final List<SuggestedAction> actions;
  final List<Map<String, Object?>> decisions;
}

final class ActionEngine {
  ActionEngine(
    this._registry,
    this._ids,
    this._clock, {
    this.evidenceGate = const ActionEvidenceGate(),
  });

  final ActionPolicyRegistry _registry;
  final IdGenerator _ids;
  final Clock _clock;
  final ActionEvidenceGate evidenceGate;

  Future<List<SuggestedAction>> generate(
    String screenshotId,
    List<ExtractedObject> objects,
  ) async => (await generateWithDiagnostics(screenshotId, objects)).actions;

  Future<ActionGenerationResult> generateWithDiagnostics(
    String screenshotId,
    List<ExtractedObject> objects,
  ) async {
    final actions = <SuggestedAction>[];
    final decisions = <Map<String, Object?>>[];
    final deduplicationKeys = <String>{};
    for (final object in objects) {
      decisions.addAll([
        for (final decision in evidenceGate.diagnosticsFor(object))
          {'objectId': object.id, ...decision},
      ]);
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
    return ActionGenerationResult(actions: actions, decisions: decisions);
  }
}
