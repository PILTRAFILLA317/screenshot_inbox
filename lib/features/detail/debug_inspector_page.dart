import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';

final class DebugInspectorPage extends ConsumerWidget {
  const DebugInspectorPage({required this.screenshotId, super.key});

  final String screenshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode, 'DebugInspectorPage must never be used in release.');
    final item = ref.watch(inboxItemsProvider(InboxQuery.one(screenshotId)));
    return Scaffold(
      appBar: AppBar(title: const Text('Local debug inspector')),
      body: item.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Inspector failed: $error')),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No data.'));
          final debug = items.single.object?.structuredData['_debug'];
          if (debug is! Map) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No debug trace was persisted. Reprocess this screenshot in a debug run.',
                ),
              ),
            );
          }
          final values = debug.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Local-only diagnostic data. OCR and model output are never sent to analytics.',
                ),
              ),
              for (final section in _sections)
                ExpansionTile(
                  initiallyExpanded: section == 'ocrBlocks',
                  title: Text(_title(section)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ')
                              .convert(values[section]),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  static String _title(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .toUpperCase();

  static const _sections = [
    'ocrBlocks',
    'deterministicEntities',
    'classification',
    'deterministicParser',
    'localIntelligence',
    'finalObject',
    'actions',
    'lifecycle',
    'timings',
  ];
}
