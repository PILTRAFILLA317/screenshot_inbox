import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot_inbox/app/theme/app_theme.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/features/shared/screenshot_thumbnail.dart';

final class InboxItemTile extends StatelessWidget {
  const InboxItemTile({
    required this.item,
    required this.onTap,
    this.onPrimaryAction,
    this.showCleanupReason = false,
    super.key,
  });

  final InboxItem item;
  final VoidCallback onTap;
  final VoidCallback? onPrimaryAction;
  final bool showCleanupReason;

  @override
  Widget build(BuildContext context) {
    final action = item.primaryAction;
    final lowConfidence =
        (item.screenshot.classificationConfidence ?? 0) < 0.62;
    return Semantics(
      button: true,
      label: '${item.title}. ${_supportingText(item)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenshotThumbnail(
                assetId: item.screenshot.assetId,
                semanticLabel: 'Screenshot for ${item.title}',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _typeIcon(item),
                          size: 16,
                          color: AppTheme.mutedInk,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showCleanupReason
                          ? item.lifecycleReason ?? 'Ready for cleanup review.'
                          : _supportingText(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: item.expiryDate != null
                            ? AppTheme.warning
                            : AppTheme.mutedInk,
                      ),
                    ),
                    if (lowConfidence) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Possible ${_typeName(item)} · Review details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (action != null && onPrimaryAction != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onPrimaryAction,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text('${action.payload['label'] ?? 'Open'}  →'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 26),
                child: Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _supportingText(InboxItem item) {
    final now = DateTime.now();
    final expiry = item.expiryDate?.toLocal();
    if (expiry != null) {
      final days = DateTime(
        expiry.year,
        expiry.month,
        expiry.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
      if (days == 0) return 'Expires today';
      if (days == 1) return 'Expires tomorrow';
      if (days > 1) return 'Expires ${DateFormat.MMMd().format(expiry)}';
      return 'Expired ${days.abs()} day${days == -1 ? '' : 's'} ago';
    }
    final date = item.importantDate?.toLocal();
    if (date != null) return DateFormat.MMMd().add_jm().format(date);
    return item.subtitle ??
        'Captured ${DateFormat.MMMd().format(item.screenshot.createdAt.toLocal())}';
  }

  static String _typeName(InboxItem item) =>
      (item.object?.type.value ?? item.screenshot.primaryType?.value ?? 'item')
          .replaceAll('conversationTask', 'task');

  static IconData _typeIcon(InboxItem item) => switch (_typeName(item)) {
    'event' => Icons.event_outlined,
    'coupon' => Icons.local_offer_outlined,
    'task' || 'conversation' => Icons.check_circle_outline,
    'order' => Icons.local_shipping_outlined,
    'product' => Icons.shopping_bag_outlined,
    'place' => Icons.place_outlined,
    _ => Icons.bookmark_border,
  };
}
