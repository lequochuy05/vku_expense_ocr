// Interface repository — UI không biết SQLite tồn tại
// Dependency inversion: UI phụ thuộc vào interface, không phải implementation
library;

import '../models/expense.dart';
import '../models/spending_summary.dart';
import '../models/expense_category.dart';

/// Interface cho tất cả thao tác với dữ liệu chi tiêu
/// Implementation: ExpenseRepositoryImpl (SQLite)
abstract interface class ExpenseRepository {
  /// Thêm giao dịch mới, trả về ID được gán
  Future<int> addExpense(Expense expense);

  /// Cập nhật giao dịch đã có
  Future<void> updateExpense(Expense expense);

  /// Xóa giao dịch theo ID
  /// Cũng xóa file ảnh nếu không giao dịch nào khác dùng ảnh đó
  Future<void> deleteExpense(int id);

  /// Lấy giao dịch theo ID
  Future<Expense?> getExpense(int id);

  /// Lấy danh sách giao dịch với filter
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
    String? searchQuery,
    String sortBy = 'transaction_date',
    bool descending = true,
    int? limit,
    int? offset,
  });

  /// Lấy giao dịch gần nhất (cho dashboard)
  Future<List<Expense>> getRecentExpenses({int limit = 5});

  /// Tổng chi tiêu trong khoảng ngày
  Future<int> getTotalAmount({DateTime? startDate, DateTime? endDate});

  /// Tóm tắt chi tiêu cho dashboard và AI
  Future<SpendingSummary> getSpendingSummary({
    required DateTime startDate,
    required DateTime endDate,
    DateTime? previousStart,
    DateTime? previousEnd,
  });

  /// Tổng chi tiêu theo danh mục trong khoảng ngày
  Future<Map<ExpenseCategory, int>> getCategoryTotals({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Chi tiêu theo từng ngày trong khoảng (cho bar chart)
  Future<Map<DateTime, int>> getDailyTotals({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Xóa tất cả dữ liệu (dùng trong settings)
  Future<void> clearAll();
}
