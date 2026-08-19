import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/processing/scheduling/processing_scheduler.dart';

void main() {
  test(
    'foreground recent work is allowed with conservative concurrency',
    () async {
      final monitor = _FakeResourceMonitor(
        const DeviceResourceState(thermal: DeviceThermalState.nominal),
      );
      final scheduler = ProcessingScheduler(resources: monitor);

      final decision = await scheduler.decide(recent: true, priority: 10);

      expect(decision.allowFastScan, isTrue);
      expect(decision.allowDeepAnalysis, isTrue);
      expect(decision.fastConcurrency, 2);
    },
  );

  test('serious thermal pressure reduces OCR and defers AI', () async {
    final scheduler = ProcessingScheduler(
      resources: _FakeResourceMonitor(
        const DeviceResourceState(thermal: DeviceThermalState.serious),
      ),
    );

    final decision = await scheduler.decide(recent: true, priority: 100);

    expect(decision.allowFastScan, isTrue);
    expect(decision.allowDeepAnalysis, isFalse);
    expect(decision.fastConcurrency, 1);
  });

  test('historical background work requires favorable resources', () async {
    final monitor = _FakeResourceMonitor(
      const DeviceResourceState(isCharging: false, isBatteryLow: true),
    );
    final scheduler = ProcessingScheduler(resources: monitor)
      ..appState = AppExecutionState.background;

    final lowBattery = await scheduler.decide(recent: false, priority: 0);
    monitor.value = const DeviceResourceState(
      isCharging: true,
      thermal: DeviceThermalState.nominal,
    );
    final charging = await scheduler.decide(recent: false, priority: 0);

    expect(lowBattery.allowFastScan, isFalse);
    expect(charging.allowFastScan, isTrue);
    expect(
      charging.allowDeepAnalysis,
      isFalse,
      reason: 'Headless local-AI bridges are intentionally not assumed.',
    );
  });
}

final class _FakeResourceMonitor implements DeviceResourceMonitor {
  _FakeResourceMonitor(this.value);
  DeviceResourceState value;

  @override
  Future<DeviceResourceState> snapshot() async => value;
}
