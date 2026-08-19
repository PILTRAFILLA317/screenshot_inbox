import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/core/debug/local_debug_log.dart';
import 'package:screenshot_inbox/processing/discovery/screenshot_discovery_coordinator.dart';
import 'package:screenshot_inbox/processing/scheduling/processing_scheduler.dart';
import 'package:workmanager/workmanager.dart';

abstract final class BackgroundProcessing {
  static const taskName = 'processHistoricalScreenshotBacklog';
  static const uniqueName = 'com.screenshotinbox.historical-processing';
  static const batchSize = 40;
  static const maximumRun = Duration(minutes: 8);
}

final class _ConstrainedBackgroundResourceMonitor
    implements DeviceResourceMonitor {
  const _ConstrainedBackgroundResourceMonitor();

  @override
  Future<DeviceResourceState> snapshot() async => const DeviceResourceState(
    isCharging: true,
    isBatteryLow: false,
    thermal: DeviceThermalState.unknown,
  );
}

@pragma('vm:entry-point')
void backgroundProcessingDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != BackgroundProcessing.taskName &&
        taskName != BackgroundProcessing.uniqueName) {
      return true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    // Workmanager starts a headless Flutter engine where the app-owned resource
    // channel may not be registered. The OS only invokes this task after the
    // charging and battery constraints below have been satisfied, so reflect
    // those guarantees explicitly instead of treating a missing channel as an
    // unfavorable device state.
    final container = ProviderContainer(
      overrides: [
        deviceResourceMonitorProvider.overrideWithValue(
          const _ConstrainedBackgroundResourceMonitor(),
        ),
      ],
    );
    try {
      final coordinator = container.read(discoveryCoordinatorProvider);
      coordinator.setAppExecutionState(AppExecutionState.background);
      await coordinator.start();
      await coordinator.analyzeRemaining(limit: BackgroundProcessing.batchSize);
      if (coordinator.state.pending > 0 || coordinator.state.active > 0) {
        await coordinator.states
            .firstWhere(
              (state) =>
                  state.phase == DiscoveryPhase.complete ||
                  state.phase == DiscoveryPhase.failed,
            )
            .timeout(BackgroundProcessing.maximumRun);
      }
      if (Platform.isIOS) await scheduleBackgroundProcessing();
      return coordinator.state.phase != DiscoveryPhase.failed;
    } on TimeoutException {
      return false;
    } finally {
      container.dispose();
    }
  });
}

Future<void> initializeBackgroundProcessing() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    await Workmanager().initialize(backgroundProcessingDispatcher);
    await scheduleBackgroundProcessing();
  } catch (error, stackTrace) {
    LocalDebugLog.event(
      'processing.background.schedule_failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> scheduleBackgroundProcessing() async {
  final constraints = Constraints(
    requiresBatteryNotLow: true,
    requiresCharging: true,
    requiresDeviceIdle: true,
  );
  if (Platform.isAndroid) {
    await Workmanager().registerPeriodicTask(
      BackgroundProcessing.uniqueName,
      BackgroundProcessing.taskName,
      frequency: const Duration(hours: 12),
      constraints: constraints,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  } else if (Platform.isIOS) {
    await Workmanager().registerProcessingTask(
      BackgroundProcessing.uniqueName,
      BackgroundProcessing.taskName,
      initialDelay: const Duration(hours: 1),
      constraints: constraints,
    );
  }
}
