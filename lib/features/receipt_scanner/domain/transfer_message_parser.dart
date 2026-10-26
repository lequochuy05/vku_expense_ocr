// TransferMessageParser — phân tích tin nhắn chuyển khoản ngân hàng
// Người dùng dán tin nhắn vào app — không cần quyền SMS
//
// Phân biệt tiền chuyển đi và tiền nhận vào để tránh nhầm lẫn
library;

import '../../../core/utils/currency_formatter.dart';

/// Loại giao dịch trong tin nhắn ngân hàng
enum TransferType {
  outgoing,  // Chuyển tiền ra (chi tiêu)
  incoming,  // Nhận tiền vào (thu nhập — không tự động lưu vào chi tiêu)
  unknown,   // Không xác định được
}

/// Kết quả phân tích tin nhắn chuyển khoản
class TransferParseResult {
  const TransferParseResult({
    this.amount,
    this.transactionDate,
    this.transactionTime,
    this.recipient,
    this.transactionCode,
    this.transferType = TransferType.unknown,
    required this.rawMessage,
    this.warnings = const [],
  });

  final int? amount;
  final DateTime? transactionDate;
  final String? transactionTime;
  final String? recipient;
  final String? transactionCode;
  final TransferType transferType;
  final String rawMessage;
  final List<String> warnings;

  bool get isOutgoing => transferType == TransferType.outgoing;
  bool get hasAmount => amount != null;
}

class TransferMessageParser {
  /// Phân tích tin nhắn ngân hàng
  static TransferParseResult parse(String message) {
    if (message.trim().isEmpty) {
      return TransferParseResult(
        rawMessage: message,
        warnings: ['Tin nhắn trống'],
      );
    }

    final warnings = <String>[];

    final type = _detectTransferType(message, warnings);
    final amount = _extractAmount(message, warnings);
    final dateTime = _extractDateTime(message, warnings);
    final recipient = _extractRecipient(message, type);
    final code = _extractTransactionCode(message);

    return TransferParseResult(
      amount: amount,
      transactionDate: dateTime?.$1,
      transactionTime: dateTime?.$2,
      recipient: recipient,
      transactionCode: code,
      transferType: type,
      rawMessage: message,
      warnings: warnings,
    );
  }

  // Xác định loại giao dịch
  static TransferType _detectTransferType(
      String message, List<String> warnings) {
    final lower = message.toLowerCase();

    // Dấu hiệu chuyển tiền ra
    if (RegExp(
      r'(?:đã\s*chuyển|chuyển\s*khoản\s*thành\s*công|thanh\s*toán|'
      r'you\s*have\s*sent|transfer\s*successful|chi\s*tiêu|payment)',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return TransferType.outgoing;
    }

    // Dấu hiệu nhận tiền vào
    if (RegExp(
      r'(?:nhận\s*được|đã\s*nhận|bạn\s*nhận|received|credit|số\s*dư\s*tăng)',
      caseSensitive: false,
    ).hasMatch(lower)) {
      warnings.add('Đây là giao dịch nhận tiền — hãy xác nhận trước khi lưu');
      return TransferType.incoming;
    }

    warnings.add('Không xác định được loại giao dịch (chuyển/nhận)');
    return TransferType.unknown;
  }

  // Trích xuất số tiền — ưu tiên mẫu có đơn vị tiền tệ rõ ràng
  static final _explicitAmountPattern = RegExp(
    r'(?:(?:số\s*tiền|amount|tiền|thanh\s*toán|thành\s*công)\s*:?\s*)?'
    r'(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:VND|vnd|₫|đ|đồng)',
    caseSensitive: false,
  );

  static final _fallbackAmountPattern = RegExp(
    r'(?:(?:số\s*tiền|amount|tiền|thanh\s*toán)\s*:?\s*)'
    r'(\d{1,3}(?:[.,]\d{3})+|\d+)',
    caseSensitive: false,
  );

  static int? _extractAmount(String message, List<String> warnings) {
    // Ưu tiên 1: Có đơn vị tiền tệ rõ ràng (VND, đ, ₫, đồng)
    final explicitMatches = _explicitAmountPattern.allMatches(message);
    for (final match in explicitMatches) {
      final raw = match.group(1) ?? '';
      final amount = CurrencyFormatter.parse(raw);
      if (amount != null && amount >= 1000) {
        return amount;
      }
    }

    // Ưu tiên 2: Có nhãn số tiền / amount đi kèm
    final fallbackMatches = _fallbackAmountPattern.allMatches(message);
    for (final match in fallbackMatches) {
      final raw = match.group(1) ?? '';
      final amount = CurrencyFormatter.parse(raw);
      if (amount != null && amount >= 1000) {
        return amount;
      }
    }

    // Ưu tiên 3: Tìm số có định dạng phân cách nghìn trong nội dung
    final genericPattern = RegExp(r'\b(\d{1,3}(?:[.,]\d{3})+)\b');
    final genericMatches = genericPattern.allMatches(message);
    final candidates = <int>[];
    for (final match in genericMatches) {
      final raw = match.group(1) ?? '';
      final amount = CurrencyFormatter.parse(raw);
      if (amount != null && amount >= 1000) {
        candidates.add(amount);
      }
    }

    if (candidates.isNotEmpty) {
      return candidates.first;
    }

    warnings.add('Không tìm thấy số tiền trong tin nhắn');
    return null;
  }

  // Trích xuất ngày và giờ
  static final _dateTimePatterns = [
    // dd/MM/yyyy HH:mm hoặc dd/MM/yyyy HH:mm:ss
    RegExp(
        r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?'),
    // Chỉ ngày
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
  ];

  static (DateTime, String?)? _extractDateTime(String message, List<String> warnings) {
    for (final pattern in _dateTimePatterns) {
      final match = pattern.firstMatch(message);
      if (match == null) continue;

      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);

        if (month < 1 || month > 12 || day < 1 || day > 31) continue;

        final date = DateTime(year, month, day);
        String? timeStr;

        if (match.groupCount >= 5 && match.group(4) != null) {
          final hour = match.group(4)!;
          final minute = match.group(5)!;
          timeStr = '$hour:$minute';
        }

        return (date, timeStr);
      } catch (_) {
        continue;
      }
    }

    warnings.add('Không tìm thấy ngày trong tin nhắn');
    return null;
  }

  // Trích xuất tên người nhận
  static final _recipientPatterns = [
    RegExp(r'(?:đến|to|tới)\s+([A-ZĐÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂẮẶẤẦẨẪẬẮẸẺẼỄỆĨỘỔỐỒỔỖỘỤỨỮỰỶỸ][^\n,]{3,30})', caseSensitive: false),
    RegExp(r'(?:người\s*nhận|recipient)\s*:?\s*([^\n,]{3,30})', caseSensitive: false),
    RegExp(r'(?:tại|at)\s+([A-Z][^\n,]{3,30})', caseSensitive: false),
  ];

  static String? _extractRecipient(String message, TransferType type) {
    for (final pattern in _recipientPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length >= 3) {
          return name;
        }
      }
    }
    return null;
  }

  // Trích xuất mã giao dịch
  static final _codePattern = RegExp(
    r'(?:mã\s*gd|ma\s*gd|mã\s*giao\s*dịch|ma\s*giao\s*dich|mã\s*tham\s*chiếu|số\s*gd|transaction\s*id|ref(?:erence)?\s*(?:no\.?|id)?|trace)\s*:?\s*([A-Z0-9]{6,20})',
    caseSensitive: false,
  );

  static String? _extractTransactionCode(String message) {
    final match = _codePattern.firstMatch(message);
    return match?.group(1);
  }
}
