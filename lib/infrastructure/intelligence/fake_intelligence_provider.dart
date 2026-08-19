import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';

final class FakeIntelligenceProvider implements IntelligenceProvider {
  FakeIntelligenceProvider({
    this.state = const IntelligenceAvailability(
      state: IntelligenceAvailabilityState.available,
      provider: 'fake-local',
      providerVersion: 'test',
    ),
    this.result,
    this.error,
  });

  IntelligenceAvailability state;
  IntelligenceResult? result;
  Object? error;
  final List<IntelligenceRequest> requests = [];

  @override
  Future<IntelligenceAvailability> availability() async => state;

  @override
  Future<IntelligenceResult> interpret(IntelligenceRequest request) async {
    requests.add(request);
    if (error case final Object failure) throw failure;
    return result ??
        const IntelligenceResult(
          provider: 'fake-local',
          providerVersion: 'test',
          interpretations: [],
          duration: Duration.zero,
        );
  }
}
