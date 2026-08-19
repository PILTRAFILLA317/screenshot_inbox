import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/actions/calendar_event_policy.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/processing/actions/action_policy.dart';
import 'package:screenshot_inbox/processing/actions/action_evidence_gate.dart';

final class EventActionPolicy implements ActionPolicy {
  const EventActionPolicy([
    this.clock = const SystemClock(),
    this.calendarPolicy = const CalendarEventPolicy(),
    this.evidenceGate = const ActionEvidenceGate(),
  ]);

  final Clock clock;
  final CalendarEventPolicy calendarPolicy;
  final ActionEvidenceGate evidenceGate;

  @override
  String get id => 'event-actions.v1';
  @override
  int get priority => 200;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.event;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final data = object.structuredData;
    final validDate = evidenceGate.eventDate(object);
    final validTitle = evidenceGate.eventTitle(object);
    final startsAt = _date(data['startsAt']);
    final reminderAt = startsAt == null
        ? null
        : _reminderBefore(startsAt, clock.now(), const Duration(hours: 1));
    final venue = evidenceGate.reliableField(object, 'venue');
    final city = evidenceGate.reliableField(object, 'city');
    final place = venue.accepted && city.accepted
        ? '${venue.value}, ${city.value}'
        : null;
    final validatedCalendarPayload = validDate.accepted && validTitle.accepted
        ? calendarPolicy.payloadFor(object)
        : null;
    final calendarPayload =
        validatedCalendarPayload ??
        {
          'label': 'Review event',
          'title': object.title,
          if (startsAt != null) 'startsAt': startsAt.toIso8601String(),
          'isAllDay': data['time'] == null,
          'defaultDurationMinutes': data['time'] == null
              ? const Duration(days: 1).inMinutes
              : const Duration(hours: 2).inMinutes,
          'location': ?place,
          'reviewRequired': true,
        };
    return [
      ActionProposal(
        type: SuggestedActionType.calendar,
        payload: calendarPayload,
        confidence: object.confidence,
      ),
      if (reminderAt != null && validDate.accepted && validTitle.accepted)
        ActionProposal(
          type: SuggestedActionType.reminder,
          payload: {
            'label': 'Create Reminder',
            'title': object.title,
            'body': 'Upcoming event from Screenshot Inbox',
            'remindAt': reminderAt.toIso8601String(),
          },
          confidence: object.confidence,
        ),
      if (place != null)
        ActionProposal(
          type: SuggestedActionType.maps,
          payload: {
            'label': 'Open Maps',
            'query': place,
            'title': object.title,
          },
          confidence: object.confidence,
        ),
    ];
  }
}

final class CouponActionPolicy implements ActionPolicy {
  const CouponActionPolicy([
    this.clock = const SystemClock(),
    this.evidenceGate = const ActionEvidenceGate(),
  ]);

  final Clock clock;
  final ActionEvidenceGate evidenceGate;

  @override
  String get id => 'coupon-actions.v1';
  @override
  int get priority => 200;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.coupon;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final code = evidenceGate.couponCode(object);
    final expiry = _date(object.structuredData['expiresAt']);
    final reminderAt = expiry == null
        ? null
        : _reminderBefore(expiry, clock.now(), const Duration(days: 1));
    return [
      if (code.accepted)
        ActionProposal(
          type: SuggestedActionType.copy,
          payload: {'label': 'Copy code', 'text': code.value},
          confidence: object.confidence,
        ),
      if (reminderAt != null)
        ActionProposal(
          type: SuggestedActionType.reminder,
          payload: {
            'label': 'Remind before expiry',
            'title': object.title,
            'body': code.accepted
                ? 'Coupon code: ${code.value}'
                : 'Coupon expires soon',
            'remindAt': reminderAt.toIso8601String(),
          },
          confidence: object.confidence,
        ),
    ];
  }
}

final class ConversationTaskActionPolicy implements ActionPolicy {
  const ConversationTaskActionPolicy([this.clock = const SystemClock()]);

  final Clock clock;

  @override
  String get id => 'conversation-task-actions.v1';
  @override
  int get priority => 200;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.conversationTask ||
      object.type == ExtractedObjectType.conversation;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final task = object.structuredData['task'];
    final remindAt = _date(object.structuredData['remindAt']);
    return [
      if (remindAt != null && remindAt.isAfter(clock.now()))
        ActionProposal(
          type: SuggestedActionType.reminder,
          payload: {
            'label': 'Create Reminder',
            'title': task is String ? task : object.title,
            'body': 'Reminder from a saved conversation',
            'remindAt': remindAt.toIso8601String(),
          },
          confidence: object.confidence,
        ),
      if (task is String && task.isNotEmpty)
        ActionProposal(
          type: SuggestedActionType.copy,
          payload: {'label': 'Copy text', 'text': task},
          confidence: object.confidence,
        ),
    ];
  }
}

final class OrderActionPolicy implements ActionPolicy {
  const OrderActionPolicy([this.evidenceGate = const ActionEvidenceGate()]);

  final ActionEvidenceGate evidenceGate;

  @override
  String get id => 'order-actions.v1';
  @override
  int get priority => 200;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.order;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final tracking = evidenceGate.trackingNumber(object);
    final trackingUrl = evidenceGate.trackingUrl(object);
    final url = evidenceGate.reliableField(
      object,
      'url',
      validate: (value) => Uri.tryParse(value)?.hasScheme == true,
    );
    return [
      if (trackingUrl.accepted)
        ActionProposal(
          type: SuggestedActionType.track,
          payload: {'label': 'Track package', 'url': trackingUrl.value},
          confidence: object.confidence,
        )
      else if (url.accepted)
        ActionProposal(
          type: SuggestedActionType.openUrl,
          payload: {'label': 'Open URL', 'url': url.value},
          confidence: object.confidence,
        ),
      if (tracking.accepted)
        ActionProposal(
          type: SuggestedActionType.copy,
          payload: {'label': 'Copy tracking', 'text': tracking.value},
          confidence: object.confidence,
        ),
      if (tracking.accepted && !trackingUrl.accepted)
        ActionProposal(
          type: SuggestedActionType.searchWeb,
          payload: {'label': 'Track package', 'query': tracking.value},
          confidence: object.confidence,
        ),
    ];
  }
}

final class ProductActionPolicy implements ActionPolicy {
  const ProductActionPolicy();

  @override
  String get id => 'product-actions.v1';
  @override
  int get priority => 200;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.product;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final url = object.structuredData['url'];
    final name = object.structuredData['productName'];
    return [
      if (url is String)
        ActionProposal(
          type: SuggestedActionType.openUrl,
          payload: {'label': 'Open URL', 'url': url},
          confidence: object.confidence,
        ),
      if (name is String)
        ActionProposal(
          type: SuggestedActionType.searchWeb,
          payload: {'label': 'Search web', 'query': name},
          confidence: object.confidence,
        ),
      if (name is String)
        ActionProposal(
          type: SuggestedActionType.copy,
          payload: {'label': 'Copy name', 'text': name},
          confidence: object.confidence,
        ),
    ];
  }
}

final class PlaceActionPolicy implements ActionPolicy {
  const PlaceActionPolicy([this.evidenceGate = const ActionEvidenceGate()]);

  final ActionEvidenceGate evidenceGate;

  @override
  String get id => 'place-actions.v1';
  @override
  int get priority => 200;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.place;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async {
    final query = evidenceGate.mapsQuery(object);
    return [
      if (query.accepted)
        ActionProposal(
          type: SuggestedActionType.maps,
          payload: {
            'label': 'Open Maps',
            'query': query.value,
            'title': object.title,
          },
          confidence: object.confidence,
        ),
      if (query.accepted)
        ActionProposal(
          type: SuggestedActionType.searchWeb,
          payload: {'label': 'Search web', 'query': query.value},
          confidence: object.confidence * 0.95,
        ),
    ];
  }
}

final class SaveObjectActionPolicy implements ActionPolicy {
  const SaveObjectActionPolicy();

  @override
  String get id => 'save-object.v2';
  @override
  int get priority => -100;
  @override
  bool supports(ExtractedObject object) =>
      !object.saved &&
      (object.type == ExtractedObjectType.place ||
          object.type == ExtractedObjectType.product);

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async => [
    ActionProposal(
      type: SuggestedActionType.saveObject,
      payload: {'label': 'Save', 'objectId': object.id},
      confidence: object.confidence,
    ),
  ];
}

/// Retained as a small composable policy for additional parser types.
final class UrlActionPolicy implements ActionPolicy {
  const UrlActionPolicy();

  @override
  String get id => 'open-url.v1';
  @override
  int get priority => 50;
  @override
  bool supports(ExtractedObject object) =>
      object.type != ExtractedObjectType.product &&
      object.type != ExtractedObjectType.order &&
      object.structuredData['url'] is String;

  @override
  Future<List<ActionProposal>> propose(ExtractedObject object) async => [
    ActionProposal(
      type: SuggestedActionType.openUrl,
      payload: {'label': 'Open URL', 'url': object.structuredData['url']},
      confidence: object.confidence,
    ),
  ];
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

DateTime? _reminderBefore(
  DateTime target,
  DateTime now,
  Duration preferredLead,
) {
  if (!target.isAfter(now)) return null;
  final preferred = target.subtract(preferredLead);
  if (preferred.isAfter(now)) return preferred;
  final remaining = target.difference(now);
  return now.add(Duration(microseconds: remaining.inMicroseconds ~/ 2));
}
