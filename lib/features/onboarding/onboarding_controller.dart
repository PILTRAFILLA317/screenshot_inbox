import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';

final onboardingControllerProvider =
    StateNotifierProvider<
      OnboardingController,
      AsyncValue<PhotoPermissionState?>
    >((ref) => OnboardingController(ref.watch(photoRepositoryProvider)));

final class OnboardingController
    extends StateNotifier<AsyncValue<PhotoPermissionState?>> {
  OnboardingController(this._photos) : super(const AsyncData(null));

  final PhotoRepository _photos;

  Future<PhotoPermissionState> requestPermission() async {
    state = const AsyncLoading();
    final permission = await AsyncValue.guard(_photos.requestPermission);
    state = permission;
    return permission.requireValue;
  }
}
