import 'dart:math' as math;

import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class ClassificationResult {
  const ClassificationResult({
    required this.type,
    required this.confidence,
    this.subtype,
    this.reasons = const [],
  });

  final ScreenshotType type;
  final String? subtype;
  final double confidence;
  final List<String> reasons;
}

abstract interface class ScreenshotClassifier {
  Future<ClassificationResult> classify(ProcessingContext context);
}

/// Compatibility extension point for product-specific deterministic rules.
final class ClassificationRule {
  const ClassificationRule({required this.result, required this.matches});

  final ClassificationResult result;
  final bool Function(ProcessingContext context) matches;
}

final class RuleBasedScreenshotClassifier implements ScreenshotClassifier {
  RuleBasedScreenshotClassifier([
    List<ClassificationRule> rules = const [],
    this.minimumUsefulConfidence = 0.62,
  ]) : rules = List.unmodifiable(rules);

  final List<ClassificationRule> rules;
  final double minimumUsefulConfidence;

  @override
  Future<ClassificationResult> classify(ProcessingContext context) async {
    for (final rule in rules) {
      if (rule.matches(context)) return rule.result;
    }

    final text = context.ocrText.toLowerCase();
    final scores = <_Candidate>[
      _event(text, context.entities),
      _coupon(text, context.entities),
      _conversation(text, context.entities),
      _order(text, context.entities),
      _product(text, context.entities),
      _place(text, context.entities),
    ]..sort((a, b) => b.score.compareTo(a.score));
    final best = scores.first;
    if (best.score >= minimumUsefulConfidence) {
      return ClassificationResult(
        type: best.type,
        subtype: '${best.type.value}.deterministic',
        confidence: math.min(0.97, best.score),
        reasons: List.unmodifiable(best.reasons),
      );
    }

    final usefulText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (usefulText.length >= 20) {
      return ClassificationResult(
        type: ScreenshotType.reference,
        subtype: 'reference.unclassified',
        confidence: math.max(0.35, best.score),
        reasons: const [
          'Text was recognized but no useful category had enough evidence.',
        ],
      );
    }
    return const ClassificationResult(
      type: ScreenshotType.other,
      subtype: 'other.low-signal',
      confidence: 0.25,
      reasons: ['Not enough reliable text or structured evidence.'],
    );
  }

  static _Candidate _event(String text, List<ExtractedEntity> entities) {
    final candidate = _Candidate(ScreenshotType.event);
    candidate.entity(entities, EntityType.date, 0.25, 'A date was found.');
    candidate.entity(entities, EntityType.time, 0.17, 'A time was found.');
    candidate.keywords(
      text,
      const [
        'concert',
        'concierto',
        'festival',
        'event',
        'evento',
        'ticket',
        'entrada',
        'doors open',
        'apertura de puertas',
        'show',
        'función',
        'funcion',
      ],
      0.34,
      'Event language was found.',
    );
    candidate.keywords(
      text,
      const ['venue', 'auditorium', 'teatro', 'stadium', 'estadio', 'sala'],
      0.18,
      'Venue-like text was found.',
    );
    return candidate;
  }

  static _Candidate _coupon(String text, List<ExtractedEntity> entities) {
    final candidate = _Candidate(ScreenshotType.coupon);
    candidate.entity(
      entities,
      EntityType.percentage,
      0.27,
      'A percentage discount was found.',
    );
    candidate.entity(
      entities,
      EntityType.couponCode,
      0.34,
      'A coupon-like code was found.',
    );
    candidate.keywords(
      text,
      const [
        'coupon',
        'cupón',
        'cupon',
        'promo code',
        'código promocional',
        'codigo promocional',
        'discount',
        'descuento',
        'off',
      ],
      0.34,
      'Coupon or discount language was found.',
    );
    candidate.keywords(
      text,
      const [
        'expires',
        'expiry',
        'valid until',
        'vence',
        'caduca',
        'válido hasta',
      ],
      0.14,
      'Expiry language was found.',
    );
    return candidate;
  }

  static _Candidate _conversation(String text, List<ExtractedEntity> entities) {
    final candidate = _Candidate(ScreenshotType.conversationTask);
    candidate.keywords(
      text,
      const [
        'remind me to',
        'remember to',
        'don\'t forget to',
        'we need to',
        'tenemos que',
        'acuérdate de',
        'acuerdate de',
        'recuérdame',
        'recuerdame',
        'no te olvides de',
        'hay que',
      ],
      0.68,
      'A reminder or commitment phrase was found.',
    );
    candidate.entity(
      entities,
      EntityType.date,
      0.1,
      'The task includes a date.',
    );
    candidate.entity(
      entities,
      EntityType.time,
      0.08,
      'The task includes a time.',
    );
    return candidate;
  }

  static _Candidate _order(String text, List<ExtractedEntity> entities) {
    final candidate = _Candidate(ScreenshotType.order);
    candidate.entity(
      entities,
      EntityType.orderCode,
      0.36,
      'An order number was found.',
    );
    candidate.entity(
      entities,
      EntityType.trackingCode,
      0.38,
      'A tracking number was found.',
    );
    candidate.keywords(
      text,
      const [
        'order',
        'pedido',
        'tracking',
        'seguimiento',
        'shipment',
        'envío',
        'envio',
        'delivery',
        'entrega',
        'shipped',
        'enviado',
      ],
      0.38,
      'Order, shipment, or delivery language was found.',
    );
    return candidate;
  }

  static _Candidate _product(String text, List<ExtractedEntity> entities) {
    final candidate = _Candidate(ScreenshotType.product);
    candidate.entity(entities, EntityType.money, 0.28, 'A price was found.');
    candidate.entity(
      entities,
      EntityType.url,
      0.1,
      'A product URL may be present.',
    );
    candidate.keywords(
      text,
      const [
        'add to cart',
        'buy now',
        'in stock',
        'out of stock',
        'añadir al carrito',
        'comprar ahora',
        'en stock',
        'producto',
        'product',
      ],
      0.42,
      'Shopping or product language was found.',
    );
    return candidate;
  }

  static _Candidate _place(String text, List<ExtractedEntity> entities) {
    final candidate = _Candidate(ScreenshotType.place);
    candidate.keywords(
      text,
      const [
        'restaurant',
        'restaurante',
        'café',
        'cafe',
        'bar',
        'hotel',
        'museum',
        'museo',
        'address',
        'dirección',
        'direccion',
        'open now',
        'abierto ahora',
      ],
      0.46,
      'Place or address language was found.',
    );
    candidate.keywords(
      text,
      const ['maps', 'cómo llegar', 'como llegar', 'directions', 'km away'],
      0.28,
      'Map or directions language was found.',
    );
    candidate.entity(
      entities,
      EntityType.phone,
      0.08,
      'A business phone number was found.',
    );
    return candidate;
  }
}

final class _Candidate {
  _Candidate(this.type);

  final ScreenshotType type;
  double score = 0;
  final List<String> reasons = [];

  void entity(
    List<ExtractedEntity> entities,
    EntityType type,
    double weight,
    String reason,
  ) {
    if (entities.any((entity) => entity.type == type)) {
      score += weight;
      reasons.add(reason);
    }
  }

  void keywords(
    String text,
    List<String> values,
    double weight,
    String reason,
  ) {
    if (values.any(text.contains)) {
      score += weight;
      reasons.add(reason);
    }
  }
}
