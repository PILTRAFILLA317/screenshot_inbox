import 'package:flutter/services.dart';

enum AppExecutionState { foreground, background }

enum DeviceThermalState { nominal, fair, serious, critical, unknown }

final class DeviceResourceState {
  const DeviceResourceState({
    this.isCharging = false,
    this.isBatteryLow = false,
    this.thermal = DeviceThermalState.unknown,
  });

  final bool isCharging;
  final bool isBatteryLow;
  final DeviceThermalState thermal;
}

abstract interface class DeviceResourceMonitor {
  Future<DeviceResourceState> snapshot();
}

final class PlatformDeviceResourceMonitor implements DeviceResourceMonitor {
  const PlatformDeviceResourceMonitor({
    this.channel = const MethodChannel(
      'com.screenshotinbox/processing_resources',
    ),
  });

  final MethodChannel channel;

  @override
  Future<DeviceResourceState> snapshot() async {
    try {
      final value = await channel.invokeMapMethod<String, Object?>('snapshot');
      final thermalName = value?['thermal'] as String?;
      return DeviceResourceState(
        isCharging: value?['isCharging'] == true,
        isBatteryLow: value?['isBatteryLow'] == true,
        thermal: DeviceThermalState.values.firstWhere(
          (state) => state.name == thermalName,
          orElse: () => DeviceThermalState.unknown,
        ),
      );
    } on MissingPluginException {
      return const DeviceResourceState();
    } on PlatformException {
      return const DeviceResourceState();
    }
  }
}

final class ProcessingConcurrencyConfig {
  const ProcessingConcurrencyConfig({
    this.fastScanConcurrency = 2,
    this.deepAnalysisConcurrency = 1,
  }) : assert(fastScanConcurrency > 0),
       assert(deepAnalysisConcurrency > 0);

  final int fastScanConcurrency;
  final int deepAnalysisConcurrency;
}

final class ProcessingSchedulingConfig {
  const ProcessingSchedulingConfig({
    this.recentWindow = const Duration(days: 30),
    this.highPriorityThreshold = 55,
    this.allowBackgroundDeepAnalysis = false,
  });

  final Duration recentWindow;
  final double highPriorityThreshold;
  final bool allowBackgroundDeepAnalysis;
}

final class ProcessingScheduleDecision {
  const ProcessingScheduleDecision({
    required this.allowFastScan,
    required this.allowDeepAnalysis,
    required this.fastConcurrency,
    required this.reason,
  });

  final bool allowFastScan;
  final bool allowDeepAnalysis;
  final int fastConcurrency;
  final String reason;
}

final class ProcessingScheduler {
  ProcessingScheduler({
    required this.resources,
    this.concurrency = const ProcessingConcurrencyConfig(),
    this.config = const ProcessingSchedulingConfig(),
  });

  final DeviceResourceMonitor resources;
  ProcessingConcurrencyConfig concurrency;
  ProcessingSchedulingConfig config;
  AppExecutionState appState = AppExecutionState.foreground;

  void setRecentWindow(Duration value) {
    config = ProcessingSchedulingConfig(
      recentWindow: value,
      highPriorityThreshold: config.highPriorityThreshold,
      allowBackgroundDeepAnalysis: config.allowBackgroundDeepAnalysis,
    );
  }

  void setConcurrency({required int fast, required int deep}) {
    concurrency = ProcessingConcurrencyConfig(
      fastScanConcurrency: fast,
      deepAnalysisConcurrency: deep,
    );
  }

  bool isRecent(DateTime capturedAt, DateTime now) =>
      now.difference(capturedAt) <= config.recentWindow;

  Future<ProcessingScheduleDecision> decide({
    required bool recent,
    required double priority,
  }) async {
    final resource = await resources.snapshot();
    if (resource.thermal == DeviceThermalState.critical) {
      return const ProcessingScheduleDecision(
        allowFastScan: false,
        allowDeepAnalysis: false,
        fastConcurrency: 1,
        reason: 'criticalThermalPressure',
      );
    }
    if (appState == AppExecutionState.background) {
      final favorable =
          resource.isCharging &&
          !resource.isBatteryLow &&
          resource.thermal != DeviceThermalState.serious;
      return ProcessingScheduleDecision(
        allowFastScan: favorable,
        allowDeepAnalysis: favorable && config.allowBackgroundDeepAnalysis,
        fastConcurrency: 1,
        reason: favorable ? 'backgroundCharging' : 'backgroundDeferred',
      );
    }
    final serious = resource.thermal == DeviceThermalState.serious;
    final highPriority = priority >= config.highPriorityThreshold;
    return ProcessingScheduleDecision(
      allowFastScan: recent || highPriority,
      allowDeepAnalysis:
          !serious && !resource.isBatteryLow && (recent || highPriority),
      fastConcurrency: serious || resource.isBatteryLow
          ? 1
          : concurrency.fastScanConcurrency,
      reason: serious
          ? 'foregroundThermalPressure'
          : resource.isBatteryLow
          ? 'foregroundBatteryLow'
          : recent
          ? 'foregroundRecent'
          : highPriority
          ? 'foregroundHighPriority'
          : 'historicalDeferred',
    );
  }
}
