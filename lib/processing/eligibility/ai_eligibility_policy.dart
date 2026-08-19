import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

enum AIEligibilityReason {
  actionableType,
  ambiguousClassification,
  multipleDateCandidates,
  multiplePriceCandidates,
  missingImportantFields,
  conflictingDeterministicFields,
  commerceTypeAmbiguity,
  noisyPlaceUi,
  explicitFutureTask,
  forcedByDebugPolicy,
}

enum AIEligibilityMode { selective, disabled, allSupported }

final class AIEligibility {
  const AIEligibility({required this.needsAI, this.reasons = const []});

  final bool needsAI;
  final List<AIEligibilityReason> reasons;
}

abstract interface class AIEligibilityPolicy {
  AIEligibility evaluate(ProcessingContext context, ParseResult deterministic);
}

final class DefaultAIEligibilityPolicy implements AIEligibilityPolicy {
  DefaultAIEligibilityPolicy({this.mode = AIEligibilityMode.selective});

  AIEligibilityMode mode;

  @override
  AIEligibility evaluate(ProcessingContext context, ParseResult deterministic) {
    final classification = context.classification;
    final type = classification?.type ?? ScreenshotType.unknown;
    final entities = context.entities;
    final reasons = <AIEligibilityReason>{};
    final actionable = _actionableTypes.contains(type.value);

    if (mode == AIEligibilityMode.disabled) {
      return const AIEligibility(needsAI: false);
    }
    if (mode == AIEligibilityMode.allSupported &&
        _supportedTypes.contains(type.value)) {
      reasons.add(AIEligibilityReason.forcedByDebugPolicy);
    }
    if (actionable) reasons.add(AIEligibilityReason.actionableType);
    if ((classification?.confidence ?? 0) < 0.76 && actionable) {
      reasons.add(AIEligibilityReason.ambiguousClassification);
    }

    final dates = entities.where((item) => item.type == EntityType.date).length;
    final prices = entities
        .where((item) => item.type == EntityType.money)
        .length;
    if (dates > 1 &&
        (type == ScreenshotType.event ||
            type == ScreenshotType.coupon ||
            type == ScreenshotType.reference)) {
      reasons.add(AIEligibilityReason.multipleDateCandidates);
    }
    if (prices > 1 &&
        (type == ScreenshotType.product || type == ScreenshotType.order)) {
      reasons.add(AIEligibilityReason.multiplePriceCandidates);
    }

    final text = context.ocrText.toLowerCase();
    final hasCommerceLanguage = _commerceLanguage.hasMatch(text);
    final hasOrderEvidence = entities.any(
      (item) =>
          item.type == EntityType.orderCode ||
          item.type == EntityType.trackingCode,
    );
    if (hasCommerceLanguage &&
        (type == ScreenshotType.product || type == ScreenshotType.order) &&
        !hasOrderEvidence) {
      reasons.add(AIEligibilityReason.commerceTypeAmbiguity);
    }

    if (type == ScreenshotType.place &&
        context.ocrAnalysis.uiNoiseCandidates.length >= 2) {
      reasons.add(AIEligibilityReason.noisyPlaceUi);
    }
    if (type == ScreenshotType.conversationTask &&
        _futureTaskLanguage.hasMatch(text)) {
      reasons.add(AIEligibilityReason.explicitFutureTask);
    }

    if (!actionable && _latentEventLanguage.hasMatch(text)) {
      reasons.add(AIEligibilityReason.ambiguousClassification);
    }
    if (!actionable &&
        _latentCouponLanguage.hasMatch(text) &&
        entities.any(
          (item) =>
              item.type == EntityType.percentage ||
              item.type == EntityType.money ||
              item.type == EntityType.date,
        )) {
      reasons.add(AIEligibilityReason.ambiguousClassification);
    }
    if (!actionable &&
        hasCommerceLanguage &&
        (entities.any((item) => item.type == EntityType.money) ||
            _strongCommerceLanguage.hasMatch(text))) {
      reasons.add(AIEligibilityReason.commerceTypeAmbiguity);
    }
    if (!actionable && _latentPlaceLanguage.hasMatch(text)) {
      reasons.add(AIEligibilityReason.noisyPlaceUi);
    }
    if (!actionable && _futureTaskLanguage.hasMatch(text)) {
      reasons.add(AIEligibilityReason.explicitFutureTask);
    }

    final object = deterministic.objects.firstOrNull;
    if (actionable &&
        (object == null || object.confidence < 0.72 || object.title.isEmpty)) {
      reasons.add(AIEligibilityReason.missingImportantFields);
    }

    final latentActionable = reasons.isNotEmpty;
    final strongNoAi =
        (!actionable && _isSimpleQrUrl(context)) ||
        (!actionable &&
            !latentActionable &&
            (type == ScreenshotType.reference || type == ScreenshotType.other));
    if (strongNoAi &&
        !reasons.contains(AIEligibilityReason.forcedByDebugPolicy)) {
      return const AIEligibility(needsAI: false);
    }
    return AIEligibility(
      needsAI: reasons.isNotEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  static bool _isSimpleQrUrl(ProcessingContext context) {
    final qr = context.entities.where((item) => item.type == EntityType.qr);
    final urls = context.entities.where((item) => item.type == EntityType.url);
    return qr.length == 1 && urls.length == 1 && context.ocrText.length < 120;
  }

  static final _commerceLanguage = RegExp(
    r'\b(?:order|pedido|delivery|entrega|shipment|env[ií]o|buy now|comprar|add to cart|carrito|in stock|sold by|vendido por|only \d+ left|reviews?)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _strongCommerceLanguage = RegExp(
    r'\b(?:buy now|comprar|add to cart|carrito|in stock|sold by|vendido por|only \d+ left|reviews?)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _latentEventLanguage = RegExp(
    r'\b(?:ticket|entradas?|concert|concierto|festival|event|evento|venue|arena|stadium|estadio|teatro|palau|centre|center|presale|puerta)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _latentCouponLanguage = RegExp(
    r'\b(?:coupon|cup[oó]n|discount|descuento|off|offer|oferta|valid through|v[aá]lido hasta|hasta el|expires?|ends?)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _latentPlaceLanguage = RegExp(
    r'\b(?:restaurant|restaurante|museum|museo|maps?|directions|c[oó]mo llegar|save this spot|calle|street|avenue|road|plaza|yard|village)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _futureTaskLanguage = RegExp(
    r'\b(?:remind|remember|don.t forget|need to|tomorrow|next week|acu[eé]rdate|recu[eé]rdame|no te olvides|tenemos (?:que|q)|ma[nñ]ana)\b',
    caseSensitive: false,
    unicode: true,
  );
  static const _actionableTypes = {
    'event',
    'coupon',
    'place',
    'product',
    'order',
    'conversationTask',
  };
  static const _supportedTypes = {
    ..._actionableTypes,
    'reference',
    'other',
    'generic',
  };
}
