// Form thêm/sửa giao dịch với validate đầy đủ
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_category.dart';
import '../../../data/repositories/expense_repository_impl.dart';

final expenseByIdProvider =
    FutureProvider.family<Expense?, int>((ref, id) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpense(id);
});

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  const AddEditExpenseScreen({super.key, this.expenseId, this.initialData});

  final int? expenseId;
  // initialData dùng khi chuyển từ OCR review
  final Map<String, dynamic>? initialData;

  @override
  ConsumerState<AddEditExpenseScreen> createState() =>
      _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expenseId != null;
    _applyInitialData();
  }

  void _applyInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _titleController.text = data['title'] as String? ?? '';
      _amountController.text =
          (data['amount'] as int?)?.toString() ?? '';
      _merchantController.text = data['merchant'] as String? ?? '';
      _noteController.text = data['note'] as String? ?? '';
      if (data['category'] is ExpenseCategory) {
        _selectedCategory = data['category'] as ExpenseCategory;
      }
      if (data['date'] is DateTime) {
        _selectedDate = data['date'] as DateTime;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang sửa, load dữ liệu từ DB
    if (_isEdit && widget.expenseId != null) {
      final expenseAsync =
          ref.watch(expenseByIdProvider(widget.expenseId!));
      return expenseAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Lỗi')),
          body: Center(child: Text('Lỗi: $e')),
        ),
        data: (expense) {
          if (expense != null && _titleController.text.isEmpty) {
            // Điền form lần đầu tiên
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _titleController.text = expense.title;
              _amountController.text = expense.amount.toString();
              _merchantController.text = expense.merchant ?? '';
              _noteController.text = expense.note ?? '';
              setState(() {
                _selectedCategory = expense.category;
                _selectedDate = expense.transactionDate;
                _paymentMethod = expense.paymentMethod ?? 'cash';
              });
            });
          }
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tên giao dịch
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên giao dịch *',
                hintText: 'Ví dụ: Mua cà phê',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập tên giao dịch' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Số tiền
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền (VND) *',
                hintText: 'Ví dụ: 50000',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: '₫',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                final amount = int.tryParse(v.trim());
                if (amount == null || amount <= 0) {
                  return 'Số tiền phải là số nguyên dương';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tên cửa hàng
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Tên cửa hàng (tùy chọn)',
                hintText: 'Ví dụ: Highlands Coffee',
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Danh mục
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Danh mục *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: cat.color),
                      const SizedBox(width: 8),
                      Text(cat.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat != null) setState(() => _selectedCategory = cat);
              },
            ),
            const SizedBox(height: 16),

            // Ngày giao dịch
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('Ngày giao dịch: ${DateFormatter.formatDate(_selectedDate)}'),
              trailing: const Icon(Icons.edit_outlined),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // Phương thức thanh toán
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Phương thức thanh toán',
                prefixIcon: Icon(Icons.payment_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                DropdownMenuItem(value: 'card', child: Text('Thẻ')),
                DropdownMenuItem(value: 'transfer', child: Text('Chuyển khoản')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _paymentMethod = v);
              },
            ),
            const SizedBox(height: 16),

            // Ghi chú
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Thêm ghi chú...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Nút lưu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveExpense,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isEdit ? Icons.save : Icons.add),
              label: Text(_isEdit ? 'Lưu thay đổi' : 'Thêm giao dịch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final amount = int.parse(_amountController.text.trim());

    final expense = Expense(
      id: _isEdit ? widget.expenseId : null,
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      transactionDate: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      merchant: _merchantController.text.trim().isEmpty
          ? null
          : _merchantController.text.trim(),
      sourceType: AppConstants.sourceManual,
      paymentMethod: _paymentMethod,
      createdAt: _isEdit ? now : now,
      updatedAt: now,
    );

    try {
      final repo = ref.read(expenseRepositoryProvider);
      if (_isEdit) {
        await repo.updateExpense(expense);
      } else {
        await repo.addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Đã cập nhật giao dịch' : 'Đã thêm giao dịch thành công'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
