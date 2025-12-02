// lib/features/activity/ui/activity_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// DS
import 'package:progear_smart_bag/core/theme/progear_background.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

// Data
import 'package:progear_smart_bag/features/weight/data/weight_repository.dart';
import 'package:progear_smart_bag/features/weight/domain/models/weight_entry.dart';
import 'package:progear_smart_bag/features/notifications/data/notifications_repository.dart';
import 'package:progear_smart_bag/features/notifications/domain/models/notification_event.dart';

// Local seen-store
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';

enum ActivityFilter { all, weight, resets }

class ActivityPage extends StatefulWidget {
  final String controllerID;
  const ActivityPage({super.key, required this.controllerID});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  late final WeightRepository _weightsRepo;
  late final NotificationsRepository _notesRepo;

  bool _loading = false;
  ActivityFilter _filter = ActivityFilter.all;

  // Unified feed
  List<_ActivityItem> _items = [];

  // Unread badges
  int _badgeAll = 0;
  int _badgeWeight = 0;
  int _badgeNotes = 0; // (resets)

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;
    _weightsRepo = WeightRepository(sb);
    _notesRepo = NotificationsRepository(sb);
    _load();
  }

  /// then clear the header dot (inside Activity).
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cid = widget.controllerID;

      final results = await Future.wait([
        _weightsRepo.fetchHistory(controllerID: cid, limit: 50),
        _notesRepo.fetch(controllerID: cid, limit: 50),
        ActivitySeenStore.instance.lastSeenAll(cid),
        ActivitySeenStore.instance.lastSeenWeight(cid),
        ActivitySeenStore.instance.lastSeenNotes(cid),
      ]);

      final weights = (results[0] as List<WeightEntry>)
          .map((w) => _ActivityItem.weight(w))
          .toList();

      // Show only weight-related notes in UI (resets/deltas)
      final notesRaw = (results[1] as List<NotificationEvent>);
      final notes = notesRaw
          .where((n) => const {'weight_reset', 'weight_delta'}
              .contains(n.kind.toLowerCase()))
          .map((n) => _ActivityItem.note(n))
          .toList();

      final lastAll = results[2] as DateTime?;
      final lastWeight = results[3] as DateTime?;
      final lastNotes = results[4] as DateTime?;

      final merged = [...weights, ...notes]
        ..sort((a, b) => b.time.compareTo(a.time));

      // Compute badges: items newer than last-seen per category.
      final unreadAll = merged
          .where((i) => lastAll == null || i.time.isAfter(lastAll))
          .length;
      final unreadW = weights
          .where((w) => lastWeight == null || w.time.isAfter(lastWeight))
          .length;
      final unreadN = notes
          .where((n) => lastNotes == null || n.time.isAfter(lastNotes))
          .length;

      if (!mounted) return;
      setState(() {
        _items = merged;
        _badgeAll = unreadAll;
        _badgeWeight = unreadW;
        _badgeNotes = unreadN;
      });

      // visited Activity? --> remove header dot.
      await ActivitySeenStore.instance.clearUnread(cid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load activity: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// When a filter is selected: mark it as seen now, clear its badge immediately.
  Future<void> _onSelectFilter(ActivityFilter f) async {
    setState(() => _filter = f);
    final cid = widget.controllerID;
    switch (f) {
      case ActivityFilter.all:
        await ActivitySeenStore.instance.markSeenAll(cid);
        setState(() => _badgeAll = 0);
        break;
      case ActivityFilter.weight:
        await ActivitySeenStore.instance.markSeenWeight(cid);
        setState(() => _badgeWeight = 0);
        break;
      case ActivityFilter.resets:
        await ActivitySeenStore.instance.markSeenNotes(cid);
        setState(() => _badgeNotes = 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply current filter
    final visible = _items.where((it) {
      switch (_filter) {
        case ActivityFilter.all:
          return true;
        case ActivityFilter.weight:
          return it.kind == _Kind.weight;
        case ActivityFilter.resets:
          return it.kind == _Kind.note; // reset/delta notes
      }
    }).toList();

    return Scaffold(
      body: ProGearBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Activity',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2,
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Filters + badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      badge: _badgeAll,
                      selected: _filter == ActivityFilter.all,
                      onTap: () => _onSelectFilter(ActivityFilter.all),
                    ),
                    _FilterChip(
                      label: 'Weight',
                      badge: _badgeWeight,
                      selected: _filter == ActivityFilter.weight,
                      onTap: () => _onSelectFilter(ActivityFilter.weight),
                    ),
                    _FilterChip(
                      label: 'Resets',
                      badge: _badgeNotes,
                      selected: _filter == ActivityFilter.resets,
                      onTap: () => _onSelectFilter(ActivityFilter.resets),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : (visible.isEmpty
                        ? const Center(
                            child: Text(
                              'No activity yet.',
                              style: AppTextStyles.secondary,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.10),
                            color: AppColors.primaryBlue,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.lg,
                                vertical: AppSizes.md,
                              ),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSizes.md),
                              itemBuilder: (_, i) =>
                                  _ActivityTile(item: visible[i]),
                            ),
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- UI helpers ----------

class _FilterChip extends StatelessWidget {
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badge > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: AppTextStyles.secondary.copyWith(
                    fontSize: AppSizes.fontSm,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _Kind { weight, note }

class _ActivityItem {
  final _Kind kind;
  final DateTime time;
  final WeightEntry? weight;
  final NotificationEvent? note;

  _ActivityItem.weight(this.weight)
      : kind = _Kind.weight,
        time = weight!.time,
        note = null;

  _ActivityItem.note(this.note)
      : kind = _Kind.note,
        time = note!.time,
        weight = null;
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityTile({required this.item});

  String _fmt(DateTime t) => DateFormat('dd MMM yyyy • HH:mm').format(t);

  (Color, IconData) _noteVisuals(NotificationEvent n) {
    final sev = (n.severity).toLowerCase();
    Color color = switch (sev) {
      'success' => const Color(0xFF159B00),
      'warn' => const Color(0xFFFFCC00),
      'error' => const Color(0xFFDD0000),
      _ => Colors.white70,
    };
    IconData icon = switch (sev) {
      'success' => Icons.check_circle_rounded,
      'warn' => Icons.warning_rounded,
      'error' => Icons.error_rounded,
      _ => Icons.notifications_none_rounded,
    };

    final kind = (n.kind).toLowerCase();
    if (kind == 'weight_reset') {
      icon = Icons.scale_rounded;
      color = const Color(0xFF159B00);
    } else if (kind == 'weight_delta') {
      icon = Icons.monitor_weight_rounded;
      color = const Color(0xFFFFCC00);
    }

    return (color, icon);
  }

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case _Kind.weight:
        final w = item.weight!;
        final delta = w.deltaG;
        final isUp = delta > 0;
        final color = delta == 0
            ? Colors.white70
            : (isUp ? const Color(0xFF159B00) : const Color(0xFFDD0000));
        final icon = delta == 0
            ? Icons.remove_rounded
            : (isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: delta == 0
                      ? Colors.white24
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current: ${w.currentG.toStringAsFixed(1)} g',
                        style: AppTextStyles.secondarybody),
                    const SizedBox(height: 2),
                    Text(
                        'Expected: ${w.expectedSnapshotG.toStringAsFixed(1)} g',
                        style: AppTextStyles.button),
                    const SizedBox(height: 4),
                    Text(_fmt(w.time),
                        style: AppTextStyles.secondary
                            .copyWith(fontSize: AppSizes.fontSm)),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} g',
                style: AppTextStyles.heading1.copyWith(color: color),
              ),
            ],
          ),
        );

      case _Kind.note:
        final n = item.note!;
        final (color, icon) = _noteVisuals(n);

        String? metaLine;
        final meta = n.meta;
        if (meta != null) {
          if (n.kind.toLowerCase() == 'weight_reset' &&
              meta['current_g'] != null) {
            metaLine = 'Snapshot: ${meta['current_g']} g';
          } else if (n.kind.toLowerCase() == 'weight_delta' &&
              meta['delta_g'] != null) {
            final d = (meta['delta_g'] as num).toDouble();
            metaLine = 'Delta: ${d.toStringAsFixed(1)} g';
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: AppTextStyles.secondarybody),
                    const SizedBox(height: 2),
                    Text(n.message, style: AppTextStyles.button),
                    if (metaLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaLine,
                        style: AppTextStyles.secondary
                            .copyWith(fontSize: AppSizes.fontSm),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(_fmt(n.time),
                        style: AppTextStyles.secondary
                            .copyWith(fontSize: AppSizes.fontSm)),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
