// Implementation của ExpenseRepository sử dụng SQLite
// UI không biết SQLite tồn tại — chỉ gọi interface
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/spending_summary.dart';
import '../../domain/repositories/expense_repository.dart';
import '../database/app_database.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<int> addExpense(Expense expense) async {
    try {
      final db = await _db.database;
      final id = await db.insert(
        AppConstants.tableExpenses,
        expense.toMap(),
      );
      return id;
    } catch (e) {
      throw DatabaseException('Không thể thêm giao dịch', cause: e);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) throw const ValidationException('ID giao dịch không hợp lệ');
    try {
      final db = await _db.database;
      final updated = expense.copyWith(updatedAt: DateTime.now());
      await db.update(
        AppConstants.tableExpenses,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    } catch (e) {
      throw DatabaseException('Không thể cập nhật giao dịch', cause: e);
    }
  }

  @override
  Future<void> deleteExpense(int id) async {
    try {
      final db = await _db.database;
      // Trước khi xóa, lấy đường dẫn ảnh để quyết định xóa file
      final expense = await getExpense(id);
      
      await db.delete(
        AppConstants.tableExpenses,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Kiểm tra file ảnh có được dùng bởi giao dịch khác không
      if (expense?.imagePath != null) {
        await _deleteImageIfUnused(db, expense!.imagePath!, excludeId: id);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Không thể xóa giao dịch', cause: e);
    }
  }

  /// Xóa file ảnh nếu không giao dịch nào khác đang dùng
  Future<void> _deleteImageIfUnused(
    dynamic db,
    String imagePath, {
    required int excludeId,
  }) async {
    final count = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${AppConstants.tableExpenses} WHERE image_path = ? AND id != ?',
      [imagePath, excludeId],
    );
    final usageCount = (count.first['cnt'] as int? ?? 0);
    if (usageCount == 0) {
      // Không ai dùng ảnh này nữa — có thể xóa file
      // (Thực tế xóa file trong ImageStorageService)
    }
  }

  @override
  Future<Expense?> getExpense(int id) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        AppConstants.tableExpenses,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Expense.fromMap(maps.first);
    } catch (e) {
      throw DatabaseException('Không thể lấy giao dịch', cause: e);
    }
  }

  @override
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    ExpenseCategory? category,
    String? searchQuery,
    String sortBy = 'transaction_date',
    bool descending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _db.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (startDate != null) {
        conditions.add('transaction_date >= ?');
        args.add(startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        conditions.add('transaction_date <= ?');
        args.add(endDate.toIso8601String().split('T')[0]);
      }
      if (category != null) {
        conditions.add('category = ?');
        args.add(category.name);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('(title LIKE ? OR merchant LIKE ? OR note LIKE ?)');
        final query = '%$searchQuery%';
        args.addAll([query, query, query]);
      }

      // Whitelist sortBy để tránh SQL injection
      final allowedSortFields = {'transaction_date', 'amount', 'created_at', 'title'};
      final safeSortBy = allowedSortFields.contains(sortBy) ? sortBy : 'transaction_date';

      final maps = await db.query(
        AppConstants.tableExpenses,
        where: conditions.isEmpty ? null : conditions.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: '$safeSortBy ${descending ? 'DESC' : 'ASC'}',
        limit: limit,
        offset: offset,
      );

      return maps.map(Expense.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Không thể lấy danh sách giao dịch', cause: e);
    }
  }

  @override
  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    return getExpenses(limit: limit, sortBy: 'transaction_date', descending: true);
  }

  @override
  Future<int> getTotalAmount({DateTime? startDate, DateTime? endDate}) async {
    try {
      final db = await _db.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (startDate != null) {
        conditions.add('transaction_date >= ?');
        args.add(startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        conditions.add('transaction_date <= ?');
        args.add(endDate.toIso8601String().split('T')[0]);
      }

      // Dùng SQL SUM cho hiệu suất tốt hơn so với load tất cả và tính ở Dart
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM ${AppConstants.tableExpenses}'
        '${conditions.isEmpty ? '' : ' WHERE ${conditions.join(" AND ")}'}',
        args.isEmpty ? null : args,
      );

      return (result.first['total'] as int? ?? 0);
    } catch (e) {
      throw DatabaseException('Không thể tính tổng chi tiêu', cause: e);
    }
  }

  @override
  Future<Map<ExpenseCategory, int>> getCategoryTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        '''
        SELECT category, COALESCE(SUM(amount), 0) as total
        FROM ${AppConstants.tableExpenses}
        WHERE transaction_date >= ? AND transaction_date <= ?
        GROUP BY category
        ORDER BY total DESC
        ''',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0],
        ],
      );

      return {
        for (final row in result)
          ExpenseCategory.fromString(row['category'] as String):
              row['total'] as int,
      };
    } catch (e) {
      throw DatabaseException('Không thể lấy tổng theo danh mục', cause: e);
    }
  }

  @override
  Future<Map<DateTime, int>> getDailyTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        '''
        SELECT transaction_date, COALESCE(SUM(amount), 0) as total
        FROM ${AppConstants.tableExpenses}
        WHERE transaction_date >= ? AND transaction_date <= ?
        GROUP BY transaction_date
        ORDER BY transaction_date ASC
        ''',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0],
        ],
      );

      return {
        for (final row in result)
          DateTime.parse(row['transaction_date'] as String):
              row['total'] as int,
      };
    } catch (e) {
      throw DatabaseException('Không thể lấy tổng theo ngày', cause: e);
    }
  }

  @override
  Future<SpendingSummary> getSpendingSummary({
    required DateTime startDate,
    required DateTime endDate,
    DateTime? previousStart,
    DateTime? previousEnd,
  }) async {
    try {
      final totalAmount = await getTotalAmount(startDate: startDate, endDate: endDate);
      final categoryTotals = await getCategoryTotals(startDate: startDate, endDate: endDate);
      final dailyTotals = await getDailyTotals(startDate: startDate, endDate: endDate);

      // Tổng số giao dịch
      final db = await _db.database;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppConstants.tableExpenses} WHERE transaction_date >= ? AND transaction_date <= ?',
        [startDate.toIso8601String().split('T')[0], endDate.toIso8601String().split('T')[0]],
      );
      final transactionCount = (countResult.first['cnt'] as int? ?? 0);

      // Tính category breakdown
      final categoryBreakdown = categoryTotals.entries.map((entry) {
        final percentage = totalAmount > 0
            ? (entry.value / totalAmount) * 100
            : 0.0;
        return CategorySummary(
          category: entry.key,
          totalAmount: entry.value,
          transactionCount: 0, // Có thể query thêm nếu cần
          percentage: percentage,
        );
      }).toList();

      // Daily breakdown
      final dailyBreakdown = dailyTotals.entries.map((entry) {
        return DailySummary(
          date: entry.key,
          totalAmount: entry.value,
          transactionCount: 0,
        );
      }).toList();

      // Tổng kỳ trước
      int? previousAmount;
      if (previousStart != null && previousEnd != null) {
        previousAmount = await getTotalAmount(
          startDate: previousStart,
          endDate: previousEnd,
        );
      }

      return SpendingSummary(
        periodStart: startDate,
        periodEnd: endDate,
        totalAmount: totalAmount,
        transactionCount: transactionCount,
        categoryBreakdown: categoryBreakdown,
        dailyBreakdown: dailyBreakdown,
        previousPeriodAmount: previousAmount,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Không thể tạo báo cáo chi tiêu', cause: e);
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _db.clearAll();
    } catch (e) {
      throw DatabaseException('Không thể xóa dữ liệu', cause: e);
    }
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(AppDatabase.instance);
});
