import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';

final class ProcessingDebugPage extends ConsumerStatefulWidget {
  const ProcessingDebugPage({super.key});

  @override
  ConsumerState<ProcessingDebugPage> createState() =>
      _ProcessingDebugPageState();
}

final class _ProcessingDebugPageState
    extends ConsumerState<ProcessingDebugPage> {
  ProcessingCacheStats? _stats;

  @override
  void initState() {
    super.initState();
    assert(kDebugMode, 'ProcessingDebugPage must never be used in release.');
    _reload();
  }

  Future<void> _reload() async {
    final value = await ref
        .read(discoveryCoordinatorProvider)
        .processingStats();
    if (mounted) setState(() => _stats = value);
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.read(discoveryCoordinatorProvider);
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Processing debug')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (stats == null)
            const LinearProgressIndicator()
          else
            Text(
              '${stats.total} indexed\n'
              'Fast scanned: ${stats.fastScanned}\n'
              'Deep analyzed: ${stats.deepAnalyzed}\n'
              'Queued: ${stats.queued}\n'
              'Deferred: ${stats.deferred}\n'
              'Failed: ${stats.failed}',
            ),
          const SizedBox(height: 24),
          DropdownButtonFormField<AIEligibilityMode>(
            initialValue: coordinator.aiEligibilityMode,
            decoration: const InputDecoration(labelText: 'AI policy'),
            items: [
              for (final mode in AIEligibilityMode.values)
                DropdownMenuItem(value: mode, child: Text(mode.name)),
            ],
            onChanged: (value) {
              if (value != null) coordinator.setDebugTuning(aiMode: value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: coordinator.concurrency.fastScanConcurrency,
            decoration: const InputDecoration(
              labelText: 'Fast Scan concurrency',
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1')),
              DropdownMenuItem(value: 2, child: Text('2')),
            ],
            onChanged: (value) {
              if (value != null) {
                coordinator.setDebugTuning(fastConcurrency: value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: coordinator.concurrency.deepAnalysisConcurrency,
            decoration: const InputDecoration(labelText: 'AI concurrency'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 (recommended)')),
              DropdownMenuItem(value: 2, child: Text('2 (benchmark only)')),
            ],
            onChanged: (value) {
              if (value != null) {
                coordinator.setDebugTuning(deepConcurrency: value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: coordinator.recentWindow.inDays,
            decoration: const InputDecoration(labelText: 'Recent window'),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
              DropdownMenuItem(value: 90, child: Text('90 days')),
            ],
            onChanged: (value) {
              if (value != null) {
                coordinator.setDebugTuning(recentWindow: Duration(days: value));
              }
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: coordinator.pause,
                child: const Text('Pause processing'),
              ),
              OutlinedButton(
                onPressed: coordinator.resume,
                child: const Text('Resume processing'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await coordinator.analyzeRemaining();
                  await _reload();
                },
                child: const Text('Run backlog'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await coordinator.clearProcessingCache();
                  await _reload();
                },
                child: const Text('Clear processing cache'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Changes are local to this debug session. Clearing the cache does not delete screenshots or user-confirmed objects.',
          ),
        ],
      ),
    );
  }
}
