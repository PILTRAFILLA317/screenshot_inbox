import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/priority/priority_engine.dart';

import '../support/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 19, 12);
  const engine = PriorityEngine();

  test('urgent actionable expiry outranks a recent passive reference', () {
    final urgent = _item(
      id: 'urgent',
      state: LifecycleState.expiring,
      expiry: now.add(const Duration(hours: 12)),
      actionable: true,
    );
    final passive = _item(
      id: 'passive',
      state: LifecycleState.understood,
      actionable: false,
    );

    expect(engine.rank([passive, urgent], now).first.screenshot.id, 'urgent');
  });

  test('handled penalty pushes an item below unfinished work', () {
    final handled = _item(
      id: 'handled',
      state: LifecycleState.handled,
      actionable: true,
      handled: true,
    );
    final open = _item(
      id: 'open',
      state: LifecycleState.actionable,
      actionable: true,
    );

    expect(engine.score(handled, now), lessThan(engine.score(open, now)));
  });
}

InboxItem _item({
  required String id,
  required LifecycleState state,
  required bool actionable,
  DateTime? expiry,
  bool handled = false,
}) {
  final screenshot = screenshotFixture(id: id, lifecycleState: state);
  final object = objectFixture(
    id: '$id-object',
    screenshotId: id,
    structuredData: {if (expiry != null) 'expiresAt': expiry.toIso8601String()},
  ).copyWith(handled: handled);
  return InboxItem(
    screenshot: screenshot,
    object: object,
    entities: const [],
    actions: actionable
        ? [
            SuggestedAction(
              id: '$id-action',
              screenshotId: id,
              extractedObjectId: object.id,
              type: SuggestedActionType.copy,
              payload: const {'text': 'value'},
              confidence: 0.9,
              status: SuggestedActionStatus.suggested,
              createdAt: screenshot.createdAt,
            ),
          ]
        : const [],
  );
}
