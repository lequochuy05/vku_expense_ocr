// ReceiptParser — phân tích văn bản OCR từ hóa đơn Việt Nam
// Độc lập hoàn toàn với Flutter UI, dễ unit test
// 
// Thuật toán trích xuất tiền:
// 1. Tìm theo nhãn ưu tiên cao: TỔNG CỘNG, TỔNG THANH TOÁN, GRAND TOTAL
// 2. Tìm theo nhãn ưu tiên trung bình: THÀNH TIỀN, TOTAL, AMOUNT
// 3. Nếu không có nhãn, lấy số tiền lớn nhất gần cuối hóa đơn
// 4. Tính confidence dựa trên số ứng viên cạnh tranh
library;

import '../../../domain/models/receipt_ocr_result.dart';
import '../../../domain/models/expense_category.dart';
import '../../../core/utils/currency_formatter.dart';

class ReceiptParser {
  /// Phân tích toàn bộ OCR text và trả về ReceiptOcrResult
  static ReceiptOcrResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return ReceiptOcrResult(
        rawText: rawText,
        confidence: OcrConfidence.unknown,
        warnings: ['Văn bản OCR trống'],
      );
    }

    final lines = rawText.split('\n').map((l) => l.trim()).toList();
    final warnings = <String>[];

    // Trích xuất các trường
    final amountResult = _extractAmount(rawText, lines, warnings);
    final dateResult = _extractDate(rawText, lines, warnings);
    final merchant = _extractMerchant(lines, warnings);
    final paymentMethod = _extractPaymentMethod(rawText);
    final category = _suggestCategory(rawText, merchant);

    // Tính confidence tổng thể
    final confidence = _calculateConfidence(
      hasAmount: amountResult != null,
      hasDate: dateResult != null,
      hasMerchant: merchant != null,
      warnings: warnings,
    );

    return ReceiptOcrResult(
      merchant: merchant,
      amount: amountResult,
      transactionDate: dateResult?.$1,
      categorySuggestion: category,
      paymentMethod: paymentMethod,
      rawText: rawText,
      confidence: confidence,
      warnings: warnings,
      isDateDefault: dateResult?.$2 ?? false,
    );
  }

  // ===== TRÍCH XUẤT SỐ TIỀN =====

  // Nhãn tổng tiền theo thứ tự ưu tiên
  // Priority 1: nhãn rõ ràng nhất
  static final _highPriorityLabels = RegExp(
    r'(?:tổng\s*cộng|tổng\s*thanh\s*toán|grand\s*total|total\s*amount|'
    r'thành\s*tiền\s*thanh\s*toán|tổng\s*tiền\s*thanh\s*toán)',
    caseSensitive: false,
  );

  // Priority 2: nhãn phổ biến
  static final _mediumPriorityLabels = RegExp(
    r'(?:thành\s*tiền|total|amount|số\s*tiền|tiền\s*thanh\s*toán|'
    r'tổng|subtotal|net\s*total)',
    caseSensitive: false,
  );

  // Pattern số tiền VND hợp lệ (tối thiểu 1000 VND, tối đa 100 tỷ)
  // Hỗ trợ: 125.000, 125,000, 1.250.000, 125000, 125.000đ, 125.000 VND
  static final _amountPattern = RegExp(
    r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{3})?|\d{4,})\s*(?:[₫đd]|VND|vnd)?',
    caseSensitive: false,
  );

  // Các nhãn cần bỏ qua (tiền thừa, tiền trả lại, không phải tổng tiền thanh toán)
  static final _skipLabels = RegExp(
    r'(?:tiền\s*thừa|tiền\s*trả|tiền\s*hoàn|change|refund|discount|giảm\s*giá|'
    r'khuyến\s*mãi|voucher|coupon)',
    caseSensitive: false,
  );

  static int? _extractAmount(
      String rawText, List<String> lines, List<String> warnings) {
    // Bước 1: Tìm theo nhãn ưu tiên cao
    final highResult = _findAmountByLabel(lines, _highPriorityLabels);
    if (highResult != null) return highResult;

    // Bước 2: Tìm theo nhãn ưu tiên trung bình
    final medResult = _findAmountByLabel(lines, _mediumPriorityLabels);
    if (medResult != null) {
      return medResult;
    }

    // Bước 3: Không có nhãn — lấy số tiền hợp lệ lớn nhất ở nửa dưới hóa đơn
    warnings.add('Không tìm thấy nhãn tổng tiền — kết quả có thể không chính xác');
    return _findLargestAmountInLowerHalf(lines);
  }

  /// Tìm số tiền trên cùng dòng hoặc dòng tiếp theo của nhãn
  static int? _findAmountByLabel(List<String> lines, RegExp labelPattern) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Bỏ qua các dòng có nhãn tiền thừa/hoàn trả
      if (_skipLabels.hasMatch(line)) continue;

      if (labelPattern.hasMatch(line)) {
        // Tìm số tiền trên cùng dòng
        final amountOnSameLine = _parseAmountFromLine(line);
        if (amountOnSameLine != null) return amountOnSameLine;

        // Tìm trên dòng kế tiếp
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          if (!_skipLabels.hasMatch(nextLine)) {
            final amountOnNextLine = _parseAmountFromLine(nextLine);
            if (amountOnNextLine != null) return amountOnNextLine;
          }
        }
      }
    }
    return null;
  }

  /// Lấy số tiền lớn nhất từ nửa dưới hóa đơn (khi không có nhãn)
  static int? _findLargestAmountInLowerHalf(List<String> lines) {
    final startIndex = lines.length ~/ 2; // Nửa dưới
    int? largest;

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      if (_skipLabels.hasMatch(line)) continue;

      final amount = _parseAmountFromLine(line);
      if (amount != null && amount >= 1000) {
        // Ít nhất 1,000 VND
        if (largest == null || amount > largest) {
          largest = amount;
        }
      }
    }

    return largest;
  }

  /// Parse số tiền từ một dòng văn bản
  static int? _parseAmountFromLine(String line) {
    final matches = _amountPattern.allMatches(line);
    for (final match in matches) {
      final raw = match.group(1) ?? '';
      final amount = CurrencyFormatter.parse(raw);
      // Lọc số điện thoại (thường 10-11 chữ số liên tiếp) và mã giao dịch
      if (amount != null && amount >= 1000 && !_isPhoneOrCode(raw)) {
        return amount;
      }
    }
    return null;
  }

  /// Kiểm tra xem chuỗi có phải số điện thoại hay mã giao dịch không
  /// Số điện thoại VN: 10-11 chữ số liên tiếp, không có dấu phân cách hợp lệ
  static bool _isPhoneOrCode(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // Số điện thoại VN có 10-11 chữ số, bắt đầu bằng 0 hoặc 84
    if (digitsOnly.length >= 9 && digitsOnly.length <= 11) {
      if (digitsOnly.startsWith('0') || digitsOnly.startsWith('84')) {
        return true;
      }
    }
    // Mã giao dịch thường rất dài (>= 12 chữ số liên tiếp)
    if (digitsOnly.length >= 12) return true;
    return false;
  }

  // ===== TRÍCH XUẤT NGÀY =====

  // Các pattern ngày phổ biến trên hóa đơn VN
  static final _datePatterns = [
    // dd/MM/yyyy hoặc dd-MM-yyyy
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})', caseSensitive: false),
    // yyyy-MM-dd (ISO)
    RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})', caseSensitive: false),
    // dd/MM/yy
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})\b', caseSensitive: false),
    // "Ngày dd tháng MM năm yyyy"
    RegExp(
      r'ngày\s+(\d{1,2})\s+tháng\s+(\d{1,2})\s+năm\s+(\d{4})',
      caseSensitive: false,
    ),
  ];

  /// Trả về (DateTime, isDefault)
  static (DateTime, bool)? _extractDate(
      String rawText, List<String> lines, List<String> warnings) {
    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(rawText);
      if (match == null) continue;

      try {
        final isIso = pattern.pattern.startsWith(r'(\d{4})');
        final isVn = pattern.pattern.contains('ngày');

        int day, month, year;

        if (isIso) {
          year = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          day = int.parse(match.group(3)!);
        } else if (isVn) {
          day = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          year = int.parse(match.group(3)!);
        } else {
          // dd/MM/yyyy hoặc dd/MM/yy
          day = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          final rawYear = int.parse(match.group(3)!);
          // Xử lý năm 2 chữ số: 00-49 → 2000-2049, 50-99 → 1950-1999
          year = rawYear < 100
              ? (rawYear < 50 ? 2000 + rawYear : 1900 + rawYear)
              : rawYear;
        }

        // Validate ngày
        if (month < 1 || month > 12 || day < 1 || day > 31) continue;
        if (year < 2000 || year > 2100) continue;

        final date = DateTime(year, month, day);
        // Kiểm tra ngày hợp lệ (DateTime tự điều chỉnh ngày sai)
        if (date.month != month || date.day != day) continue;

        return (date, false);
      } catch (_) {
        continue;
      }
    }

    warnings.add('Không tìm thấy ngày trong hóa đơn — sử dụng ngày hôm nay làm mặc định');
    return null; // Không trả về ngày mặc định ở đây — để UI quyết định
  }

  // ===== TRÍCH XUẤT MERCHANT =====

  // Pattern các dòng cần bỏ qua khi tìm merchant
  static final _skipMerchantPatterns = [
    RegExp(r'^\d+$'), // Chỉ có số
    RegExp(r'^\+?\d[\d\s\-()]{8,}$'), // Số điện thoại
    RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}'), // Ngày tháng
    RegExp(r'^[A-Z0-9]{8,}$'), // Mã giao dịch (toàn chữ hoa và số)
    RegExp(
      r'(?:địa\s*chỉ|dia\s*chi|address|tel|phone|fax|email|website|www\.|hotline)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:hóa\s*đơn|hoa\s*don|invoice|receipt|phiếu|phieu|bill|no\.|số\s*:|so\s*:)',
      caseSensitive: false,
    ),
  ];

  static String? _extractMerchant(List<String> lines, List<String> warnings) {
    // Ưu tiên các dòng đầu — thường là tên cửa hàng
    for (int i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      if (line.length < 3) continue; // Quá ngắn

      bool skip = false;
      for (final pattern in _skipMerchantPatterns) {
        if (pattern.hasMatch(line)) {
          skip = true;
          break;
        }
      }
      if (skip) continue;

      // Loại bỏ số ở đầu dòng
      final cleaned = line.replaceAll(RegExp(r'^[\d\s*]+'), '').trim();
      if (cleaned.length >= 3) {
        return _capitalize(cleaned);
      }
    }

    warnings.add('Không xác định được tên cửa hàng');
    return null;
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    final words = text.split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  // ===== TRÍCH XUẤT PHƯƠNG THỨC THANH TOÁN =====

  static String? _extractPaymentMethod(String rawText) {
    final lower = rawText.toLowerCase();
    if (lower.contains('tiền mặt') ||
        lower.contains('tien mat') ||
        lower.contains('cash')) {
      return 'cash';
    }
    if (lower.contains('thẻ') ||
        lower.contains('the ') ||
        lower.contains('card') ||
        lower.contains('visa') ||
        lower.contains('mastercard')) {
      return 'card';
    }
    if (lower.contains('chuyển khoản') ||
        lower.contains('chuyen khoan') ||
        lower.contains('transfer') ||
        lower.contains('momo') ||
        lower.contains('vnpay') ||
        lower.contains('zalopay')) {
      return 'transfer';
    }
    return null;
  }

  // ===== GỢI Ý DANH MỤC =====

  static ExpenseCategory? _suggestCategory(String rawText, String? merchant) {
    final combined = '$rawText ${merchant ?? ''}';
    return ExpenseCategory.suggestFromText(combined);
  }

  // ===== TÍNH CONFIDENCE =====

  static OcrConfidence _calculateConfidence({
    required bool hasAmount,
    required bool hasDate,
    required bool hasMerchant,
    required List<String> warnings,
  }) {
    if (!hasAmount) return OcrConfidence.low;

    final score = (hasAmount ? 3 : 0) +
        (hasDate ? 2 : 0) +
        (hasMerchant ? 1 : 0) -
        warnings.length;

    if (score >= 5) return OcrConfidence.high;
    if (score >= 3) return OcrConfidence.medium;
    return OcrConfidence.low;
  }
}
