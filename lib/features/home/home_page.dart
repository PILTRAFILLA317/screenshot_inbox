import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/app/theme/app_theme.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/features/detail/screenshot_detail_page.dart';
import 'package:screenshot_inbox/features/home/home_controller.dart';
import 'package:screenshot_inbox/features/home/processing_debug_page.dart';
import 'package:flutter/foundation.dart';
import 'package:screenshot_inbox/features/inbox/inbox_list_page.dart';
import 'package:screenshot_inbox/features/search/search_page.dart';
import 'package:screenshot_inbox/features/shared/inbox_item_tile.dart';
import 'package:screenshot_inbox/processing/discovery/screenshot_discovery_coordinator.dart';
import 'package:screenshot_inbox/processing/scheduling/processing_scheduler.dart';

final class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

final class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final controller = ref.read(homeControllerProvider.notifier);
      controller.setAppExecutionState(AppExecutionState.foreground);
      controller.resumeProcessing();
    } else if (state == AppLifecycleState.paused) {
      final controller = ref.read(homeControllerProvider.notifier);
      controller.setAppExecutionState(AppExecutionState.background);
      controller.pauseProcessing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(homeControllerProvider.notifier).refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Screenshot Inbox',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search screenshots',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SearchPage(),
                          ),
                        ),
                        icon: const Icon(Icons.search),
                      ),
                      IconButton(
                        tooltip: 'Open saved library',
                        onPressed: () =>
                            _openList('Library', const InboxQuery.library()),
                        icon: const Icon(Icons.bookmarks_outlined),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'More options',
                        onSelected: (value) {
                          if (value == 'analyzeRemaining') {
                            unawaited(
                              ref
                                  .read(homeControllerProvider.notifier)
                                  .analyzeRemaining(),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'analyzeRemaining',
                            child: Text('Analyze older screenshots'),
                          ),
                        ],
                      ),
                      if (kDebugMode)
                        IconButton(
                          tooltip: 'Processing debug',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProcessingDebugPage(),
                            ),
                          ),
                          icon: const Icon(Icons.speed),
                        ),
                    ],
                  ),
                ),
              ),
              home.when(
                loading: () => const SliverToBoxAdapter(child: _HomeSkeleton()),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _HomeError(error: error),
                ),
                data: (state) => SliverList.list(
                  children: [
                    _DiscoveryStatus(state: state.discovery),
                    _Section(
                      title: 'Need Action',
                      count: state.needActionCount,
                      items: state.needAction,
                      onSeeAll: () => _openList(
                        'Need Action',
                        const InboxQuery.needAction(),
                      ),
                      onTap: _openDetail,
                      onAction: _execute,
                    ),
                    _Section(
                      title: 'Expiring',
                      count: state.expiringCount,
                      items: state.expiring,
                      onSeeAll: () =>
                          _openList('Expiring', const InboxQuery.expiring()),
                      onTap: _openDetail,
                      onAction: _execute,
                    ),
                    _Section(
                      title: 'Clean Up',
                      count: state.cleanUpCount,
                      items: state.cleanUp,
                      showCleanupReason: true,
                      onSeeAll: () => _openList(
                        'Cleanup',
                        const InboxQuery.cleanup(),
                        cleanup: true,
                      ),
                      onTap: _openDetail,
                    ),
                    _Section(
                      title: 'Recent',
                      count: state.recent.length,
                      items: state.recent.take(6).toList(growable: false),
                      onSeeAll: () => _openList(
                        'Recent',
                        const InboxQuery.recent(limit: null),
                      ),
                      onTap: _openDetail,
                    ),
                    if (state.recent.isEmpty && !state.discovery.isWorking)
                      const _EmptyInbox(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(InboxItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScreenshotDetailPage(screenshotId: item.screenshot.id),
      ),
    );
  }

  void _openList(String title, InboxQuery query, {bool cleanup = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InboxListPage(title: title, query: query, cleanupMode: cleanup),
      ),
    );
  }

  Future<void> _execute(InboxItem item) async {
    final action = item.primaryAction;
    if (action == null) return;
    try {
      await ref.read(actionExecutionServiceProvider).execute(action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.payload['label']} completed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }
}

final class _DiscoveryStatus extends ConsumerWidget {
  const _DiscoveryStatus({required this.state});
  final DiscoveryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        state.isWorking ||
        state.phase == DiscoveryPhase.paused ||
        state.phase == DiscoveryPhase.failed ||
        state.hasLimitedAccess;
    if (!visible) return const SizedBox.shrink();
    final title = state.phase == DiscoveryPhase.finding
        ? 'Finding screenshots…'
        : state.phase == DiscoveryPhase.paused
        ? 'Processing paused'
        : state.phase == DiscoveryPhase.failed
        ? 'Could not finish the scan'
        : 'Analyzing on this device…';
    final detail = state.hasLimitedAccess
        ? 'Limited Photos access · ${state.fastScanned} fast scanned · ${state.pending + state.active} active'
        : '${state.fastScanned} fast scanned · ${state.deepAnalyzed} deeply analyzed · ${state.deferred} deferred';
    return Semantics(
      liveRegion: true,
      label: '$title. $detail',
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (state.isWorking)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (state.phase == DiscoveryPhase.paused)
              IconButton(
                tooltip: 'Resume processing',
                onPressed: ref
                    .read(homeControllerProvider.notifier)
                    .resumeProcessing,
                icon: const Icon(Icons.play_arrow),
              )
            else if (state.isWorking)
              IconButton(
                tooltip: 'Pause processing',
                onPressed: ref
                    .read(homeControllerProvider.notifier)
                    .pauseProcessing,
                icon: const Icon(Icons.pause),
              ),
          ],
        ),
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.items,
    required this.onSeeAll,
    required this.onTap,
    this.onAction,
    this.showCleanupReason = false,
  });

  final String title;
  final int count;
  final List<InboxItem> items;
  final VoidCallback onSeeAll;
  final void Function(InboxItem item) onTap;
  final void Function(InboxItem item)? onAction;
  final bool showCleanupReason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Semantics(
                label: '$count items in $title',
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: title == 'Expiring'
                        ? AppTheme.warning
                        : AppTheme.mutedInk,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (var index = 0; index < items.length; index++) ...[
              InboxItemTile(
                item: items[index],
                showCleanupReason: showCleanupReason,
                onTap: () => onTap(items[index]),
                onPrimaryAction:
                    onAction == null || items[index].primaryAction == null
                    ? null
                    : () => onAction!(items[index]),
              ),
              if (index < items.length - 1) const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }
}

final class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 12, 32, 48),
    child: Column(
      children: [
        const Icon(Icons.photo_library_outlined, size: 34),
        const SizedBox(height: 12),
        Text(
          'No screenshots found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Take a screenshot or expand Photos access, then pull down to scan again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

final class _HomeError extends ConsumerWidget {
  const _HomeError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 34),
          const SizedBox(height: 12),
          Text(
            'The local inbox could not be loaded. $error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: ref.read(homeControllerProvider.notifier).refresh,
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

final class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        SizedBox(height: 58, child: ColoredBox(color: Color(0xFFEDEDED))),
        SizedBox(height: 28),
        SizedBox(height: 120, child: ColoredBox(color: Color(0xFFEDEDED))),
        SizedBox(height: 18),
        SizedBox(height: 120, child: ColoredBox(color: Color(0xFFEDEDED))),
      ],
    ),
  );
}
