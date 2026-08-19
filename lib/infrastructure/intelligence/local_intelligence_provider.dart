import 'package:flutter/services.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';

final class LocalIntelligenceProvider implements IntelligenceProvider {
  const LocalIntelligenceProvider({
    this._channel = const MethodChannel(
      'com.screenshotinbox/local_intelligence',
    ),
  });

  final MethodChannel _channel;

  @override
  Future<IntelligenceAvailability> availability() async {
    try {
      final value = await _channel.invokeMapMethod<String, Object?>(
        'availability',
      );
      if (value == null) return _unknown('Native bridge returned no state.');
      final name = value['state'] as String?;
      final state = IntelligenceAvailabilityState.values
          .where((candidate) => candidate.name == name)
          .firstOrNull;
      return IntelligenceAvailability(
        state: state ?? IntelligenceAvailabilityState.unknown,
        provider: value['provider'] as String? ?? 'local-unknown',
        providerVersion: value['providerVersion'] as String?,
        reason: value['reason'] as String?,
      );
    } on MissingPluginException {
      return _unknown('Local intelligence bridge is not installed.');
    } on PlatformException catch (error) {
      return _unknown('Availability check failed: ${error.code}.');
    }
  }

  @override
  Future<IntelligenceResult> interpret(IntelligenceRequest request) async {
    final value = await _channel.invokeMapMethod<String, Object?>(
      'interpret',
      request.toJson(),
    );
    if (value == null) {
      throw const FormatException('Local intelligence returned no result.');
    }
    return IntelligenceResult.fromJson(value);
  }

  static IntelligenceAvailability _unknown(String reason) =>
      IntelligenceAvailability(
        state: IntelligenceAvailabilityState.unknown,
        provider: 'local-unknown',
        reason: reason,
      );
}
