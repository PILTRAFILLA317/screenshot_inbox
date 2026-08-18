import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';

final class ActionProposal {
  const ActionProposal({
    required this.type,
    required this.payload,
    required this.confidence,
  });

  final SuggestedActionType type;
  final JsonMap payload;
  final double confidence;
}

abstract interface class ActionPolicy {
  String get id;

  int get priority;

  bool supports(ExtractedObject object);

  Future<List<ActionProposal>> propose(ExtractedObject object);
}
