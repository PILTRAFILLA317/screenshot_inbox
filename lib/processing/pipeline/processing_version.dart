/// Bump only when persisted OCR/parser/intelligence output must be regenerated.
abstract final class ProcessingVersion {
  static const current = 3;
  static const ocr = 2;
  static const classifier = 2;
  static const parser = 2;
  static const intelligence = 2;
}
