// Danh sách giao dịch có tìm kiếm, lọc, xóa, sửa
// Dùng ListView.builder (không dùng SingleChildScrollView + Column)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_category.dart';
import '../../../data/repositories/expense_repository_impl.dart';
import '../../../routing/app_router.dart';
import '../../dashboard/presentation/widgets/expense_summary_card.dart';

// Filter state — lưu trạng thái search và filter
class ExpenseFilter {
  const ExpenseFilter({
    this.searchQuery = '',
    this.category,
    this.startDate,
    this.endDate,
    this.sortBy = 'transaction_date',
    this.descending = true,
  });

  final String searchQuery;
  final ExpenseCategory? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final bool descending;

  ExpenseFilter copyWith({
    String? searchQuery,
    Object? category = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    String? sortBy,
    bool? descending,
  }) {
    return ExpenseFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category == _sentinel
          ? this.category
          : category as ExpenseCategory?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
    );
  }

  static const _sentinel = Object();
}

class ExpenseFilterNotifier extends StateNotifier<ExpenseFilter> {
  ExpenseFilterNotifier() : super(const ExpenseFilter());

  void update(ExpenseFilter filter) => state = filter;

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setCategory(ExpenseCategory? category) =>
      state = state.copyWith(category: category);

  void reset() => state = const ExpenseFilter();
}

final expenseFilterNotifierProvider =
    StateNotifierProvider<ExpenseFilterNotifier, ExpenseFilter>((ref) {
  return ExpenseFilterNotifier();
});

final filteredExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final filter = ref.watch(expenseFilterNotifierProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses(
    searchQuery: filter.searchQuery.isEmpty ? null : filter.searchQuery,
    category: filter.category,
    startDate: filter.startDate,
    endDate: filter.endDate,
    sortBy: filter.sortBy,
    descending: filter.descending,
  );
});

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final filter = ref.watch(expenseFilterNotifierProvider);
    final filterNotifier = ref.read(expenseFilterNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
        actions: [
          // Nút xóa filter
          if (filter.category != null ||
              filter.startDate != null ||
              filter.searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                filterNotifier.reset();
                _searchController.clear();
              },
              tooltip: 'Xóa bộ lọc',
            ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên, cửa hàng...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: null,
              ),
              onChanged: filterNotifier.setSearch,
            ),
          ),
          // Filter danh mục
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: filter.category == null,
                  onSelected: (_) => filterNotifier.setCategory(null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 14, color: cat.color),
                        const SizedBox(width: 4),
                        Text(cat.displayName),
                      ],
                    ),
                    selected: filter.category == cat,
                    onSelected: (selected) =>
                        filterNotifier.setCategory(selected ? cat : null),
                  ),
                )),
              ],
            ),
          ),
          // Danh sách giao dịch
          Expanded(
            child: expensesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Lỗi: ${e.toString()}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(filteredExpensesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (expenses) => expenses.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(filteredExpensesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          // Dismissible để vượt xóa có xác nhận
                          return Dismissible(
                            key: ValueKey(expense.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) =>
                                _confirmDelete(context, expense),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.delete_outlined,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                            onDismissed: (_) => _deleteExpense(expense),
                            child: ExpenseSummaryCard(
                              expense: expense,
                              onTap: () => context.push(
                                AppRoutes.editExpense.replaceFirst(
                                    ':id', '${expense.id}'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addExpense),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, Expense expense) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: Text(
          'Xóa "${expense.merchant ?? expense.title}"?\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final repo = ref.read(expenseRepositoryProvider);
    try {
      await repo.deleteExpense(expense.id!);
      ref.invalidate(filteredExpensesProvider);
      // Invalidate dashboard cũng
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${expense.merchant ?? expense.title}"'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $e')),
        );
      }
    }
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
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy giao dịch nào',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
