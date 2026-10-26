import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/core/constants/app_constants.dart';
import 'package:vku_expense_ocr/data/database/app_database.dart';
import 'package:vku_expense_ocr/data/repositories/expense_repository_impl.dart';
import 'package:vku_expense_ocr/domain/models/expense.dart';
import 'package:vku_expense_ocr/domain/models/expense_category.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late ExpenseRepositoryImpl repository;

  setUp(() async {
    repository = ExpenseRepositoryImpl(AppDatabase.instance);
    await repository.clearAll();
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  group('SQLite Database CRUD & Aggregation Unit Tests', () {
    test('addExpense inserts record and returns valid ID', () async {
      final now = DateTime.now();
      final expense = Expense(
        title: 'Cà phê sáng',
        amount: 35000,
        category: ExpenseCategory.food,
        transactionDate: now,
        sourceType: AppConstants.sourceManual,
        merchant: 'Highlands Coffee',
        paymentMethod: 'cash',
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.addExpense(expense);
      expect(id, isPositive);

      final fetched = await repository.getExpense(id);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Cà phê sáng'));
      expect(fetched.amount, equals(35000));
      expect(fetched.category, equals(ExpenseCategory.food));
      expect(fetched.merchant, equals('Highlands Coffee'));
    });

    test('updateExpense updates record fields accurately', () async {
      final now = DateTime.now();
      final expense = Expense(
        title: 'Đổ xăng',
        amount: 50000,
        category: ExpenseCategory.transport,
        transactionDate: now,
        sourceType: AppConstants.sourceManual,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.addExpense(expense);
      final inserted = await repository.getExpense(id);

      final updated = inserted!.copyWith(
        title: 'Đổ xăng xe máy',
        amount: 60000,
      );
      await repository.updateExpense(updated);

      final reFetched = await repository.getExpense(id);
      expect(reFetched!.title, equals('Đổ xăng xe máy'));
      expect(reFetched.amount, equals(60000));
    });

    test('deleteExpense removes record from database', () async {
      final now = DateTime.now();
      final expense = Expense(
        title: 'Mua sách',
        amount: 120000,
        category: ExpenseCategory.education,
        transactionDate: now,
        sourceType: AppConstants.sourceManual,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.addExpense(expense);
      expect(await repository.getExpense(id), isNotNull);

      await repository.deleteExpense(id);
      expect(await repository.getExpense(id), isNull);
    });

    test('getExpenses filters by category and searchQuery', () async {
      final now = DateTime.now();
      await repository.addExpense(Expense(
        title: 'Bún bò Huế',
        amount: 40000,
        category: ExpenseCategory.food,
        transactionDate: now,
        sourceType: AppConstants.sourceManual,
        createdAt: now,
        updatedAt: now,
      ));

      await repository.addExpense(Expense(
        title: 'Vé xem phim CGV',
        amount: 110000,
        category: ExpenseCategory.entertainment,
        transactionDate: now,
        sourceType: AppConstants.sourceManual,
        createdAt: now,
        updatedAt: now,
      ));

      // Filter category
      final foodList = await repository.getExpenses(category: ExpenseCategory.food);
      expect(foodList.length, equals(1));
      expect(foodList.first.title, equals('Bún bò Huế'));

      // Filter query
      final searchResult = await repository.getExpenses(searchQuery: 'CGV');
      expect(searchResult.length, equals(1));
      expect(searchResult.first.title, equals('Vé xem phim CGV'));
    });

    test('getTotalAmount and getCategoryTotals calculate aggregates correctly', () async {
      final today = DateTime.now();
      await repository.addExpense(Expense(
        title: 'Cơm trưa',
        amount: 30000,
        category: ExpenseCategory.food,
        transactionDate: today,
        sourceType: AppConstants.sourceManual,
        createdAt: today,
        updatedAt: today,
      ));

      await repository.addExpense(Expense(
        title: 'Cà phê',
        amount: 25000,
        category: ExpenseCategory.food,
        transactionDate: today,
        sourceType: AppConstants.sourceManual,
        createdAt: today,
        updatedAt: today,
      ));

      await repository.addExpense(Expense(
        title: 'Grab bike',
        amount: 45000,
        category: ExpenseCategory.transport,
        transactionDate: today,
        sourceType: AppConstants.sourceManual,
        createdAt: today,
        updatedAt: today,
      ));

      final total = await repository.getTotalAmount();
      expect(total, equals(100000));

      final catTotals = await repository.getCategoryTotals(
        startDate: today.subtract(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 1)),
      );

      expect(catTotals[ExpenseCategory.food], equals(55000));
      expect(catTotals[ExpenseCategory.transport], equals(45000));
    });

    test('getSpendingSummary generates complete metrics', () async {
      final today = DateTime.now();
      await repository.addExpense(Expense(
        title: 'Siêu thị',
        amount: 200000,
        category: ExpenseCategory.shopping,
        transactionDate: today,
        sourceType: AppConstants.sourceManual,
        createdAt: today,
        updatedAt: today,
      ));

      final summary = await repository.getSpendingSummary(
        startDate: today.subtract(const Duration(days: 1)),
        endDate: today.add(const Duration(days: 1)),
      );

      expect(summary.totalAmount, equals(200000));
      expect(summary.transactionCount, equals(1));
      expect(summary.categoryBreakdown.first.category, equals(ExpenseCategory.shopping));
      expect(summary.categoryBreakdown.first.percentage, equals(100.0));
    });

    test('clearAll removes all expenses', () async {
      final now = DateTime.now();
      await repository.addExpense(Expense(
        title: 'Ăn tối',
        amount: 50000,
        category: ExpenseCategory.food,
        transactionDate: now,
        sourceType: AppConstants.sourceManual,
        createdAt: now,
        updatedAt: now,
      ));

      expect((await repository.getRecentExpenses()).length, equals(1));

      await repository.clearAll();
      expect((await repository.getRecentExpenses()).length, equals(0));
    });
  });
}
