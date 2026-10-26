import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/features/receipt_scanner/domain/transfer_message_parser.dart';

void main() {
  group('TransferMessageParser Unit Tests', () {
    test('parses outgoing bank transfer correctly', () {
      const msg =
          'Bạn đã chuyển khoản thành công 250,000 VND đến NGUYEN VAN A lúc 12/10/2026 14:30. Mã GD: FT2628591823.';
      final result = TransferMessageParser.parse(msg);

      expect(result.amount, equals(250000));
      expect(result.transferType, equals(TransferType.outgoing));
      expect(result.isOutgoing, isTrue);
      expect(result.transactionDate, equals(DateTime(2026, 10, 12)));
      expect(result.transactionTime, equals('14:30'));
      expect(result.recipient, contains('NGUYEN VAN A'));
      expect(result.transactionCode, equals('FT2628591823'));
    });

    test('parses merchant payment transfer message', () {
      const msg =
          'Giao dịch thanh toán 85.000đ tại COFFEE HOUSE ngày 10/10/2026 09:15.';
      final result = TransferMessageParser.parse(msg);

      expect(result.amount, equals(85000));
      expect(result.transferType, equals(TransferType.outgoing));
      expect(result.recipient, contains('COFFEE HOUSE'));
      expect(result.transactionDate, equals(DateTime(2026, 10, 10)));
    });

    test('detects incoming transfer and warns user', () {
      const msg =
          'Tài khoản nhận được 1,000,000 VND từ TRAN THI B lúc 11/10/2026 10:00.';
      final result = TransferMessageParser.parse(msg);

      expect(result.amount, equals(1000000));
      expect(result.transferType, equals(TransferType.incoming));
      expect(result.isOutgoing, isFalse);
      expect(result.warnings,
          contains('Đây là giao dịch nhận tiền — hãy xác nhận trước khi lưu'));
    });

    test('ignores transaction codes when identifying amount', () {
      const msg =
          'Chuyen khoan thanh cong 120.000 VND toi NGUYEN VAN C. Ma giao dich 99887766554433.';
      final result = TransferMessageParser.parse(msg);

      expect(result.amount, equals(120000));
      expect(result.amount, isNot(equals(99887766554433)));
    });

    test('handles empty message', () {
      final result = TransferMessageParser.parse('   ');
      expect(result.amount, isNull);
      expect(result.warnings, contains('Tin nhắn trống'));
    });
  });
}
