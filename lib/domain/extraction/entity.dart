import 'package:screenshot_inbox/core/utils/json_types.dart';

final class EntityType {
  const EntityType(this.value);

  final String value;

  static const date = EntityType('date');
  static const time = EntityType('time');
  static const url = EntityType('url');
  static const email = EntityType('email');
  static const phone = EntityType('phone');
  static const money = EntityType('money');
  static const percentage = EntityType('percentage');
  static const place = EntityType('place');
  static const person = EntityType('person');
  static const merchant = EntityType('merchant');
  static const product = EntityType('product');
  static const orderCode = EntityType('orderCode');
  static const trackingCode = EntityType('trackingCode');
  static const couponCode = EntityType('couponCode');
  static const qr = EntityType('qr');
  static const other = EntityType('other');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EntityType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class ExtractedEntity {
  const ExtractedEntity({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.rawValue,
    required this.normalizedValue,
    required this.confidence,
    this.metadata = const {},
  });

  final String id;
  final String screenshotId;
  final EntityType type;
  final String rawValue;
  final String normalizedValue;
  final double confidence;
  final JsonMap metadata;
}
