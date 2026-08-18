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
  Future<PhotoPermissionState> requestPermission();

  Future<List<PhotoAsset>> getScreenshots({DateTime? after, int? limit});

  Future<Uint8List?> getThumbnail(String assetId);

  Future<Uint8List?> getProcessingImage(String assetId);

  Future<void> deleteAssets(List<String> assetIds);
}
