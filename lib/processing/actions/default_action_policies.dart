import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy.dart';

final class SaveObjectActionPolicy implements ActionPolicy {
  const SaveObjectActionPolicy();

  @override
  String get id => 'save-object.v1';

  @override
  int get priority => -100;

  @override
  bool supports(ExtractedObject object) => !object.saved;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async => [
    ActionProposal(
      type: SuggestedActionType.saveObject,
      payload: {'objectId': object.id},
      confidence: object.confidence,
    ),
  ];
}

final class UrlActionPolicy implements ActionPolicy {
  const UrlActionPolicy();

  @override
  String get id => 'open-url.v1';

  @override
  int get priority => 100;

  @override
  bool supports(ExtractedObject object) =>
      object.structuredData['url'] is String;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async => [
    ActionProposal(
      type: SuggestedActionType.openUrl,
      payload: {'url': object.structuredData['url']},
      confidence: object.confidence,
    ),
  ];
}
