import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action_repository.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';

final class InterpretationService {
  const InterpretationService({
    required this.objects,
    required this.actions,
    required this.screenshots,
    required this.lifecycleEvents,
    required this.actionEngine,
    required this.lifecycleEngine,
    required this.clock,
    required this.ids,
  });

  final ExtractedObjectRepository objects;
  final SuggestedActionRepository actions;
  final ScreenshotRepository screenshots;
  final LifecycleEventRepository lifecycleEvents;
  final ActionEngine actionEngine;
  final LifecycleEngine lifecycleEngine;
  final Clock clock;
  final IdGenerator ids;

  Future<void> correct({
    required Screenshot screenshot,
    required ExtractedObject object,
    required ExtractedObjectType type,
    required String title,
    DateTime? importantDate,
  }) async {
    final now = clock.now();
    final oldFields = object.structuredData['_userConfirmedFields'];
    final confirmed = oldFields is List
        ? oldFields.whereType<String>().toSet()
        : <String>{};
    confirmed.addAll(['type', 'title']);
    final data = <String, Object?>{
      ...object.structuredData,
      '_userConfirmedFields': confirmed.toList(growable: false),
    };
    if (importantDate != null) {
      confirmed.add('importantDate');
      final iso = importantDate.toUtc().toIso8601String();
      data['importantDate'] = iso;
      if (type == ExtractedObjectType.event) data['startsAt'] = iso;
      if (type == ExtractedObjectType.coupon) data['expiresAt'] = iso;
      if (type == ExtractedObjectType.conversationTask) data['remindAt'] = iso;
      if (type == ExtractedObjectType.order) {
        data['deliveryDate'] = iso;
      }
      data['_userConfirmedFields'] = confirmed.toList(growable: false);
    }
    final corrected = object.copyWith(
      type: type,
      subtype: '${type.value}.user-confirmed',
      title: title.trim(),
      structuredData: data,
      updatedAt: now,
    );
    await objects.save(corrected);
    final proposed = await actionEngine.generate(screenshot.id, [corrected]);
    await actions.replaceForScreenshot(screenshot.id, proposed);
    final evaluation = lifecycleEngine.evaluate([corrected]).first;
    final state =
        evaluation.state == LifecycleState.understood && proposed.isNotEmpty
        ? LifecycleState.actionable
        : evaluation.state;
    await screenshots.save(
      screenshot.copyWith(
        primaryType: ScreenshotType(type.value),
        primarySubtype: '${type.value}.user-confirmed',
        currentLifecycleState: state,
      ),
    );
    await lifecycleEvents.appendAll([
      LifecycleEvent(
        id: ids.next(),
        screenshotId: screenshot.id,
        type: LifecycleEventType.understood,
        timestamp: now,
        reason: 'The interpretation was corrected and confirmed by the user.',
        metadata: {
          'confirmedFields': confirmed.toList(growable: false),
          'type': type.value,
        },
      ),
    ]);
  }
}
