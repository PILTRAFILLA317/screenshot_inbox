import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class ClassificationResult {
  const ClassificationResult({
    required this.type,
    required this.confidence,
    this.subtype,
  });

  final ScreenshotType type;
  final String? subtype;
  final double confidence;
}

abstract interface class ScreenshotClassifier {
  Future<ClassificationResult> classify(ProcessingContext context);
}

final class ClassificationRule {
  const ClassificationRule({required this.result, required this.matches});

  final ClassificationResult result;
  final bool Function(ProcessingContext context) matches;
}

final class RuleBasedScreenshotClassifier implements ScreenshotClassifier {
  RuleBasedScreenshotClassifier(this.rules);

  final List<ClassificationRule> rules;

  @override
  Future<ClassificationResult> classify(ProcessingContext context) async {
    for (final rule in rules) {
      if (rule.matches(context)) {
        return rule.result;
      }
    }
    return const ClassificationResult(
      type: ScreenshotType.generic,
      confidence: 0.5,
    );
  }
}
