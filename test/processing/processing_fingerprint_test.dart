import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_fingerprint.dart';

void main() {
  const current = ProcessingFingerprint(
    ocrVersion: 2,
    classifierVersion: 2,
    parserVersion: 2,
    intelligenceVersion: 1,
  );

  test('same asset and stage versions reuse fast and deep cache', () {
    final fast = current.fastFor('asset');

    expect(current.fastFor('asset'), fast);
    expect(current.deepFor(fast), current.deepFor(fast));
  });

  test('intelligence change reuses OCR but invalidates only deep analysis', () {
    const changed = ProcessingFingerprint(
      ocrVersion: 2,
      classifierVersion: 2,
      parserVersion: 2,
      intelligenceVersion: 2,
    );
    final currentFast = current.fastFor('asset');
    final changedFast = changed.fastFor('asset');

    expect(changedFast, currentFast);
    expect(changed.deepFor(changedFast), isNot(current.deepFor(currentFast)));
  });

  test(
    'parser change invalidates interpretation while UI and clock do not',
    () {
      const changedParser = ProcessingFingerprint(
        ocrVersion: 2,
        classifierVersion: 2,
        parserVersion: 3,
        intelligenceVersion: 1,
      );

      expect(changedParser.fastFor('asset'), isNot(current.fastFor('asset')));
      expect(
        current.fastFor('asset'),
        current.fastFor('asset'),
        reason: 'UI and lifecycle clocks are absent from the fingerprint.',
      );
    },
  );
}
