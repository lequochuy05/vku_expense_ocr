// Định dạng tiền Việt Nam (VND)
// VND không có số thập phân — luôn là số nguyên
// Format: 1.250.000 ₫ (dấu chấm phân cách hàng nghìn, ký hiệu ₫ ở sau)
library;

import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  // NumberFormat với locale 'vi' cho định dạng số Việt Nam
  // Dùng 'vi' vì 'vi_VN' cần package intl đầy đủ
  static final _formatter = NumberFormat('#,###', 'vi');

  /// Format số tiền VND thành chuỗi hiển thị
  /// Ví dụ: 1250000 → "1.250.000 ₫"
  static String format(int amount) {
    // Với locale vi, dấu phân cách nghìn là dấu chấm (.)
    return '${_formatter.format(amount)} ₫';
  }

  /// Format ngắn gọn cho thẻ tóm tắt
  /// Ví dụ: 1250000 → "1.25M ₫" hoặc "1.250.000 ₫"
  static String formatCompact(int amount) {
    if (amount >= 1000000000) {
      final billions = amount / 1000000000;
      return '${_formatDecimal(billions)}B ₫';
    } else if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${_formatDecimal(millions)}M ₫';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${_formatDecimal(thousands)}K ₫';
    }
    return format(amount);
  }

  static String _formatDecimal(double value) {
    if (value == value.truncate()) {
      return value.truncate().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Parse chuỗi tiền VND về int
  /// Hỗ trợ: "1.250.000", "1,250,000", "1250000", "125000đ", "125.000 VND"
  /// Trả về null nếu không parse được
  static int? parse(String text) {
    if (text.isEmpty) return null;

    // Loại bỏ mọi ký tự chữ, ký hiệu tiền tệ và khoảng trắng, chỉ giữ lại số và dấu chấm, phẩy
    var cleaned = text.replaceAll(RegExp(r'[^\d.,]'), '').trim();

    if (cleaned.isEmpty) return null;

    // Xác định xem dấu chấm hay phẩy là phân cách nghìn
    // Trong VND: "1.250.000" (chấm = nghìn), "1,250,000" (phẩy = nghìn)
    // Không có số thập phân trong VND
    final dotCount = '.'.allMatches(cleaned).length;
    final commaCount = ','.allMatches(cleaned).length;

    String normalized;
    if (dotCount > 1) {
      // Nhiều dấu chấm → phân cách nghìn theo kiểu VN: 1.250.000
      normalized = cleaned.replaceAll('.', '');
    } else if (commaCount > 1) {
      // Nhiều dấu phẩy → phân cách nghìn: 1,250,000
      normalized = cleaned.replaceAll(',', '');
    } else if (dotCount == 1 && commaCount == 0) {
      // Chỉ có 1 dấu chấm — có thể là 125.000 (nghìn VN) hoặc 125.5 (thập phân)
      // Trong ngữ cảnh VND, nếu sau dấu chấm có đúng 3 chữ số → nghìn
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = cleaned.replaceAll('.', '');
      } else {
        // Có thể là số thập phân — VND không có số lẻ
        // Làm tròn lên
        normalized = cleaned.replaceAll('.', '');
      }
    } else if (commaCount == 1 && dotCount == 0) {
      // Chỉ có 1 dấu phẩy — kiểu 125,000 (nghìn theo EN) hoặc 125,5
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length == 3) {
        normalized = cleaned.replaceAll(',', '');
      } else {
        normalized = cleaned.replaceAll(',', '');
      }
    } else {
      // Không có dấu phân cách → số thuần
      normalized = cleaned.replaceAll(',', '').replaceAll('.', '');
    }

    return int.tryParse(normalized.trim());
  }
}
