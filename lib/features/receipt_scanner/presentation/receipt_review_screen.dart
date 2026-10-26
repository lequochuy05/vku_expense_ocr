// Màn hình xác nhận kết quả OCR trước khi lưu
// Người dùng có thể sửa tất cả trường
// Không tự động lưu — phải qua bước xác nhận
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/expense.dart';
import '../../../domain/models/expense_category.dart';
import '../../../domain/models/receipt_ocr_result.dart';
import '../../../data/repositories/expense_repository_impl.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  const ReceiptReviewScreen({super.key, this.ocrResult});
  final ReceiptOcrResult? ocrResult;

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _initFromOcr();
  }

  void _initFromOcr() {
    final result = widget.ocrResult;
    if (result == null) return;

    // Điền từ kết quả OCR
    _merchantController.text = result.merchant ?? '';
    _titleController.text = result.merchant ?? '';
    if (result.amount != null) {
      _amountController.text = result.amount.toString();
    }
    if (result.transactionDate != null) {
      _date = result.transactionDate!;
    }
    if (result.categorySuggestion != null) {
      _category = result.categorySuggestion!;
    }
    if (result.paymentMethod != null) {
      _paymentMethod = result.paymentMethod!;
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
    final theme = Theme.of(context);
    final result = widget.ocrResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận hóa đơn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Toggle xem OCR text gốc
          if (result != null)
            IconButton(
              icon: Icon(_showRawText
                  ? Icons.visibility_off
                  : Icons.text_snippet_outlined),
              onPressed: () =>
                  setState(() => _showRawText = !_showRawText),
              tooltip: 'Xem văn bản OCR gốc',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Badge độ tin cậy + cảnh báo
            if (result != null) _ConfidenceBadge(result: result),

            if (_showRawText && result != null) ...[
              const SizedBox(height: 12),
              _RawTextCard(rawText: result.rawText),
            ],

            const SizedBox(height: 16),

            // Tên giao dịch
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên giao dịch *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 16),

            // Số tiền — nổi bật nếu chưa xác nhận
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: result?.amount == null
                    ? 'Số tiền (cần nhập thủ công) *'
                    : 'Số tiền (VND) *',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₫',
                // Nổi bật nếu trường cần xác nhận
                filled: result?.amount == null,
                fillColor: result?.amount == null
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                final amount = int.tryParse(v);
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
                labelText: 'Tên cửa hàng',
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Danh mục
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
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
                if (cat != null) setState(() => _category = cat);
              },
            ),
            const SizedBox(height: 16),

            // Ngày giao dịch
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today_outlined,
                color: result?.isDateDefault == true
                    ? theme.colorScheme.error
                    : null,
              ),
              title: Text(
                result?.isDateDefault == true
                    ? '⚠ Ngày (mặc định, hãy kiểm tra lại): ${DateFormatter.formatDate(_date)}'
                    : 'Ngày giao dịch: ${DateFormatter.formatDate(_date)}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: result?.isDateDefault == true
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // Ghi chú
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Nút xác nhận lưu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveExpense,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Xác nhận và lưu'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Quay lại — không lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final amount = int.parse(_amountController.text.trim());

    final expense = Expense(
      title: _titleController.text.trim().isEmpty
          ? (_merchantController.text.trim().isEmpty ? 'Hóa đơn OCR' : _merchantController.text.trim())
          : _titleController.text.trim(),
      amount: amount,
      category: _category,
      transactionDate: _date,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      merchant: _merchantController.text.trim().isEmpty
          ? null
          : _merchantController.text.trim(),
      sourceType: AppConstants.sourceOcr,
      rawOcrText: widget.ocrResult?.rawText,
      paymentMethod: _paymentMethod,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.addExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu giao dịch thành công')),
        );
        // Quay về dashboard
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Badge hiển thị độ tin cậy và cảnh báo
class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.result});
  final ReceiptOcrResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (result.confidence) {
      OcrConfidence.high => ('✅ Độ tin cậy cao', Colors.green),
      OcrConfidence.medium => ('⚠ Độ tin cậy trung bình', Colors.orange),
      OcrConfidence.low => ('❌ Độ tin cậy thấp', Colors.red),
      OcrConfidence.unknown => ('❓ Không xác định', Colors.grey),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...result.warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 14,
                        color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        w,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
        const Text(
          'ℹ Hãy kiểm tra kỹ trước khi xác nhận',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

/// Card hiển thị raw OCR text
class _RawTextCard extends StatelessWidget {
  const _RawTextCard({required this.rawText});
  final String rawText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Văn bản OCR gốc:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              rawText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
