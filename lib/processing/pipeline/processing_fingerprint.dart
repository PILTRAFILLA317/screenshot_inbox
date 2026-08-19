/// Stage-specific versions deliberately avoid invalidating OCR when only the
/// local-intelligence prompt or validation schema changes.
final class ProcessingFingerprint {
  const ProcessingFingerprint({
    required this.ocrVersion,
    required this.classifierVersion,
    required this.parserVersion,
    required this.intelligenceVersion,
  });

  final int ocrVersion;
  final int classifierVersion;
  final int parserVersion;
  final int intelligenceVersion;

  String fastFor(String assetFingerprint) =>
      '$assetFingerprint|ocr:$ocrVersion|classifier:$classifierVersion|parser:$parserVersion';

  String deepFor(String fastFingerprint) =>
      '$fastFingerprint|intelligence:$intelligenceVersion';
}
