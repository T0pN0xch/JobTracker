import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/job_application.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/application_card.dart';

enum SortOption {
  dateAppliedNewest,
  dateAppliedOldest,
  companyName,
  status,
  priority,
}

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.dateAppliedNewest:
        return 'Date applied (newest)';
      case SortOption.dateAppliedOldest:
        return 'Date applied (oldest)';
      case SortOption.companyName:
        return 'Company name';
      case SortOption.status:
        return 'Status';
      case SortOption.priority:
        return 'Priority';
    }
  }

  String get orderByClause {
    switch (this) {
      case SortOption.dateAppliedNewest:
        return 'dateApplied DESC';
      case SortOption.dateAppliedOldest:
        return 'dateApplied ASC';
      case SortOption.companyName:
        return 'company COLLATE NOCASE ASC';
      case SortOption.status:
        return 'status ASC';
      case SortOption.priority:
        return 'priority ASC';
    }
  }
}

class HomeTabContent extends StatefulWidget {
  final SortOption sortOption;
  final Future<void> Function({JobApplication? application}) onOpenAddEdit;

  const HomeTabContent({
    super.key,
    required this.sortOption,
    required this.onOpenAddEdit,
  });

  @override
  State<HomeTabContent> createState() => HomeTabContentState();
}

class HomeTabContentState extends State<HomeTabContent> {
  List<JobApplication> _applications = [];
  Map<JobStatus, int> _totalCounts = {};
  bool _loading = true;

  String _searchQuery = '';
  JobStatus? _statusFilter;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(HomeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortOption != widget.sortOption) _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void reload() => _loadAll();

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getAll(
        statusFilter: _statusFilter,
        searchQuery: _searchQuery,
        orderBy: widget.sortOption.orderByClause,
      ),
      DatabaseHelper.instance.getStatusCounts(),
    ]);
    if (!mounted) return;
    setState(() {
      _applications = results[0] as List<JobApplication>;
      _totalCounts = results[1] as Map<JobStatus, int>;
      _loading = false;
    });
  }

  Future<void> _deleteApplication(JobApplication application) async {
    if (application.id == null) return;
    await DatabaseHelper.instance.delete(application.id!);
    await NotificationService.instance.cancelReminder(application.id!);
    _loadAll();
  }

  Future<bool> _confirmDelete(JobApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete application?'),
        content: Text(
          'Remove ${application.company}'
          '${application.position?.isNotEmpty == true ? ' — ${application.position}' : ''}?\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBE123C)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PipelineStrip(
          counts: _totalCounts,
          activeFilter: _statusFilter,
          onTap: (status) {
            setState(() =>
                _statusFilter = _statusFilter == status ? null : status);
            _loadAll();
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search company or position…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadAll();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _loadAll();
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _FilterChip(
                label: 'All',
                selected: _statusFilter == null,
                onTap: () {
                  setState(() => _statusFilter = null);
                  _loadAll();
                },
              ),
              ...JobStatus.values.map(
                (status) => _FilterChip(
                  label: status.label,
                  selected: _statusFilter == status,
                  onTap: () {
                    setState(() => _statusFilter = status);
                    _loadAll();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _applications.isEmpty
                  ? _EmptyState(
                      hasFilter: _statusFilter != null ||
                          _searchQuery.isNotEmpty)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadAll,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.only(bottom: 96, top: 4),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          return Dismissible(
                            key: ValueKey(app.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFBE123C),
                                  size: 26),
                            ),
                            confirmDismiss: (_) => _confirmDelete(app),
                            onDismissed: (_) => _deleteApplication(app),
                            child: ApplicationCard(
                              application: app,
                              onTap: () =>
                                  widget.onOpenAddEdit(application: app),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Pipeline Infographic ──────────────────────────────────────────────────────

class _PipelineStrip extends StatelessWidget {
  final Map<JobStatus, int> counts;
  final JobStatus? activeFilter;
  final void Function(JobStatus) onTap;

  static const _pipeline = [
    JobStatus.wishlist,
    JobStatus.applied,
    JobStatus.phoneScreen,
    JobStatus.interview,
    JobStatus.offer,
  ];

  const _PipelineStrip({
    required this.counts,
    required this.activeFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    final applied = counts[JobStatus.applied] ?? 0;
    final interview = counts[JobStatus.interview] ?? 0;
    final offer = counts[JobStatus.offer] ?? 0;

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _QuickStat(
                    value: total,
                    label: 'Total',
                    color: AppColors.primary),
                _vDivider(),
                _QuickStat(
                    value: applied,
                    label: 'Applied',
                    color: const Color(0xFF15803D)),
                _vDivider(),
                _QuickStat(
                    value: interview,
                    label: 'Interview',
                    color: const Color(0xFFB45309)),
                if (offer > 0) ...[
                  _vDivider(),
                  _QuickStat(
                      value: offer,
                      label: 'Offer 🎉',
                      color: const Color(0xFF065F46)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              'Pipeline',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              itemCount: _pipeline.length * 2 - 1,
              itemBuilder: (context, index) {
                if (index.isOdd) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFFD1D5DB)),
                  );
                }
                final status = _pipeline[index ~/ 2];
                final count = counts[status] ?? 0;
                final (bg, text) = AppColors.forStatus(status);
                final isActive = activeFilter == status;
                return GestureDetector(
                  onTap: () => onTap(status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 84,
                    margin: const EdgeInsets.only(bottom: 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? text : bg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                  color: text.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isActive ? Colors.white : text,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.85)
                                : text.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        width: 1,
        height: 28,
        color: AppColors.border,
      );
}

class _QuickStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _QuickStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.work_outline_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No matches found' : 'No applications yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try adjusting your search or filter'
                  : 'Tap + to add your first job application',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
