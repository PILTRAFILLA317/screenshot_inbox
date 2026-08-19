import 'package:screenshot_inbox/core/utils/json_types.dart';

final class ExtractedObjectType {
  const ExtractedObjectType(this.value);

  final String value;

  static const event = ExtractedObjectType('event');
  static const place = ExtractedObjectType('place');
  static const product = ExtractedObjectType('product');
  static const order = ExtractedObjectType('order');
  static const coupon = ExtractedObjectType('coupon');
  static const conversationTask = ExtractedObjectType('conversationTask');
  static const conversation = ExtractedObjectType('conversation');
  static const reference = ExtractedObjectType('reference');
  static const other = ExtractedObjectType('other');
  static const generic = ExtractedObjectType('generic');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedObjectType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class ExtractedObject {
  const ExtractedObject({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.subtype,
    required this.title,
    required this.structuredData,
    required this.confidence,
    required this.saved,
    required this.handled,
    required this.createdAt,
    required this.updatedAt,
    this.subtitle,
  });

  final String id;
  final String screenshotId;
  final ExtractedObjectType type;
  final String subtype;
  final String title;
  final String? subtitle;
  final JsonMap structuredData;
  final double confidence;
  final bool saved;
  final bool handled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExtractedObject copyWith({
    ExtractedObjectType? type,
    String? subtype,
    String? title,
    String? subtitle,
    bool clearSubtitle = false,
    JsonMap? structuredData,
    double? confidence,
    bool? saved,
    bool? handled,
    DateTime? updatedAt,
  }) => ExtractedObject(
    id: id,
    screenshotId: screenshotId,
    type: type ?? this.type,
    subtype: subtype ?? this.subtype,
    title: title ?? this.title,
    subtitle: clearSubtitle ? null : subtitle ?? this.subtitle,
    structuredData: structuredData ?? this.structuredData,
    confidence: confidence ?? this.confidence,
    saved: saved ?? this.saved,
    handled: handled ?? this.handled,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
