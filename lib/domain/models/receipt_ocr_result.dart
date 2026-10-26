// Kết quả từ Regex parser sau khi phân tích OCR text
// Tất cả trường đều nullable — parser không tự đặt giá trị mặc định khi không chắc
library;

import 'expense_category.dart';

/// Mức độ tin cậy của kết quả phân tích
enum OcrConfidence {
  high,    // Có nhãn rõ ràng, số tiền duy nhất, ngày hợp lệ
  medium,  // Có một số tín hiệu nhưng không chắc chắn
  low,     // Nhiều ứng viên cạnh tranh hoặc không có nhãn
  unknown, // Không có dữ liệu
}

/// Kết quả phân tích hóa đơn từ OCR text
/// Confidence phản ánh chất lượng trích xuất thực tế
class ReceiptOcrResult {
  const ReceiptOcrResult({
    this.merchant,
    this.amount,
    this.transactionDate,
    this.categorySuggestion,
    this.paymentMethod,
    required this.rawText,
    required this.confidence,
    this.warnings = const [],
    this.isDateDefault = false,
  });

  /// Tên cửa hàng/merchant (có thể null nếu không tìm thấy)
  final String? merchant;

  /// Tổng tiền VND (int, null nếu không xác định được)
  final int? amount;

  /// Ngày giao dịch (null nếu không tìm thấy trong OCR)
  final DateTime? transactionDate;

  /// Gợi ý danh mục (null nếu không có gợi ý)
  final ExpenseCategory? categorySuggestion;

  /// Phương thức thanh toán nếu xác định được
  final String? paymentMethod;

  /// Văn bản OCR gốc để người dùng kiểm tra
  final String rawText;

  /// Mức độ tin cậy của kết quả
  final OcrConfidence confidence;

  /// Danh sách cảnh báo: "Không tìm thấy nhãn TOTAL", "Ngày mặc định", v.v.
  final List<String> warnings;

  /// true nếu transactionDate là ngày hiện tại (mặc định, chưa xác nhận từ OCR)
  final bool isDateDefault;

  bool get hasAmount => amount != null;
  bool get hasMerchant => merchant != null;
  bool get hasDate => transactionDate != null;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    return 'ReceiptOcrResult(merchant: $merchant, amount: $amount, '
        'date: $transactionDate, confidence: $confidence, '
        'warnings: $warnings)';
  }
}
