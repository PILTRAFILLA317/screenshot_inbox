import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/features/onboarding/onboarding_controller.dart';

void main() {
  test(
    'onboarding depends on the PhotoRepository contract, not photo_manager',
    () async {
      final repository = _FakePhotoRepository(PhotoPermissionState.limited);
      final controller = OnboardingController(repository);
      addTearDown(controller.dispose);

      final permission = await controller.requestPermission();

      expect(permission, PhotoPermissionState.limited);
      expect(controller.state.requireValue, PhotoPermissionState.limited);
      expect(repository.requestCount, 1);
    },
  );
}

final class _FakePhotoRepository implements PhotoRepository {
  _FakePhotoRepository(this.permission);

  final PhotoPermissionState permission;
  int requestCount = 0;

  @override
  Future<PhotoPermissionState> requestPermission() async {
    requestCount++;
    return permission;
  }

  @override
  Future<void> deleteAssets(List<String> assetIds) async {}

  @override
  Future<Uint8List?> getProcessingImage(String assetId) async => null;

  @override
  Future<List<PhotoAsset>> getScreenshots({
    DateTime? after,
    int? limit,
  }) async => const [];

  @override
  Future<Uint8List?> getThumbnail(String assetId) async => null;
}
