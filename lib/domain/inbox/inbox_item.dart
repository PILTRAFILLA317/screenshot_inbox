import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';

final class InboxItem {
  const InboxItem({
    required this.screenshot,
    required this.actions,
    required this.entities,
    this.object,
    this.lifecycleReason,
  });

  final Screenshot screenshot;
  final ExtractedObject? object;
  final List<SuggestedAction> actions;
  final List<ExtractedEntity> entities;
  final String? lifecycleReason;

  String get title =>
      object?.title ?? _firstLine(screenshot.ocrText) ?? 'Screenshot';
  String? get subtitle => object?.subtitle;

  List<SuggestedAction> get pendingActions => actions
      .where(
        (action) =>
            action.status == SuggestedActionStatus.suggested ||
            action.status == SuggestedActionStatus.failed,
      )
      .toList(growable: false);

  SuggestedAction? get primaryAction =>
      pendingActions.isEmpty ? null : pendingActions.first;

  bool get isHandled =>
      object?.handled == true ||
      screenshot.currentLifecycleState == LifecycleState.handled ||
      screenshot.currentLifecycleState == LifecycleState.keep ||
      screenshot.currentLifecycleState == LifecycleState.deleted;

  bool get needsAction => pendingActions.isNotEmpty && !isHandled;
  bool get isSaved => object?.saved ?? false;

  DateTime? get expiryDate =>
      _date(object?.structuredData['expiresAt']) ??
      _date(object?.structuredData['expiryDate']);

  DateTime? get importantDate =>
      _date(object?.structuredData['importantDate']) ??
      expiryDate ??
      _date(object?.structuredData['startsAt']) ??
      _date(object?.structuredData['deliveryDate']);

  static String? _firstLine(String? text) {
    if (text == null) return null;
    for (final line in text.split('\n')) {
      if (line.trim().isNotEmpty) return line.trim();
    }
    return null;
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

enum InboxFilter { recent, needAction, expiring, cleanup, library, search, one }

final class InboxQuery {
  const InboxQuery({
    required this.filter,
    this.limit,
    this.search,
    this.screenshotId,
  });

  const InboxQuery.recent({int? limit = 20})
    : this(filter: InboxFilter.recent, limit: limit);
  const InboxQuery.needAction({int? limit})
    : this(filter: InboxFilter.needAction, limit: limit);
  const InboxQuery.expiring({int? limit})
    : this(filter: InboxFilter.expiring, limit: limit);
  const InboxQuery.cleanup({int? limit})
    : this(filter: InboxFilter.cleanup, limit: limit);
  const InboxQuery.library({int? limit})
    : this(filter: InboxFilter.library, limit: limit);
  const InboxQuery.search(String value, {int? limit = 200})
    : this(filter: InboxFilter.search, search: value, limit: limit);
  const InboxQuery.one(String id)
    : this(filter: InboxFilter.one, screenshotId: id, limit: 1);

  final InboxFilter filter;
  final int? limit;
  final String? search;
  final String? screenshotId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxQuery &&
          filter == other.filter &&
          limit == other.limit &&
          search == other.search &&
          screenshotId == other.screenshotId;

  @override
  int get hashCode => Object.hash(filter, limit, search, screenshotId);
}

abstract interface class InboxRepository {
  Stream<List<InboxItem>> watch(InboxQuery query);
  Future<List<InboxItem>> find(InboxQuery query);
}
