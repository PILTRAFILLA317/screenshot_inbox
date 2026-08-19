import 'dart:typed_data';

import 'package:screenshot_inbox/processing/image/processing_image_policy.dart';

enum PhotoPermissionState {
  notDetermined,
  restricted,
  denied,
  authorized,
  limited,
}

extension PhotoPermissionStateAccess on PhotoPermissionState {
  bool get canRead =>
      this == PhotoPermissionState.authorized ||
      this == PhotoPermissionState.limited;
}

final class PhotoAsset {
  const PhotoAsset({
    required this.id,
    required this.createdAt,
    required this.width,
    required this.height,
    this.sizeBytes,
  });

  final String id;
  final DateTime createdAt;
  final int width;
  final int height;
  final int? sizeBytes;
}

final class ProcessingImageLoad {
  const ProcessingImageLoad({
    required this.bytes,
    required this.width,
    required this.height,
    required this.assetLoadingDuration,
    required this.generationDuration,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final Duration assetLoadingDuration;
  final Duration generationDuration;
}

abstract interface class PhotoRepository {
  Future<PhotoPermissionState> currentPermission();

  Future<PhotoPermissionState> requestPermission();

  Future<void> openSettings();

  Future<List<PhotoAsset>> getScreenshots({DateTime? after, int? limit});

  /// Emits bounded metadata batches, newest batches first. Image bytes are
  /// deliberately loaded through the separate thumbnail/processing methods.
  Stream<List<PhotoAsset>> getScreenshotBatches({int batchSize = 50});

  Future<Uint8List?> getThumbnail(String assetId);

  Future<ProcessingImageLoad?> getProcessingImage(
    String assetId, {
    ProcessingImagePurpose purpose = ProcessingImagePurpose.ocr,
  });

  /// Returns the asset IDs actually deleted after native confirmation.
  Future<Set<String>> deleteAssets(List<String> assetIds);
}
