enum ProcessingImagePurpose { thumbnail, ocr, localAI }

final class ProcessingImageSpec {
  const ProcessingImageSpec({
    required this.maxDimension,
    required this.jpegQuality,
  });

  final int maxDimension;
  final int jpegQuality;
}

/// One tuning point for every image representation used by the app.
final class ProcessingImagePolicy {
  const ProcessingImagePolicy({
    this.thumbnail = const ProcessingImageSpec(
      maxDimension: 512,
      jpegQuality: 86,
    ),
    this.ocr = const ProcessingImageSpec(maxDimension: 1800, jpegQuality: 92),
    this.localAI = const ProcessingImageSpec(
      maxDimension: 1280,
      jpegQuality: 88,
    ),
  });

  final ProcessingImageSpec thumbnail;
  final ProcessingImageSpec ocr;
  final ProcessingImageSpec localAI;

  ProcessingImageSpec forPurpose(ProcessingImagePurpose purpose) =>
      switch (purpose) {
        ProcessingImagePurpose.thumbnail => thumbnail,
        ProcessingImagePurpose.ocr => ocr,
        ProcessingImagePurpose.localAI => localAI,
      };
}
