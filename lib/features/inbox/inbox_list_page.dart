import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/features/detail/screenshot_detail_page.dart';
import 'package:screenshot_inbox/features/shared/inbox_item_tile.dart';
import 'package:screenshot_inbox/features/shared/screenshot_thumbnail.dart';

final class InboxListPage extends ConsumerWidget {
  const InboxListPage({
    required this.title,
    required this.query,
    this.cleanupMode = false,
    super.key,
  });

  final String title;
  final InboxQuery query;
  final bool cleanupMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxItemsProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: items.when(
          loading: () => const _ListSkeleton(),
          error: (error, _) => _ListError(error: error),
          data: (values) => values.isEmpty
              ? _EmptyList(title: title)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: values.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => cleanupMode
                      ? _CleanupItem(item: values[index])
                      : InboxItemTile(
                          item: values[index],
                          onTap: () => _openDetail(context, values[index]),
                          onPrimaryAction: values[index].primaryAction == null
                              ? null
                              : () => _execute(context, ref, values[index]),
                        ),
                ),
        ),
      ),
    );
  }

  static void _openDetail(BuildContext context, InboxItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScreenshotDetailPage(screenshotId: item.screenshot.id),
      ),
    );
  }

  static Future<void> _execute(
    BuildContext context,
    WidgetRef ref,
    InboxItem item,
  ) async {
    final action = item.primaryAction;
    if (action == null) return;
    try {
      await ref.read(actionExecutionServiceProvider).execute(action);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.payload['label']} completed.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  static String _friendlyError(Object error) {
    final value = error.toString().replaceFirst('Bad state: ', '');
    return value.isEmpty ? 'The action could not be completed.' : value;
  }
}

final class _CleanupItem extends ConsumerWidget {
  const _CleanupItem({required this.item});

  final InboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenshotThumbnail(
                assetId: item.screenshot.assetId,
                semanticLabel: 'Screenshot for ${item.title}',
                width: 88,
                height: 108,
                borderRadius: 12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.lifecycleReason ?? 'The useful part of this screenshot is no longer active.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _keep(context, ref),
                  child: const Text('Keep'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _delete(context, ref),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _keep(BuildContext context, WidgetRef ref) async {
    await ref.read(screenshotCommandServiceProvider).keep(item.screenshot);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Screenshot kept.')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this screenshot?'),
        content: const Text(
          'Photos will ask for native confirmation. Screenshot Inbox never deletes images silently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await ref
        .read(screenshotCommandServiceProvider)
        .delete(item.screenshot);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? 'Screenshot deleted from Photos.'
                : 'The screenshot was not deleted.',
          ),
        ),
      );
    }
  }
}

final class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 36),
          const SizedBox(height: 14),
          Text(
            'Nothing in $title',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'New relevant screenshots will appear here as they are processed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

final class _ListError extends StatelessWidget {
  const _ListError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Semantics(
        liveRegion: true,
        child: Text(
          'This list could not be loaded. $error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

final class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(20),
    itemCount: 6,
    separatorBuilder: (_, _) => const SizedBox(height: 18),
    itemBuilder: (_, _) => const Row(
      children: [
        SizedBox(
          width: 64,
          height: 76,
          child: ColoredBox(color: Color(0xFFEDEDED)),
        ),
        SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ColoredBox(color: Color(0xFFEDEDED)),
          ),
        ),
      ],
    ),
  );
}
