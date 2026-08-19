import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/processing/entities/temporal_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

abstract interface class EntityExtractor {
  Future<List<ExtractedEntity>> extract(ProcessingContext context);
}

final class RegexEntityExtractor implements EntityExtractor {
  RegexEntityExtractor(this._ids, {TemporalParser? temporalParser})
    : _temporal = temporalParser ?? const TemporalParser();

  final IdGenerator _ids;
  final TemporalParser _temporal;

  static final _url = RegExp(
    r'\b(?:https?://|www\.)[^\s<>()]+',
    caseSensitive: false,
  );
  static final _email = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final _phone = RegExp(
    r'(?<![\w])(?:\+?\d{1,3}[\s.-]?)?(?:\(?\d{2,4}\)?[\s.-]?)?\d{3}[\s.-]?\d{3,4}(?![\w])',
  );
  static final _percentage = RegExp(r'\b\d{1,3}(?:[.,]\d+)?\s?%');
  static final _money = RegExp(
    r'(?:[$€£]\s?\d[\d.,]*|\b\d[\d.,]*\s?(?:EUR|USD|GBP)\b)',
    caseSensitive: false,
  );
  static final _couponLabel = RegExp(
    r'\b(?:coupon(?:\s+code)?|promo(?:\s+code)?|discount|descuento|cup[oó]n|c[oó]digo(?:\s+promocional)?|code)\b\s*[:#-]\s*([A-Z0-9][A-Z0-9_-]{3,19})',
    caseSensitive: false,
    unicode: true,
  );
  static final _orderLabel = RegExp(
    r'(?:order|pedido|orden)\s*(?:number|n[úu]mero|no\.?|#)?\s*[:#-]?\s*([A-Z0-9][A-Z0-9-]{3,24})',
    caseSensitive: false,
    unicode: true,
  );
  static final _trackingLabel = RegExp(
    r'(?:tracking|seguimiento|shipment|env[ií]o|gu[ií]a)\s*(?:number|n[úu]mero|no\.?|#)?\s*[:#-]?\s*([A-Z0-9][A-Z0-9-]{5,30})',
    caseSensitive: false,
    unicode: true,
  );

  @override
  Future<List<ExtractedEntity>> extract(ProcessingContext context) async {
    final entities = <ExtractedEntity>[];
    final seen = <String>{};

    void add(
      EntityType type,
      String raw,
      String normalized,
      double confidence, {
      Map<String, Object?> metadata = const {},
    }) {
      final clean = normalized.trim();
      if (clean.isEmpty || !seen.add('${type.value}:${clean.toLowerCase()}')) {
        return;
      }
      final blockIds = _evidenceFor(context, raw);
      entities.add(
        ExtractedEntity(
          id: _ids.next(),
          screenshotId: context.screenshot.id,
          type: type,
          rawValue: raw,
          normalizedValue: clean,
          confidence: confidence,
          metadata: {
            ...metadata,
            if (blockIds.isNotEmpty) 'blockIds': blockIds,
          },
        ),
      );
    }

    final text = context.ocrText;
    for (final match in _url.allMatches(text)) {
      final raw = match.group(0)!;
      final withoutPunctuation = raw.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
      add(
        EntityType.url,
        raw,
        withoutPunctuation.startsWith('www.')
            ? 'https://$withoutPunctuation'
            : withoutPunctuation,
        0.97,
        metadata: {'source': 'ocr'},
      );
    }
    for (final match in _email.allMatches(text)) {
      add(
        EntityType.email,
        match.group(0)!,
        match.group(0)!.toLowerCase(),
        0.97,
      );
    }
    for (final match in _phone.allMatches(text)) {
      final raw = match.group(0)!;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 7 && digits.length <= 15) {
        add(EntityType.phone, raw, raw.trim(), 0.78);
      }
    }
    for (final match in _percentage.allMatches(text)) {
      add(
        EntityType.percentage,
        match.group(0)!,
        match.group(0)!.replaceAll(' ', ''),
        0.96,
      );
    }
    for (final match in _money.allMatches(text)) {
      add(EntityType.money, match.group(0)!, match.group(0)!.trim(), 0.92);
    }
    for (final match in _temporal.dates(text, context.screenshot.createdAt)) {
      add(
        EntityType.date,
        match.raw,
        match.normalized,
        match.confidence,
        metadata: {'start': match.start, 'end': match.end},
      );
    }
    for (final match in _temporal.times(text)) {
      add(
        EntityType.time,
        match.raw,
        match.normalized,
        match.confidence,
        metadata: {'start': match.start, 'end': match.end},
      );
    }
    _extractLabeledCode(_couponLabel, text, EntityType.couponCode, add, 0.9);
    _extractLabeledCode(_orderLabel, text, EntityType.orderCode, add, 0.94);
    _extractLabeledCode(
      _trackingLabel,
      text,
      EntityType.trackingCode,
      add,
      0.94,
    );

    for (final barcode in context.barcodes) {
      add(
        barcode.format == 'qrCode' ? EntityType.qr : EntityType.barcode,
        barcode.rawValue,
        barcode.rawValue,
        0.99,
        metadata: {
          'format': barcode.format,
          'valueType': barcode.valueType,
          ...barcode.payload,
        },
      );
      final barcodeUrl = barcode.payload['url'];
      if (barcodeUrl is String) {
        add(
          EntityType.url,
          barcodeUrl,
          barcodeUrl,
          0.99,
          metadata: {'source': 'barcode'},
        );
      }
      final barcodeEmail = barcode.payload['email'];
      if (barcodeEmail is String) {
        add(EntityType.email, barcodeEmail, barcodeEmail.toLowerCase(), 0.99);
      }
      final barcodePhone = barcode.payload['phone'];
      if (barcodePhone is String) {
        add(EntityType.phone, barcodePhone, barcodePhone, 0.99);
      }
    }

    return entities;
  }

  static void _extractLabeledCode(
    RegExp pattern,
    String text,
    EntityType type,
    void Function(
      EntityType type,
      String raw,
      String normalized,
      double confidence, {
      Map<String, Object?> metadata,
    })
    add,
    double confidence,
  ) {
    for (final match in pattern.allMatches(text)) {
      final value = match.group(1)!;
      if (!_looksLikeCode(value)) continue;
      add(type, value, value.toUpperCase(), confidence);
    }
  }

  static bool _looksLikeCode(String value) {
    if (value.length < 4 || value.length > 32) return false;
    final lower = value.toLowerCase();
    const stopWords = {
      'code',
      'codigo',
      'coupon',
      'order',
      'pedido',
      'number',
      'numero',
      'tracking',
    };
    return !stopWords.contains(lower) && RegExp(r'[A-Za-z]').hasMatch(value);
  }

  static List<String> _evidenceFor(ProcessingContext context, String raw) {
    final needle = raw.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return [
      for (final block in context.recognizedText.blocks)
        if (block.id.isNotEmpty && block.text.toLowerCase().contains(needle))
          block.id,
    ];
  }
}
