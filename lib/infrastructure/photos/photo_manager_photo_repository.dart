import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:screenshot_inbox/core/debug/local_debug_log.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/processing/image/processing_image_policy.dart';

final class PhotoManagerPhotoRepository implements PhotoRepository {
  const PhotoManagerPhotoRepository({
    this.imagePolicy = const ProcessingImagePolicy(),
  });

  final ProcessingImagePolicy imagePolicy;

  static const _pageSize = 200;

  @override
  Future<PhotoPermissionState> currentPermission() async {
    final permission = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    return _permissionStates[permission] ?? PhotoPermissionState.denied;
  }

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
  Future<void> openSettings() => PhotoManager.openSetting();

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
  Stream<List<PhotoAsset>> getScreenshotBatches({int batchSize = 50}) async* {
    if (batchSize <= 0) return;
    final permission = await currentPermission();
    if (!permission.canRead) return;

    final filter = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: DateTime.fromMillisecondsSinceEpoch(0),
        max: DateTime.now(),
      ),
      orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    final paths = await _screenshotPaths(filter);
    final emitted = <String>{};
    var page = 0;
    while (true) {
      final pageAssets = <AssetEntity>[];
      var anyPathHasMore = false;
      for (final path in paths) {
        final assets = await path.getAssetListPaged(
          page: page,
          size: batchSize,
          type: RequestType.image,
        );
        if (assets.isNotEmpty) anyPathHasMore = true;
        for (final asset in assets) {
          if (emitted.add(asset.id)) pageAssets.add(asset);
        }
      }
      if (!anyPathHasMore) break;
      pageAssets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      for (var start = 0; start < pageAssets.length; start += batchSize) {
        final end = math.min(start + batchSize, pageAssets.length);
        yield [
          for (final asset in pageAssets.sublist(start, end))
            PhotoAsset(
              id: asset.id,
              createdAt: asset.createDateTime.toUtc(),
              width: asset.width,
              height: asset.height,
            ),
        ];
      }
      page++;
    }
  }

  @override
  Future<Uint8List?> getThumbnail(String assetId) async {
    final watch = Stopwatch()..start();
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    final spec = imagePolicy.thumbnail;
    final bytes = await asset.thumbnailDataWithSize(
      _boundedSize(asset.width, asset.height, maxDimension: spec.maxDimension),
      format: ThumbnailFormat.jpeg,
      quality: spec.jpegQuality,
    );
    watch.stop();
    LocalDebugLog.event(
      'processing.thumbnail.loaded',
      metadata: {
        'assetId': assetId,
        'thumbnailLoadingMs': watch.elapsedMilliseconds,
        'encodedBytes': bytes?.length ?? 0,
      },
    );
    return bytes;
  }

  @override
  Future<ProcessingImageLoad?> getProcessingImage(
    String assetId, {
    ProcessingImagePurpose purpose = ProcessingImagePurpose.ocr,
  }) async {
    final assetWatch = Stopwatch()..start();
    final asset = await AssetEntity.fromId(assetId);
    assetWatch.stop();
    if (asset == null) return null;
    final spec = imagePolicy.forPurpose(purpose);
    final size = _boundedSize(
      asset.width,
      asset.height,
      maxDimension: spec.maxDimension,
    );
    final generationWatch = Stopwatch()..start();
    final bytes = await asset.thumbnailDataWithSize(
      size,
      format: ThumbnailFormat.jpeg,
      quality: spec.jpegQuality,
    );
    generationWatch.stop();
    if (bytes == null) return null;
    return ProcessingImageLoad(
      bytes: bytes,
      width: size.width,
      height: size.height,
      assetLoadingDuration: assetWatch.elapsed,
      generationDuration: generationWatch.elapsed,
    );
  }

  @override
  Future<Set<String>> deleteAssets(List<String> assetIds) async {
    if (assetIds.isEmpty) return const {};
    return (await PhotoManager.editor.deleteWithIds(assetIds)).toSet();
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

  static ThumbnailSize _boundedSize(
    int width,
    int height, {
    required int maxDimension,
  }) {
    final largest = math.max(width, height);
    if (largest <= maxDimension) {
      return ThumbnailSize(width, height);
    }
    final scale = maxDimension / largest;
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
