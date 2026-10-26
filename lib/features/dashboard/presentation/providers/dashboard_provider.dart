// Provider quản lý trạng thái dashboard
// Lấy dữ liệu từ SQLite qua repository, không truy cập DB trực tiếp
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/models/expense.dart';
import '../../../../domain/models/spending_summary.dart';
import '../../../../data/repositories/expense_repository_impl.dart';

/// Provider cho danh sách giao dịch gần nhất (5 cái)
final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getRecentExpenses(limit: 5);
});

/// Provider cho tóm tắt chi tiêu tháng hiện tại
final monthlySpendingSummaryProvider =
    FutureProvider<SpendingSummary>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final start = DateFormatter.firstDayOfMonth(now);
  final end = DateFormatter.lastDayOfMonth(now);

  final prevStart = DateTime(now.year, now.month - 1, 1);
  final prevEnd =
      DateFormatter.lastDayOfMonth(DateTime(now.year, now.month - 1));

  return repo.getSpendingSummary(
    startDate: start,
    endDate: end,
    previousStart: prevStart,
    previousEnd: prevEnd,
  );
});

/// Provider cho tổng chi tiêu tuần hiện tại
final weeklyTotalProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final days = DateFormatter.last7Days();
  return repo.getTotalAmount(
    startDate: days.first,
    endDate: days.last,
  );
});

/// Provider cho dữ liệu bar chart 7 ngày
final weeklyDailyTotalsProvider =
    FutureProvider<Map<DateTime, int>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final days = DateFormatter.last7Days();
  return repo.getDailyTotals(
    startDate: days.first,
    endDate: days.last,
  );
});
