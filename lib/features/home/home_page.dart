import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/features/home/home_controller.dart';

final class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Screenshot Inbox',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (kDebugMode)
                        IconButton(
                          tooltip: 'Load debug fixtures',
                          onPressed: () => ref
                              .read(homeControllerProvider.notifier)
                              .loadDebugFixtures(),
                          icon: const Icon(Icons.science_outlined),
                        ),
                    ],
                  ),
                ),
              ),
              home.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load the local inbox: $error'),
                    ),
                  ),
                ),
                data: (state) => SliverList.list(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Need Action',
                              count: state.needAction,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: 'Expiring',
                              count: state.expiring,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: 'Clean Up',
                              count: state.cleanUp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Recent screenshots',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state.recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Text(
                          'Your processed screenshots will appear here.',
                        ),
                      )
                    else
                      for (final screenshot in state.recent)
                        _RecentScreenshotTile(screenshot: screenshot),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

final class _RecentScreenshotTile extends StatelessWidget {
  const _RecentScreenshotTile({required this.screenshot});

  final Screenshot screenshot;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().add_jm().format(
      screenshot.createdAt.toLocal(),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text(screenshot.ocrText?.split('\n').first ?? 'Screenshot'),
          subtitle: Text(date),
          trailing: Text(screenshot.currentLifecycleState.name),
        ),
      ),
    );
  }
}
