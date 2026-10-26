// Dashboard — màn hình tổng quan chính
// Dùng dữ liệu thật từ SQLite, không dùng số liệu cố định
// AsyncValue xử lý loading, error, data state
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/spending_summary.dart';
import '../../../routing/app_router.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/expense_summary_card.dart';
import '../../statistics/presentation/widgets/donut_chart.dart';
import '../../statistics/presentation/widgets/weekly_bar_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monthlyAsync = ref.watch(monthlySpendingSummaryProvider);
    final recentAsync = ref.watch(recentExpensesProvider);
    final weeklyTotalsAsync = ref.watch(weeklyDailyTotalsProvider);
    final weeklyTotalAsync = ref.watch(weeklyTotalProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Làm mới tất cả providers
            ref
              ..invalidate(monthlySpendingSummaryProvider)
              ..invalidate(recentExpensesProvider)
              ..invalidate(weeklyDailyTotalsProvider)
              ..invalidate(weeklyTotalProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.colorScheme.surface,
                title: Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('VKU Expense AI'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.go(AppRoutes.settings),
                    tooltip: 'Cài đặt',
                  ),
                ],
              ),

              // Nội dung chính
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Card tổng chi tiêu tháng
                    monthlyAsync.when(
                      loading: () => const _SummaryCardSkeleton(),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (summary) => _MonthlyOverviewCard(summary: summary),
                    ),
                    const SizedBox(height: 16),

                    // Row: Chi tiêu tuần + Số GD
                    Row(
                      children: [
                        Expanded(
                          child: weeklyTotalAsync.when(
                            loading: () => const _SmallCardSkeleton(),
                            error: (_, __) =>
                                const _SmallStatCard(
                                    title: 'Tuần này', value: '--'),
                            data: (total) => _SmallStatCard(
                              title: 'Tuần này',
                              value: CurrencyFormatter.formatCompact(total),
                              icon: Icons.calendar_view_week,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: monthlyAsync.when(
                            loading: () => const _SmallCardSkeleton(),
                            error: (_, __) =>
                                const _SmallStatCard(
                                    title: 'Giao dịch', value: '--'),
                            data: (summary) => _SmallStatCard(
                              title: 'Giao dịch',
                              value: summary.transactionCount.toString(),
                              icon: Icons.receipt_long_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Biểu đồ Donut danh mục
                    Text(
                      'Phân bổ theo danh mục',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    monthlyAsync.when(
                      loading: () => const SizedBox(
                          height: 200, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (summary) => summary.categoryBreakdown.isEmpty
                          ? const _EmptyChart(
                              message: 'Chưa có giao dịch nào trong tháng này')
                          : DonutChart(
                              categories: summary.categoryBreakdown,
                              totalAmount: summary.totalAmount,
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Biểu đồ cột 7 ngày
                    Text(
                      '7 ngày gần nhất',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    weeklyTotalsAsync.when(
                      loading: () => const SizedBox(
                          height: 180, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (totals) => WeeklyBarChart(dailyTotals: totals),
                    ),
                    const SizedBox(height: 24),

                    // Giao dịch gần nhất
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giao dịch gần nhất',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.expenseList),
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    recentAsync.when(
                      loading: () => const _ListSkeleton(),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (expenses) => expenses.isEmpty
                          ? _EmptyExpenses(
                              onAdd: () => context.push(AppRoutes.addExpense))
                          : Column(
                              children: expenses
                                  .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ExpenseSummaryCard(
                                          expense: e,
                                          onTap: () => context.push(
                                              AppRoutes.editExpense
                                                  .replaceFirst(':id', '${e.id}')),
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 80), // Space for FAB
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút quét hóa đơn
          FloatingActionButton.small(
            heroTag: 'fab_scan',
            onPressed: () => context.push(AppRoutes.receiptScanner),
            tooltip: 'Quét hóa đơn',
            child: const Icon(Icons.document_scanner_outlined),
          ),
          const SizedBox(height: 8),
          // Nút thêm thủ công
          FloatingActionButton(
            heroTag: 'fab_add',
            onPressed: () => context.push(AppRoutes.addExpense),
            tooltip: 'Thêm giao dịch',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ===== WIDGETS NộI BỘ =====

class _MonthlyOverviewCard extends StatelessWidget {
  const _MonthlyOverviewCard({required this.summary});
  final SpendingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = summary.changePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiêu tháng ${DateFormatter.formatMonthYear(summary.periodStart)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                if (change != null)
                  Chip(
                    label: Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: change <= 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    backgroundColor: (change <= 0 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(summary.totalAmount),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (summary.previousPeriodAmount != null)
              Text(
                'Tháng trước: ${CurrencyFormatter.format(summary.previousPeriodAmount!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.title,
    required this.value,
    this.icon,
  });

  final String title;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: 20,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8)),
            const SizedBox(height: 8),
            Text(title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có giao dịch nào\nHãy thêm giao dịch đầu tiên của bạn!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm giao dịch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lỗi: $message',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _SmallCardSkeleton extends StatelessWidget {
  const _SmallCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Card(child: SizedBox(height: 72)),
        ),
      ),
    );
  }
}
