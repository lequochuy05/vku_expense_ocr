import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/domain/models/expense_category.dart';
import 'package:vku_expense_ocr/domain/models/spending_summary.dart';
import 'package:vku_expense_ocr/features/statistics/presentation/widgets/donut_chart.dart';
import 'package:vku_expense_ocr/features/statistics/presentation/widgets/weekly_bar_chart.dart';

void main() {
  group('DonutChart Widget Tests', () {
    testWidgets('renders empty state when totalAmount is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DonutChart(
              categories: [],
              totalAmount: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    });

    testWidgets('renders properly with multiple categories and legends', (tester) async {
      final categories = [
        const CategorySummary(
          category: ExpenseCategory.food,
          totalAmount: 70000,
          transactionCount: 2,
          percentage: 70.0,
        ),
        const CategorySummary(
          category: ExpenseCategory.transport,
          totalAmount: 30000,
          transactionCount: 1,
          percentage: 30.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DonutChart(
                categories: categories,
                totalAmount: 100000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check center total and labels
      expect(find.text('Tổng'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Di chuyển'), findsOneWidget);
      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('30.0%'), findsOneWidget);
    });

    testWidgets('renders properly with a single category', (tester) async {
      final categories = [
        const CategorySummary(
          category: ExpenseCategory.shopping,
          totalAmount: 500000,
          transactionCount: 1,
          percentage: 100.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DonutChart(
                categories: categories,
                totalAmount: 500000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Mua sắm'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
    });
  });

  group('WeeklyBarChart Widget Tests', () {
    testWidgets('renders empty state when all 7 days have zero spending', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(dailyTotals: {}),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chưa có chi tiêu trong 7 ngày qua'), findsOneWidget);
    });

    testWidgets('renders bar chart when spending exists and handles taps', (tester) async {
      final today = DateTime.now();
      final dailyTotals = {
        today: 150000,
        today.subtract(const Duration(days: 1)): 80000,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyBarChart(dailyTotals: dailyTotals),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Chart custom painter rendered
      expect(find.byType(CustomPaint), findsWidgets);

      // Tap on the chart to trigger tooltip
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
    });
  });
}
