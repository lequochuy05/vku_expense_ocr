// Model chính cho giao dịch chi tiêu
// amount lưu dạng int (đơn vị VND) để tránh lỗi số thực
library;

import 'expense_category.dart';

/// Model một giao dịch chi tiêu
class Expense {
  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.transactionDate,
    this.note,
    this.merchant,
    required this.sourceType,
    this.rawOcrText,
    this.imagePath,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;

  /// Tên giao dịch / mô tả
  final String title;

  /// Số tiền (VND), lưu dạng int để tránh lỗi dấu phẩy động
  final int amount;

  /// Danh mục chi tiêu
  final ExpenseCategory category;

  /// Ngày giao dịch (ISO 8601: yyyy-MM-dd)
  final DateTime transactionDate;

  /// Ghi chú tùy chọn
  final String? note;

  /// Tên cửa hàng / người nhận
  final String? merchant;

  /// Nguồn nhập liệu: 'manual', 'ocr', 'transfer'
  final String sourceType;

  /// Văn bản OCR gốc (chỉ có khi sourceType == 'ocr')
  final String? rawOcrText;

  /// Đường dẫn ảnh hóa đơn (chỉ lưu path, không lưu base64)
  final String? imagePath;

  /// Phương thức thanh toán: 'cash', 'card', 'transfer', null
  final String? paymentMethod;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tạo bản copy có sửa đổi một số trường
  Expense copyWith({
    int? id,
    String? title,
    int? amount,
    ExpenseCategory? category,
    DateTime? transactionDate,
    String? note,
    String? merchant,
    String? sourceType,
    String? rawOcrText,
    String? imagePath,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      sourceType: sourceType ?? this.sourceType,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      imagePath: imagePath ?? this.imagePath,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Chuyển đổi sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'note': note,
      'merchant': merchant,
      'source_type': sourceType,
      'raw_ocr_text': rawOcrText,
      'image_path': imagePath,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Tạo Expense từ Map SQLite
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as int,
      category: ExpenseCategory.fromString(map['category'] as String),
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      note: map['note'] as String?,
      merchant: map['merchant'] as String?,
      sourceType: map['source_type'] as String,
      rawOcrText: map['raw_ocr_text'] as String?,
      imagePath: map['image_path'] as String?,
      paymentMethod: map['payment_method'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Expense(id: $id, title: $title, amount: $amount, date: $transactionDate)';
}
