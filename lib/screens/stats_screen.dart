import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/job_application.dart';
import '../theme/app_theme.dart';

class StatsTabContent extends StatefulWidget {
  const StatsTabContent({super.key});

  @override
  State<StatsTabContent> createState() => _StatsTabContentState();
}

class _StatsTabContentState extends State<StatsTabContent> {
  static const _weeks = 8;

  Map<JobStatus, int> _statusCounts = {};
  List<int> _weeklyCounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getStatusCounts(),
      DatabaseHelper.instance.getWeeklyApplicationCounts(_weeks),
    ]);
    if (!mounted) return;
    setState(() {
      _statusCounts = results[0] as Map<JobStatus, int>;
      _weeklyCounts = results[1] as List<int>;
      _loading = false;
    });
  }

  int get _wishlistCount => _statusCounts[JobStatus.wishlist] ?? 0;
  int get _nonWishlistTotal => _statusCounts.entries
      .where((e) => e.key != JobStatus.wishlist)
      .fold(0, (sum, e) => sum + e.value);
  int get _total => _nonWishlistTotal + _wishlistCount;

  int _countAtOrBeyond(JobStatus threshold) {
    final order = JobStatus.values;
    final idx = order.indexOf(threshold);
    return _statusCounts.entries
        .where((e) =>
            e.key != JobStatus.wishlist && order.indexOf(e.key) >= idx)
        .fold(0, (sum, e) => sum + e.value);
  }

  double get _responseRate {
    if (_nonWishlistTotal == 0) return 0;
    return _countAtOrBeyond(JobStatus.phoneScreen) / _nonWishlistTotal * 100;
  }

  double get _interviewRate {
    if (_nonWishlistTotal == 0) return 0;
    return _countAtOrBeyond(JobStatus.interview) / _nonWishlistTotal * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _HeroCard(
            total: _total,
            applied: _nonWishlistTotal,
            wishlist: _wishlistCount,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RingGauge(
                  label: 'Response Rate',
                  sublabel: 'Got past Applied',
                  percentage: _responseRate,
                  color: const Color(0xFF0F766E),
                  lightColor: const Color(0xFFCCFBF1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RingGauge(
                  label: 'Interview Rate',
                  sublabel: 'Reached interview',
                  percentage: _interviewRate,
                  color: const Color(0xFFB45309),
                  lightColor: const Color(0xFFFEF3C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FunnelCard(statusCounts: _statusCounts),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Status Breakdown',
            icon: Icons.donut_large_rounded,
            child: SizedBox(
              height: 220,
              child: _StatusBarChart(statusCounts: _statusCounts),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Applications — Last $_weeks Weeks',
            icon: Icons.trending_up_rounded,
            child: SizedBox(
              height: 180,
              child: _WeeklyLineChart(weeklyCounts: _weeklyCounts),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final int total;
  final int applied;
  final int wishlist;

  const _HeroCard(
      {required this.total, required this.applied, required this.wishlist});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? applied / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B50C8), Color(0xFF9B8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Applications',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _HeroBadge(
                      label: 'Applied',
                      count: applied,
                      bg: Colors.white24,
                      fg: Colors.white),
                  const SizedBox(height: 6),
                  _HeroBadge(
                      label: 'Wishlist',
                      count: wishlist,
                      bg: Colors.white12,
                      fg: Colors.white70),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(ratio * 100).toStringAsFixed(0)}% in active pipeline',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(100 - ratio * 100).toStringAsFixed(0)}% wishlist',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color bg;
  final Color fg;

  const _HeroBadge(
      {required this.label,
      required this.count,
      required this.bg,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count ',
              style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          Text(label,
              style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Ring Gauge ────────────────────────────────────────────────────────────────

class _RingGauge extends StatelessWidget {
  final String label;
  final String sublabel;
  final double percentage;
  final Color color;
  final Color lightColor;

  const _RingGauge({
    required this.label,
    required this.sublabel,
    required this.percentage,
    required this.color,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percentage.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: pct == 0 ? 0.001 : pct,
                        color: color,
                        radius: 14,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: pct >= 100 ? 0.001 : (100 - pct),
                        color: lightColor,
                        radius: 14,
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: pct > 0 && pct < 100 ? 2 : 0,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Conversion Funnel ─────────────────────────────────────────────────────────

class _FunnelCard extends StatelessWidget {
  final Map<JobStatus, int> statusCounts;

  static const _stages = [
    JobStatus.applied,
    JobStatus.phoneScreen,
    JobStatus.interview,
    JobStatus.offer,
    JobStatus.rejected,
  ];

  const _FunnelCard({required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    final baseline = statusCounts[JobStatus.applied] ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Conversion Funnel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'vs. ${statusCounts[JobStatus.applied] ?? 0} applied',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._stages.map((status) {
            final count = statusCounts[status] ?? 0;
            final (bg, fg) = AppColors.forStatus(status);
            final ratio =
                baseline > 0 ? (count / baseline).clamp(0.0, 1.0) : 0.0;
            final pct =
                baseline > 0 ? (count / baseline * 100) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      status.label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(
                                  height: 26, color: bg),
                              FractionallySizedBox(
                                widthFactor: ratio == 0 ? 0.015 : ratio,
                                child: Container(
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: fg,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      count.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: ratio > 0.25
                                            ? Colors.white
                                            : fg,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text(
                      status == JobStatus.applied
                          ? '100%'
                          : '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Section Card Wrapper ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Status Bar Chart ──────────────────────────────────────────────────────────

class _StatusBarChart extends StatelessWidget {
  final Map<JobStatus, int> statusCounts;
  const _StatusBarChart({required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    final statuses = JobStatus.values;
    final maxCount = statusCounts.values.isEmpty
        ? 1
        : statusCounts.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxCount + 1).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              '${statuses[groupIndex].label}\n${rod.toY.toInt()}',
              const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 5),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= statuses.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(statuses[i].label,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        barGroups: [
          for (var i = 0; i < statuses.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (statusCounts[statuses[i]] ?? 0).toDouble(),
                  color: AppColors.forStatus(statuses[i]).$1,
                  borderSide: BorderSide(
                      color: AppColors.forStatus(statuses[i])
                          .$2
                          .withValues(alpha: 0.5),
                      width: 1),
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Weekly Line Chart ─────────────────────────────────────────────────────────

class _WeeklyLineChart extends StatelessWidget {
  final List<int> weeklyCounts;
  const _WeeklyLineChart({required this.weeklyCounts});

  @override
  Widget build(BuildContext context) {
    if (weeklyCounts.every((v) => v == 0)) {
      return const Center(
        child: Text('No data yet',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
    }

    final maxCount = weeklyCounts.isEmpty
        ? 1
        : weeklyCounts.reduce((a, b) => a > b ? a : b);

    final spots = [
      for (var i = 0; i < weeklyCounts.length; i++)
        FlSpot(i.toDouble(), weeklyCounts[i].toDouble()),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (weeklyCounts.length - 1).toDouble(),
        minY: 0,
        maxY: (maxCount + 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 24),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                final weeksAgo = weeklyCounts.length - 1 - i;
                if (i < 0 || i >= weeklyCounts.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    weeksAgo == 0 ? 'Now' : '-${weeksAgo}w',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()} apps',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
