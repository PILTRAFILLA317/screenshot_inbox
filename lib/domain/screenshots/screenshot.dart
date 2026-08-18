import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';

enum ScreenshotProcessingStatus {
  discovered,
  queued,
  processing,
  processed,
  failed,
}

final class Screenshot {
  const Screenshot({
    required this.id,
    required this.assetId,
    required this.createdAt,
    required this.indexedAt,
    required this.width,
    required this.height,
    required this.processingStatus,
    required this.currentLifecycleState,
    required this.processingVersion,
    this.sizeBytes,
    this.ocrText,
    this.primaryType,
    this.primarySubtype,
    this.classificationConfidence,
    this.lastProcessedAt,
  });

  final String id;
  final String assetId;
  final DateTime createdAt;
  final DateTime indexedAt;
  final int width;
  final int height;
  final int? sizeBytes;
  final ScreenshotProcessingStatus processingStatus;
  final String? ocrText;
  final ScreenshotType? primaryType;
  final String? primarySubtype;
  final double? classificationConfidence;
  final LifecycleState currentLifecycleState;
  final DateTime? lastProcessedAt;
  final int processingVersion;

  Screenshot copyWith({
    ScreenshotProcessingStatus? processingStatus,
    String? ocrText,
    ScreenshotType? primaryType,
    String? primarySubtype,
    double? classificationConfidence,
    LifecycleState? currentLifecycleState,
    DateTime? lastProcessedAt,
    int? processingVersion,
  }) {
    return Screenshot(
      id: id,
      assetId: assetId,
      createdAt: createdAt,
      indexedAt: indexedAt,
      width: width,
      height: height,
      sizeBytes: sizeBytes,
      processingStatus: processingStatus ?? this.processingStatus,
      ocrText: ocrText ?? this.ocrText,
      primaryType: primaryType ?? this.primaryType,
      primarySubtype: primarySubtype ?? this.primarySubtype,
      classificationConfidence:
          classificationConfidence ?? this.classificationConfidence,
      currentLifecycleState:
          currentLifecycleState ?? this.currentLifecycleState,
      lastProcessedAt: lastProcessedAt ?? this.lastProcessedAt,
      processingVersion: processingVersion ?? this.processingVersion,
    );
  }
}
