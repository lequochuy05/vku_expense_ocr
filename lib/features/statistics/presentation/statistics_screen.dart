// Màn hình thống kê chi tiêu — donut chart + bar chart + bảng phân tích
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/spending_summary.dart';
import '../../../data/repositories/expense_repository_impl.dart';
import 'widgets/donut_chart.dart';
import 'widgets/weekly_bar_chart.dart';

enum StatsPeriod {
  thisWeek('Tuần này'),
  thisMonth('Tháng này'),
  last30Days('30 ngày qua'),
  last90Days('3 tháng qua');

  const StatsPeriod(this.label);
  final String label;
}

class StatsPeriodNotifier extends StateNotifier<StatsPeriod> {
  StatsPeriodNotifier() : super(StatsPeriod.thisMonth);

  void set(StatsPeriod period) => state = period;
}

final statsPeriodNotifierProvider =
    StateNotifierProvider<StatsPeriodNotifier, StatsPeriod>((ref) {
  return StatsPeriodNotifier();
});

final statisticsSummaryProvider =
    FutureProvider<SpendingSummary>((ref) async {
  final period = ref.watch(statsPeriodNotifierProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();

  late DateTime start;
  late DateTime end;
  DateTime? prevStart;
  DateTime? prevEnd;

  switch (period) {
    case StatsPeriod.thisWeek:
      final days = DateFormatter.last7Days();
      start = days.first;
      end = days.last;
      prevStart = start.subtract(const Duration(days: 7));
      prevEnd = end.subtract(const Duration(days: 7));
    case StatsPeriod.thisMonth:
      start = DateFormatter.firstDayOfMonth(now);
      end = DateFormatter.lastDayOfMonth(now);
      prevStart =
          DateFormatter.firstDayOfMonth(DateTime(now.year, now.month - 1));
      prevEnd =
          DateFormatter.lastDayOfMonth(DateTime(now.year, now.month - 1));
    case StatsPeriod.last30Days:
      end = now;
      start = now.subtract(const Duration(days: 30));
      prevStart = start.subtract(const Duration(days: 30));
      prevEnd = start;
    case StatsPeriod.last90Days:
      end = now;
      start = now.subtract(const Duration(days: 90));
  }

  return repo.getSpendingSummary(
    startDate: start,
    endDate: end,
    previousStart: prevStart,
    previousEnd: prevEnd,
  );
});

final statisticsDailyTotalsProvider =
    FutureProvider<Map<DateTime, int>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final days = DateFormatter.last7Days();
  return repo.getDailyTotals(
    startDate: days.first,
    endDate: days.last,
  );
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodNotifierProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);
    final dailyAsync = ref.watch(statisticsDailyTotalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                ..invalidate(statisticsSummaryProvider)
                ..invalidate(statisticsDailyTotalsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: StatsPeriod.values
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: period == p,
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(statsPeriodNotifierProvider.notifier)
                                    .set(p);
                              }
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Nội dung
          Expanded(
            child: summaryAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lỗi: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(statisticsSummaryProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (summary) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tổng quan
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tổng chi tiêu',
                                    style: theme.textTheme.bodySmall),
                                Text(
                                  CurrencyFormatter.format(summary.totalAmount),
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${summary.transactionCount} giao dịch',
                                  style: theme.textTheme.bodySmall),
                              if (summary.changePercentage != null)
                                Text(
                                  '${summary.changePercentage! >= 0 ? '+' : ''}'  
                                  '${summary.changePercentage!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: summary.changePercentage! <= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Donut chart
                  Text('Phân bổ danh mục',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  summary.totalAmount > 0
                      ? DonutChart(
                          categories: summary.categoryBreakdown,
                          totalAmount: summary.totalAmount,
                        )
                      : const _EmptyState(),
                  const SizedBox(height: 24),

                  // Bar chart
                  Text('Chi tiêu 7 ngày qua',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  dailyAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                    data: (totals) => WeeklyBarChart(dailyTotals: totals),
                  ),
                  const SizedBox(height: 24),

                  // Bảng phân loại
                  if (summary.categoryBreakdown.isNotEmpty) ...[
                    Text('Chi tiết theo danh mục',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...summary.categoryBreakdown.map((cat) => Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cat.category.color
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.category.icon,
                                  color: cat.category.color, size: 20),
                            ),
                            title: Text(cat.category.displayName),
                            subtitle: Text(
                                '${cat.percentage.toStringAsFixed(1)}%'),
                            trailing: Text(
                              CurrencyFormatter.format(cat.totalAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          const Text('Không có dữ liệu trong kỳ này'),
        ],
      ),
    );
  }
}
