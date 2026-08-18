import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';

final class PhotoManagerPhotoRepository implements PhotoRepository {
  const PhotoManagerPhotoRepository();

  static const _pageSize = 200;
  static const _processingMaxDimension = 2400;

  @override
  Future<PhotoPermissionState> requestPermission() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    return _permissionStates[permission] ?? PhotoPermissionState.denied;
  }

  @override
  Future<List<PhotoAsset>> getScreenshots({DateTime? after, int? limit}) async {
    if (limit != null && limit <= 0) return const [];
    final permission = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    if (permission != PermissionState.authorized &&
        permission != PermissionState.limited) {
      return const [];
    }

    final filter = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: after ?? DateTime.fromMillisecondsSinceEpoch(0),
        max: DateTime.now(),
      ),
      orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    final paths = await _screenshotPaths(filter);
    final assets = <String, AssetEntity>{};
    for (final path in paths) {
      var page = 0;
      while (limit == null || assets.length < limit) {
        final remaining = limit == null ? _pageSize : limit - assets.length;
        final pageSize = math.min(_pageSize, remaining);
        if (pageSize <= 0) break;
        final pageAssets = await path.getAssetListPaged(
          page: page,
          size: pageSize,
          type: RequestType.image,
        );
        for (final asset in pageAssets) {
          assets[asset.id] = asset;
        }
        if (pageAssets.length < pageSize) break;
        page++;
      }
      if (limit != null && assets.length >= limit) break;
    }

    final sorted = assets.values.toList()
      ..sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return [
      for (final asset in limit == null ? sorted : sorted.take(limit))
        PhotoAsset(
          id: asset.id,
          createdAt: asset.createDateTime.toUtc(),
          width: asset.width,
          height: asset.height,
        ),
    ];
  }

  @override
  Future<Uint8List?> getThumbnail(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    return asset?.thumbnailDataWithSize(
      const ThumbnailSize.square(512),
      format: ThumbnailFormat.jpeg,
      quality: 88,
    );
  }

  @override
  Future<Uint8List?> getProcessingImage(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    final size = _boundedSize(asset.width, asset.height);
    return asset.thumbnailDataWithSize(
      size,
      format: ThumbnailFormat.jpeg,
      quality: 95,
    );
  }

  @override
  Future<void> deleteAssets(List<String> assetIds) async {
    if (assetIds.isEmpty) return;
    await PhotoManager.editor.deleteWithIds(assetIds);
  }

  Future<List<AssetPathEntity>> _screenshotPaths(
    FilterOptionGroup filter,
  ) async {
    if (Platform.isIOS) {
      return PhotoManager.getAssetPathList(
        hasAll: false,
        type: RequestType.image,
        filterOption: filter,
        pathFilterOption: const PMPathFilter(
          darwin: PMDarwinPathFilter(
            type: [PMDarwinAssetCollectionType.smartAlbum],
            subType: [PMDarwinAssetCollectionSubtype.smartAlbumScreenshots],
          ),
        ),
      );
    }
    if (Platform.isAndroid) {
      final paths = await PhotoManager.getAssetPathList(
        hasAll: false,
        type: RequestType.image,
        filterOption: filter,
      );
      final screenshots = <AssetPathEntity>[];
      for (final path in paths) {
        final relativePath = await path.relativePathAsync;
        final identity = '${path.name}/${relativePath ?? ''}'.toLowerCase();
        if (identity.contains('screenshot')) screenshots.add(path);
      }
      return screenshots;
    }
    return const [];
  }

  static ThumbnailSize _boundedSize(int width, int height) {
    final largest = math.max(width, height);
    if (largest <= _processingMaxDimension) {
      return ThumbnailSize(width, height);
    }
    final scale = _processingMaxDimension / largest;
    return ThumbnailSize(
      math.max(1, (width * scale).round()),
      math.max(1, (height * scale).round()),
    );
  }

  static const _permissionStates = <PermissionState, PhotoPermissionState>{
    PermissionState.notDetermined: PhotoPermissionState.notDetermined,
    PermissionState.restricted: PhotoPermissionState.restricted,
    PermissionState.denied: PhotoPermissionState.denied,
    PermissionState.authorized: PhotoPermissionState.authorized,
    PermissionState.limited: PhotoPermissionState.limited,
  };
}
