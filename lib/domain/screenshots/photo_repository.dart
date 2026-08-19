import 'dart:typed_data';

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

abstract interface class PhotoRepository {
  Future<PhotoPermissionState> currentPermission();

  Future<PhotoPermissionState> requestPermission();

  Future<void> openSettings();

  Future<List<PhotoAsset>> getScreenshots({DateTime? after, int? limit});

  /// Emits bounded metadata batches, newest batches first. Image bytes are
  /// deliberately loaded through the separate thumbnail/processing methods.
  Stream<List<PhotoAsset>> getScreenshotBatches({int batchSize = 50});

  Future<Uint8List?> getThumbnail(String assetId);

  Future<Uint8List?> getProcessingImage(String assetId);

  /// Returns the asset IDs actually deleted after native confirmation.
  Future<Set<String>> deleteAssets(List<String> assetIds);
}
