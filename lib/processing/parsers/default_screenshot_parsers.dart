import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/entities/temporal_parser.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class EventParser extends _TypedParser {
  EventParser(super.ids, super.clock);

  @override
  String get id => 'event.v1';

  @override
  Set<ScreenshotType> get supportedTypes => {ScreenshotType.event};

  @override
  ExtractedObject build(ProcessingContext context) {
    final date = entityAwayFromKeywords(context, EntityType.date, const [
      'purchased',
      'purchase',
      'bought',
      'comprado',
      'compra',
    ], fallbackToFirst: false)?.normalizedValue;
    final time = entity(context, EntityType.time)?.normalizedValue;
    final startsAt = const TemporalParser().combine(date, time);
    final venue =
        labeledValue(context.ocrText, const [
          'venue',
          'lugar',
          'ubicación',
          'ubicacion',
        ]) ??
        lineWithCue(context, _TypedParser._venueCue);
    final city =
        labeledValue(context.ocrText, const ['city', 'ciudad']) ??
        lineAfter(context, venue, reject: _TypedParser._nonCityCue);
    return object(
      context,
      type: ExtractedObjectType.event,
      title: eventTitle(context),
      subtitle: venue,
      data: {
        'date': ?date,
        'time': ?time,
        if (startsAt != null) 'startsAt': startsAt.toIso8601String(),
        'venue': ?venue,
        'city': ?city,
      },
    );
  }
}

final class CouponParser extends _TypedParser {
  CouponParser(super.ids, super.clock);

  @override
  String get id => 'coupon.v1';

  @override
  Set<ScreenshotType> get supportedTypes => {ScreenshotType.coupon};

  @override
  ExtractedObject build(ProcessingContext context) {
    final merchant = usefulTitle(context, ignored: _TypedParser._couponNoise);
    final discount = entity(context, EntityType.percentage)?.normalizedValue;
    final code =
        entity(context, EntityType.couponCode)?.normalizedValue ??
        standaloneCode(context);
    final expiry = _dateNear(context, const [
      'expires',
      'expiry',
      'valid until',
      'vence',
      'caduca',
      'válido',
    ]);
    return object(
      context,
      type: ExtractedObjectType.coupon,
      title: discount == null ? merchant : '$merchant · $discount off',
      subtitle: code == null ? null : 'Code $code',
      data: {
        if (merchant != 'Coupon') 'merchant': merchant,
        'discount': ?discount,
        'couponCode': ?code,
        if (expiry != null) ...{
          'expiryDate': expiry,
          'expiresAt': DateTime.parse(expiry).toUtc().toIso8601String(),
        },
      },
      fallbackTitle: 'Coupon',
    );
  }
}

final class ConversationTaskParser extends _TypedParser {
  ConversationTaskParser(super.ids, super.clock);

  @override
  String get id => 'conversation-task.v1';

  @override
  Set<ScreenshotType> get supportedTypes => {
    ScreenshotType.conversationTask,
    ScreenshotType.conversation,
  };

  @override
  ExtractedObject build(ProcessingContext context) {
    final line = lines(context).firstWhere(
      _TypedParser._taskCue.hasMatch,
      orElse: () => usefulTitle(context),
    );
    final task = line.replaceFirst(_TypedParser._taskPrefix, '').trim();
    final date = entity(context, EntityType.date)?.normalizedValue;
    final time = entity(context, EntityType.time)?.normalizedValue;
    final at = const TemporalParser().combine(date, time);
    final allLines = lines(context);
    final person = allLines.isNotEmpty && allLines.first != line
        ? _shortPerson(allLines.first)
        : null;
    return object(
      context,
      type: ExtractedObjectType.conversationTask,
      title: task.isEmpty ? line : task,
      subtitle: person,
      data: {
        'task': task.isEmpty ? line : task,
        'date': ?date,
        'time': ?time,
        if (at != null) 'remindAt': at.toUtc().toIso8601String(),
        'person': ?person,
        'sourceText': line,
      },
      fallbackTitle: 'Conversation task',
    );
  }
}

final class OrderParser extends _TypedParser {
  OrderParser(super.ids, super.clock);

  @override
  String get id => 'order.v1';

  @override
  Set<ScreenshotType> get supportedTypes => {ScreenshotType.order};

  @override
  ExtractedObject build(ProcessingContext context) {
    final merchant = usefulTitle(context, ignored: _TypedParser._orderNoise);
    final order = entity(context, EntityType.orderCode)?.normalizedValue;
    final tracking = entity(context, EntityType.trackingCode)?.normalizedValue;
    final delivery = _dateNear(context, const [
      'delivery',
      'arrives',
      'delivered by',
      'entrega',
      'llega',
    ]);
    final url = entity(context, EntityType.url)?.normalizedValue;
    return object(
      context,
      type: ExtractedObjectType.order,
      title: merchant,
      subtitle: tracking == null ? null : 'Tracking $tracking',
      data: {
        if (merchant != 'Order') 'merchant': merchant,
        'orderNumber': ?order,
        'trackingNumber': ?tracking,
        'deliveryDate': ?delivery,
        'url': ?url,
      },
      fallbackTitle: 'Order',
    );
  }
}

final class ProductParser extends _TypedParser {
  ProductParser(super.ids, super.clock);

  @override
  String get id => 'product.v1';

  @override
  Set<ScreenshotType> get supportedTypes => {ScreenshotType.product};

  @override
  ExtractedObject build(ProcessingContext context) {
    final name = usefulTitle(context, ignored: _TypedParser._productNoise);
    final price = entityAwayFromKeywords(context, EntityType.money, const [
      'was',
      'before',
      'shipping',
      'delivery',
      'antes',
      'envío',
      'envio',
    ])?.normalizedValue;
    final url = entity(context, EntityType.url)?.normalizedValue;
    final merchant = labeledValue(context.ocrText, const [
      'sold by',
      'seller',
      'vendido por',
      'tienda',
    ]);
    return object(
      context,
      type: ExtractedObjectType.product,
      title: name,
      subtitle: price,
      data: {
        if (name != 'Product') 'productName': name,
        'price': ?price,
        'merchant': ?merchant,
        'url': ?url,
      },
      fallbackTitle: 'Product',
    );
  }
}

final class PlaceParser extends _TypedParser {
  PlaceParser(super.ids, super.clock);

  @override
  String get id => 'place.v1';

  @override
  Set<ScreenshotType> get supportedTypes => {ScreenshotType.place};

  @override
  ExtractedObject build(ProcessingContext context) {
    final name = usefulTitle(context, ignored: _TypedParser._placeNoise);
    final address =
        labeledValue(context.ocrText, const [
          'address',
          'dirección',
          'direccion',
        ]) ??
        _address(context.ocrText);
    final city = labeledValue(context.ocrText, const ['city', 'ciudad']);
    return object(
      context,
      type: ExtractedObjectType.place,
      title: name,
      subtitle: address ?? city,
      data: {
        if (name != 'Place') 'name': name,
        'address': ?address,
        'city': ?city,
        if (address != null || name != 'Place')
          'mapsQuery': [name, address, city].whereType<String>().join(', '),
      },
      fallbackTitle: 'Place',
    );
  }
}

abstract base class _TypedParser implements ScreenshotParser {
  _TypedParser(this.ids, this.clock);

  final IdGenerator ids;
  final Clock clock;

  @override
  int get priority => 100;

  @override
  bool canParse(ProcessingContext context) => context.ocrText.trim().isNotEmpty;

  ExtractedObject build(ProcessingContext context);

  @override
  Future<ParseResult> parse(ProcessingContext context) async =>
      ParseResult(objects: [build(context)]);

  ExtractedObject object(
    ProcessingContext context, {
    required ExtractedObjectType type,
    required String title,
    required Map<String, Object?> data,
    String? subtitle,
    String fallbackTitle = 'Screenshot',
  }) {
    final now = clock.now();
    final cleanTitle = title.trim().isEmpty ? fallbackTitle : title.trim();
    return ExtractedObject(
      id: ids.next(),
      screenshotId: context.screenshot.id,
      type: type,
      subtype: context.classification?.subtype ?? '${type.value}.deterministic',
      title: cleanTitle,
      subtitle: subtitle,
      structuredData: {
        ...data,
        '_parserId': id,
        '_fieldMetadata': {
          'title': _deterministicField(context, cleanTitle),
          for (final entry in data.entries)
            if (entry.value != null)
              entry.key: _deterministicField(context, entry.value),
        },
        'classificationReasons': context.classification?.reasons ?? const [],
        'entityIds': context.entities.map((entity) => entity.id).toList(),
      },
      confidence: context.classification?.confidence ?? 0.5,
      saved: false,
      handled: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  ExtractedEntity? entity(ProcessingContext context, EntityType type) {
    for (final entity in context.entities) {
      if (entity.type == type) return entity;
    }
    return null;
  }

  ExtractedEntity? entityAwayFromKeywords(
    ProcessingContext context,
    EntityType type,
    List<String> keywords, {
    bool fallbackToFirst = true,
  }) {
    final candidates = context.entities
        .where((item) => item.type == type)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    final lower = context.ocrText.toLowerCase();
    for (final candidate in candidates) {
      final start = candidate.metadata['start'];
      if (start is! int) return candidate;
      final from = (start - 32).clamp(0, lower.length);
      final to = (start + candidate.rawValue.length + 32).clamp(
        0,
        lower.length,
      );
      final nearby = lower.substring(from, to);
      if (!keywords.any(nearby.contains)) return candidate;
    }
    return fallbackToFirst ? candidates.first : null;
  }

  List<String> lines(ProcessingContext context) => context.ocrText
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.length >= 2)
      .toList(growable: false);

  String usefulTitle(
    ProcessingContext context, {
    List<String> ignored = const [],
  }) {
    for (final line in lines(context)) {
      final lower = line.toLowerCase();
      if (line.length > 80 ||
          ignored.any(lower.contains) ||
          RegExp(r'^(https?://|www\.|\d{1,2}[:/.\-])').hasMatch(lower)) {
        continue;
      }
      return line;
    }
    return lines(context).firstOrNull ?? 'Screenshot';
  }

  String eventTitle(ProcessingContext context) {
    final all = lines(context);
    for (final line in all) {
      final lower = line.toLowerCase();
      if (_eventNoise.any(lower.contains) ||
          _navigationNoise.contains(lower) ||
          _venueCue.hasMatch(line) ||
          line.length > 70 ||
          RegExp(r'\d').hasMatch(line)) {
        continue;
      }
      return line;
    }
    return usefulTitle(context, ignored: _eventNoise);
  }

  String? standaloneCode(ProcessingContext context) {
    final values = lines(context);
    for (var index = 0; index < values.length; index++) {
      final line = values[index];
      if (!RegExp(r'^[A-Z0-9][A-Z0-9_-]{3,19}$').hasMatch(line) ||
          !RegExp(r'[A-Z]').hasMatch(line) ||
          !RegExp(r'\d').hasMatch(line)) {
        continue;
      }
      final neighborhood = values
          .skip((index - 2).clamp(0, values.length))
          .take(5)
          .join(' ')
          .toLowerCase();
      if (RegExp(
        r'coupon|promo|discount|descuento|cup[oó]n|off|code|c[oó]digo',
        unicode: true,
      ).hasMatch(neighborhood)) {
        return line;
      }
    }
    return null;
  }

  String? lineWithCue(ProcessingContext context, RegExp cue) {
    for (final line in lines(context)) {
      if (cue.hasMatch(line)) return line;
    }
    return null;
  }

  String? lineAfter(
    ProcessingContext context,
    String? anchor, {
    required RegExp reject,
  }) {
    if (anchor == null) return null;
    final all = lines(context);
    final index = all.indexOf(anchor);
    if (index < 0 || index + 1 >= all.length) return null;
    final candidate = all[index + 1];
    if (candidate.length > 45 ||
        RegExp(r'\d').hasMatch(candidate) ||
        reject.hasMatch(candidate)) {
      return null;
    }
    return candidate;
  }

  String? labeledValue(String text, List<String> labels) {
    for (final line in text.split('\n')) {
      final clean = line.trim();
      final lower = clean.toLowerCase();
      for (final label in labels) {
        final index = lower.indexOf(label);
        if (index < 0) continue;
        final value = clean
            .substring(index + label.length)
            .replaceFirst(RegExp(r'^\s*[:\-–]\s*'), '')
            .trim();
        if (value.length >= 2 && value.length <= 100) return value;
      }
    }
    return null;
  }

  String? _dateNear(ProcessingContext context, List<String> keywords) {
    final dates = context.entities
        .where((entity) => entity.type == EntityType.date)
        .toList();
    if (dates.isEmpty) return null;
    final lower = context.ocrText.toLowerCase();
    final positions = <int>[
      for (final keyword in keywords)
        for (
          var position = lower.indexOf(keyword);
          position >= 0;
          position = lower.indexOf(keyword, position + keyword.length)
        )
          position,
    ];
    if (positions.isEmpty) return null;
    dates.sort((a, b) {
      int distance(ExtractedEntity entity) {
        final start = entity.metadata['start'];
        if (start is! int) return 1 << 30;
        return positions
            .map((position) => (start - position).abs())
            .reduce((left, right) => left < right ? left : right);
      }

      return distance(a).compareTo(distance(b));
    });
    return dates.first.normalizedValue;
  }

  Map<String, Object?> _deterministicField(
    ProcessingContext context,
    Object? value,
  ) {
    final text = value?.toString().toLowerCase() ?? '';
    final evidence = [
      for (final block in context.recognizedText.blocks)
        if (block.id.isNotEmpty && block.text.toLowerCase().contains(text))
          block.id,
    ];
    return {
      'source': 'machineDeterministic',
      'confidence': context.classification?.confidence ?? 0.5,
      'confidenceBasis': 'heuristic',
      'evidence': evidence,
    };
  }

  String? _shortPerson(String value) {
    final clean = value.trim();
    if (clean.length < 2 ||
        clean.length > 35 ||
        RegExp(r'\d').hasMatch(clean)) {
      return null;
    }
    return clean;
  }

  String? _address(String text) {
    final match = RegExp(
      r'\b(?:\d{1,5}\s+)?[A-ZÁÉÍÓÚÑ][^\n,]{2,50}\s(?:Street|St\.?|Road|Rd\.?|Avenue|Ave\.?|Boulevard|Blvd\.?|Calle|Avenida|Av\.?|Plaza|Paseo)\b[^\n]*',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(text);
    return match?.group(0)?.trim();
  }

  static final _taskCue = RegExp(
    r"\b(remind me to|remember to|don't forget to|we need to|tenemos que|acu[eé]rdate de|recu[eé]rdame|no te olvides de|hay que)\b",
    caseSensitive: false,
    unicode: true,
  );
  static final _taskPrefix = RegExp(
    r"^.*?\b(remind me to|remember to|don't forget to|we need to|tenemos que|acu[eé]rdate de|recu[eé]rdame|no te olvides de|hay que)\b\s*",
    caseSensitive: false,
    unicode: true,
  );

  static const _eventNoise = [
    'ticketmaster',
    'ticket',
    'entrada',
    'doors open',
    'apertura de puertas',
  ];
  static const _navigationNoise = {
    'home',
    'tickets',
    'profile',
    'back',
    'share',
  };
  static final _venueCue = RegExp(
    r'\b(stadium|estadio|arena|theatre|theater|teatro|auditorium|auditorio|metropolitano|palacio|forum|fòrum|hall|sala)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _nonCityCue = RegExp(
    r'\b(order|pedido|sector|row|fila|seat|asiento|purchased|comprado|ticket|entrada)\b',
    caseSensitive: false,
    unicode: true,
  );
  static const _couponNoise = [
    'coupon code',
    'código',
    'codigo',
    'expires',
    'vence',
    'discount',
    'descuento',
  ];
  static const _orderNoise = [
    'order #',
    'order number',
    'pedido #',
    'tracking',
    'seguimiento',
    'delivery',
    'entrega',
  ];
  static const _productNoise = [
    'add to cart',
    'buy now',
    'añadir al carrito',
    'comprar ahora',
  ];
  static const _placeNoise = [
    'directions',
    'cómo llegar',
    'como llegar',
    'open now',
    'abierto ahora',
  ];
}
