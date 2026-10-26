// Model tóm tắt chi tiêu dùng cho dashboard và AI advisor
library;

import 'expense_category.dart';

/// Tóm tắt chi tiêu theo danh mục
class CategorySummary {
  const CategorySummary({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  final ExpenseCategory category;
  final int totalAmount;
  final int transactionCount;

  /// Tỷ lệ % so với tổng chi tiêu (0.0 - 100.0)
  final double percentage;
}

/// Tóm tắt chi tiêu theo ngày (dùng cho bar chart)
class DailySummary {
  const DailySummary({
    required this.date,
    required this.totalAmount,
    required this.transactionCount,
  });

  final DateTime date;
  final int totalAmount;
  final int transactionCount;
}

/// Tóm tắt tổng chi tiêu cho dashboard
class SpendingSummary {
  const SpendingSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalAmount,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
    this.previousPeriodAmount,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalAmount;
  final int transactionCount;

  /// Chi tiết theo danh mục (đã sắp xếp theo tổng tiền giảm dần)
  final List<CategorySummary> categoryBreakdown;

  /// Chi tiết theo ngày trong tuần
  final List<DailySummary> dailyBreakdown;

  /// Tổng chi tiêu kỳ trước (để so sánh)
  final int? previousPeriodAmount;

  /// Thay đổi % so với kỳ trước (null nếu không có dữ liệu kỳ trước)
  double? get changePercentage {
    if (previousPeriodAmount == null || previousPeriodAmount == 0) return null;
    return ((totalAmount - previousPeriodAmount!) / previousPeriodAmount!) * 100;
  }

  /// Tóm tắt văn bản cho Gemini (không chứa dữ liệu nhạy cảm)
  Map<String, dynamic> toAiSummary() {
    return {
      'period': '${periodStart.toIso8601String().split('T')[0]} đến ${periodEnd.toIso8601String().split('T')[0]}',
      'total_amount_vnd': totalAmount,
      'transaction_count': transactionCount,
      'previous_period_amount_vnd': previousPeriodAmount,
      'change_percentage': changePercentage?.toStringAsFixed(1),
      'categories': categoryBreakdown.map((c) => {
        'name': c.category.displayName,
        'amount_vnd': c.totalAmount,
        'percentage': c.percentage.toStringAsFixed(1),
        'transaction_count': c.transactionCount,
      }).toList(),
    };
  }
}
