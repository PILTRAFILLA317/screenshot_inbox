import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/application/screenshots/lifecycle_refresh_service.dart';
import 'package:screenshot_inbox/core/debug/debug_fixture_seeder.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/processing/discovery/screenshot_discovery_coordinator.dart';

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
        ref.watch(inboxRepositoryProvider),
        ref.watch(discoveryCoordinatorProvider),
        ref.watch(lifecycleRefreshServiceProvider),
        ref.watch(debugFixtureSeederProvider),
      );
    });

final class HomeState {
  const HomeState({
    required this.needActionCount,
    required this.expiringCount,
    required this.cleanUpCount,
    required this.needAction,
    required this.expiring,
    required this.cleanUp,
    required this.recent,
    required this.discovery,
  });

  final int needActionCount;
  final int expiringCount;
  final int cleanUpCount;
  final List<InboxItem> needAction;
  final List<InboxItem> expiring;
  final List<InboxItem> cleanUp;
  final List<InboxItem> recent;
  final DiscoveryState discovery;

  HomeState copyWith({DiscoveryState? discovery}) => HomeState(
    needActionCount: needActionCount,
    expiringCount: expiringCount,
    cleanUpCount: cleanUpCount,
    needAction: needAction,
    expiring: expiring,
    cleanUp: cleanUp,
    recent: recent,
    discovery: discovery ?? this.discovery,
  );
}

final class HomeController extends StateNotifier<AsyncValue<HomeState>> {
  HomeController(
    this._inbox,
    this._discovery,
    this._lifecycleRefresh,
    this._fixtures,
  ) : super(const AsyncLoading()) {
    _inboxSubscription = _inbox
        .watch(const InboxQuery.recent(limit: 1))
        .listen(
          (_) => _scheduleReload(),
          onError: (Object error, StackTrace stackTrace) {
            state = AsyncError(error, stackTrace);
          },
        );
    _discoverySubscription = _discovery.states.listen((discovery) {
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(discovery: discovery));
      }
    });
    unawaited(_start());
  }

  final InboxRepository _inbox;
  final ScreenshotDiscoveryCoordinator _discovery;
  final LifecycleRefreshService _lifecycleRefresh;
  final DebugFixtureSeeder _fixtures;
  late final StreamSubscription<List<InboxItem>> _inboxSubscription;
  late final StreamSubscription<DiscoveryState> _discoverySubscription;
  var _reloading = false;
  var _reloadAgain = false;
  Timer? _reloadTimer;

  Future<void> _start() async {
    try {
      await _lifecycleRefresh.refresh();
    } finally {
      await _discovery.start();
    }
  }

  void _scheduleReload() {
    if (_reloadTimer?.isActive ?? false) return;
    final delay = state.isLoading
        ? Duration.zero
        : const Duration(milliseconds: 500);
    _reloadTimer = Timer(delay, () => unawaited(_reload()));
  }

  Future<void> _reload() async {
    if (_reloading) {
      _reloadAgain = true;
      return;
    }
    _reloading = true;
    try {
      final results = await Future.wait([
        _inbox.find(const InboxQuery.needAction()),
        _inbox.find(const InboxQuery.expiring()),
        _inbox.find(const InboxQuery.cleanup()),
        _inbox.find(const InboxQuery.recent(limit: 12)),
      ]);
      state = AsyncData(
        HomeState(
          needActionCount: results[0].length,
          expiringCount: results[1].length,
          cleanUpCount: results[2].length,
          needAction: results[0].take(4).toList(growable: false),
          expiring: results[1].take(4).toList(growable: false),
          cleanUp: results[2].take(3).toList(growable: false),
          recent: results[3],
          discovery: _discovery.state,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _reloading = false;
      if (_reloadAgain) {
        _reloadAgain = false;
        _scheduleReload();
      }
    }
  }

  Future<void> refresh() => _discovery.restart();
  void pauseProcessing() => _discovery.pause();
  void resumeProcessing() => _discovery.resume();

  Future<void> loadDebugFixtures() async {
    if (!kDebugMode) return;
    await _fixtures.seed();
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    unawaited(_inboxSubscription.cancel());
    unawaited(_discoverySubscription.cancel());
    super.dispose();
  }
}
