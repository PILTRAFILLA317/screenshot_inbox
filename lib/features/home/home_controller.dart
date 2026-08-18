import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/core/debug/debug_fixture_seeder.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';

final debugFixtureSeederProvider = Provider<DebugFixtureSeeder>(
  (ref) => DebugFixtureSeeder(
    ref.watch(processingStoreProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<HomeState>>((ref) {
      return HomeController(
        ref.watch(screenshotRepositoryProvider),
        ref.watch(debugFixtureSeederProvider),
      );
    });

final class HomeState {
  const HomeState({
    required this.needAction,
    required this.expiring,
    required this.cleanUp,
    required this.recent,
  });

  final int needAction;
  final int expiring;
  final int cleanUp;
  final List<Screenshot> recent;
}

final class HomeController extends StateNotifier<AsyncValue<HomeState>> {
  HomeController(this._screenshots, this._fixtures)
    : super(const AsyncLoading()) {
    _subscription = _screenshots.watchRecent().listen(
      _loadSummary,
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  final ScreenshotRepository _screenshots;
  final DebugFixtureSeeder _fixtures;
  late final StreamSubscription<List<Screenshot>> _subscription;

  Future<void> _loadSummary(List<Screenshot> recent) async {
    state = await AsyncValue.guard(() async {
      final counts = await Future.wait([
        _screenshots.countByLifecycleStates({LifecycleState.actionable}),
        _screenshots.countByLifecycleStates({
          LifecycleState.expiring,
          LifecycleState.expired,
        }),
        _screenshots.countByLifecycleStates({LifecycleState.cleanupCandidate}),
      ]);
      return HomeState(
        needAction: counts[0],
        expiring: counts[1],
        cleanUp: counts[2],
        recent: recent,
      );
    });
  }

  Future<void> loadDebugFixtures() async {
    if (!kDebugMode) return;
    await _fixtures.seed();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
