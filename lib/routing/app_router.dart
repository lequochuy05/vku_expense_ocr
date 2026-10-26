// go_router configuration cho VKU Expense AI
// Tất cả màn hình được đăng ký ở đây
// Không để navigation làm mất dữ liệu OCR chưa xác nhận
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/expenses/presentation/expense_list_screen.dart';
import '../features/expenses/presentation/add_edit_expense_screen.dart';
import '../features/receipt_scanner/presentation/receipt_scanner_screen.dart';
import '../features/receipt_scanner/presentation/receipt_review_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/ai_advisor/presentation/ai_advisor_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../domain/models/receipt_ocr_result.dart';

/// Tên route constants — tránh lỗi typo
class AppRoutes {
  AppRoutes._();

  static const dashboard = '/';
  static const expenseList = '/expenses';
  static const addExpense = '/expenses/add';
  static const editExpense = '/expenses/edit/:id';
  static const receiptScanner = '/scanner';
  static const receiptReview = '/scanner/review';
  static const statistics = '/statistics';
  static const aiAdvisor = '/ai-advisor';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    routes: [
      // Shell route với BottomNavigationBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.expenseList,
                builder: (context, state) => const ExpenseListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.aiAdvisor,
                builder: (context, state) => const AiAdvisorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Màn hình không thuộc shell (full-screen)
      GoRoute(
        path: AppRoutes.addExpense,
        builder: (context, state) => const AddEditExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.editExpense,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return AddEditExpenseScreen(expenseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.receiptScanner,
        builder: (context, state) => const ReceiptScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.receiptReview,
        builder: (context, state) {
          // Truyền dữ liệu OCR qua extra — không qua URL để bảo vệ dữ liệu nhạy cảm
          final ocrResult = state.extra as ReceiptOcrResult?;
          return ReceiptReviewScreen(ocrResult: ocrResult);
        },
      ),
    ],
  );
});

/// Shell widget với BottomNavigationBar
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
