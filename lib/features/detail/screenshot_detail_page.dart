import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screenshot_inbox/app/providers.dart';
import 'package:screenshot_inbox/app/theme/app_theme.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/features/shared/screenshot_thumbnail.dart';
import 'package:screenshot_inbox/features/detail/debug_inspector_page.dart';

final class ScreenshotDetailPage extends ConsumerWidget {
  const ScreenshotDetailPage({required this.screenshotId, super.key});

  final String screenshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(inboxItemsProvider(InboxQuery.one(screenshotId)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Open debug inspector',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DebugInspectorPage(screenshotId: screenshotId),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: result.when(
          loading: () => const _DetailSkeleton(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('This screenshot could not be loaded. $error'),
            ),
          ),
          data: (items) => items.isEmpty
              ? const Center(child: Text('Screenshot not found.'))
              : _DetailBody(item: items.single),
        ),
      ),
    );
  }
}

final class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.item});

  final InboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final object = item.object;
    final confidence = item.screenshot.classificationConfidence ?? 0;
    final lowConfidence = confidence < 0.62;
    final details = _visibleDetails(object?.structuredData ?? const {});
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        Center(
          child: ScreenshotThumbnail(
            assetId: item.screenshot.assetId,
            semanticLabel: 'Original screenshot for ${item.title}',
            width: 220,
            height: 286,
            borderRadius: 14,
          ),
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (object != null)
              IconButton(
                tooltip: 'Edit interpretation',
                onPressed: () => _edit(context, object),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: lowConfidence
              ? 'Low confidence interpretation. Review details.'
              : 'Interpretation confidence ${(confidence * 100).round()} percent.',
          child: Text(
            lowConfidence
                ? 'Possible ${_typeLabel(object?.type)} detected · Review details'
                : '${_typeLabel(object?.type)} · ${(confidence * 100).round()}% confidence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: lowConfidence ? AppTheme.warning : AppTheme.mutedInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (item.lifecycleReason != null) ...[
          const SizedBox(height: 12),
          Text(
            item.lifecycleReason!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (details.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final detail in details)
            _DetailRow(label: detail.$1, value: detail.$2),
        ],
        if (item.pendingActions.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Suggested actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < item.pendingActions.length; index++)
            _ActionRow(action: item.pendingActions[index], primary: index == 0),
        ],
        const SizedBox(height: 28),
        _DetailRow(
          label: 'Captured',
          value: DateFormat.yMMMd().add_jm().format(
            item.screenshot.createdAt.toLocal(),
          ),
        ),
        _DetailRow(
          label: 'Processing',
          value: item.screenshot.processingStatus.name,
        ),
        const SizedBox(height: 28),
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
    );
  }

  Future<void> _edit(BuildContext context, ExtractedObject object) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditInterpretationSheet(item: item, object: object),
    );
  }

  Future<void> _keep(BuildContext context, WidgetRef ref) async {
    await ref.read(screenshotCommandServiceProvider).keep(item.screenshot);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this screenshot?'),
        content: const Text(
          'Photos will show its native confirmation before anything is deleted.',
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
    if (context.mounted && deleted) Navigator.pop(context);
  }

  static List<(String, String)> _visibleDetails(Map<String, Object?> data) {
    const hidden = {
      'entityIds',
      'classificationReasons',
      '_userConfirmedFields',
    };
    return [
      for (final entry in data.entries)
        if (!hidden.contains(entry.key) &&
            !entry.key.startsWith('_') &&
            entry.value != null &&
            entry.value.toString().trim().isNotEmpty)
          (_humanize(entry.key), _formatValue(entry.value!)),
    ];
  }

  static String _humanize(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceFirstMapped(RegExp(r'^.'), (match) => match[0]!.toUpperCase());

  static String _formatValue(Object value) {
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null) {
        return DateFormat.yMMMd().add_jm().format(date.toLocal());
      }
    }
    return value.toString();
  }

  static String _typeLabel(ExtractedObjectType? type) {
    final value = type?.value ?? 'reference';
    return value == 'conversationTask' ? 'Conversation task' : _humanize(value);
  }
}

final class _ActionRow extends ConsumerStatefulWidget {
  const _ActionRow({required this.action, required this.primary});
  final SuggestedAction action;
  final bool primary;

  @override
  ConsumerState<_ActionRow> createState() => _ActionRowState();
}

final class _ActionRowState extends ConsumerState<_ActionRow> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final label = (widget.action.payload['label'] as String?) ?? 'Open';
    final visibleLabel = widget.action.status == SuggestedActionStatus.failed
        ? 'Retry $label'
        : label;
    final button = widget.primary
        ? FilledButton(
            onPressed: _busy ? null : _execute,
            child: Text(_busy ? 'Working…' : visibleLabel),
          )
        : OutlinedButton(
            onPressed: _busy ? null : _execute,
            child: Text(_busy ? 'Working…' : visibleLabel),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: button),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Dismiss $label',
            onPressed: _busy ? null : _dismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _execute() async {
    setState(() => _busy = true);
    try {
      var action = widget.action;
      if (action.type == SuggestedActionType.calendar) {
        final reviewed = await showModalBottomSheet<SuggestedAction>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _CalendarReviewSheet(action: action),
        );
        if (reviewed == null) return;
        action = reviewed;
      }
      await ref.read(actionExecutionServiceProvider).execute(action);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Action completed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    await ref.read(actionExecutionServiceProvider).dismiss(widget.action);
    if (mounted) setState(() => _busy = false);
  }
}

final class _CalendarReviewSheet extends StatefulWidget {
  const _CalendarReviewSheet({required this.action});

  final SuggestedAction action;

  @override
  State<_CalendarReviewSheet> createState() => _CalendarReviewSheetState();
}

final class _CalendarReviewSheetState extends State<_CalendarReviewSheet> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late DateTime _startsAt;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();
    final payload = widget.action.payload;
    final parsed = DateTime.tryParse(payload['startsAt'] as String? ?? '');
    _startsAt = parsed == null
        ? DateTime.now().add(const Duration(days: 1))
        : parsed.isUtc
        ? parsed.toLocal()
        : parsed;
    _isAllDay = payload['isAllDay'] == true;
    _title = TextEditingController(text: payload['title'] as String? ?? '');
    _location = TextEditingController(
      text: payload['location'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review event', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Confirm the extracted details before Calendar creates anything.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat.yMMMd().format(_startsAt)),
                ),
              ),
              if (!_isAllDay) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(DateFormat.jm().format(_startsAt)),
                  ),
                ),
              ],
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('All-day event'),
            value: _isAllDay,
            onChanged: (value) => setState(() => _isAllDay = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _title.text.trim().isEmpty ? null : _confirm,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (selected == null) return;
    setState(() {
      _startsAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _startsAt.hour,
        _startsAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (selected == null) return;
    setState(() {
      _startsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _confirm() {
    final payload = widget.action.payload;
    final durationMinutes = payload['defaultDurationMinutes'];
    final duration = Duration(
      minutes: durationMinutes is num
          ? durationMinutes.round()
          : _isAllDay
          ? const Duration(days: 1).inMinutes
          : const Duration(hours: 2).inMinutes,
    );
    final start = _isAllDay
        ? DateTime(_startsAt.year, _startsAt.month, _startsAt.day)
        : _startsAt;
    Navigator.pop(
      context,
      widget.action.copyWith(
        payload: {
          ...payload,
          'label': 'Add to Calendar',
          'title': _title.text.trim(),
          'location': _location.text.trim(),
          'startsAt': start.toIso8601String(),
          'endsAt': start.add(duration).toIso8601String(),
          'isAllDay': _isAllDay,
          'endTimeInferred': true,
        },
      ),
    );
  }
}

final class _EditInterpretationSheet extends ConsumerStatefulWidget {
  const _EditInterpretationSheet({required this.item, required this.object});
  final InboxItem item;
  final ExtractedObject object;

  @override
  ConsumerState<_EditInterpretationSheet> createState() =>
      _EditInterpretationSheetState();
}

final class _EditInterpretationSheetState
    extends ConsumerState<_EditInterpretationSheet> {
  late final TextEditingController _title;
  late ExtractedObjectType _type;
  DateTime? _importantDate;
  var _saving = false;

  static const _types = [
    ExtractedObjectType.event,
    ExtractedObjectType.coupon,
    ExtractedObjectType.place,
    ExtractedObjectType.product,
    ExtractedObjectType.conversationTask,
    ExtractedObjectType.order,
    ExtractedObjectType.reference,
    ExtractedObjectType.other,
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.object.title);
    _type = _types.contains(widget.object.type)
        ? widget.object.type
        : ExtractedObjectType.reference;
    _importantDate = widget.item.importantDate?.toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit interpretation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Your confirmed fields will not be overwritten by later processing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<ExtractedObjectType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final type in _types)
                DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.value.replaceAll(
                      'conversationTask',
                      'Conversation task',
                    ),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _importantDate == null
                  ? 'Set important date'
                  : DateFormat.yMMMd().format(_importantDate!),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving || _title.text.trim().isEmpty ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save corrections'),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _importantDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (selected == null) return;
    final previous = _importantDate;
    setState(() {
      _importantDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        previous?.hour ?? 9,
        previous?.minute ?? 0,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(interpretationServiceProvider)
        .correct(
          screenshot: widget.item.screenshot,
          object: widget.object,
          type: _type,
          title: _title.text,
          importantDate: _importantDate,
        );
    if (mounted) Navigator.pop(context);
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

final class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        SizedBox(
          width: 220,
          height: 286,
          child: ColoredBox(color: Color(0xFFEDEDED)),
        ),
        SizedBox(height: 26),
        SizedBox(height: 64, child: ColoredBox(color: Color(0xFFEDEDED))),
      ],
    ),
  );
}
