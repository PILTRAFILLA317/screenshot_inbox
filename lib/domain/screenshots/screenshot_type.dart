/// Extensible value object. New types do not require changing a central enum.
final class ScreenshotType {
  const ScreenshotType(this.value);

  final String value;

  static const unknown = ScreenshotType('unknown');
  static const generic = ScreenshotType('generic');
  static const event = ScreenshotType('event');
  static const coupon = ScreenshotType('coupon');
  static const product = ScreenshotType('product');
  static const place = ScreenshotType('place');
  static const order = ScreenshotType('order');
  static const conversationTask = ScreenshotType('conversationTask');
  static const reference = ScreenshotType('reference');
  static const other = ScreenshotType('other');

  /// Kept for rows created by the architecture prototype.
  static const conversation = ScreenshotType('conversation');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScreenshotType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
