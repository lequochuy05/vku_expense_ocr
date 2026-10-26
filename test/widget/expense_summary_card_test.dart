import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/constants/app_constants.dart';
import 'package:vku_expense_ocr/core/utils/currency_formatter.dart';
import 'package:vku_expense_ocr/domain/models/expense.dart';
import 'package:vku_expense_ocr/domain/models/expense_category.dart';
import 'package:vku_expense_ocr/features/dashboard/presentation/widgets/expense_summary_card.dart';

void main() {
  group('ExpenseSummaryCard Widget Tests', () {
    testWidgets('renders transaction details and source badges', (tester) async {
      final now = DateTime.now();
      final expense = Expense(
        id: 1,
        title: 'Trà sữa Gong Cha',
        amount: 65000,
        category: ExpenseCategory.food,
        transactionDate: now,
        sourceType: AppConstants.sourceOcr,
        merchant: 'Gong Cha',
        createdAt: now,
        updatedAt: now,
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              expense: expense,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & merchant
      expect(find.text('Trà sữa Gong Cha'), findsOneWidget);
      expect(find.text('Gong Cha'), findsOneWidget);

      // Verify formatted VND amount
      expect(find.text(CurrencyFormatter.format(65000)), findsOneWidget);

      // Verify category icon
      expect(find.byIcon(ExpenseCategory.food.icon), findsOneWidget);

      // Verify OCR badge
      expect(find.text('OCR'), findsOneWidget);

      // Tap card
      await tester.tap(find.byType(ExpenseSummaryCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders transfer source badge', (tester) async {
      final now = DateTime.now();
      final expense = Expense(
        id: 2,
        title: 'Chuyển tiền trọ',
        amount: 1500000,
        category: ExpenseCategory.housing,
        transactionDate: now,
        sourceType: AppConstants.sourceTransfer,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(expense: expense),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chuyển khoản'), findsOneWidget);
    });
  });
}
